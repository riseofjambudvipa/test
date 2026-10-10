#!/bin/bash
# CapStudio — Build All Platforms Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

PLATFORM=${1:-"all"}
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)

echo "================================================"
echo "  CapStudio Build Script v$VERSION"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# Step 1: Check Flutter
echo ""
echo "--- Checking Flutter ---"
flutter --version
flutter pub get
log_ok "Flutter OK"

# Step 2: Run analysis
echo ""
echo "--- Running Analysis ---"
flutter analyze
log_ok "Analysis passed"

# Step 3: Run tests
echo ""
echo "--- Running Tests ---"
flutter test
log_ok "Tests passed"

# Step 4: Platform builds
build_android() {
    echo ""
    echo "--- Building Android ---"
    if [ -n "$KEYSTORE_FILE" ]; then
        flutter build appbundle --release
        log_ok "Android App Bundle built: build/app/outputs/bundle/release/app-release.aab"
    else
        log_warn "KEYSTORE_FILE not set — building debug APK"
        flutter build apk --debug --target-platform android-arm64
        log_ok "Android Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
    fi
}

build_ios() {
    echo ""
    echo "--- Building iOS ---"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warn "iOS build requires macOS — skipping"
        return
    fi
    # Check xcframework
    if [ ! -d "ios/whisper_xcframework/whisper.xcframework" ]; then
        log_warn "whisper.xcframework not found — building..."
        chmod +x third_party/scripts/build/build_whisper_ios.sh
        ./third_party/scripts/build/build_whisper_ios.sh
    fi
    cd ios && pod install --repo-update && cd ..
    flutter build ios --release --no-codesign
    log_ok "iOS build complete: build/ios/iphoneos/Runner.app"
}

build_macos() {
    echo ""
    echo "--- Building macOS ---"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warn "macOS build requires macOS — skipping"
        return
    fi
    flutter build macos --release
    log_ok "macOS build complete: build/macos/Build/Products/Release/CapStudio.app"
}

build_windows() {
    echo ""
    echo "--- Building Windows ---"
    flutter build windows --release
    log_ok "Windows build complete: build/windows/x64/runner/Release/"
}

build_linux() {
    echo ""
    echo "--- Building Linux ---"
    flutter build linux --release
    log_ok "Linux build complete: build/linux/x64/release/bundle/"
    if [ -f "third_party/scripts/create_deb.sh" ]; then
        echo "Creating Debian package (.deb)..."
        chmod +x third_party/scripts/create_deb.sh
        ./third_party/scripts/create_deb.sh || log_warn "Debian packaging skipped or failed."
    fi
}

build_web() {
    echo ""
    echo "--- Building Web (Offline-First PWA) ---"
    flutter build web --release --pwa-strategy offline-first
    log_ok "Web build complete: build/web/"
}

case "$PLATFORM" in
    android) build_android ;;
    ios)     build_ios ;;
    macos)   build_macos ;;
    windows) build_windows ;;
    linux)   build_linux ;;
    web)     build_web ;;
    all)
        build_android
        build_ios
        build_macos
        build_windows
        build_linux
        build_web
        ;;
    *)
        echo "Usage: $0 [android|ios|macos|windows|linux|web|all]"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo -e "  ${GREEN}Build Complete!${NC}"
echo "================================================"
