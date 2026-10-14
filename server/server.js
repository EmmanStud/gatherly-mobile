"use strict";

const crypto = require("node:crypto");
const path = require("node:path");
const { promisify } = require("node:util");
const express = require("express");
const dotenv = require("dotenv");
const jwt = require("jsonwebtoken");
const { MongoClient, ObjectId } = require("mongodb");

dotenv.config({ path: path.join(__dirname, ".env") });

const app = express();
const scrypt = promisify(crypto.scrypt);
const passwordSpecialCharacters = "!@#$%^&*()_+-=[]{}|;:'\",.<>/?~`";
const emailJsTemplateId = "template_gyx5ecm";
const verificationLifetimeMs = 10 * 60 * 1000;
const verificationResendDelayMs = 60 * 1000;
const verificationMaxAttempts = 5;
const passwordResetLifetimeMs = 10 * 60 * 1000;
const corsOrigins = new Set(
  (process.env.CORS_ORIGINS || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
);

app.disable("x-powered-by");
app.use((req, res, next) => {
  res.vary("Origin");
  const origin = req.get("origin");
  if (origin && corsOrigins.has(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  } else if (origin && req.method === "OPTIONS") {
    return res.status(403).json({ error: "Origin is not allowed." });
  }
  if (req.method === "OPTIONS") return res.status(204).end();
  next();
});
app.use(express.json({ limit: "32kb" }));

let databasePromise;

async function getDatabase() {
  if (!databasePromise) {
    databasePromise = (async () => {
      const uri = process.env.MONGODB_URI;
      if (!uri) throw new Error("MONGODB_URI is not configured.");
      if (!process.env.JWT_SECRET) throw new Error("JWT_SECRET is not configured.");

      const client = new MongoClient(uri, { serverSelectionTimeoutMS: 10000 });
      await client.connect();
      const database = client.db("Gatherly");
      await Promise.all([
        database.collection("customer_accounts").createIndex({ email: 1 }, { unique: true }),
        database.collection("admin_accounts").createIndex({ email: 1 }, { unique: true }),
        database.collection("email_verifications").createIndex({ email: 1 }, { unique: true }),
        database.collection("email_verifications").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
        database.collection("password_resets").createIndex({ email: 1 }, { unique: true }),
        database.collection("password_resets").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
      ]);
      return { client, database };
    })().catch((error) => {
      databasePromise = undefined;
      throw error;
    });
  }
  return databasePromise;
}

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

app.use(asyncRoute(async (req, res, next) => {
  const { database } = await getDatabase();
  req.db = database;
  next();
}));

function validString(value, maxLength) {
  return typeof value === "string" && value.trim().length > 0 && value.length <= maxLength;
}

function isValidEmail(email) {
  return validString(email, 254) && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

function hasValidPasswordComplexity(password) {
  return /[A-Z]/.test(password)
    && /[a-z]/.test(password)
    && /\d/.test(password)
    && [...password].some((character) => passwordSpecialCharacters.includes(character));
}

async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const passwordHash = (await scrypt(password, salt, 64)).toString("hex");
  return { passwordHash, passwordSalt: salt };
}

async function verifyPassword(password, account) {
  if (!account?.passwordHash || !account.passwordSalt) return false;
  const candidateHash = await scrypt(password, account.passwordSalt, 64);
  const storedHash = Buffer.from(account.passwordHash, "hex");
  return candidateHash.length === storedHash.length
    && crypto.timingSafeEqual(candidateHash, storedHash);
}

function hashVerificationCode(email, code) {
  return crypto.createHmac("sha256", process.env.JWT_SECRET)
    .update(`${email}:${code}`)
    .digest("hex");
}

function createSessionToken(userId, accountType) {
  return jwt.sign(
    { sub: userId, accountType },
    process.env.JWT_SECRET,
    { algorithm: "HS256", expiresIn: "7d" },
  );
}

function getBearerToken(req) {
  const authorization = req.get("authorization") || "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

function readSession(token) {
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ["HS256"] });
    const id = typeof payload.sub === "string" && ObjectId.isValid(payload.sub)
      ? new ObjectId(payload.sub)
      : null;
    const accountType = payload.accountType;
    if (!id || !["customer", "admin"].includes(accountType)) return null;
    return { id, accountType };
  } catch {
    return null;
  }
}

