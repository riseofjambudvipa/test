#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CapStudio Android Release Keystore Generator (Linux / macOS)
# ==============================================================================

KEYSTORE_PATH="${1:-android/app/capstudio-release.jks}"
ALIAS="${2:-capstudio}"

echo "=========================================================="
echo "   CapStudio Android Production Keystore Generator        "
echo "=========================================================="

if ! command -v keytool &> /dev/null; then
    echo "Error: keytool was not found on PATH. Please install JDK." >&2
    exit 1
fi

read -rsp "Enter password for keystore and alias: " PASSWORD
echo ""

if [ ${#PASSWORD} -lt 6 ]; then
    echo "Error: Password must be at least 6 characters." >&2
    exit 1
fi

mkdir -p "$(dirname "$KEYSTORE_PATH")"

echo "Generating keystore at: $KEYSTORE_PATH..."

keytool -genkeypair -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$PASSWORD" \
    -keypass "$PASSWORD" \
    -dname "CN=CapStudio, OU=Engineering, O=CapStudio, L=Global, ST=Global, C=US"

echo "Keystore generated successfully!"

BASE64_PATH="${KEYSTORE_PATH}.base64.txt"
base64 < "$KEYSTORE_PATH" | tr -d '\n' > "$BASE64_PATH"

echo "----------------------------------------------------------"
echo "  GITHUB ACTIONS CI SECRETS CONFIGURATION                 "
echo "----------------------------------------------------------"
echo "Add these 4 secrets to your GitHub repository (Settings -> Secrets -> Actions):"
echo ""
echo "  KEYSTORE_BASE64   : (Copied to $BASE64_PATH)"
echo "  KEYSTORE_PASSWORD : $PASSWORD"
echo "  KEY_ALIAS         : $ALIAS"
echo "  KEY_PASSWORD      : $PASSWORD"
echo "----------------------------------------------------------"

KEY_PROPS="android/key.properties"
cat > "$KEY_PROPS" <<EOF
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=$ALIAS
storeFile=../app/capstudio-release.jks
EOF

echo "Wrote local properties template to: $KEY_PROPS"
echo "SECURITY WARNING: Never commit .jks, .base64.txt, or key.properties to git."
