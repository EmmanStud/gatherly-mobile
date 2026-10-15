# Gatherly Mobile

Gatherly is a Flutter organizer app backed by the Express API in `server/`. The API shares the Gatherly MongoDB database and account records with the website.

## Run locally

### Start the API

In PowerShell, from the project root:

```powershell
cd server
npm install
$env:CORS_ORIGINS = "http://localhost:5000"
npm start
```

The server listens on port `4000` by default. Configure its environment in `server/.env`; see `server/.env.example` for the variable names. Do not place server secrets in the Flutter app.

### Start Flutter Web

In a second terminal, from the Flutter project root:

```powershell
flutter pub get
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:4000/api
```

For other Flutter targets, pass the reachable API URL through `--dart-define=API_BASE_URL=...`. The API must be reachable from the device, and its CORS allowlist must include the browser origin when running Flutter Web.

## Server environment variable names

Set these variables in `server/.env` or in the server hosting environment. This documentation intentionally lists names only:

- `MONGODB_URI`
- `JWT_SECRET`
- `EMAILJS_SERVICE_ID`
- `EMAILJS_PUBLIC_KEY`
- `EMAILJS_PRIVATE_KEY`
- `CORS_ORIGINS`
- `PUBLIC_APP_URL`

## Deliberately not included

These website features remain web-only and are not implemented in the Flutter app:

- Public event registration
- PayMongo payment and refund processing
- Geoapify venue autocomplete
