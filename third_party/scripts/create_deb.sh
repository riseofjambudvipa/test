#!/bin/bash
# CapStudio — Debian Package Creator (.deb)
# Flutter Linux bundles have a specific layout:
#   /opt/capstudio/capstudio       <- main executable (lowercase, Flutter convention)
#   /opt/capstudio/lib/            <- required shared libraries (must stay adjacent to binary)
#   /opt/capstudio/data/           <- Flutter assets and fonts
# A wrapper script at /usr/bin/capstudio sets LD_LIBRARY_PATH and launches the bundle.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEB_BUILD_DIR="/tmp/capstudio_deb"
BUNDLE_SRC="$PROJECT_ROOT/build/linux/x64/release/bundle"

# Extract version dynamically from pubspec.yaml
VERSION=$(grep '^version: ' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1 | tr -d '\r')
if [ -z "$VERSION" ]; then
    echo "ERROR: Could not extract version from $PROJECT_ROOT/pubspec.yaml"
    exit 1
fi

echo "================================================"
echo "  CapStudio Linux Debian Packager               "
echo "================================================"

# Step 1: Verify build exists
if [ ! -d "$BUNDLE_SRC" ]; then
    echo "ERROR: Build bundle not found at $BUNDLE_SRC"
    echo "Run: flutter build linux --release"
    exit 1
fi

# Step 2: Build directory tree
echo "Preparing workspace..."
rm -rf "$DEB_BUILD_DIR"
mkdir -p "$DEB_BUILD_DIR/opt/capstudio"
mkdir -p "$DEB_BUILD_DIR/usr/bin"
mkdir -p "$DEB_BUILD_DIR/usr/share/applications"
mkdir -p "$DEB_BUILD_DIR/usr/share/pixmaps"
mkdir -p "$DEB_BUILD_DIR/DEBIAN"

# Step 3: Copy entire Flutter bundle to /opt/capstudio/
# Keeps lib/ and data/ directories intact alongside the executable.
echo "Copying compiled release bundle..."
cp -r "$BUNDLE_SRC/." "$DEB_BUILD_DIR/opt/capstudio/"
chmod +x "$DEB_BUILD_DIR/opt/capstudio/capstudio"

# Step 4: /usr/bin/capstudio wrapper — sets LD_LIBRARY_PATH before exec
cat > "$DEB_BUILD_DIR/usr/bin/capstudio" << 'WRAPPER'
#!/bin/bash
INSTALL_DIR="/opt/capstudio"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
exec "$INSTALL_DIR/capstudio" "$@"
WRAPPER
chmod +x "$DEB_BUILD_DIR/usr/bin/capstudio"

# Step 5: Icon
if [ -f "$PROJECT_ROOT/assets/logo/logo.png" ]; then
    cp "$PROJECT_ROOT/assets/logo/logo.png" "$DEB_BUILD_DIR/usr/share/pixmaps/capstudio.png"
fi

# Step 6: DEBIAN/control
echo "Generating control file..."
cat > "$DEB_BUILD_DIR/DEBIAN/control" << EOF
Package: capstudio
Version: $VERSION
Section: video
Priority: optional
Architecture: amd64
Maintainer: CapStudio Team <support@capstudio.app>
Depends: libgtk-3-0, libgl1-mesa-glx | libgl1, libmpv1 | libmpv2
Description: Free offline AI caption studio
 Local AI-powered video caption editor. Transcribes, styles, and
 burns in captions without any cloud upload.
EOF

# Step 7: DEBIAN/postinst — fix permissions after install
cat > "$DEB_BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
chmod -R 755 /opt/capstudio
chmod +x /opt/capstudio/capstudio
chmod +x /usr/bin/capstudio
EOF
chmod 755 "$DEB_BUILD_DIR/DEBIAN/postinst"

# Step 8: .desktop launcher with correct Exec and MimeType
echo "Generating desktop entry..."
cat > "$DEB_BUILD_DIR/usr/share/applications/capstudio.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=CapStudio
GenericName=Caption Studio
Comment=Free offline AI caption studio
Exec=/usr/bin/capstudio %U
Icon=capstudio
Type=Application
Terminal=false
StartupNotify=true
Categories=Video;AudioVideo;
MimeType=video/mp4;video/x-matroska;video/webm;video/avi;video/quicktime;
EOF

# Step 9: Build .deb
echo "Building .deb package..."
DEB_FILE="$PROJECT_ROOT/capstudio_${VERSION}_amd64.deb"
dpkg-deb --build "$DEB_BUILD_DIR" "$DEB_FILE"

echo "================================================"
echo "Done: capstudio_${VERSION}_amd64.deb"
echo "Install: sudo dpkg -i capstudio_${VERSION}_amd64.deb"
echo "================================================"
