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

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN_PATH="$BIN_DIR/$APP_NAME"
FW_SRC="$BIN_DIR/Sparkle.framework"
if [[ ! -x "$BIN_PATH" ]]; then
    echo "error: binary not found at $BIN_PATH" >&2
    exit 1
fi
if [[ ! -d "$FW_SRC" ]]; then
    echo "error: Sparkle.framework not found at $FW_SRC" >&2
    exit 1
fi

echo "==> assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp -R "$FW_SRC" "$APP_DIR/Contents/Frameworks/"

install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

# Ad-hoc signature so the binary can run locally and accessibility state
# sticks to a stable code-identity rather than resetting on each rebuild.
echo "==> codesign (ad-hoc)"
codesign --force --timestamp=none --sign - "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc" >/dev/null
codesign --force --timestamp=none --sign - "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc" >/dev/null
codesign --force --timestamp=none --sign - "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app" >/dev/null
codesign --force --timestamp=none --sign - "$APP_DIR/Contents/Frameworks/Sparkle.framework" >/dev/null
codesign --force --timestamp=none --sign - "$APP_DIR/Contents/MacOS/$APP_NAME" >/dev/null
codesign --force --timestamp=none --sign - "$APP_DIR" >/dev/null

echo "==> verifying signature"
codesign --verify --deep --strict "$APP_DIR" >/dev/null

echo
echo "Built: $APP_DIR"
echo "Run:   open \"$APP_DIR\""
