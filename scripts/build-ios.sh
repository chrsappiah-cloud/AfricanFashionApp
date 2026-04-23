#!/bin/sh
# Builds with DerivedData outside the synchronized app source tree (never under AfricanFashionApp/AfricanFashionApp/).
#
# Optional — YouTube Data API v3 (Home screen “Curated embeds”):
#   YOUTUBE_DATA_API_KEY='your-google-api-key' "$0" build
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${DERIVED_DATA_PATH:-${TMPDIR:-/tmp}/AfricanFashionApp-xcodebuild}"
exec xcodebuild \
	-project "$ROOT/AfricanFashionApp.xcodeproj" \
	-scheme AfricanFashionApp \
	-destination 'generic/platform=iOS Simulator' \
	-derivedDataPath "$DERIVED" \
	"$@"
