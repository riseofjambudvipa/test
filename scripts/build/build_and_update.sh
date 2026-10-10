#!/bin/bash
# CapStudio Master Build & Update Utility for macOS and Linux
# Runs updates and platform builds safely with verification.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

write_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "  ${YELLOW}$1${NC}"
    echo -e "${CYAN}================================================${NC}"
}

setup_java() {
    if [ -z "$JAVA_HOME" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS auto-detection
            if [ -x "/usr/libexec/java_home" ]; then
                export JAVA_HOME=$(/usr/libexec/java_home -v 17) 2>/dev/null || export JAVA_HOME=$(/usr/libexec/java_home)
                echo "Auto-detected macOS JAVA_HOME: $JAVA_HOME"
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux auto-detection
            for dir in /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/default-java /usr/lib/jvm/java-11-openjdk-amd64; do
                if [ -d "$dir" ]; then
                    export JAVA_HOME="$dir"
                    export PATH="$dir/bin:$PATH"
                    echo "Auto-detected Linux JAVA_HOME: $JAVA_HOME"
                    break
                fi
            done
        fi
    fi

    if [ -z "$JAVA_HOME" ]; then
        echo -e "${YELLOW}WARNING: JAVA_HOME is not set and could not be auto-detected.${NC}"
        echo -e "${YELLOW}Android builds may fail if JDK is missing.${NC}"
    else
        echo "Using JAVA_HOME: $JAVA_HOME"
    fi
}

clean_and_get() {
    write_header "Cleaning & Getting Dependencies"
    echo "Running flutter clean..."
    flutter clean
    echo "Running flutter pub get..."
    flutter pub get
    echo -e "${GREEN}Dependencies successfully updated!${NC}"
}

run_verification() {
    write_header "Running System Verification"
    echo "Analyzing code structure (flutter analyze)..."
    flutter analyze
    
    echo "Running 310+ unit & widget tests (flutter test)..."
    flutter test
    echo -e "${GREEN}Verification checks completed successfully!${NC}"
}

compile_android_debug() {
    setup_java
    write_header "Building Android Debug APK"
    echo "Compiling whisper.cpp & packaging APK (android-arm64)..."
    flutter build apk --debug --target-platform android-arm64
    echo -e "${GREEN}Success! APK generated at: build/app/outputs/flutter-apk/app-debug.apk${NC}"
}

compile_android_release() {
    setup_java
    write_header "Building Android Release APK"
    echo "Compiling release build..."
    flutter build apk --release --target-platform android-arm64
    echo -e "${GREEN}Success! Release APK generated at: build/app/outputs/flutter-apk/app-release.apk${NC}"
}

compile_desktop() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        write_header "Building macOS Desktop Release"
        flutter build macos --release
        echo -e "${GREEN}Success! macOS App built in: build/macos/Build/Products/Release/CapStudio.app${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        write_header "Building Linux Desktop Release"
        flutter build linux --release
        echo -e "${GREEN}Success! Linux bundle built in: build/linux/x64/release/bundle/${NC}"
    else
        echo -e "${RED}ERROR: Desktop build target not supported for OS: $OSTYPE${NC}"
    fi
}

update_submodules() {
    write_header "Updating whisper.cpp Submodule"
    echo "Checking out latest source files..."
    git submodule init
    git submodule update --recursive
    echo -e "${GREEN}Submodules updated!${NC}"
}

run_safe_upgrade() {
    write_header "Running Safe Package Upgrades"
    echo "Upgrading within pubspec.yaml constraints..."
    flutter pub upgrade
    echo "Testing if updates introduced conflicts..."
    flutter analyze
    echo -e "${GREEN}Upgrades successfully completed and verified!${NC}"
}

# Main loop
while true; do
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "      ${YELLOW}CapStudio Master Controller (macOS/Linux)${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo " 1. Clean & Fetch Dependencies (flutter clean)"
    echo " 2. Run Verification Checks (analyze & test)"
    echo " 3. Build Android Debug APK (Local Testing)"
    echo " 4. Build Android Release APK (Distribution)"
    echo " 5. Build Desktop App (macOS or Linux)"
    echo " 6. Update whisper.cpp Native Submodule"
    echo " 7. Perform Safe Dependency Upgrades"
    echo " 8. Exit"
    echo -e "${CYAN}================================================${NC}"
    
    read -p "Select an option (1-8): " choice
    
    case $choice in
        1) clean_and_get ;;
        2) run_verification ;;
        3) compile_android_debug ;;
        4) compile_android_release ;;
        5) compile_desktop ;;
        6) update_submodules ;;
        7) run_safe_upgrade ;;
        8) echo "Exiting. Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please choose between 1 and 8.${NC}" ;;
    esac
    
    read -p "Press Enter to return to menu..." temp
done
