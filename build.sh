#!/usr/bin/env bash
# Build a distributable QuickSplit.app bundle from SPM output.
# Usage: ./build.sh [debug|release]   (default: release)

set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="QuickSplit"
BUNDLE_ID="com.yukiyasui.quicksplit"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/.build"
APP_DIR="$ROOT/dist/$APP_NAME.app"

echo "==> swift build ($CONFIG)"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
    echo "error: binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Ad-hoc signature so the binary can run locally and accessibility state
# sticks to a stable code-identity rather than resetting on each rebuild.
echo "==> codesign (ad-hoc)"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo
echo "Built: $APP_DIR"
echo "Run:   open \"$APP_DIR\""