function emailJsConfigured() {
  return Boolean(process.env.EMAILJS_SERVICE_ID && process.env.EMAILJS_PUBLIC_KEY);
}

async function sendEmailJsMessage(templateParams) {
  const payload = {
    service_id: process.env.EMAILJS_SERVICE_ID,
    template_id: emailJsTemplateId,
    user_id: process.env.EMAILJS_PUBLIC_KEY,
    template_params: templateParams,
  };
  if (process.env.EMAILJS_PRIVATE_KEY) {
    payload.accessToken = process.env.EMAILJS_PRIVATE_KEY;
  }
  return fetch("https://api.emailjs.com/api/v1.0/email/send", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}

app.post("/api/auth/email-verification/status", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  if (!isValidEmail(email)) return res.status(400).json({ error: "Enter a valid email address." });

  const [verification, customerAccount, adminAccount] = await Promise.all([
    req.db.collection("email_verifications").findOne(
      { email, verified: true },
      { projection: { _id: 1 } },
    ),
    req.db.collection("customer_accounts").findOne({ email }, { projection: { _id: 1 } }),
    req.db.collection("admin_accounts").findOne({ email }, { projection: { _id: 1 } }),
  ]);
  res.json({
    verified: Boolean(verification),
    registered: Boolean(customerAccount || adminAccount),
  });
}));

app.post("/api/auth/email-verification/send", asyncRoute(async (req, res) => {
  const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  if (!validString(name, 100) || !isValidEmail(email)) {
    return res.status(400).json({ error: "Enter your name and a valid email address." });
  }
  if (!emailJsConfigured()) {
    return res.status(503).json({ error: "Email verification is not configured. Please contact support." });
  }
  if (await req.db.collection("email_verifications").findOne({ email, verified: true })) {
    return res.status(409).json({ error: "This email address is already verified." });
  }
  const existingAccounts = await Promise.all([
    req.db.collection("customer_accounts").findOne({ email }, { projection: { _id: 1 } }),
    req.db.collection("admin_accounts").findOne({ email }, { projection: { _id: 1 } }),
  ]);
  if (existingAccounts.some(Boolean)) {
    return res.status(409).json({ error: "Email is already registered, please log in to continue." });
  }

  const verifications = req.db.collection("email_verifications");
  const existingVerification = await verifications.findOne({ email });
  const now = new Date();
  if (existingVerification?.lastSentAt
    && now.getTime() - existingVerification.lastSentAt.getTime() < verificationResendDelayMs) {
    const retryAfterSeconds = Math.ceil(
      (verificationResendDelayMs - (now.getTime() - existingVerification.lastSentAt.getTime())) / 1000,
    );
    return res.status(429).json({
      error: `Please wait ${retryAfterSeconds} seconds before requesting another code.`,
      retryAfterSeconds,
    });
  }

  const code = crypto.randomInt(100000, 1000000).toString();
  let emailResponse;
  try {
    emailResponse = await sendEmailJsMessage({
      name,
      email,
      to_email: email,
      verification_code: code,
      expires_in: "10 minutes",
    });
  } catch (error) {
    console.error("EmailJS request failed:", error);
    return res.status(502).json({ error: "Unable to send the verification email. Please try again." });
  }
  if (!emailResponse.ok) {
    const providerMessage = await emailResponse.text();
    if (emailResponse.status === 403 && providerMessage.toLowerCase().includes("private key")) {
      console.error("EmailJS strict mode requires EMAILJS_PRIVATE_KEY.");
      return res.status(503).json({
        error: "Email verification requires an EmailJS private key. Configure EMAILJS_PRIVATE_KEY on the backend or disable strict mode in EmailJS.",
      });
    }
    if (emailResponse.status === 422
      && providerMessage.toLowerCase().includes("recipients address is corrupted")) {
      console.error("EmailJS rejected the verification recipient address (HTTP 422).");
      return res.status(400).json({
        error: "EmailJS rejected the recipient address. Check the email address and the template's recipient field.",
      });
    }
    console.error(`EmailJS returned HTTP ${emailResponse.status}.`);
    return res.status(502).json({
      error: "Unable to send the verification email. Please check the address and try again.",
    });
  }

  await verifications.updateOne(
    { email },
    {
      $set: {
        codeHash: hashVerificationCode(email, code),
        expiresAt: new Date(now.getTime() + verificationLifetimeMs),
        lastSentAt: now,
        attempts: 0,
        verified: false,
      },
    },
    { upsert: true },
  );
  res.json({ message: "Verification code sent.", expiresIn: verificationLifetimeMs / 1000 });
}));

