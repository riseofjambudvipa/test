#!/usr/bin/env bash
# ==============================================================================
# CapStudio: Custom Gradle / Cache Location Setup (macOS & Linux)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "====================================================================="
echo "          CapStudio: Custom Gradle / Cache Location Setup"
echo "====================================================================="
echo ""
echo "This utility configures custom Gradle and Pub cache locations to prevent"
echo "disk-space exhaustion on your primary system drive during builds."
echo ""
echo "Project Root: $PROJECT_ROOT"
echo ""

# Default to standard HOME directory
DEFAULT_CACHE_BASE="$HOME"

# Check root free space in GB
ROOT_FREE_GB=$(df -k "$HOME" | awk 'NR==2 {printf "%.1f", $4/1048576}')
echo "Primary drive ($HOME) has ${ROOT_FREE_GB} GB free space."

# Check for external/secondary volumes with plenty of space on macOS / Linux
SUGGESTED_DIR="$DEFAULT_CACHE_BASE"
if [ "$(uname)" = "Darwin" ]; then
    # macOS external volumes
    if [ -d "/Volumes" ]; then
        for vol in /Volumes/*; do
            if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
                vol_free=$(df -k "$vol" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1048576}')
                echo "  Found external volume: $vol ($vol_free GB free)"
                if (( $(echo "$ROOT_FREE_GB < 15.0" | bc -l) )); then
                    SUGGESTED_DIR="$vol"
                fi
            fi
        done
    fi
else
    # Linux mounts
    for mnt in /media/* /mnt/*; do
        if [ -d "$mnt" ]; then
            mnt_free=$(df -k "$mnt" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1048576}')
            echo "  Found secondary mount: $mnt ($mnt_free GB free)"
            if (( $(echo "$ROOT_FREE_GB < 15.0" | bc -l) )); then
                SUGGESTED_DIR="$mnt"
            fi
        fi
    done
fi

DEFAULT_GRADLE_DIR="$SUGGESTED_DIR/gradle_cache"
DEFAULT_PUB_DIR="$SUGGESTED_DIR/pub_cache"

echo ""
read -p "Enter directory for Gradle Cache [Default: $DEFAULT_GRADLE_DIR]: " USER_GRADLE_DIR
USER_GRADLE_DIR="${USER_GRADLE_DIR:-$DEFAULT_GRADLE_DIR}"

read -p "Enter directory for Flutter Pub Cache [Default: $DEFAULT_PUB_DIR]: " USER_PUB_DIR
USER_PUB_DIR="${USER_PUB_DIR:-$DEFAULT_PUB_DIR}"

mkdir -p "$USER_GRADLE_DIR/tmp"
mkdir -p "$USER_PUB_DIR"

echo ""
echo "====================================================================="
echo "Active Configuration:"
echo " - GRADLE_USER_HOME : $USER_GRADLE_DIR"
echo " - PUB_CACHE        : $USER_PUB_DIR"
echo " - JAVA Temp Dir    : $USER_GRADLE_DIR/tmp"
echo "====================================================================="
echo ""

export GRADLE_USER_HOME="$USER_GRADLE_DIR"
export PUB_CACHE="$USER_PUB_DIR"
export TEMP="$USER_GRADLE_DIR/tmp"
export TMP="$USER_GRADLE_DIR/tmp"
export _JAVA_OPTIONS="-Djava.io.tmpdir=$USER_GRADLE_DIR/tmp"
export GRADLE_OPTS="-Dgradle.user.home=$USER_GRADLE_DIR -Djava.io.tmpdir=$USER_GRADLE_DIR/tmp"

cd "$PROJECT_ROOT"

if [ -d "android" ]; then
    cat <<EOF > "android/gradle.properties"
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m -Djava.io.tmpdir=$USER_GRADLE_DIR/tmp -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.newDsl=false
android.builtInKotlin=false
kotlin.incremental=false

systemProp.gradle.user.home=$USER_GRADLE_DIR
systemProp.java.io.tmpdir=$USER_GRADLE_DIR/tmp
EOF
    echo "[OK] Updated android/gradle.properties"
fi

if [ -f "android/gradlew" ]; then
    echo "Stopping any running Gradle background daemons..."
    (cd android && ./gradlew --stop 2>/dev/null || true)
fi

echo ""
echo "====================================================================="
echo "Choose Build Action:"
echo " [1] Build Release APK (Universal Fat APK)"
echo " [2] Build Release Split APKs (arm64-v8a, armeabi-v7a, x86_64)"
echo " [3] Build Release App Bundle (AAB for Google Play Store)"
echo " [4] Build Debug APK (Local Device Testing)"
echo " [5] Clean + Pub Get + Build Release APK"
echo " [6] Exit"
echo "====================================================================="
echo ""
read -p "Enter choice (1-6) [Default: 1]: " BUILD_CHOICE
BUILD_CHOICE="${BUILD_CHOICE:-1}"

case "$BUILD_CHOICE" in
    1) flutter build apk --release ;;
    2) flutter build apk --release --split-per-abi ;;
    3) flutter build appbundle --release ;;
    4) flutter build apk --debug ;;
    5) flutter clean && flutter pub get && flutter build apk --release ;;
    *) echo "Exiting." ;;
esac

echo ""
echo "Build script completed!"
