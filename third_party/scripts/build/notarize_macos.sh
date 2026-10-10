#!/usr/bin/env bash
# ==============================================================================
# CapStudio — macOS Code Signing, Notarization & Stapling Automation
# ==============================================================================
# Requirements:
#   - macOS machine with Xcode Command Line Tools installed
#   - Apple Developer ID Application Certificate installed in Keychain
#   - Notarytool credentials stored in Keychain or passed as environment variables:
#       KEYCHAIN_PROFILE (preferred, via `xcrun notarytool store-credentials`)
#       OR
#       APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD
# ==============================================================================

set -euo pipefail

APP_NAME="CapStudio"
BUNDLE_ID="com.capstudio.ai"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build/macos/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-macOS-Universal.dmg"
DMG_PATH="${PROJECT_DIR}/build/${DMG_NAME}"
ENTITLEMENTS="${PROJECT_DIR}/macos/Runner/Release.entitlements"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

echo "======================================================================"
echo "          CapStudio macOS Code Signing & Notarization Pipeline        "
echo "======================================================================"

# Step 1: Check environment & build output
if [ ! -d "${APP_PATH}" ]; then
  log_info "Release build not found. Building CapStudio for macOS..."
  cd "${PROJECT_DIR}"
  flutter build macos --release
fi

if [ ! -d "${APP_PATH}" ]; then
  log_error "App bundle not found at: ${APP_PATH}"
  exit 1
fi

# Step 2: Determine Signing Identity
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
if [ -z "${SIGNING_IDENTITY}" ]; then
  log_info "Detecting Developer ID Application certificate in Keychain..."
  SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application:" | head -n 1 | awk -F'"' '{print $2}' || true)
fi

if [ -z "${SIGNING_IDENTITY}" ]; then
  log_error "No 'Developer ID Application' certificate found in keychain."
  log_error "Please set DEVELOPER_ID_APPLICATION=\"Developer ID Application: Your Name (TEAM_ID)\""
  exit 1
fi

log_info "Using Signing Identity: ${SIGNING_IDENTITY}"

# Step 3: Deep Sign All Embedded Binaries & Frameworks
log_info "Signing embedded frameworks, dynamic libraries, and binaries..."

find "${APP_PATH}/Contents/Frameworks" -type f -name "*.dylib" -o -name "*.framework" 2>/dev/null | while read -r framework; do
  log_info "Signing framework/dylib: $(basename "${framework}")"
  codesign --force --verify --verbose --timestamp --options runtime --sign "${SIGNING_IDENTITY}" "${framework}"
done

# Sign bundled auxiliary binaries (e.g. ffmpeg, whisper-cli) if present
if [ -d "${APP_PATH}/Contents/Resources/bin" ]; then
  find "${APP_PATH}/Contents/Resources/bin" -type f | while read -r binary; do
    log_info "Signing auxiliary binary: $(basename "${binary}")"
    codesign --force --verify --verbose --timestamp --options runtime --sign "${SIGNING_IDENTITY}" "${binary}"
  done
fi

# Sign main App Bundle with entitlements
log_info "Signing main app bundle with entitlements: ${ENTITLEMENTS}"
codesign --force --verify --verbose --deep --timestamp \
  --options runtime \
  --entitlements "${ENTITLEMENTS}" \
  --sign "${SIGNING_IDENTITY}" \
  "${APP_PATH}"

log_info "Verifying code signature integrity..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
spctl -a -t exec -vv "${APP_PATH}"
log_success "Code signature verified successfully."

# Step 4: Package App into Notarizable DMG
mkdir -p "${PROJECT_DIR}/build"
rm -f "${DMG_PATH}"

log_info "Creating Disk Image (DMG) for distribution..."
hdiutil create -volname "${APP_NAME}" \
  -srcfolder "${APP_PATH}" \
  -ov -format UDZO \
  "${DMG_PATH}"

# Sign the DMG container
log_info "Signing DMG container..."
codesign --force --verify --verbose --timestamp --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
log_success "Created signed DMG at: ${DMG_PATH}"

# Step 5: Submit for Apple Notarization
log_info "Submitting DMG to Apple Notary Service..."

NOTARY_ARGS=()
if [ -n "${KEYCHAIN_PROFILE:-}" ]; then
  NOTARY_ARGS+=(--keychain-profile "${KEYCHAIN_PROFILE}")
elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; then
  NOTARY_ARGS+=(--apple-id "${APPLE_ID}" --team-id "${APPLE_TEAM_ID}" --password "${APPLE_APP_SPECIFIC_PASSWORD}")
else
  log_warn "No notarization credentials found in environment (KEYCHAIN_PROFILE or APPLE_ID/TEAM_ID/PASSWORD)."
  log_warn "DMG is signed locally, but skipping Apple Notarization submission."
  log_warn "To notarize, run:"
  log_warn "  xcrun notarytool submit \"${DMG_PATH}\" --keychain-profile <profile-name> --wait"
  exit 0
fi

log_info "Uploading and waiting for Apple Notarization ticket..."
xcrun notarytool submit "${DMG_PATH}" "${NOTARY_ARGS[@]}" --wait

# Step 6: Staple the Notarization Ticket
log_info "Stapling notarization ticket to DMG..."
xcrun stapler staple "${DMG_PATH}"

log_info "Stapling notarization ticket to App Bundle..."
xcrun stapler staple "${APP_PATH}"

# Step 7: Final Gatekeeper Verification
log_info "Running final Gatekeeper assessment..."
spctl -a -t open --context context:primary-signature -v "${DMG_PATH}"

log_success "======================================================================"
log_success " CapStudio DMG is fully signed, notarized, and stapled ready for release! "
log_success " Artifact: ${DMG_PATH} "
log_success "======================================================================"
