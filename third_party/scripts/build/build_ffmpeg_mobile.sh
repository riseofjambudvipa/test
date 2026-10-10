#!/bin/bash
# ==============================================================================
# CapStudio Custom FFmpeg Native Build Script for Android & iOS
# ==============================================================================
# This script automates compiling a custom, optimized, size-reduced version of
# FFmpeg with libass support (required for burning styled subtitles) for
# mobile platforms using the ffmpeg-kit build system.
#
# Prerequisite Tools:
# - Android: ANDROID_NDK_HOME set to NDK 25+, cmake, nasm, yasm, autoconf, libtool.
# - iOS: macOS, Xcode command line tools installed.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Target branch matching the current ffmpeg_kit_flutter version (6.0)
FFMPEG_KIT_TAG="v6.0"
FFMPEG_KIT_URL="https://github.com/arthenica/ffmpeg-kit.git"
CLONE_DIR="$PROJECT_ROOT/third_party/ffmpeg-kit"

# Subtitle-burning required external libraries
EXTERNAL_LIBS="--enable-libass --enable-freetype --enable-fribidi --enable-harfbuzz --enable-fontconfig"

# Print usage information
usage() {
    echo "Usage: $0 [android | ios | clean | help]"
    echo ""
    echo "Commands:"
    echo "  android    Compile optimized FFmpeg .aar for Android (requires ANDROID_NDK_HOME)"
    echo "  ios        Compile optimized FFmpeg .xcframework for iOS (requires macOS & Xcode)"
    echo "  clean      Remove temporary build artifacts and cloned repositories"
    echo "  help       Show this help message"
    echo ""
    exit 1
}

# Setup build system repository
setup_ffmpeg_kit() {
    if [ ! -d "$CLONE_DIR" ]; then
        echo "Cloning ffmpeg-kit ($FFMPEG_KIT_TAG) to $CLONE_DIR..."
        git clone --depth 1 --branch "$FFMPEG_KIT_TAG" "$FFMPEG_KIT_URL" "$CLONE_DIR"
    else
        echo "ffmpeg-kit directory already exists at $CLONE_DIR"
    fi
}

build_android() {
    echo "----------------------------------------"
    echo "Building Custom FFmpeg for Android..."
    echo "----------------------------------------"

    # Check NDK path
    if [ -z "$ANDROID_NDK_HOME" ]; then
        echo "ERROR: ANDROID_NDK_HOME is not set."
        echo "Example: export ANDROID_NDK_HOME=/Users/user/Library/Android/sdk/ndk/25.1.8937393"
        exit 1
    fi

    setup_ffmpeg_kit

    cd "$CLONE_DIR"

    # Run ffmpeg-kit android build script
    # We build arm64-v8a, armeabi-v7a, and x86_64 (excluding 32-bit x86 to save app size)
    # The flag -l adds external libraries.
    echo "Executing ffmpeg-kit android.sh..."
    ./android.sh \
        --api=24 \
        --no-archive \
        --abi="arm64-v8a,armeabi-v7a,x86_64" \
        $EXTERNAL_LIBS

    echo ""
    echo "Android Compilation Successful!"
    echo "Built binaries are located in: $CLONE_DIR/prebuilt/android-aar"
    echo "To use these in Flutter, replace the package dependency with your custom .aar library."
    cd - > /dev/null
}

build_ios() {
    echo "----------------------------------------"
    echo "Building Custom FFmpeg for iOS..."
    echo "----------------------------------------"

    # Check for macOS
    if [ "$(uname)" != "Darwin" ]; then
        echo "ERROR: iOS compilation requires a macOS environment with Xcode."
        exit 1
    fi

    setup_ffmpeg_kit

    cd "$CLONE_DIR"

    # Run ffmpeg-kit ios build script
    # We build for arm64 (device) and arm64-simulator to keep compile time and size low.
    echo "Executing ffmpeg-kit ios.sh..."
    ./ios.sh \
        --no-archive \
        --xcframework \
        $EXTERNAL_LIBS

    echo ""
    echo "iOS Compilation Successful!"
    echo "Built frameworks are located in: $CLONE_DIR/prebuilt/ios-xcframework"
    echo "To use these in Flutter, reference the custom xcframework inside your ios/Podfile."
    cd - > /dev/null
}

clean_all() {
    echo "Cleaning up ffmpeg-kit build folders..."
    rm -rf "$CLONE_DIR"
    echo "Cleanup complete."
}

# Parse command line argument
case "$1" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    clean)
        clean_all
        ;;
    help|*)
        usage
        ;;
esac
