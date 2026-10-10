# CapStudio - Windows Binary Auto-Updater / Repair Script
# Double-click or run this script to automatically update/repair FFmpeg and Whisper CLI.

$ErrorActionPreference = "Stop"

# Setup Paths
$appData = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $env:USERPROFILE "AppData\Roaming" }
$binDir = Join-Path $appData "CapStudio\bin"
$tempDir = Join-Path $appData "CapStudio\temp_update"

Write-Host "==============================================" -ForegroundColor Orange
Write-Host "   CapStudio Binary Updater & Repair Utility" -ForegroundColor Cyan -Bold
Write-Host "==============================================" -ForegroundColor Orange
Write-Host "Target Directory: $binDir" -ForegroundColor Gray
Write-Host ""

# Create directories if they do not exist
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# -------------------------------------------------------------
# 1. Detect CPU Features (AVX2 Support)
# -------------------------------------------------------------
Write-Host "[1/5] Detecting CPU Capabilities..." -ForegroundColor Yellow
$hasAvx = $false
try {
    $cpuid = Add-Type -PassThru -Name CPUID -MemberDefinition @"
      [System.Runtime.InteropServices.DllImport("kernel32.dll")]
      public static extern bool IsProcessorFeaturePresent(int feature);
"@
    $hasAvx = $cpuid::IsProcessorFeaturePresent(40) # Feature 40 = PF_AVX2_INSTRUCTIONS_AVAILABLE
} catch {
    Write-Host "AVX2 detection failed, defaulting to safe generic fallback." -ForegroundColor Gray
}

if ($hasAvx) {
    Write-Host "  -> CPU supports AVX2. Using optimized x64 build." -ForegroundColor Green
    $whisperUrl = "https://github.com/ggml-org/whisper.cpp/releases/download/v1.8.4/whisper-bin-x64.zip"
    $expectedWhisperSha256 = "74f973345cb52ef5ba3ec9e7e7af8e48cc8c71722d1528603b80588a11f82e3e"
} else {
    Write-Host "  -> CPU does not support AVX2. Using custom generic (non-AVX2) build." -ForegroundColor Yellow
    $whisperUrl = "https://github.com/chyrenselin/Local-AI-Caption-Studio/releases/download/v0.0.1/whisper-cli-win-x64-noavx.zip"
    Write-Host "  Fetching remote SHA-256 checksum for generic build..." -ForegroundColor Gray
    try {
        $whisperSha256Url = "$whisperUrl.sha256"
        $expectedWhisperSha256 = (Invoke-WebRequest -Uri $whisperSha256Url -UseBasicParsing -UserAgent "Mozilla/5.0").Content.Trim().Split(" ")[0].ToLower()
    } catch {
        Write-Host "  WARNING: Failed to fetch remote SHA-256. Skipping checksum verification." -ForegroundColor Yellow
        $expectedWhisperSha256 = ""
    }
}

# -------------------------------------------------------------
# 2. Download and Configure FFmpeg
# -------------------------------------------------------------
Write-Host ""
Write-Host "[2/5] Downloading, Verifying, and Installing FFmpeg..." -ForegroundColor Yellow
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$ffmpegZip = "$tempDir\ffmpeg.zip"

Write-Host "  Downloading FFmpeg from Gyan.dev..." -ForegroundColor Gray
Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegZip -UserAgent "Mozilla/5.0"

Write-Host "  Fetching remote SHA-256 checksum from server..." -ForegroundColor Gray
$ffmpegSha256Url = "$ffmpegUrl.sha256"
$expectedFfmpegSha256 = (Invoke-WebRequest -Uri $ffmpegSha256Url -UseBasicParsing -UserAgent "Mozilla/5.0").Content.Trim().Split(" ")[0].ToLower()

