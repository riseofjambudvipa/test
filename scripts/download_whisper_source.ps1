# CapStudio - Download whisper.cpp Source
# Downloads whisper.cpp v1.9.4 (certified version for CapStudio) into third_party/whisper.cpp
# Run this if you don't have git or the submodule is missing.
#
# Usage: .\scripts\download_whisper_source.ps1
#        .\scripts\download_whisper_source.ps1 -Version v1.9.4

param(
    [string]$Version = "v1.9.4"
)

$ErrorActionPreference = "Stop"
$root       = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path
$destDir    = Join-Path $root "third_party\whisper.cpp"
$zipFile    = Join-Path $env:TEMP "whisper_cpp_$Version.zip"
$extractDir = Join-Path $env:TEMP "whisper_cpp_extract_$Version"
$url        = "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/$Version.zip"

Write-Host ""
Write-Host "CapStudio - whisper.cpp Source Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Version : $Version" -ForegroundColor Green
Write-Host "  Dest    : $destDir" -ForegroundColor Green
Write-Host ""

# Already present?
if (Test-Path (Join-Path $destDir "CMakeLists.txt")) {
    Write-Host "[OK] whisper.cpp source already present at:" -ForegroundColor Green
    Write-Host "     $destDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To force re-download, delete the folder first:" -ForegroundColor Yellow
    Write-Host "  Remove-Item -Recurse -Force '$destDir'" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Create third_party dir if needed
$thirdParty = Join-Path $root "third_party"
if (-not (Test-Path $thirdParty)) {
    New-Item -ItemType Directory -Path $thirdParty | Out-Null
}

# Download
Write-Host "[1/3] Downloading whisper.cpp $Version ..." -ForegroundColor Cyan
Write-Host "      $url" -ForegroundColor Gray
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Write-Host "[OK] Downloaded." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try manually downloading from:" -ForegroundColor Yellow
    Write-Host "  $url" -ForegroundColor Gray
    Write-Host "Then extract and place it at: third_party\whisper.cpp\" -ForegroundColor Gray
    exit 1
}

# Extract
Write-Host "[2/3] Extracting zip..." -ForegroundColor Cyan
if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
New-Item -ItemType Directory -Path $extractDir | Out-Null
Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

# The zip contains a folder like "whisper.cpp-1.8.4"
$innerFolder = Get-ChildItem $extractDir -Directory | Select-Object -First 1
if (-not $innerFolder) {
    Write-Host "[FAIL] Unexpected zip structure." -ForegroundColor Red
    exit 1
}

Write-Host "[3/3] Installing to $destDir ..." -ForegroundColor Cyan
Move-Item -Path $innerFolder.FullName -Destination $destDir -Force

# Cleanup temp files
Remove-Item -Force $zipFile -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue

# Verify
if (Test-Path (Join-Path $destDir "CMakeLists.txt")) {
    Write-Host ""
    Write-Host "[OK] whisper.cpp $Version ready at:" -ForegroundColor Green
    Write-Host "     $destDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next step: run 'flutter run -d <device>'" -ForegroundColor Cyan
    Write-Host "Gradle will compile the JNI .so files automatically." -ForegroundColor Cyan
} else {
    Write-Host "[FAIL] CMakeLists.txt not found after extraction." -ForegroundColor Red
    exit 1
}
