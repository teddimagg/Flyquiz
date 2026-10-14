#!/usr/bin/env bash
# Archives Flyquiz and uploads it to TestFlight using Xcode cloud signing.
# Needs no certificates or provisioning profiles: only an App Store Connect API key (Admin role).
#
# Required env:
#   ASC_KEY_ID        App Store Connect API key ID
#   ASC_ISSUER_ID     App Store Connect issuer ID
#   ASC_KEY_P8        Contents of the AuthKey_XXXX.p8 file (raw text, or base64 of it)
#   DEVELOPMENT_TEAM  10-character Apple team ID
# Optional env:
#   BUILD_NUMBER      CFBundleVersion (defaults to a timestamp); must increase on every upload
#   BUNDLE_ID         Overrides the bundle identifier in project.yml
set -euo pipefail
cd "$(dirname "$0")/../.."

: "${ASC_KEY_ID:?ASC_KEY_ID is not set}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is not set}"
: "${ASC_KEY_P8:?ASC_KEY_P8 is not set}"
: "${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is not set}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
KEY_PATH="$WORK/AuthKey_${ASC_KEY_ID}.p8"
if [[ "$ASC_KEY_P8" == *"BEGIN PRIVATE KEY"* ]]; then
  printf '%s\n' "$ASC_KEY_P8" > "$KEY_PATH"
else
  printf '%s' "$ASC_KEY_P8" | base64 --decode > "$KEY_PATH"
fi

AUTH=(
  -allowProvisioningUpdates
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
)

EXTRA=()
if [[ -n "${BUNDLE_ID:-}" ]]; then EXTRA+=(PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"); fi

ARCHIVE="build/Flyquiz.xcarchive"
rm -rf "$ARCHIVE"

echo "▶︎ Archiving build $BUILD_NUMBER"
# Archive unsigned; signing happens at export with Apple's cloud-managed distribution certificate.
xcodebuild archive \
  -project Flyquiz.xcodeproj \
  -scheme Flyquiz \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -derivedDataPath build/DerivedData \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO \
  ${EXTRA[@]+"${EXTRA[@]}"} \
  -quiet

cat > "$WORK/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>${DEVELOPMENT_TEAM}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

echo "▶︎ Signing and uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$WORK/ExportOptions.plist" \
  -exportPath build/export \
  "${AUTH[@]}"

echo "✅ Build $BUILD_NUMBER uploaded. It shows up in TestFlight once Apple finishes processing (usually 5–15 min)."
