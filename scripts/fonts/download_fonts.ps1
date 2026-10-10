# CapStudio Font Download Script (PowerShell)
# Downloads ALL font assets from Google Fonts GitHub repo
# Run: powershell -ExecutionPolicy Bypass -File scripts/download_fonts.ps1
#
# NOTE: Google Fonts has migrated to VARIABLE font format.
# Variable fonts contain ALL weights in a single file.
# Brackets in filenames are URL-encoded: [ → %5B, ] → %5D, , → %2C

$ErrorActionPreference = "Continue"

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$Dest = Join-Path $ProjectRoot "assets\fonts"
if (!(Test-Path -Path $Dest)) { New-Item -ItemType Directory -Force -Path $Dest | Out-Null }

$Base = "https://github.com/google/fonts/raw/main/ofl"

# ── Template / Creative Fonts ──────────────────────────────────────────────
$Fonts = [ordered]@{
    # Variable fonts (contain all weights)
    "Montserrat-Variable.ttf"      = "$Base/montserrat/Montserrat%5Bwght%5D.ttf"
    "Outfit-Variable.ttf"          = "$Base/outfit/Outfit%5Bwght%5D.ttf"
    "Raleway-Variable.ttf"         = "$Base/raleway/Raleway%5Bwght%5D.ttf"
    "Orbitron-Variable.ttf"        = "$Base/orbitron/Orbitron%5Bwght%5D.ttf"
    "Urbanist-Variable.ttf"        = "$Base/urbanist/Urbanist%5Bwght%5D.ttf"
    "Fraunces-Variable.ttf"        = "$Base/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf"
    "Gabarito-Variable.ttf"        = "$Base/gabarito/Gabarito%5Bwght%5D.ttf"
    "Oswald-Variable.ttf"          = "$Base/oswald/Oswald%5Bwght%5D.ttf"
    "Caveat-Variable.ttf"          = "$Base/caveat/Caveat%5Bwght%5D.ttf"
    "Exo2-Variable.ttf"            = "$Base/exo2/Exo2%5Bwght%5D.ttf"
    "Nunito-Variable.ttf"          = "$Base/nunito/Nunito%5Bwght%5D.ttf"
    "SpaceGrotesk-Variable.ttf"    = "$Base/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf"
    "PlayfairDisplay-Variable.ttf" = "$Base/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf"
    "DancingScript-Variable.ttf"   = "$Base/dancingscript/DancingScript%5Bwght%5D.ttf"
    # Static fonts (single weight only)
    "Anton-Regular.ttf"            = "$Base/anton/Anton-Regular.ttf"
    "BebasNeue-Regular.ttf"        = "$Base/bebasneue/BebasNeue-Regular.ttf"
    "Bangers-Regular.ttf"          = "$Base/bangers/Bangers-Regular.ttf"
    "Poppins-Bold.ttf"             = "$Base/poppins/Poppins-Bold.ttf"
    "Poppins-ExtraBold.ttf"        = "$Base/poppins/Poppins-ExtraBold.ttf"
    "DMSerifDisplay-Regular.ttf"   = "$Base/dmseriftext/DMSerifText-Regular.ttf"
    "ComicNeue-Bold.ttf"           = "$Base/comicneue/ComicNeue-Bold.ttf"
    "RubikGlitch-Regular.ttf"      = "$Base/rubikglitch/RubikGlitch-Regular.ttf"
    "Pacifico-Regular.ttf"         = "$Base/pacifico/Pacifico-Regular.ttf"
    "BlackHanSans-Regular.ttf"     = "$Base/blackhansans/BlackHanSans-Regular.ttf"
    "Righteous-Regular.ttf"        = "$Base/righteous/Righteous-Regular.ttf"
    "Lobster-Regular.ttf"          = "$Base/lobster/Lobster-Regular.ttf"
    "PressStart2P-Regular.ttf"     = "$Base/pressstart2p/PressStart2P-Regular.ttf"
}

