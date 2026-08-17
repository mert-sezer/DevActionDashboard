#!/usr/bin/env bash
set -euo pipefail

# Builds a drag-to-Applications DMG.
#
# Default: ad-hoc signature (open-source / local). Gatekeeper will warn until
# the user opens the app once via right-click → Open.
#
# Developer ID (paid Apple Developer Program):
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./.github/scripts/package-dmg.sh
#
# Optional notarization after a Developer ID sign:
#   NOTARIZE=1 APPLE_ID=... APPLE_TEAM_ID=... APPLE_APP_SPECIFIC_PASSWORD=... ./.github/scripts/package-dmg.sh

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Release}"
SCHEME="DevActionDashboard"
PRODUCT_NAME="DevActionDashboard"
DISPLAY_NAME="Dev Action Dashboard"
IDENTITY="${CODESIGN_IDENTITY:--}"
NOTARIZE="${NOTARIZE:-0}"

VERSION="$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("project.yml").read_text()
match = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', text)
print(match.group(1) if match else "0.0.0")
PY
)"

DERIVED="$ROOT/build/DerivedData"
STAGE="$ROOT/build/dmg-root"
DIST="$ROOT/dist"
APP_SRC="$DERIVED/Build/Products/${CONFIGURATION}/${PRODUCT_NAME}.app"
APP_DST="$STAGE/${DISPLAY_NAME}.app"
DMG_NAME="DevActionDashboard-${VERSION}.dmg"
DMG_PATH="$DIST/$DMG_NAME"

rm -rf "$STAGE"
mkdir -p "$STAGE" "$DIST"

echo "Building ${DISPLAY_NAME} ${VERSION} (${CONFIGURATION})…"

xcodebuild \
  -project DevActionDashboard.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= \
  build

if [[ ! -d "$APP_SRC" ]]; then
  echo "Build product missing: $APP_SRC" >&2
  exit 1
fi

cp -R "$APP_SRC" "$APP_DST"
ln -s /Applications "$STAGE/Applications"

if [[ "$IDENTITY" == "-" ]]; then
  echo "Signing ad-hoc…"
  codesign --force --sign - --options runtime "$APP_DST"
else
  echo "Signing with ${IDENTITY}…"
  codesign --force --sign "$IDENTITY" --options runtime --timestamp "$APP_DST"
fi

codesign --verify --verbose=2 "$APP_DST"

echo "Creating ${DMG_NAME}…"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$DISPLAY_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH" >/dev/null

if [[ "$IDENTITY" != "-" ]]; then
  codesign --force --sign "$IDENTITY" --timestamp "$DMG_PATH"
fi

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ "$IDENTITY" == "-" ]]; then
    echo "Notarization requires CODESIGN_IDENTITY to be a Developer ID." >&2
    exit 1
  fi
  : "${APPLE_ID:?APPLE_ID is required for notarization}"
  : "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required for notarization}"
  : "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD is required for notarization}"

  echo "Submitting for notarization…"
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

shasum -a 256 "$DMG_PATH" | tee "$DIST/${DMG_NAME}.sha256"

echo
echo "DMG:    $DMG_PATH"
echo "SHA256: $DIST/${DMG_NAME}.sha256"