app.post("/api/auth/email-verification/verify", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  const code = req.body?.code;
  if (!isValidEmail(email) || typeof code !== "string" || !/^\d{6}$/.test(code)) {
    return res.status(400).json({ error: "Enter a valid email and six-digit verification code." });
  }

  const verification = await req.db.collection("email_verifications").findOneAndUpdate(
    {
      email,
      expiresAt: { $gt: new Date() },
      verified: false,
      attempts: { $lt: verificationMaxAttempts },
    },
    { $inc: { attempts: 1 } },
    { returnDocument: "after" },
  );
  if (!verification) {
    return res.status(400).json({ error: "The code is expired or invalid. Request a new code." });
  }

  const suppliedHash = Buffer.from(hashVerificationCode(email, code), "hex");
  const storedHash = Buffer.from(verification.codeHash, "hex");
  if (suppliedHash.length !== storedHash.length
    || !crypto.timingSafeEqual(suppliedHash, storedHash)) {
    return res.status(400).json({ error: "The verification code is incorrect." });
  }

  await req.db.collection("email_verifications").updateOne(
    { _id: verification._id, verified: false },
    { $set: { verified: true, verifiedAt: new Date() }, $unset: { expiresAt: "" } },
  );
  res.json({ verified: true, email });
}));

app.post("/api/auth/register", asyncRoute(async (req, res) => {
  const { name, email, password } = req.body || {};
  if (!validString(name, 100) || !validString(email, 254)
    || typeof password !== "string" || password.length < 8 || password.length > 128
    || !hasValidPasswordComplexity(password)) {
    return res.status(400).json({
      error: "Enter a name and valid email. Passwords must be 8–128 characters and include uppercase, lowercase, a digit, and a supported special character.",
    });
  }
  const normalizedEmail = email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    return res.status(400).json({ error: "Enter a valid email address." });
  }

  const existingAccounts = await Promise.all([
    req.db.collection("customer_accounts").findOne({ email: normalizedEmail }, { projection: { _id: 1 } }),
    req.db.collection("admin_accounts").findOne({ email: normalizedEmail }, { projection: { _id: 1 } }),
  ]);
  if (existingAccounts.some(Boolean)) {
    return res.status(409).json({ error: "Email is already registered, please log in to continue." });
  }

  const verification = await req.db.collection("email_verifications").findOne({
    email: normalizedEmail,
    verified: true,
  });
  if (!verification) {
    return res.status(400).json({ error: "Verify your email address before creating an account." });
  }

  const passwordFields = await hashPassword(password);
  const userId = new ObjectId();
  try {
    await req.db.collection("customer_accounts").insertOne({
      _id: userId,
      name: name.trim(),
      email: normalizedEmail,
      ...passwordFields,
      createdAt: new Date(),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ error: "Email is already registered, please log in to continue." });
    }
    throw error;
  }

  await req.db.collection("email_verifications").deleteOne({ _id: verification._id });
  const user = { name: name.trim(), email: normalizedEmail, accountType: "customer" };
  res.status(201).json({
    user,
    token: createSessionToken(userId.toString(), user.accountType),
  });
}));

app.post("/api/auth/login", asyncRoute(async (req, res) => {
  const { email, password } = req.body || {};
  if (!validString(email, 254) || typeof password !== "string") {
    return res.status(400).json({ error: "Enter your email and password." });
  }
  const normalizedEmail = email.trim().toLowerCase();
  const [adminAccount, customerAccount] = await Promise.all([
    req.db.collection("admin_accounts").findOne({ email: normalizedEmail }),
    req.db.collection("customer_accounts").findOne({ email: normalizedEmail }),
  ]);
  const candidates = [
    { account: adminAccount, accountType: "admin" },
    { account: customerAccount, accountType: "customer" },
  ];
  let authenticated;
  for (const candidate of candidates) {
    if (await verifyPassword(password, candidate.account)) {
      authenticated = candidate;
      break;
    }
  }
  if (!authenticated) {
    return res.status(401).json({ error: "Email or password is incorrect." });
  }
  const user = {
    name: authenticated.account.name,
    email: authenticated.account.email,
    accountType: authenticated.accountType,
  };
  res.json({
    user,
    token: createSessionToken(authenticated.account._id.toString(), authenticated.accountType),
  });
}));