Write-Host "  Verifying file integrity..." -ForegroundColor Gray
$actualFfmpegSha256 = (Get-FileHash -Path $ffmpegZip -Algorithm SHA256).Hash.ToLower()
if ($actualFfmpegSha256 -ne $expectedFfmpegSha256) {
    Write-Host "  [X] FFmpeg Integrity Verification Failed!" -ForegroundColor Red
    Write-Host "      Expected SHA-256: $expectedFfmpegSha256" -ForegroundColor Red
    Write-Host "      Actual computed:  $actualFfmpegSha256" -ForegroundColor Red
    throw "FFmpeg download is corrupted or has been tampered with."
}
Write-Host "  [✓] Integrity verification passed!" -ForegroundColor Green

Write-Host "  Extracting FFmpeg..." -ForegroundColor Gray
$ffmpegExtractPath = "$tempDir\ffmpeg_extracted"
Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegExtractPath -Force

Write-Host "  Locating and copying ffmpeg.exe..." -ForegroundColor Gray
$ffmpegExe = Get-ChildItem -Path $ffmpegExtractPath -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
if ($ffmpegExe) {
    Copy-Item -Path $ffmpegExe.FullName -Destination "$binDir\ffmpeg.exe" -Force
    Write-Host "  [✓] FFmpeg successfully installed!" -ForegroundColor Green
} else {
    throw "Could not locate ffmpeg.exe inside the downloaded archive."
}

# -------------------------------------------------------------
# 3. Download and Configure Whisper CLI
# -------------------------------------------------------------
Write-Host ""
Write-Host "[3/5] Downloading, Verifying, and Installing Whisper CLI..." -ForegroundColor Yellow
$whisperZip = "$tempDir\whisper.zip"

Write-Host "  Downloading Whisper CLI from GitHub..." -ForegroundColor Gray
Invoke-WebRequest -Uri $whisperUrl -OutFile $whisperZip -UserAgent "Mozilla/5.0"

Write-Host "  Verifying file integrity..." -ForegroundColor Gray
if ($expectedWhisperSha256) {
    $actualWhisperSha256 = (Get-FileHash -Path $whisperZip -Algorithm SHA256).Hash.ToLower()
    if ($actualWhisperSha256 -ne $expectedWhisperSha256) {
        Write-Host "  [X] Whisper Integrity Verification Failed!" -ForegroundColor Red
        Write-Host "      Expected SHA-256: $expectedWhisperSha256" -ForegroundColor Red
        Write-Host "      Actual computed:  $actualWhisperSha256" -ForegroundColor Red
        throw "Whisper download is corrupted or has been tampered with."
    }
    Write-Host "  [✓] Integrity verification passed!" -ForegroundColor Green
} else {
    Write-Host "  [✓] Skipping integrity verification (no checksum available)." -ForegroundColor Yellow
}

Write-Host "  Extracting Whisper CLI..." -ForegroundColor Gray
$whisperExtractPath = "$tempDir\whisper_extracted"
Expand-Archive -Path $whisperZip -DestinationPath $whisperExtractPath -Force

Write-Host "  Locating and copying executables and DLLs..." -ForegroundColor Gray
# Copy main executable (might be main.exe or whisper-cli.exe)
$whisperExe = Get-ChildItem -Path $whisperExtractPath -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "*main*" -or $_.Name -like "*whisper*" } | Select-Object -First 1
if ($whisperExe) {
    Copy-Item -Path $whisperExe.FullName -Destination "$binDir\whisper-cli.exe" -Force
    Write-Host "  Copied executable: $($whisperExe.Name) -> whisper-cli.exe" -ForegroundColor Gray
} else {
    throw "Could not locate Whisper executable inside the archive."
}

# Copy companion DLL files
Get-ChildItem -Path $whisperExtractPath -Filter "*.dll" -Recurse | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "$binDir\$($_.Name)" -Force
    Write-Host "  Copied companion DLL: $($_.Name)" -ForegroundColor Gray
}
Write-Host "  [✓] Whisper CLI successfully installed!" -ForegroundColor Green

# -------------------------------------------------------------
# 4. Clean Up Temporary Files
# -------------------------------------------------------------
Write-Host ""
Write-Host "[4/5] Cleaning up temporary files..." -ForegroundColor Yellow
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force | Out-Null
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "   Update Completed Successfully!" -ForegroundColor Green -Bold
Write-Host "   Both FFmpeg & Whisper are ready for use." -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey($true)
