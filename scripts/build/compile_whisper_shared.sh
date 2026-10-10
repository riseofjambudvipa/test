#!/bin/bash
# CapStudio - Compile whisper.cpp as a Shared Library (.so / .dylib) for FFI
# Run this script to compile whisper.cpp as a shared dynamic library and copy it into the macOS/Linux runner build directories.

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WHISPER_ROOT="$PROJECT_ROOT/third_party/whisper.cpp"
BUILD_DIR="$WHISPER_ROOT/build_shared_local"

echo "=========================================================="
echo "  CapStudio Shared Whisper.cpp Library Compiler (.so/.dylib)"
echo "=========================================================="
echo "Source Path: $WHISPER_ROOT"
echo ""

# 1. Verify Submodule Source
if [ ! -f "$WHISPER_ROOT/CMakeLists.txt" ]; then
    echo "whisper.cpp submodule source is missing. Initializing..."
    cd "$PROJECT_ROOT"
    git submodule update --init --recursive
    if [ ! -f "$WHISPER_ROOT/CMakeLists.txt" ]; then
        echo "Error: Failed to initialize whisper.cpp submodule."
        exit 1
    fi
fi

# 2. Configure CMake flags for Shared Library Build
CMAKE_FLAGS=(
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS=ON"
    "-DWHISPER_BUILD_TESTS=OFF"
    "-DWHISPER_BUILD_EXAMPLES=OFF"
)

# Detect OS
OS_TYPE="$(uname -s)"
if [ "$OS_TYPE" == "Darwin" ]; then
    echo "OS Detected: macOS"
    OUTPUT_LIB_DIR="$PROJECT_ROOT/macos"
    LIB_EXT="dylib"
    LIB_PREFIX="lib"
else
    echo "OS Detected: Linux"
    OUTPUT_LIB_DIR="$PROJECT_ROOT/linux"
    LIB_EXT="so"
    LIB_PREFIX="lib"
fi

# 3. Create and enter build folder
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 4. Configure Build
echo ""
echo "[1/3] Configuring CMake project..."
cmake "$WHISPER_ROOT" "${CMAKE_FLAGS[@]}"

# 5. Compile Shared Library
echo ""
echo "[2/3] Compiling Shared Library (Release Mode)..."
cmake --build . --config Release --target whisper

# 6. Copy compiled library
echo ""
echo "[3/3] Copying dynamic library to Flutter runner..."
LIB_NAME="${LIB_PREFIX}whisper.${LIB_EXT}"
FOUND_LIB=$(find . -name "$LIB_NAME" | head -n 1)

if [ -n "$FOUND_LIB" ]; then
    mkdir -p "$OUTPUT_LIB_DIR"
    cp "$FOUND_LIB" "$OUTPUT_LIB_DIR/$LIB_NAME"
    echo "  [✓] $LIB_NAME successfully compiled and copied to: $OUTPUT_LIB_DIR/$LIB_NAME"
else
    echo "Error: Failed to locate compiled library: $LIB_NAME"
    exit 1
fi

echo ""
echo "Finished successfully!"