app.get("/api/auth/session", asyncRoute(async (req, res) => {
  const session = getBearerToken(req) ? readSession(getBearerToken(req)) : null;
  if (!session) return res.json({ user: null });

  const collectionName = session.accountType === "admin" ? "admin_accounts" : "customer_accounts";
  const user = await req.db.collection(collectionName).findOne(
    { _id: session.id },
    { projection: { name: 1, email: 1 } },
  );
  if (!user) return res.json({ user: null });
  res.json({ user: { name: user.name, email: user.email, accountType: session.accountType } });
}));

app.post("/api/auth/logout", (req, res) => res.status(204).end());

app.post("/api/auth/password-reset/send", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  if (!isValidEmail(email)) return res.status(400).json({ error: "Enter a valid email address." });
  if (!emailJsConfigured()) {
    return res.status(503).json({ error: "Password recovery is temporarily unavailable. Please try again later." });
  }

  const resets = req.db.collection("password_resets");
  const existingReset = await resets.findOne({ email }, { projection: { lastSentAt: 1 } });
  const now = new Date();
  if (existingReset?.lastSentAt
    && now.getTime() - existingReset.lastSentAt.getTime() < verificationResendDelayMs) {
    const retryAfterSeconds = Math.ceil(
      (verificationResendDelayMs - (now.getTime() - existingReset.lastSentAt.getTime())) / 1000,
    );
    return res.status(429).json({
      error: `Please wait ${retryAfterSeconds} seconds before requesting another recovery code.`,
      retryAfterSeconds,
    });
  }

  const [adminAccount, customerAccount] = await Promise.all([
    req.db.collection("admin_accounts").findOne({ email }, { projection: { _id: 1, name: 1 } }),
    req.db.collection("customer_accounts").findOne({ email }, { projection: { _id: 1, name: 1 } }),
  ]);
  const account = adminAccount || customerAccount;
  const accountType = adminAccount ? "admin" : customerAccount ? "customer" : null;
  const code = crypto.randomInt(100000, 1000000).toString();
  const codeHash = hashVerificationCode(
    email,
    account ? code : crypto.randomBytes(32).toString("hex"),
  );

  if (account) {
    try {
      const emailResponse = await sendEmailJsMessage({
        name: account.name,
        email,
        to_email: email,
        verification_code: code,
        expires_in: "10 minutes",
      });
      if (!emailResponse.ok) {
        console.error(`EmailJS password recovery returned HTTP ${emailResponse.status}.`);
        if (emailResponse.status === 403) {
          return res.status(503).json({
            error: "Password recovery email is not configured correctly. Please contact support.",
          });
        }
        return res.status(502).json({ error: "Unable to send the recovery code. Please try again." });
      }
    } catch (error) {
      console.error("EmailJS password recovery request failed:", error);
      return res.status(502).json({ error: "Unable to send the recovery code. Please try again." });
    }
  }

  await resets.updateOne(
    { email },
    {
      $set: {
        accountType,
        codeHash,
        expiresAt: new Date(now.getTime() + passwordResetLifetimeMs),
        lastSentAt: now,
        attempts: 0,
        consumed: false,
      },
      $unset: { verifiedAt: "", resetTokenHash: "", resetTokenExpiresAt: "" },
    },
    { upsert: true },
  );
  res.json({ message: "If an account exists for this email, a recovery code has been sent." });
}));

