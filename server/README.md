# Gatherly auth API

Set the server-only variables from `.env.example` in `server/.env` (or the Vercel project settings). `MONGODB_URI` must point to the Gatherly Atlas cluster and `JWT_SECRET` must match the website's value.

```sh
npm install
npm start
```

The local server listens on port 4000. For Flutter Web, set `CORS_ORIGINS=http://localhost:5000`. Deploy this directory as its own Vercel project.
