#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/Applications/AfricanFashionApp"
WORKER_DIR="${ROOT_DIR}/backend/cloudflare-worker"

if [[ ! -d "$WORKER_DIR" ]]; then
  echo "Worker directory not found: $WORKER_DIR"
  exit 1
fi

cd "$WORKER_DIR"

echo "Checking Wrangler authentication..."
if ! npx wrangler whoami >/dev/null 2>&1; then
  echo
  echo "Wrangler is not authenticated."
  echo "Run: npx wrangler login"
  echo "Then rerun this script."
  exit 1
fi

echo "Wrangler authenticated."
echo
echo "Ensure secrets are set (run once per account/environment):"
echo "  npx wrangler secret put AUTH_JWT_SECRET"
echo "  npx wrangler secret put UPLOAD_TOKEN_SECRET"
echo "  # Optional:"
echo "  npx wrangler secret put PUBLIC_ASSET_BASE_URL"
echo
read -r -p "Proceed with deploy now? [y/N] " PROCEED
if [[ "${PROCEED:-}" != "y" && "${PROCEED:-}" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

npx wrangler deploy

echo
echo "Deploy complete."
echo "Set Xcode scheme env var:"
echo "  AFRICANFASHION_API_BASE_URL=<workers.dev url>"
