#!/bin/bash
set -e

# Default to base model if no argument is provided
MODEL_NAME=${1:-base}

# Check if model is supported
SUPPORTED_MODELS=("tiny" "tiny.en" "base" "base.en" "small" "small.en" "medium" "medium.en" "large-v1" "large-v2" "large-v3")

# Check if the model is in the list
VALID=false
for m in "${SUPPORTED_MODELS[@]}"; do
    if [ "$m" = "$MODEL_NAME" ]; then
        VALID=true
        break
    fi
done

if [ "$VALID" = false ]; then
    echo "ERROR: Unsupported model name: $MODEL_NAME"
    echo "Supported models: ${SUPPORTED_MODELS[*]}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# We download to assets/models for packing or testing
MODELS_DIR="$PROJECT_ROOT/assets/models"
mkdir -p "$MODELS_DIR"

URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL_NAME}.bin"
OUTPUT_FILE="$MODELS_DIR/ggml-${MODEL_NAME}.bin"

echo "----------------------------------------"
echo "Downloading Whisper model: $MODEL_NAME..."
echo "URL: $URL"
echo "Destination: $OUTPUT_FILE"
echo "----------------------------------------"

if command -v curl >/dev/null 2>&1; then
    curl -L "$URL" -o "$OUTPUT_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget "$URL" -O "$OUTPUT_FILE"
else
    echo "ERROR: Neither curl nor wget is installed. Cannot download."
    exit 1
fi

echo "----------------------------------------"
echo "Download completed successfully!"
echo "To use this model in development, place it inside the support directory:"
echo " - Windows: %APPDATA%/CapStudio/models/ggml-${MODEL_NAME}.bin"
echo " - macOS: ~/Library/Application Support/CapStudio/models/ggml-${MODEL_NAME}.bin"
echo " - Linux: ~/.local/share/CapStudio/models/ggml-${MODEL_NAME}.bin"
echo "----------------------------------------"
