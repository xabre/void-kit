#!/bin/bash
set -euo pipefail

PROJECT="VoidKit/VoidKit.xcodeproj"
SCHEME="VoidKit"
CONFIGURATION="${1:-Release}"

echo "Building $SCHEME ($CONFIGURATION)..."

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath build \
  -arch arm64 -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  build 2>&1 | tail -5

echo "Build succeeded."
