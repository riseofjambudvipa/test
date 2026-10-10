# CapStudio - Compile and Install Local Whisper CLI for Windows
# Double-click or run this script to compile whisper-cli from source and install it locally.

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptDir\..\..\.."
$whisperRoot = Resolve-Path "$projectRoot\third_party\whisper.cpp"
$buildDir = Join-Path $whisperRoot "build_win_local"
$appData = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $env:USERPROFILE "AppData\Roaming" }
$binDir = Join-Path $appData "CapStudio\bin"

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
Write-Host "  CapStudio Local Whisper CLI Compiler (Windows)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Yellow
Write-Host "Whisper Source: $whisperRoot" -ForegroundColor Gray
Write-Host "Target Folder:  $binDir" -ForegroundColor Gray
Write-Host ""

# 1. Verify Submodule Source
if (-not (Test-Path "$whisperRoot\CMakeLists.txt")) {
    Write-Host "Whisper.cpp submodule source is missing. Initializing submodule..." -ForegroundColor Yellow
    cd $projectRoot
    git submodule update --init --recursive
    if (-not (Test-Path "$whisperRoot\CMakeLists.txt")) {
        throw "Failed to initialize whisper.cpp submodule. Please run: git submodule update --init --recursive"
    }
}

# 2. Resolve CMake Path
$cmake = Get-CMakePath
if (-not $cmake) {
    throw "CMake was not found on this system. Please install Visual Studio with C++ Desktop Development tools."
}
Write-Host "Using CMake: $cmake" -ForegroundColor Gray

# 3. Detect CPU capabilities to choose build flags
Write-Host ""
Write-Host "[1/4] Detecting CPU features..." -ForegroundColor Yellow
$hasAvx2 = $false
try {
    $typeLoaded = [System.Management.Automation.PSTypeName]"CPUIDLocal"
    if ($typeLoaded.Type -ne $null) {
        $hasAvx2 = [CPUIDLocal]::IsProcessorFeaturePresent(40)
    } else {
        $cpuid = Add-Type -PassThru -Name CPUIDLocal -MemberDefinition '[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(int feature);'
        $hasAvx2 = $cpuid::IsProcessorFeaturePresent(40)
    }
} catch {
    Write-Host "AVX2 detection failed. Defaulting to safe generic build." -ForegroundColor Gray
}

if ($hasAvx2) {
    Write-Host "  -> AVX2 support detected. Compiling optimized build." -ForegroundColor Green
    $cmakeFlags = @(
        "-DCMAKE_BUILD_TYPE=Release",
        "-DGGML_AVX2=ON",
        "-DGGML_AVX=ON",
        "-DGGML_FMA=ON",
        "-DGGML_F16C=ON",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DWHISPER_BUILD_TESTS=OFF",
        "-DWHISPER_BUILD_EXAMPLES=ON"
    )
} else {
    Write-Host "  -> No AVX2 support. Compiling generic fallback build." -ForegroundColor Yellow
    $cmakeFlags = @(
        "-DCMAKE_BUILD_TYPE=Release",
        "-DGGML_AVX2=OFF",
        "-DGGML_AVX=OFF",
        "-DGGML_FMA=OFF",
        "-DGGML_F16C=OFF",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DWHISPER_BUILD_TESTS=OFF",
        "-DWHISPER_BUILD_EXAMPLES=ON"
    )
}

# 4. Configure CMake
Write-Host ""
Write-Host "[2/4] Configuring CMake project..." -ForegroundColor Yellow
if (Test-Path $buildDir) { Remove-Item -Path $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

& $cmake -S "$whisperRoot" -B "$buildDir" $cmakeFlags | Out-Host

# 5. Compile Target
Write-Host ""
Write-Host "[3/4] Compiling whisper-cli static binary..." -ForegroundColor Yellow
& $cmake --build "$buildDir" --config Release --target whisper-cli | Out-Host

# 6. Locate and Install Binary
Write-Host ""
Write-Host "[4/4] Installing compiled binary..." -ForegroundColor Yellow
$compiledExe = Get-ChildItem -Path $buildDir -Filter "whisper-cli.exe" -Recurse | Select-Object -First 1
if (-not $compiledExe) {
    throw "Compilation succeeded, but could not locate compiled whisper-cli.exe."
}

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

$destPath = "$binDir\whisper-cli.exe"
Copy-Item -Path $compiledExe.FullName -Destination $destPath -Force
Write-Host "Successfully installed locally: $destPath" -ForegroundColor Green

# Cleanup build directory
Remove-Item -Path $buildDir -Recurse -Force | Out-Null

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  Whisper CLI Compiled & Installed Successfully!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey($true)
