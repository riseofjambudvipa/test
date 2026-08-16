# CapStudio - Windows Mobile Dependency Auto-Updater for Developers
# Updates FFmpeg and whisper.cpp for Android without manual compilation knowledge.

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   CapStudio Mobile Dependency Auto-Updater (Win)" -ForegroundColor Green -Bold
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "This script simplifies upgrading FFmpeg and Whisper for iOS & Android on Windows."
Write-Host ""

# -------------------------------------------------------------
# 1. Update FFmpeg Kit Version in pubspec.yaml
# -------------------------------------------------------------
Write-Host "[1/3] Checking FFmpeg Kit Package Version..." -ForegroundColor Yellow
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath

$currentVersionLine = $pubspecContent | Select-String "ffmpeg_kit_flutter_new:"
$currentVersion = $currentVersionLine.ToString().Split(":")[1].Trim()
Write-Host "Current FFmpeg Kit Package version: $currentVersion" -ForegroundColor Green

$updateFfmpeg = Read-Host "Do you want to update FFmpeg Kit Package? (y/N)"
if ($updateFfmpeg -eq "y" -or $updateFfmpeg -eq "Y") {
    $newVersion = Read-Host "Enter new version (e.g. ^4.2.2 or ^5.0.0)"
    if ($newVersion) {
        $newContent = $pubspecContent -replace "ffmpeg_kit_flutter_new:.*", "ffmpeg_kit_flutter_new: $newVersion"
        Set-Content $pubspecPath $newContent
        Write-Host "[✓] pubspec.yaml updated with FFmpeg Kit version $newVersion" -ForegroundColor Green
    }
} else {
    Write-Host "Skipped FFmpeg Kit update." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 2. Update whisper.cpp Submodule Version
# -------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Updating whisper.cpp Submodule..." -ForegroundColor Yellow

Push-Location "third_party\whisper.cpp"
try {
    Write-Host "Fetching latest tags from GitHub..." -ForegroundColor Gray
    git fetch --tags --all
    
    Write-Host "Recent Whisper releases:" -ForegroundColor Gray
    git tag -l | Select-Object -Last 10
    
    $whisperTag = Read-Host "Enter target whisper.cpp release tag (e.g., v1.8.4 or v1.9.0)"
    if ($whisperTag) {
        Write-Host "Checking out $whisperTag..." -ForegroundColor Gray
        git checkout "$whisperTag"
        git submodule update --init --recursive
        Write-Host "[✓] Submodule whisper.cpp successfully updated to $whisperTag" -ForegroundColor Green
    } else {
        Write-Host "Invalid tag entered. Keeping current version." -ForegroundColor Red
    }
} finally {
    Pop-Location
}

# -------------------------------------------------------------
# 3. Compile Native Libraries for iOS / Android
# -------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Compiling Native Wrappers..." -ForegroundColor Yellow

# A. Android Compilation: No work required!
Write-Host "Android:" -ForegroundColor Cyan
Write-Host "  -> Android uses dynamic CMake compilation via Gradle."
Write-Host "  -> No manual compilation steps needed! Gradle will automatically build" -ForegroundColor Green
Write-Host "     the updated whisper.cpp files when you run 'flutter run' or 'flutter build'." -ForegroundColor Green

# B. iOS Compilation: Compile xcframework (requires Mac)
Write-Host ""
Write-Host "iOS:" -ForegroundColor Cyan
Write-Host "  -> iOS frameworks require compilation on a macOS machine with Xcode."
Write-Host "  -> If building for iOS, run this project on a Mac and run 'update_mobile_dependencies.sh'." -ForegroundColor Yellow

# -------------------------------------------------------------
# 4. Fetch dependencies
# -------------------------------------------------------------
Write-Host ""
Write-Host "Fetching Flutter Dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   Mobile Dependencies Update Complete!" -ForegroundColor Green -Bold
Write-Host "==================================================" -ForegroundColor Green
Write-Host "You can now run 'flutter run -d android' to test."
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey($true)
