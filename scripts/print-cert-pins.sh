#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host> [port]"
  echo "Example: $0 api.africanfashion.example 443"
  exit 1
fi

HOST="$1"
PORT="${2:-443}"

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required but not found."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

CHAIN_FILE="$TMP_DIR/chain.pem"

echo "Fetching certificate chain from ${HOST}:${PORT} ..."
openssl s_client -showcerts -servername "$HOST" -connect "${HOST}:${PORT}" </dev/null 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > "$CHAIN_FILE"

if [[ ! -s "$CHAIN_FILE" ]]; then
  echo "No certificates received from ${HOST}:${PORT}."
  exit 1
fi

awk -v dir="$TMP_DIR" '
  /-----BEGIN CERTIFICATE-----/ { c++; f=sprintf("%s/cert-%02d.pem", dir, c) }
  { print > f }
' "$CHAIN_FILE"

echo
echo "Certificate pins for ${HOST}:${PORT}"
echo "Paste one or more values into certificatePinsByHost[\"${HOST}\"]"
echo

for cert in "$TMP_DIR"/cert-*.pem; do
  [[ -f "$cert" ]] || continue
  PIN="$(openssl x509 -in "$cert" -outform DER | openssl dgst -sha256 -binary | openssl base64)"
  SUBJECT="$(openssl x509 -in "$cert" -noout -subject | sed 's/^subject=//')"
  ISSUER="$(openssl x509 -in "$cert" -noout -issuer | sed 's/^issuer=//')"
  NOT_AFTER="$(openssl x509 -in "$cert" -noout -enddate | sed 's/^notAfter=//')"
  echo "- pin-sha256: ${PIN}"
  echo "  subject: ${SUBJECT}"
  echo "  issuer: ${ISSUER}"
  echo "  expires: ${NOT_AFTER}"
  echo
done

echo "Tip: keep at least two valid pins per host during certificate rotation."
