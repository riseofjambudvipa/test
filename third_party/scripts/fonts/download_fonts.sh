#!/usr/bin/env bash
# CapStudio Font Download Script (Bash/macOS/Linux)
# Downloads ALL font assets from Google Fonts GitHub repo
# Run: bash scripts/download_fonts.sh
#
# NOTE: Google Fonts has migrated to VARIABLE font format.
# Brackets in filenames are URL-encoded: [ → %5B, ] → %5D, , → %2C

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

DEST="$PROJECT_ROOT/assets/fonts"
mkdir -p "$DEST"
BASE="https://github.com/google/fonts/raw/main/ofl"

get_file_size() {
    local file="$1"
    local size=0
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    # Strip any whitespace
    size=$(echo "$size" | tr -d '[:space:]')
    # If not a number, default to 0
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        size=0
    fi
    echo "$size"
}

download_font() {
    local url="$1" out="$2"
    local size=0
    if [ -f "$out" ]; then
        size=$(get_file_size "$out")
        if [ "$size" -gt 1024 ]; then
            echo "  [SKIP] $(basename "$out") (already exists)"
            return 0
        fi
    fi
    echo "Downloading $(basename "$out")..."
    for i in 1 2 3; do
        if curl -fsSL --retry 3 -o "$out" "$url"; then
            size=$(get_file_size "$out")
            if [ "$size" -gt 1024 ]; then
                echo "  [OK] $(basename "$out") ($((size / 1024)) KB)"
                return 0
            fi
            echo "  WARNING: File too small ($size bytes), retrying..."
        fi
        sleep $((i * 2))
    done
    echo "  [FAIL] $(basename "$out")"
    return 1
}

echo "=== DOWNLOADING TEMPLATE & CREATIVE FONTS ==="

# Variable fonts
download_font "$BASE/montserrat/Montserrat%5Bwght%5D.ttf"              "$DEST/Montserrat-Variable.ttf"
download_font "$BASE/outfit/Outfit%5Bwght%5D.ttf"                      "$DEST/Outfit-Variable.ttf"
download_font "$BASE/raleway/Raleway%5Bwght%5D.ttf"                    "$DEST/Raleway-Variable.ttf"
download_font "$BASE/orbitron/Orbitron%5Bwght%5D.ttf"                  "$DEST/Orbitron-Variable.ttf"
download_font "$BASE/urbanist/Urbanist%5Bwght%5D.ttf"                  "$DEST/Urbanist-Variable.ttf"
download_font "$BASE/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf" "$DEST/Fraunces-Variable.ttf"
download_font "$BASE/gabarito/Gabarito%5Bwght%5D.ttf"                  "$DEST/Gabarito-Variable.ttf"
download_font "$BASE/oswald/Oswald%5Bwght%5D.ttf"                      "$DEST/Oswald-Variable.ttf"
download_font "$BASE/caveat/Caveat%5Bwght%5D.ttf"                      "$DEST/Caveat-Variable.ttf"
download_font "$BASE/exo2/Exo2%5Bwght%5D.ttf"                          "$DEST/Exo2-Variable.ttf"
download_font "$BASE/nunito/Nunito%5Bwght%5D.ttf"                      "$DEST/Nunito-Variable.ttf"
download_font "$BASE/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf"          "$DEST/SpaceGrotesk-Variable.ttf"
download_font "$BASE/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf"    "$DEST/PlayfairDisplay-Variable.ttf"
download_font "$BASE/dancingscript/DancingScript%5Bwght%5D.ttf"        "$DEST/DancingScript-Variable.ttf"

# Static fonts
download_font "$BASE/anton/Anton-Regular.ttf"                          "$DEST/Anton-Regular.ttf"
download_font "$BASE/bebasneue/BebasNeue-Regular.ttf"                  "$DEST/BebasNeue-Regular.ttf"
download_font "$BASE/bangers/Bangers-Regular.ttf"                      "$DEST/Bangers-Regular.ttf"
download_font "$BASE/poppins/Poppins-Bold.ttf"                         "$DEST/Poppins-Bold.ttf"
download_font "$BASE/poppins/Poppins-ExtraBold.ttf"                    "$DEST/Poppins-ExtraBold.ttf"
download_font "$BASE/dmseriftext/DMSerifText-Regular.ttf"              "$DEST/DMSerifDisplay-Regular.ttf"
download_font "$BASE/comicneue/ComicNeue-Bold.ttf"                     "$DEST/ComicNeue-Bold.ttf"
download_font "$BASE/rubikglitch/RubikGlitch-Regular.ttf"              "$DEST/RubikGlitch-Regular.ttf"
download_font "$BASE/pacifico/Pacifico-Regular.ttf"                    "$DEST/Pacifico-Regular.ttf"
download_font "$BASE/blackhansans/BlackHanSans-Regular.ttf"            "$DEST/BlackHanSans-Regular.ttf"
download_font "$BASE/righteous/Righteous-Regular.ttf"                  "$DEST/Righteous-Regular.ttf"
download_font "$BASE/lobster/Lobster-Regular.ttf"                      "$DEST/Lobster-Regular.ttf"
download_font "$BASE/pressstart2p/PressStart2P-Regular.ttf"            "$DEST/PressStart2P-Regular.ttf"

