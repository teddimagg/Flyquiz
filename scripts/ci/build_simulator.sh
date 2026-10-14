#!/usr/bin/env bash
# Unsigned simulator build: proves the app compiles. Used for PRs and when TestFlight secrets are absent.
set -euo pipefail
cd "$(dirname "$0")/../.."

xcodebuild build \
  -project Flyquiz.xcodeproj \
  -scheme Flyquiz \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
echo "✅ Simulator build succeeded"
