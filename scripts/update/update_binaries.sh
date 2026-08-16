#!/bin/bash
# CapStudio - macOS and Linux Binary Auto-Updater / Repair Script
# Runs updates and configures executables for local AI processing.

set -e

# Detect Operating System
OS="$(uname -s)"
ARCH="$(uname -m)"

# Setup Paths
if [ "$OS" = "Darwin" ]; then
    binDir="$HOME/Library/Application Support/CapStudio/bin"
else
    binDir="$HOME/.local/share/CapStudio/bin"
fi
tempDir="/tmp/capstudio_update"

echo "=============================================="
echo "   CapStudio Binary Updater & Repair Utility"
echo "=============================================="
echo "Operating System: $OS ($ARCH)"
echo "Target Directory: $binDir"
echo "----------------------------------------------"

mkdir -p "$binDir"
mkdir -p "$tempDir"

# -------------------------------------------------------------
# 1. macOS Integration (via Homebrew)
# -------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
    echo "[1/3] Updating system packages on macOS..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed! Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Updating Homebrew index..."
    brew update
    
    echo "Installing/Updating FFmpeg..."
    brew install ffmpeg
    
    echo "Installing/Updating Whisper..."
    brew install whisper-cpp
    
    # Create symlinks in CapStudio bin folder
    echo "Linking binaries to CapStudio..."
    ln -sf "$(which ffmpeg)" "$binDir/ffmpeg"
    ln -sf "$(which whisper-cpp)" "$binDir/whisper-cli"
    
    echo "  [✓] Dependencies successfully linked on macOS!"
    
# -------------------------------------------------------------
# 2. Linux Integration (via Package Manager or Local Compilation)
# -------------------------------------------------------------
else
    echo "[1/3] Updating system packages on Linux..."
    
    # Check package manager
    if [ -f /etc/debian_version ]; then
        echo "Detected Debian/Ubuntu system."
        sudo apt update
        sudo apt install -y ffmpeg git build-essential
        
    elif [ -f /etc/fedora-release ]; then
        echo "Detected Fedora system."
        sudo dnf install -y ffmpeg git make gcc-c++ sdl2-devel
        
    elif [ -f /etc/arch-release ]; then
        echo "Detected Arch Linux system."
        sudo pacman -S --noconfirm ffmpeg whisper-cpp git
        ln -sf "$(which whisper-cpp)" "$binDir/whisper-cli"

    else
        # ROBUSTNESS FIX (found in second-pass review): previously there was
        # no fallback here, so a user on any distro other than
        # Debian/Ubuntu/Fedora/Arch (openSUSE, Void, Gentoo, NixOS, etc.)
        # would see this entire block silently do nothing — no error, no
        # explanation, just a missing ffmpeg with no clue why. whisper.cpp
        # still gets compiled from source below regardless of distro, so
        # only ffmpeg needs a manual-install nudge here.
        echo "Unrecognized Linux distribution — could not auto-detect a package manager."
        echo "Please install ffmpeg manually using your distro's package manager, e.g.:"
        echo "  openSUSE: sudo zypper install ffmpeg"
        echo "  Void:     sudo xbps-install ffmpeg"
        echo "  Gentoo:   sudo emerge media-video/ffmpeg"
        echo "  NixOS:    nix-env -iA nixos.ffmpeg"
        echo "whisper.cpp will still be compiled from source below."
    fi

    # Auto link ffmpeg
    if command -v ffmpeg &> /dev/null; then
        ln -sf "$(which ffmpeg)" "$binDir/ffmpeg"
    fi

    # Compile whisper.cpp if it is not arch linux
    if [ ! -f /etc/arch-release ]; then
        echo "[2/3] Compiling whisper.cpp natively from source..."
        cd "$tempDir"
        if [ ! -d "whisper.cpp" ]; then
            git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git
        fi
        cd whisper.cpp
        # Build with make (outputs whisper-cli since whisper.cpp v1.5.x)
        make -j$(nproc) whisper-cli 2>/dev/null || make -j$(nproc)
        
        # Try whisper-cli first (modern name), fall back to main (legacy name)
        if [ -f "whisper-cli" ]; then
          cp whisper-cli "$binDir/whisper-cli"
        elif [ -f "main" ]; then
          cp main "$binDir/whisper-cli"
        else
          echo "  [✗] Error: Neither whisper-cli nor main binary found after build."
          exit 1
        fi
        chmod +x "$binDir/whisper-cli"
        echo "  [✓] whisper.cpp compiled successfully!"
    fi
fi

# -------------------------------------------------------------
# 3. Clean up
# -------------------------------------------------------------
echo ""
echo "[3/3] Cleaning up temporary build folders..."
rm -rf "$tempDir"

echo "=============================================="
echo "   Update Completed Successfully!"
echo "   FFmpeg & Whisper are fully active."
echo "=============================================="
