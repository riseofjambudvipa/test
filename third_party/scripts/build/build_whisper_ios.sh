#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../../pubspec.yaml" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

WHISPER_ROOT="$PROJECT_ROOT/third_party/whisper.cpp"
OUTPUT_DIR="$PROJECT_ROOT/ios/whisper_xcframework"
FRAMEWORK_NAME="whisper"

# Supported architectures
ARCHS_DEVICE="arm64"
ARCHS_SIMULATOR="arm64 x86_64"

# Clean up previous builds
rm -rf "$OUTPUT_DIR"
rm -rf "$WHISPER_ROOT/build_ios_device"
rm -rf "$WHISPER_ROOT/build_ios_sim"

# Build for device
echo "Building for iOS device (arm64)..."
cmake -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="arm64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="16.0" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_METAL=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -B "$WHISPER_ROOT/build_ios_device" \
    "$WHISPER_ROOT"

cmake --build "$WHISPER_ROOT/build_ios_device" \
    --config Release \
    -- -sdk iphoneos -quiet

# Build for simulator
echo "Building for iOS simulator (arm64 + x86_64)..."
cmake -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="16.0" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_METAL=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -B "$WHISPER_ROOT/build_ios_sim" \
    "$WHISPER_ROOT"

cmake --build "$WHISPER_ROOT/build_ios_sim" \
    --config Release \
    -- -sdk iphonesimulator -quiet

# Create xcframework
echo "Creating xcframework..."
mkdir -p "$OUTPUT_DIR"

# Find and combine all built static libraries (.a files) to include ggml, ggml-base, etc.
echo "Combining device static libraries..."
DEVICE_LIBS=$(find "$WHISPER_ROOT/build_ios_device" -name "*.a")
echo "Found device libraries: $DEVICE_LIBS"
libtool -static -o "$WHISPER_ROOT/build_ios_device/libwhisper_combined.a" $DEVICE_LIBS

echo "Combining simulator static libraries..."
SIM_LIBS=$(find "$WHISPER_ROOT/build_ios_sim" -name "*.a")
echo "Found simulator libraries: $SIM_LIBS"
libtool -static -o "$WHISPER_ROOT/build_ios_sim/libwhisper_combined.a" $SIM_LIBS

# Consolidate all required public headers (whisper.h + ggml.h and its dependencies)
TEMP_HEADERS_DIR="$WHISPER_ROOT/build_headers"
rm -rf "$TEMP_HEADERS_DIR"
mkdir -p "$TEMP_HEADERS_DIR"
cp "$WHISPER_ROOT/include/whisper.h" "$TEMP_HEADERS_DIR/"
cp "$WHISPER_ROOT/ggml/include/"*.h "$TEMP_HEADERS_DIR/"

xcodebuild -create-xcframework \
    -library "$WHISPER_ROOT/build_ios_device/libwhisper_combined.a" \
    -headers "$TEMP_HEADERS_DIR" \
    -library "$WHISPER_ROOT/build_ios_sim/libwhisper_combined.a" \
    -headers "$TEMP_HEADERS_DIR" \
    -output "$OUTPUT_DIR/whisper.xcframework"

rm -rf "$TEMP_HEADERS_DIR"

echo "Copying xcframework to ios/Runner/whisper_xcframework/ for Xcode reference compatibility..."
mkdir -p ios/Runner/whisper_xcframework
rm -rf ios/Runner/whisper_xcframework/whisper.xcframework
cp -R "$OUTPUT_DIR/whisper.xcframework" ios/Runner/whisper_xcframework/

echo "Done. xcframework at: $OUTPUT_DIR/whisper.xcframework"