echo ""
echo "=== DOWNLOADING NOTO LANGUAGE FONTS (21 families) ==="
download_font "$BASE/notosans/NotoSans%5Bwdth%2Cwght%5D.ttf"                     "$DEST/NotoSans-Variable.ttf"
download_font "$BASE/notosansdevanagari/NotoSansDevanagari%5Bwdth%2Cwght%5D.ttf" "$DEST/NotoSansDevanagari-Variable.ttf"
download_font "$BASE/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf"         "$DEST/NotoSansArabic-Variable.ttf"
download_font "$BASE/notosansthai/NotoSansThai%5Bwdth%2Cwght%5D.ttf"             "$DEST/NotoSansThai-Variable.ttf"
download_font "$BASE/notosanshebrew/NotoSansHebrew%5Bwdth%2Cwght%5D.ttf"         "$DEST/NotoSansHebrew-Variable.ttf"
download_font "$BASE/notosanstamil/NotoSansTamil%5Bwdth%2Cwght%5D.ttf"           "$DEST/NotoSansTamil-Variable.ttf"
download_font "$BASE/notosanstelugu/NotoSansTelugu%5Bwdth%2Cwght%5D.ttf"         "$DEST/NotoSansTelugu-Variable.ttf"
download_font "$BASE/notosansbengali/NotoSansBengali%5Bwdth%2Cwght%5D.ttf"       "$DEST/NotoSansBengali-Variable.ttf"
download_font "$BASE/notosansgujarati/NotoSansGujarati%5Bwdth%2Cwght%5D.ttf"     "$DEST/NotoSansGujarati-Variable.ttf"
download_font "$BASE/notosanskannada/NotoSansKannada%5Bwdth%2Cwght%5D.ttf"       "$DEST/NotoSansKannada-Variable.ttf"
download_font "$BASE/notosansmalayalam/NotoSansMalayalam%5Bwdth%2Cwght%5D.ttf"   "$DEST/NotoSansMalayalam-Variable.ttf"
download_font "$BASE/notosansgurmukhi/NotoSansGurmukhi%5Bwdth%2Cwght%5D.ttf"     "$DEST/NotoSansGurmukhi-Variable.ttf"
download_font "$BASE/notosansoriya/NotoSansOriya%5Bwdth%2Cwght%5D.ttf"           "$DEST/NotoSansOriya-Variable.ttf"
download_font "$BASE/notosanssinhala/NotoSansSinhala%5Bwdth%2Cwght%5D.ttf"       "$DEST/NotoSansSinhala-Variable.ttf"
download_font "$BASE/notosansmyanmar/NotoSansMyanmar%5Bwdth%2Cwght%5D.ttf"       "$DEST/NotoSansMyanmar-Variable.ttf"
download_font "$BASE/notosanskhmer/NotoSansKhmer%5Bwdth%2Cwght%5D.ttf"           "$DEST/NotoSansKhmer-Variable.ttf"
download_font "$BASE/notosanslao/NotoSansLao%5Bwdth%2Cwght%5D.ttf"               "$DEST/NotoSansLao-Variable.ttf"
download_font "$BASE/notosansgeorgian/NotoSansGeorgian%5Bwdth%2Cwght%5D.ttf"     "$DEST/NotoSansGeorgian-Variable.ttf"
download_font "$BASE/notosansarmenian/NotoSansArmenian%5Bwdth%2Cwght%5D.ttf"     "$DEST/NotoSansArmenian-Variable.ttf"
download_font "$BASE/notosansethiopic/NotoSansEthiopic%5Bwdth%2Cwght%5D.ttf"     "$DEST/NotoSansEthiopic-Variable.ttf"
download_font "$BASE/notonastaliqurdu/NotoNastaliqUrdu%5Bwght%5D.ttf"            "$DEST/NotoNastaliqUrdu-Variable.ttf"

echo ""
echo "=== SUMMARY ==="
TOTAL=$(find "$DEST" -name "*.ttf" | wc -l | tr -d ' ')
SIZE=$(du -sh "$DEST" | awk '{print $1}')
echo "Total fonts: $TOTAL files ($SIZE)"
