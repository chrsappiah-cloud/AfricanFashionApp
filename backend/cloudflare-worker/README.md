# AfricanFashionApp Cloudflare Worker API

Free-tier backend with JWT auth + R2 upload middleware.

## Endpoints

- `GET /health`, `GET /healthz`, `GET /status`, `GET /v1/health`
- `POST /v1/auth/login` (also `/auth/login`, `/login`)
- `POST /v1/uploads/presign` (JWT required)
- `PUT /v1/uploads/direct/:key?token=...` (one-time upload token)
- `GET /v1/system/storage-backends` (Cloudflare + iCloud backend status)
- `GET /v1/system/database-blueprint` (canonical storage schema structure)
- `POST /v1/storage/resolve` (resolve provider for admin/user workload)

## Cloudflare setup (free)

1. Create an R2 bucket:
   - `africanfashion-uploads`
2. Ensure `wrangler.toml` matches bucket name under `[[r2_buckets]]`.
3. Create secrets:
   - `AUTH_JWT_SECRET`
   - `UPLOAD_TOKEN_SECRET`
4. Configure vars in `wrangler.toml` (or as environment overrides):
   - `ICLOUD_CONTAINER_ID`
   - `STORAGE_PRIMARY_PROVIDER` (default: `cloudflare`)
   - `STORAGE_FAILOVER_PROVIDER` (default: `icloud`)

## Quick start

1. Install dependencies:
   - `npm install`
2. Login to Cloudflare:
   - `npx wrangler login`
3. Set secrets:
   - `npx wrangler secret put AUTH_JWT_SECRET`
   - `npx wrangler secret put UPLOAD_TOKEN_SECRET`
4. (Optional) set a public asset base URL:
   - `npx wrangler secret put PUBLIC_ASSET_BASE_URL`
   - e.g. custom domain pointing to R2
3. Deploy:
   - `npm run deploy`
5. Copy the deployed Worker URL (example: `https://africanfashion-api.<subdomain>.workers.dev`)

## Point iOS app to deployed API

In Xcode Scheme -> Run -> Environment Variables, add:

- `AFRICANFASHION_API_BASE_URL`
- value: your Worker URL, e.g. `https://africanfashion-api.<subdomain>.workers.dev`

The app already reads this variable in `AppConfiguration`.

## Notes

- This implementation issues and verifies HS256 JWTs inside the Worker (good for starter/prototype).
- For stronger production posture, switch auth to your IdP and verify upstream JWTs in Worker.
- `PUBLIC_ASSET_BASE_URL` is optional; without it, upload responses still return object keys.
- Use `storage-backends` and `database-blueprint` endpoints from admin tooling to validate Cloudflare/iCloud readiness before promoting production builds.
