# CapStudio - Compile whisper.cpp as a Shared Library (.dll) for FFI
# Run this script to compile whisper.cpp as a shared dynamic library and copy it into the Windows runner folder.

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptDir\..\..\.."
$whisperRoot = Resolve-Path "$projectRoot\third_party\whisper.cpp"
$buildDir = "$whisperRoot\build_shared_local"
$outputLibDir = "$projectRoot\windows\runner" # Copy directly to the Runner directory so Flutter bundles it

function Get-CMakePath {
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

    $paths = @(
        "${env:ProgramFiles}\CMake\bin\cmake.exe",
        "${env:ProgramFiles(x86)}\CMake\bin\cmake.exe"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  CapStudio Shared Whisper.cpp Library Compiler (.DLL)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "Source Path: $whisperRoot" -ForegroundColor Gray
Write-Host "Output Path: $outputLibDir" -ForegroundColor Gray
Write-Host ""

# 1. Verify Submodule Source
if (-not (Test-Path "$whisperRoot\CMakeLists.txt")) {
    Write-Host "whisper.cpp submodule source is missing. Initializing..." -ForegroundColor Yellow
    cd $projectRoot
    git submodule update --init --recursive
    if (-not (Test-Path "$whisperRoot\CMakeLists.txt")) {
        throw "Failed to initialize whisper.cpp submodule. Run: git submodule update --init --recursive"
    }
}

# 2. Resolve CMake Path
$cmake = Get-CMakePath
if (-not $cmake) {
    throw "CMake was not found on this system. Please install Visual Studio with C++ Desktop Development tools."
}

# 3. Detect CPU capabilities for AVX2 support
$hasAvx2 = $false
try {
    $typeLoaded = [System.Management.Automation.PSTypeName]"CPUIDLocalShared"
    if ($typeLoaded.Type -ne $null) {
        $hasAvx2 = [CPUIDLocalShared]::IsProcessorFeaturePresent(40)
    } else {
        $cpuid = Add-Type -PassThru -Name CPUIDLocalShared -MemberDefinition '[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(int feature);'
        $hasAvx2 = $cpuid::IsProcessorFeaturePresent(40)
    }
} catch {
    Write-Host "AVX2 detection failed. Defaulting to safe generic build." -ForegroundColor Gray
}

# Configure CMake flags for Shared Library Build
$cmakeFlags = @(
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=ON",
    "-DWHISPER_BUILD_TESTS=OFF",
    "-DWHISPER_BUILD_EXAMPLES=OFF"
)

if ($hasAvx2) {
    Write-Host "  -> AVX2 support detected. Compiling optimized AVX2 build." -ForegroundColor Green
    $cmakeFlags += @(
        "-DGGML_AVX2=ON",
        "-DGGML_AVX=ON",
        "-DGGML_FMA=ON",
        "-DGGML_F16C=ON"
    )
} else {
    Write-Host "  -> No AVX2 support. Compiling generic fallback build." -ForegroundColor Yellow
    $cmakeFlags += @(
        "-DGGML_AVX2=OFF",
        "-DGGML_AVX=OFF",
        "-DGGML_FMA=OFF",
        "-DGGML_F16C=OFF"
    )
}

# 4. Create and enter build folder
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force | Out-Null
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
cd $buildDir

# 5. Configure Build
Write-Host ""
Write-Host "[1/3] Configuring CMake project..." -ForegroundColor Yellow
& $cmake $whisperRoot $cmakeFlags

# 6. Compile Shared Library
Write-Host ""
Write-Host "[2/3] Compiling Shared Library (Release Mode)..." -ForegroundColor Yellow
& $cmake --build . --config Release --target whisper

# 7. Copy whisper.dll to Flutter Runner Directory
Write-Host ""
Write-Host "[3/3] Copying whisper.dll to Flutter Runner Directory..." -ForegroundColor Yellow
$dllFile = Get-ChildItem -Path $buildDir -Filter "whisper.dll" -Recurse | Select-Object -First 1

if ($dllFile) {
    if (-not (Test-Path $outputLibDir)) {
        New-Item -ItemType Directory -Path $outputLibDir -Force | Out-Null
    }
    Copy-Item -Path $dllFile.FullName -Destination "$outputLibDir\whisper.dll" -Force
    Write-Host "  [+] whisper.dll successfully compiled and copied to: $outputLibDir\whisper.dll" -ForegroundColor Green
} else {
    throw "Failed to locate compiled whisper.dll file."
}

Write-Host ""
Write-Host "Finished successfully!" -ForegroundColor Green