# ── Noto Language Fonts (21 families — covers ALL Whisper scripts) ─────────
$NotoFonts = [ordered]@{
    "NotoSans-Variable.ttf"            = "$Base/notosans/NotoSans%5Bwdth%2Cwght%5D.ttf"
    "NotoSansDevanagari-Variable.ttf"  = "$Base/notosansdevanagari/NotoSansDevanagari%5Bwdth%2Cwght%5D.ttf"
    "NotoSansArabic-Variable.ttf"      = "$Base/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf"
    "NotoSansThai-Variable.ttf"        = "$Base/notosansthai/NotoSansThai%5Bwdth%2Cwght%5D.ttf"
    "NotoSansHebrew-Variable.ttf"      = "$Base/notosanshebrew/NotoSansHebrew%5Bwdth%2Cwght%5D.ttf"
    "NotoSansTamil-Variable.ttf"       = "$Base/notosanstamil/NotoSansTamil%5Bwdth%2Cwght%5D.ttf"
    "NotoSansTelugu-Variable.ttf"      = "$Base/notosanstelugu/NotoSansTelugu%5Bwdth%2Cwght%5D.ttf"
    "NotoSansBengali-Variable.ttf"     = "$Base/notosansbengali/NotoSansBengali%5Bwdth%2Cwght%5D.ttf"
    "NotoSansGujarati-Variable.ttf"    = "$Base/notosansgujarati/NotoSansGujarati%5Bwdth%2Cwght%5D.ttf"
    "NotoSansKannada-Variable.ttf"     = "$Base/notosanskannada/NotoSansKannada%5Bwdth%2Cwght%5D.ttf"
    "NotoSansMalayalam-Variable.ttf"   = "$Base/notosansmalayalam/NotoSansMalayalam%5Bwdth%2Cwght%5D.ttf"
    "NotoSansGurmukhi-Variable.ttf"    = "$Base/notosansgurmukhi/NotoSansGurmukhi%5Bwdth%2Cwght%5D.ttf"
    "NotoSansOriya-Variable.ttf"       = "$Base/notosansoriya/NotoSansOriya%5Bwdth%2Cwght%5D.ttf"
    "NotoSansSinhala-Variable.ttf"     = "$Base/notosanssinhala/NotoSansSinhala%5Bwdth%2Cwght%5D.ttf"
    "NotoSansMyanmar-Variable.ttf"     = "$Base/notosansmyanmar/NotoSansMyanmar%5Bwdth%2Cwght%5D.ttf"
    "NotoSansKhmer-Variable.ttf"       = "$Base/notosanskhmer/NotoSansKhmer%5Bwdth%2Cwght%5D.ttf"
    "NotoSansLao-Variable.ttf"         = "$Base/notosanslao/NotoSansLao%5Bwdth%2Cwght%5D.ttf"
    "NotoSansGeorgian-Variable.ttf"    = "$Base/notosansgeorgian/NotoSansGeorgian%5Bwdth%2Cwght%5D.ttf"
    "NotoSansArmenian-Variable.ttf"    = "$Base/notosansarmenian/NotoSansArmenian%5Bwdth%2Cwght%5D.ttf"
    "NotoSansEthiopic-Variable.ttf"    = "$Base/notosansethiopic/NotoSansEthiopic%5Bwdth%2Cwght%5D.ttf"
    "NotoNastaliqUrdu-Variable.ttf"    = "$Base/notonastaliqurdu/NotoNastaliqUrdu%5Bwght%5D.ttf"
}

function Download-Font {
    param ([string]$Url, [string]$OutPath)
    $retries = 3
    for ($i = 1; $i -le $retries; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing -ErrorAction Stop
            $size = (Get-Item $OutPath).Length
            if ($size -gt 1024) { return $true }
            Write-Host "  WARNING: File too small ($size bytes), retrying..."
        } catch {
            Write-Host "  Retry $i/$retries failed: $_"
        }
        Start-Sleep -Seconds ($i * 2)
    }
    return $false
}

Write-Host "=== DOWNLOADING TEMPLATE & CREATIVE FONTS ($(($Fonts.Count)) files) ==="
$successCount = 0; $failCount = 0
foreach ($file in $Fonts.Keys) {
    $out = Join-Path -Path $Dest -ChildPath $file
    if ((Test-Path -Path $out) -and (Get-Item $out).Length -gt 1024) {
        Write-Host "  [SKIP] $file (already exists)"
        $successCount++; continue
    }
    Write-Host "Downloading $file..."
    if (Download-Font -Url $Fonts[$file] -OutPath $out) {
        $kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
        Write-Host "  [OK] $file ($kb KB)"
        $successCount++
    } else {
        Write-Host "  [FAIL] $file"
        $failCount++
    }
}

Write-Host ""
Write-Host "=== DOWNLOADING NOTO LANGUAGE FONTS ($(($NotoFonts.Count)) files) ==="
foreach ($file in $NotoFonts.Keys) {
    $out = Join-Path -Path $Dest -ChildPath $file
    if ((Test-Path -Path $out) -and (Get-Item $out).Length -gt 1024) {
        Write-Host "  [SKIP] $file (already exists)"
        $successCount++; continue
    }
    Write-Host "Downloading $file..."
    if (Download-Font -Url $NotoFonts[$file] -OutPath $out) {
        $kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
        Write-Host "  [OK] $file ($kb KB)"
        $successCount++
    } else {
        Write-Host "  [FAIL] $file"
        $failCount++
    }
}

Write-Host ""
Write-Host "=== SUMMARY ==="
$total = Get-ChildItem "$Dest\*.ttf"
$totalMB = [math]::Round(($total | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host "Success: $successCount | Failed: $failCount"
Write-Host "Total fonts on disk: $($total.Count) files ($totalMB MB)"
