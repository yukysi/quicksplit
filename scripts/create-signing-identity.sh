#!/usr/bin/env bash
# Create the stable local code signing identity used by build.sh.

set -euo pipefail

IDENTITY_NAME="QuickSplit Code Signing"
LOGIN_KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -Fq "$IDENTITY_NAME"; then
    echo "Code signing identity already exists: $IDENTITY_NAME"
    exit 0
fi

TMP_DIR="$(mktemp -d)"
KEY_FILE="$TMP_DIR/quicksplit-signing.key"
CRT_FILE="$TMP_DIR/quicksplit-signing.crt"
P12_FILE="$TMP_DIR/quicksplit-signing.p12"
PASS_FILE="$TMP_DIR/quicksplit-signing.pass"
CONFIG_FILE="$TMP_DIR/openssl.cnf"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

chmod 700 "$TMP_DIR"
openssl rand -hex 32 >"$PASS_FILE"
chmod 600 "$PASS_FILE"

echo "Creating code signing identity: $IDENTITY_NAME"

cat >"$CONFIG_FILE" <<EOF
[ req ]
prompt = no
distinguished_name = dn
x509_extensions = v3_codesign

[ dn ]
CN = $IDENTITY_NAME

[ v3_codesign ]
keyUsage = digitalSignature
extendedKeyUsage = codeSigning
EOF

openssl req \
    -x509 \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CRT_FILE" \
    -days 3650 \
    -nodes \
    -config "$CONFIG_FILE"

openssl pkcs12 \
    -export \
    -legacy \
    -inkey "$KEY_FILE" \
    -in "$CRT_FILE" \
    -out "$P12_FILE" \
    -name "$IDENTITY_NAME" \
    -passout "file:$PASS_FILE"

security import "$P12_FILE" \
    -k "$LOGIN_KEYCHAIN" \
    -P "$(cat "$PASS_FILE")" \
    -T /usr/bin/codesign

echo "Allowing codesign to access the imported private key."
echo "If prompted, enter your login keychain password. Continuing is safe if this step fails; you may need to approve codesign manually once."
security set-key-partition-list \
    -S apple-tool:,apple: \
    -k '' \
    "$LOGIN_KEYCHAIN" || true

echo "Created code signing identity: $IDENTITY_NAME"
echo "Run ./build.sh next; it will automatically use this identity when available."
