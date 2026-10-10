#!/bin/bash
# CapStudio - Mobile Dependency Auto-Updater for Developers
# Updates FFmpeg and whisper.cpp for Android & iOS without manual compilation knowledge.

set -e

# Colors for terminal output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0;30m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"
WHISPER_DIR="$PROJECT_ROOT/third_party/whisper.cpp"

echo -e "${CYAN}==================================================${NC}"
echo -e "${GREEN}   CapStudio Mobile Dependency Auto-Updater"
echo -e "${CYAN}==================================================${NC}"
echo -e "This script simplifies upgrading FFmpeg and Whisper for iOS & Android."
echo -e "Project Root: $PROJECT_ROOT"
echo ""

# -------------------------------------------------------------
# 1. Update FFmpeg Kit Version in pubspec.yaml
# -------------------------------------------------------------
echo -e "${YELLOW}[1/3] Checking FFmpeg Kit Package Version...${NC}"
current_version=$(grep "ffmpeg_kit_flutter_new:" "$PUBSPEC_PATH" | sed 's/.*: //')
echo -e "Current FFmpeg Kit Package version: ${GREEN}$current_version${NC}"

read -p "Do you want to update FFmpeg Kit Package? (y/N): " update_ffmpeg
if [ "$update_ffmpeg" = "y" ] || [ "$update_ffmpeg" = "Y" ]; then
    read -p "Enter new version (e.g. ^4.2.2 or ^5.0.0): " new_ffmpeg_version
    if [ -n "$new_ffmpeg_version" ]; then
        # Replace the version in pubspec.yaml
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/ffmpeg_kit_flutter_new:.*/ffmpeg_kit_flutter_new: $new_ffmpeg_version/" "$PUBSPEC_PATH"
        else
            sed -i "s/ffmpeg_kit_flutter_new:.*/ffmpeg_kit_flutter_new: $new_ffmpeg_version/" "$PUBSPEC_PATH"
        fi
        echo -e "${GREEN}[✓] pubspec.yaml updated with FFmpeg Kit version $new_ffmpeg_version${NC}"
    fi
else
    echo "Skipped FFmpeg Kit update."
fi

# -------------------------------------------------------------
# 2. Update whisper.cpp Submodule Version
# -------------------------------------------------------------
echo ""
echo -e "${YELLOW}[2/3] Updating whisper.cpp Submodule...${NC}"
cd "$WHISPER_DIR"

echo "Fetching latest tags from GitHub..."
git fetch --tags --all

# Show recent tags
echo -e "Recent Whisper releases:"
git tag -l | tail -n 10

read -p "Enter target whisper.cpp release tag (e.g., v1.8.4 or v1.9.0): " whisper_tag

if [ -n "$whisper_tag" ]; then
    echo "Checking out $whisper_tag..."
    git checkout "$whisper_tag"
    git submodule update --init --recursive
    echo -e "${GREEN}[✓] Submodule whisper.cpp successfully updated to $whisper_tag${NC}"
else
    echo -e "${RED}Invalid tag entered. Keeping current version.${NC}"
fi
cd ../..

# -------------------------------------------------------------
# 3. Compile Native Libraries for iOS / Android
# -------------------------------------------------------------
echo ""
echo -e "${YELLOW}[3/3] Compiling Native Wrappers...${NC}"

# A. Android Compilation: No work required!
echo -e "${CYAN}Android:${NC}"
echo -e "  -> Android uses dynamic CMake compilation via Gradle."
echo -e "  -> ${GREEN}No manual compilation steps needed!${NC} Gradle will automatically build"
echo -e "     the updated whisper.cpp files when you run 'flutter run' or 'flutter build'."

# B. iOS Compilation: Compile xcframework
echo ""
echo -e "${CYAN}iOS:${NC}"
if [ "$(uname)" = "Darwin" ]; then
    read -p "Do you want to compile whisper.xcframework for iOS? (y/N): " compile_ios
    if [ "$compile_ios" = "y" ] || [ "$compile_ios" = "Y" ]; then
        echo "Building whisper.xcframework using CMake & Xcode..."
        chmod +x scripts/build/build_whisper_ios.sh
        ./scripts/build/build_whisper_ios.sh
        echo -e "${GREEN}[✓] iOS whisper.xcframework successfully built and linked!${NC}"
    else
        echo "Skipped iOS compilation."
    fi
else
    echo -e "  -> ${YELLOW}Skipping iOS Compilation:${NC} (requires macOS and Xcode to compile iOS frameworks)."
fi

# -------------------------------------------------------------
# 4. Fetch dependencies
# -------------------------------------------------------------
echo ""
echo -e "${YELLOW}Fetching Flutter Dependencies...${NC}"
flutter pub get

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Mobile Dependencies Update Complete!"
echo -e "${GREEN}==================================================${NC}"
echo "You can now run 'flutter run -d android' or 'flutter run -d ios' to test."
