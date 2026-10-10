# CapStudio - Compile Generic (Non-AVX2) Whisper CLI for Windows
# Used by developers/CI to build the fallback binary for release hosting.

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = $PSScriptRoot
$projectRoot = (Resolve-Path "$scriptDir\..\..\..").Path
$whisperRoot = Join-Path $projectRoot "third_party\whisper.cpp"
$buildDir = Join-Path $whisperRoot "build_win_generic"
$stageDir = Join-Path $projectRoot "build\whisper_desktop_stage"
$outputDir = Join-Path $projectRoot "build\whisper_desktop"

function Get-CMakePath {
    # 1. Check system path
    $cmd = Get-Command "cmake.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2. Check Visual Studio installations
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstall = & $vswhere -latest -property installationPath
        if ($vsInstall) {
            $vsCmake = Join-Path $vsInstall "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
            if (Test-Path $vsCmake) { return $vsCmake }
        }
    }

    # 3. Check Program Files fallback
    $paths = @(
        "${env:ProgramFiles}\CMake\bin\cmake.exe",
        "${env:ProgramFiles(x86)}\CMake\bin\cmake.exe"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

Write-Host "====================================================" -ForegroundColor Yellow
Write-Host "  CapStudio Non-AVX2 Whisper CLI Compiler" -ForegroundColor Cyan -Bold
Write-Host "====================================================" -ForegroundColor Yellow
Write-Host "Whisper Source: $whisperRoot" -ForegroundColor Gray
Write-Host "Output Directory: $outputDir" -ForegroundColor Gray
Write-Host ""

# Ensure submodule is present
if (-not (Test-Path "$whisperRoot\CMakeLists.txt")) {
    Write-Host "ERROR: whisper.cpp source folder is empty!" -ForegroundColor Red
    Write-Host "Please initialize git submodules first:" -ForegroundColor Red
    Write-Host "  git submodule update --init --recursive" -ForegroundColor Yellow
    exit 1
}

# Resolve CMake path
$cmake = Get-CMakePath
if (-not $cmake) {
    throw "CMake was not found on this system. Please install CMake or Visual Studio with C++ tools."
}
Write-Host "Using CMake: $cmake" -ForegroundColor Gray
Write-Host ""

# 1. Prepare Staging & Output Directories
if (Test-Path $stageDir) { Remove-Item -Path $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 2. Configure CMake
Write-Host "[1/5] Configuring CMake with AVX2 disabled..." -ForegroundColor Yellow
if (Test-Path $buildDir) { Remove-Item -Path $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# We disable AVX2, AVX1, FMA, F16C for maximum compatibility with older/Pentium/Celeron CPUs
& $cmake -S "$whisperRoot" -B "$buildDir" `
    -DCMAKE_BUILD_TYPE=Release `
    -DGGML_AVX2=OFF `
    -DGGML_AVX=OFF `
    -DGGML_FMA=OFF `
    -DGGML_F16C=OFF `
    -DBUILD_SHARED_LIBS=OFF `
    -DWHISPER_BUILD_TESTS=OFF `
    -DWHISPER_BUILD_EXAMPLES=ON | Out-Host

# 3. Compile Whisper CLI target
Write-Host ""
Write-Host "[2/5] Compiling whisper-cli static binary..." -ForegroundColor Yellow
& $cmake --build "$buildDir" --config Release --target whisper-cli | Out-Host

# 4. Locate Compiled Executable
Write-Host ""
Write-Host "[3/5] Locating compiled binary..." -ForegroundColor Yellow
$compiledExe = Get-ChildItem -Path $buildDir -Filter "whisper-cli.exe" -Recurse | Select-Object -First 1
if (-not $compiledExe) {
    throw "Could not locate compiled whisper-cli.exe in build folder."
}
Write-Host "Found compiled binary: $($compiledExe.FullName)" -ForegroundColor Green

# Copy to staging directory
Copy-Item -Path $compiledExe.FullName -Destination "$stageDir\whisper-cli.exe" -Force

# 5. Pack Attribution and License
Write-Host ""
Write-Host "[4/5] Packaging license and attributions..." -ForegroundColor Yellow
$origLicensePath = "$whisperRoot\LICENSE"
$stageLicensePath = "$stageDir\LICENSE.txt"

$attributionPreamble = @"
========================================================================
CapStudio Attribution & Credit Notice
This is a custom, non-AVX2 compatible compilation of whisper.cpp
built for compatibility with processors lacking AVX2 instruction sets.

Original Software: whisper.cpp (v1.8.4)
Original Authors: Georgi Gerganov & ggml-org contributors
Original Repository: https://github.com/ggml-org/whisper.cpp
========================================================================

"@

if (Test-Path $origLicensePath) {
    $licenseContent = Get-Content -Path $origLicensePath -Raw
    $fullLicense = $attributionPreamble + $licenseContent
    $fullLicense | Out-File -FilePath $stageLicensePath -Encoding utf8 -Force
    Write-Host "Created LICENSE.txt with attribution notes." -ForegroundColor Green
} else {
    Write-Host "WARNING: Original LICENSE file not found in whisper.cpp root!" -ForegroundColor Yellow
    $attributionPreamble | Out-File -FilePath $stageLicensePath -Encoding utf8 -Force
}

# 6. Create Zip Archive and Checksum
Write-Host ""
Write-Host "[5/5] Creating release zip and SHA-256 checksum..." -ForegroundColor Yellow
$zipFile = "$outputDir\whisper-cli-win-x64-noavx.zip"
$shaFile = "$zipFile.sha256"

if (Test-Path $zipFile) { Remove-Item -Path $zipFile -Force }
if (Test-Path $shaFile) { Remove-Item -Path $shaFile -Force }

# Compress staging directory
Compress-Archive -Path "$stageDir\*" -DestinationPath $zipFile -Force
Write-Host "Successfully packaged: $zipFile" -ForegroundColor Green

# Compute SHA-256
$computedHash = (Get-FileHash -Path $zipFile -Algorithm SHA256).Hash.ToLower()
# Save format: "hash filename" (standard sha256sum format)
"$computedHash  whisper-cli-win-x64-noavx.zip" | Out-File -FilePath $shaFile -Encoding ascii -Force
Write-Host "Computed SHA-256: $computedHash" -ForegroundColor Green
Write-Host "Saved SHA-256 to: $shaFile" -ForegroundColor Green

# Clean up build stage
Remove-Item -Path $stageDir -Recurse -Force | Out-Null

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  Compilation and Packaging Completed Successfully!" -ForegroundColor Green -Bold
Write-Host "====================================================" -ForegroundColor Green
