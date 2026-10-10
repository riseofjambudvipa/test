<#
.SYNOPSIS
    Compiles and packages both AVX2 and No-AVX whisper-cli binaries for Windows distribution.
.DESCRIPTION
    Builds whisper-cli from the third_party/whisper.cpp submodule (or fetches from upstream),
    bundles the executables with LICENSE.txt, creates release .zip archives, and computes
    SHA-256 verification hashes ready for GitHub Releases.
#>

[CmdletBinding()]
param(
    [string]$WhisperSource = "$PSScriptRoot\..\..\whisper.cpp",
    [string]$OutputDir = "$PSScriptRoot\..\..\..\dist"
)

$ErrorActionPreference = "Stop"

function Get-CMakeCommand {
    $cmd = Get-Command "cmake.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstall = & $vswhere -latest -property installationPath
        if ($vsInstall) {
            $vsCmake = Join-Path $vsInstall "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
            if (Test-Path $vsCmake) { return $vsCmake }
        }
    }
    return $null
}

$cmake = Get-CMakeCommand
if (-not $cmake) {
    Write-Error "CMake was not found. Please install CMake or Visual Studio C++ tools."
    exit 1
}

$whisperSourcePath = Resolve-Path $WhisperSource -ErrorAction SilentlyContinue
if (-not $whisperSourcePath -or -not (Test-Path "$whisperSourcePath\CMakeLists.txt")) {
    Write-Host "Submodule whisper.cpp missing. Initializing git submodules..." -ForegroundColor Yellow
    git submodule update --init --recursive
    $whisperSourcePath = Resolve-Path $WhisperSource -ErrorAction SilentlyContinue
    if (-not $whisperSourcePath -or -not (Test-Path "$whisperSourcePath\CMakeLists.txt")) {
        Write-Error "Could not locate whisper.cpp source at $WhisperSource"
        exit 1
    }
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$resolvedOut = (Resolve-Path $OutputDir).Path

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CapStudio Whisper Multi-Target Windows Packager" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Source: $whisperSourcePath" -ForegroundColor Gray
Write-Host "Output: $resolvedOut" -ForegroundColor Gray
Write-Host ""

# 1. Build Optimized AVX2 Target
Write-Host "[1/2] Building Windows x64 (AVX2 / Modern CPUs)..." -ForegroundColor Yellow
$buildDirAvx = Join-Path $resolvedOut "build_avx"
if (Test-Path $buildDirAvx) { Remove-Item -Path $buildDirAvx -Recurse -Force }

& $cmake -S "$whisperSourcePath" -B "$buildDirAvx" `
    -DCMAKE_BUILD_TYPE=Release `
    -DGGML_AVX2=ON `
    -DGGML_AVX=ON `
    -DGGML_FMA=ON `
    -DGGML_F16C=ON `
    -DBUILD_SHARED_LIBS=OFF `
    -DWHISPER_BUILD_TESTS=OFF `
    -DWHISPER_BUILD_EXAMPLES=ON

& $cmake --build "$buildDirAvx" --config Release --target whisper-cli

$exeAvx = Get-ChildItem -Path $buildDirAvx -Filter "whisper-cli.exe" -Recurse | Select-Object -First 1
if (-not $exeAvx) {
    Write-Error "AVX build succeeded, but whisper-cli.exe was not found."
    exit 1
}

$stageAvx = Join-Path $resolvedOut "stage_win_avx"
if (Test-Path $stageAvx) { Remove-Item -Path $stageAvx -Recurse -Force }
New-Item -ItemType Directory -Path $stageAvx -Force | Out-Null

Copy-Item -Path $exeAvx.FullName -Destination (Join-Path $stageAvx "whisper-cli.exe")
if (Test-Path "$whisperSourcePath\LICENSE") {
    Copy-Item -Path "$whisperSourcePath\LICENSE" -Destination (Join-Path $stageAvx "LICENSE.txt")
}

$zipAvx = Join-Path $resolvedOut "whisper-cli-win-x64-avx.zip"
if (Test-Path $zipAvx) { Remove-Item -Path $zipAvx -Force }
Compress-Archive -Path "$stageAvx\*" -DestinationPath $zipAvx -Force

$hashAvx = (Get-FileHash -Path $zipAvx -Algorithm SHA256).Hash.ToLower()
Set-Content -Path "$zipAvx.sha256" -Value "$hashAvx  whisper-cli-win-x64-avx.zip"
Write-Host "  -> Created: $zipAvx" -ForegroundColor Green
Write-Host "  -> SHA-256: $hashAvx" -ForegroundColor Gray
Write-Host ""

# 2. Build Generic No-AVX Target
Write-Host "[2/2] Building Windows x64 Generic (No-AVX / Older PCs)..." -ForegroundColor Yellow
$buildDirNoAvx = Join-Path $resolvedOut "build_noavx"
if (Test-Path $buildDirNoAvx) { Remove-Item -Path $buildDirNoAvx -Recurse -Force }

& $cmake -S "$whisperSourcePath" -B "$buildDirNoAvx" `
    -DCMAKE_BUILD_TYPE=Release `
    -DGGML_AVX2=OFF `
    -DGGML_AVX=OFF `
    -DGGML_FMA=OFF `
    -DGGML_F16C=OFF `
    -DBUILD_SHARED_LIBS=OFF `
    -DWHISPER_BUILD_TESTS=OFF `
    -DWHISPER_BUILD_EXAMPLES=ON

& $cmake --build "$buildDirNoAvx" --config Release --target whisper-cli

$exeNoAvx = Get-ChildItem -Path $buildDirNoAvx -Filter "whisper-cli.exe" -Recurse | Select-Object -First 1
if (-not $exeNoAvx) {
    Write-Error "No-AVX build succeeded, but whisper-cli.exe was not found."
    exit 1
}

$stageNoAvx = Join-Path $resolvedOut "stage_win_noavx"
if (Test-Path $stageNoAvx) { Remove-Item -Path $stageNoAvx -Recurse -Force }
New-Item -ItemType Directory -Path $stageNoAvx -Force | Out-Null

Copy-Item -Path $exeNoAvx.FullName -Destination (Join-Path $stageNoAvx "whisper-cli.exe")
if (Test-Path "$whisperSourcePath\LICENSE") {
    Copy-Item -Path "$whisperSourcePath\LICENSE" -Destination (Join-Path $stageNoAvx "LICENSE.txt")
}

$zipNoAvx = Join-Path $resolvedOut "whisper-cli-win-x64-noavx.zip"
if (Test-Path $zipNoAvx) { Remove-Item -Path $zipNoAvx -Force }
Compress-Archive -Path "$stageNoAvx\*" -DestinationPath $zipNoAvx -Force

$hashNoAvx = (Get-FileHash -Path $zipNoAvx -Algorithm SHA256).Hash.ToLower()
Set-Content -Path "$zipNoAvx.sha256" -Value "$hashNoAvx  whisper-cli-win-x64-noavx.zip"
Write-Host "  -> Created: $zipNoAvx" -ForegroundColor Green
Write-Host "  -> SHA-256: $hashNoAvx" -ForegroundColor Gray
Write-Host ""

# Clean staging directories
Remove-Item -Path $stageAvx, $stageNoAvx -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Packaging Complete! Upload these files to GitHub Releases:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Get-ChildItem -Path $resolvedOut -Filter "whisper-cli-win-x64-*" | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor White
}
