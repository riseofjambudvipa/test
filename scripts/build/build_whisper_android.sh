#!/bin/bash
set -e

# Verify ANDROID_NDK_HOME or ANDROID_SDK_ROOT
if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
        # Auto-detect latest installed NDK version
        NDK_DIR=$(ls -d $ANDROID_SDK_ROOT/ndk/* 2>/dev/null | tail -n 1)
        if [ -n "$NDK_DIR" ]; then
            export ANDROID_NDK_HOME="$NDK_DIR"
            echo "Auto-detected NDK at: $ANDROID_NDK_HOME"
        fi
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "ERROR: ANDROID_NDK_HOME is not set or not a valid directory."
    echo "Please set it to your Android NDK installation path."
    echo "Example: export ANDROID_NDK_HOME=/Users/user/Library/Android/sdk/ndk/25.1.8937393"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

WHISPER_ROOT="$PROJECT_ROOT/third_party/whisper.cpp"
OUTPUT_JNI_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"
TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

# Supported architectures and target platforms
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
ANDROID_API=24

echo "----------------------------------------"
echo "Building whisper.cpp for Android..."
echo "NDK path: $ANDROID_NDK_HOME"
echo "Target API: $ANDROID_API"
echo "----------------------------------------"

for ABI in "${ABIS[@]}"; do
    echo "Building for ABI: $ABI..."
    BUILD_DIR="$WHISPER_ROOT/build_android_$ABI"
    
    # Clean previous builds
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # Configure CMake
    cmake -H"$WHISPER_ROOT" -B"$BUILD_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM=android-$ANDROID_API \
        -DANDROID_STL=c++_shared \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=OFF \
        -DWHISPER_BUILD_SERVER=OFF

    # Build shared library target
    cmake --build "$BUILD_DIR" --config Release --target whisper

    # Copy output binary to gradle library paths
    DEST_DIR="$OUTPUT_JNI_DIR/$ABI"
    mkdir -p "$DEST_DIR"
    
    # On Android, CMake outputs libwhisper.so
    if [ -f "$BUILD_DIR/src/libwhisper.so" ]; then
        cp "$BUILD_DIR/src/libwhisper.so" "$DEST_DIR/libwhisper.so"
        echo "Successfully copied libwhisper.so to $DEST_DIR"
    elif [ -f "$BUILD_DIR/libwhisper.so" ]; then
        cp "$BUILD_DIR/libwhisper.so" "$DEST_DIR/libwhisper.so"
        echo "Successfully copied libwhisper.so to $DEST_DIR"
    else
        echo "ERROR: Compiled libwhisper.so not found in $BUILD_DIR"
        exit 1
    fi
done

echo "----------------------------------------"
echo "Android whisper build complete!"
echo "Libraries saved at: $OUTPUT_JNI_DIR"
echo "----------------------------------------"
