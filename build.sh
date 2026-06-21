#!/usr/bin/env bash
# Build a distributable QuickSplit.app bundle from SPM output.
# Usage: ./build.sh [debug|release]   (default: release)

set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="QuickSplit"
BUNDLE_ID="com.yukiyasui.quicksplit"
SIGN_IDENTITY="${SIGN_IDENTITY:-QuickSplit Code Signing}"
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

# Prefer a stable local signing identity so TCC can keep accessibility grants
# across rebuilds by matching the certificate-based designated requirement.
# Match by name across all identities (no -p codesigning): a self-signed local
# cert is untrusted (CSSMERR_TP_NOT_TRUSTED) and thus hidden by the codesigning
# policy filter, yet codesign can still sign with it and the cert-based DR is
# what TCC keys on.
if security find-identity 2>/dev/null | grep -Fq "$SIGN_IDENTITY"; then
    SIGN_ARG=("$SIGN_IDENTITY")
    echo "==> codesign ($SIGN_IDENTITY)"
else
    SIGN_ARG=(-)
    echo "warning: 安定署名証明書が無いため ad-hoc にフォールバック。権限維持には scripts/create-signing-identity.sh を一度実行してください" >&2
    echo "==> codesign (ad-hoc fallback)"
fi

codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc" >/dev/null
codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc" >/dev/null
codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app" >/dev/null
codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR/Contents/Frameworks/Sparkle.framework" >/dev/null
codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR/Contents/MacOS/$APP_NAME" >/dev/null
codesign --force --timestamp=none --sign "${SIGN_ARG[@]}" "$APP_DIR" >/dev/null

echo "==> verifying signature"
codesign --verify --deep --strict "$APP_DIR" >/dev/null

echo
echo "Built: $APP_DIR"
echo "Run:   open \"$APP_DIR\""