app.post("/api/auth/password-reset/verify", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  const { code } = req.body || {};
  if (!isValidEmail(email) || typeof code !== "string" || !/^\d{6}$/.test(code)) {
    return res.status(400).json({ error: "Enter a valid email address and six-digit recovery code." });
  }

  const resets = req.db.collection("password_resets");
  const reset = await resets.findOneAndUpdate(
    {
      email,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: verificationMaxAttempts },
      consumed: false,
      verifiedAt: { $exists: false },
    },
    { $inc: { attempts: 1 } },
    { returnDocument: "after" },
  );
  if (!reset || !reset.accountType || !reset.codeHash) {
    return res.status(400).json({ error: "The recovery code is expired or invalid. Request a new code." });
  }

  const suppliedHash = Buffer.from(hashVerificationCode(email, code), "hex");
  const storedHash = Buffer.from(reset.codeHash, "hex");
  if (suppliedHash.length !== storedHash.length
    || !crypto.timingSafeEqual(suppliedHash, storedHash)) {
    return res.status(400).json({ error: "The recovery code is incorrect." });
  }

  const resetToken = crypto.randomBytes(32).toString("hex");
  const verified = await resets.updateOne(
    {
      _id: reset._id,
      consumed: false,
      verifiedAt: { $exists: false },
      expiresAt: { $gt: new Date() },
    },
    {
      $set: {
        verifiedAt: new Date(),
        resetTokenHash: crypto.createHash("sha256").update(resetToken).digest("hex"),
        resetTokenExpiresAt: new Date(Date.now() + passwordResetLifetimeMs),
        expiresAt: new Date(Date.now() + passwordResetLifetimeMs),
      },
    },
  );
  if (verified.modifiedCount !== 1) {
    return res.status(400).json({ error: "The recovery code is expired or invalid. Request a new code." });
  }
  res.json({ resetToken });
}));

app.post("/api/auth/password-reset/complete", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  const { resetToken, newPassword, confirmNewPassword } = req.body || {};
  if (!isValidEmail(email) || typeof resetToken !== "string" || !/^[a-f0-9]{64}$/i.test(resetToken)
    || typeof newPassword !== "string" || newPassword.length < 8 || newPassword.length > 128
    || !hasValidPasswordComplexity(newPassword)
    || typeof confirmNewPassword !== "string" || newPassword !== confirmNewPassword) {
    return res.status(400).json({
      error: "Verify your recovery code, confirm the new password exactly, and meet all password requirements.",
    });
  }

  const resets = req.db.collection("password_resets");
  const resetTokenHash = crypto.createHash("sha256").update(resetToken).digest("hex");
  const reset = await resets.findOne({
    email,
    resetTokenHash,
    resetTokenExpiresAt: { $gt: new Date() },
    consumed: false,
  });
  if (!reset || !reset.accountType || !reset.codeHash) {
    return res.status(400).json({ error: "Verify a valid recovery code before resetting your password." });
  }

  const collectionName = reset.accountType === "admin" ? "admin_accounts" : "customer_accounts";
  const account = await req.db.collection(collectionName).findOne(
    { email },
    { projection: { _id: 1, passwordHash: 1, passwordSalt: 1 } },
  );
  if (!account) {
    return res.status(400).json({ error: "The recovery code is expired or invalid. Request a new code." });
  }
  if (await verifyPassword(newPassword, account)) {
    return res.status(400).json({ error: "Your new password must be different from your current password." });
  }

  const consumed = await resets.updateOne(
    { _id: reset._id, consumed: false, resetTokenHash, resetTokenExpiresAt: { $gt: new Date() } },
    { $set: { consumed: true } },
  );
  if (consumed.modifiedCount !== 1) {
    return res.status(400).json({ error: "The recovery code is expired or invalid. Request a new code." });
  }

  const updated = await req.db.collection(collectionName).updateOne(
    {
      _id: account._id,
      passwordHash: account.passwordHash,
      passwordSalt: account.passwordSalt,
    },
    { $set: await hashPassword(newPassword) },
  );
  if (updated.matchedCount !== 1) {
    return res.status(409).json({
      error: "Your password changed during this request. Request a new recovery code.",
    });
  }
  await resets.deleteOne({ _id: reset._id });
  res.json({ message: "Password reset successfully. You can now sign in with your new password." });
}));

app.use((req, res) => res.status(404).json({ error: "Not found." }));
app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    return res.status(400).json({ error: "Invalid JSON request body." });
  }
  console.error("Authentication API request failed:", error);
  res.status(500).json({ error: "Unable to complete the request. Please try again." });
});

if (require.main === module) {
  const port = Number(process.env.PORT || 4000);
  getDatabase()
    .then(() => {
      app.listen(port, () => console.log(`Gatherly auth API listening on port ${port}.`));
    })
    .catch((error) => {
      console.error("Unable to start the Gatherly auth API:", error.message);
      process.exitCode = 1;
    });
}

module.exports = app;
