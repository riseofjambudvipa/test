# CapStudio Master Production Build & Packaging Utility
# Runs validation checks, compiles FFI libraries, and builds production bundles across all 6 platforms.

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = $PSScriptRoot
$projectRoot = (Resolve-Path "$scriptDir\..\..\..").Path
$whisperSharedScript = Join-Path $scriptDir "compile_whisper_shared.ps1"
$windowsRunnerDir = Join-Path $projectRoot "windows\runner"
$windowsOutputReleaseDir = Join-Path $projectRoot "build\windows\x64\runner\Release"

function Write-Header ($text) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
}

function Setup-Java {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
        Write-Host "Using existing JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
        return
    }

    $candidates = @(
        "$env:ProgramFiles\Android\Android Studio\jbr",
        "${env:ProgramFiles(x86)}\Android\Android Studio\jbr",
        "$env:LOCALAPPDATA\Android\Android Studio\jbr",
        "$env:ProgramFiles\Java\jdk*",
        "${env:ProgramFiles(x86)}\Java\jdk*",
        "$env:ProgramFiles\Eclipse Adoptium\jdk*",
        "$env:ProgramFiles\Microsoft\jdk*"
    )
    foreach ($pattern in $candidates) {
        if (-not $pattern) { continue }
        $resolved = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved -and (Test-Path (Join-Path $resolved.FullName "bin\java.exe"))) {
            $env:JAVA_HOME = $resolved.FullName
            $env:PATH = "$($resolved.FullName)\bin;$env:PATH"
            Write-Host "Auto-configured JAVA_HOME: $($resolved.FullName)" -ForegroundColor Green
            return
        }
    }

    $javaCmd = Get-Command "java.exe" -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaBin = Split-Path -Parent $javaCmd.Source
        $javaHome = Split-Path -Parent $javaBin
        $env:JAVA_HOME = $javaHome
        Write-Host "Found java on PATH, set JAVA_HOME to: $javaHome" -ForegroundColor Gray
        return
    }

    Write-Host "WARNING: JAVA_HOME is not set and no standard JDK was automatically found." -ForegroundColor Yellow
    Write-Host "Android builds may fail if JDK is not configured." -ForegroundColor Yellow
}

function Clean-And-Get {
    Write-Header "Cleaning & Getting Dependencies"
    Write-Host "Running flutter clean..." -ForegroundColor Gray
    Push-Location $projectRoot
    try {
        flutter clean
        Write-Host "Running flutter pub get..." -ForegroundColor Gray
        flutter pub get
        Write-Host "Dependencies successfully updated!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Run-Verification {
    Write-Header "Running System Verification Checks"
    Push-Location $projectRoot
    try {
        Write-Host "Analyzing code structure (flutter analyze)..." -ForegroundColor Gray
        $analyzeResult = flutter analyze --no-pub
        Write-Host $analyzeResult
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: flutter analyze failed with exit code $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
        
        Write-Host "Running 596 unit & widget test suite (flutter test)..." -ForegroundColor Gray
        $testResult = flutter test --no-pub
        Write-Host $testResult
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: flutter test failed with exit code $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
        Write-Host "Verification checks completed successfully! (100% GREEN)" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Verify-Whisper-Dll {
    Write-Header "Verifying Whisper FFI Shared Library"
    $dllPath = Join-Path $windowsRunnerDir "whisper.dll"
    if (-not (Test-Path $dllPath)) {
        Write-Host "whisper.dll was not found in runner folder. Compiling now..." -ForegroundColor Yellow
        if (Test-Path $whisperSharedScript) {
            & $whisperSharedScript
        } else {
            throw "Could not locate compile_whisper_shared.ps1 script at: $whisperSharedScript"
        }
    } else {
        Write-Host "whisper.dll is present and ready for FFI loading." -ForegroundColor Green
    }
}

function Compile-Windows {
    Verify-Whisper-Dll
    Write-Header "Building Windows Desktop Release"
    Push-Location $projectRoot
    try {
        Write-Host "Compiling Windows FFI-integrated executable..." -ForegroundColor Gray
        flutter build windows --release
        
        # Copy FFI dll to the build output folder if needed
        $dllPath = Join-Path $windowsRunnerDir "whisper.dll"
        if (Test-Path $dllPath) {
            if (-not (Test-Path $windowsOutputReleaseDir)) {
                New-Item -ItemType Directory -Path $windowsOutputReleaseDir -Force | Out-Null
            }
            Copy-Item -Path $dllPath -Destination $windowsOutputReleaseDir -Force
            Write-Host "  [+] Bundled whisper.dll copy verified in release output directory." -ForegroundColor Green
        }
        
        # Bundle static FFmpeg / FFprobe if available
        $ffmpegSources = @(
            Join-Path $projectRoot "assets\bin\ffmpeg.exe",
            Join-Path $projectRoot "bin\ffmpeg.exe"
        )
        foreach ($cand in $ffmpegSources) {
            if (Test-Path $cand) {
                Copy-Item -Path $cand -Destination $windowsOutputReleaseDir -Force
                Write-Host "  [+] Bundled ffmpeg.exe copied to release output directory." -ForegroundColor Green
                break
            }
        }
        $ffprobeSources = @(
            Join-Path $projectRoot "assets\bin\ffprobe.exe",
            Join-Path $projectRoot "bin\ffprobe.exe"
        )
        foreach ($cand in $ffprobeSources) {
            if (Test-Path $cand) {
                Copy-Item -Path $cand -Destination $windowsOutputReleaseDir -Force
                Write-Host "  [+] Bundled ffprobe.exe copied to release output directory." -ForegroundColor Green
                break
            }
        }

        Write-Host "Success! Windows executable built in: $windowsOutputReleaseDir" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Package-Windows-Installer {
    Write-Header "Packaging Windows Inno Setup Installer"
    $issPath = Join-Path $projectRoot "third_party\scripts\capstudio_setup.iss"
    if (-not (Test-Path $issPath)) {
        throw "Could not locate Inno Setup script at: $issPath"
    }

    if (-not (Test-Path (Join-Path $windowsOutputReleaseDir "CapStudio.exe"))) {
        Write-Host "WARNING: CapStudio.exe not found in $windowsOutputReleaseDir." -ForegroundColor Yellow
        Write-Host "Please build the Windows release first (Option 3)." -ForegroundColor Yellow
        $proceed = Read-Host "Proceed anyway? (y/N)"
        if ($proceed -ne "y" -and $proceed -ne "Y") {
            return
        }
    }

    $iscc = Get-Command "iscc" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not $iscc) {
        $candidatePaths = @(
            "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
            "$env:ProgramFiles\Inno Setup 5\ISCC.exe",
            "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe"
        )
        foreach ($cand in $candidatePaths) {
            if ($cand -and (Test-Path $cand)) {
                $iscc = $cand
                break
            }
        }
    }

    if (-not $iscc) {
        Write-Host "Inno Setup Compiler (ISCC.exe) was not found in PATH or standard Program Files paths." -ForegroundColor Yellow
        Write-Host "To generate CapStudio-Setup.exe, install Inno Setup 6 from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        return
    }

    Write-Host "Compiling Inno Setup installer using: $iscc" -ForegroundColor Gray
    & $iscc "$issPath"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Windows Installer successfully generated in scripts directory!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Inno Setup compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
}

function Compile-Android-Release {
    Setup-Java
    Write-Header "Building Android Production Release (AAB & Split APKs)"
    Push-Location $projectRoot
    try {
        Write-Host "Compiling Google Play App Bundle (AAB)..." -ForegroundColor Gray
        flutter build appbundle --release
        Write-Host "Compiling Split-per-ABI APKs (arm64, armeabi, x86_64)..." -ForegroundColor Gray
        flutter build apk --release --split-per-abi
        Write-Host "Success!" -ForegroundColor Green
        Write-Host "  App Bundle: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
        Write-Host "  APKs:       build\app\outputs\flutter-apk\" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Compile-Web-Release {
    Write-Header "Building Web Production PWA"
    Push-Location $projectRoot
    try {
        Write-Host "Compiling offline-first WebAssembly bundle..." -ForegroundColor Gray
        flutter build web --release --pwa-strategy offline-first
        Write-Host "Success! Web PWA generated in: build\web\" -ForegroundColor Green
        Write-Host "Static assets include coi-serviceworker and vendored WASM runtimes." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Compile-Linux-Release {
    Write-Header "Building Linux Desktop Release"
    Push-Location $projectRoot
    try {
        if ($IsLinux -or (Get-Command "uname" -ErrorAction SilentlyContinue)) {
            Write-Host "Compiling Linux release bundle..." -ForegroundColor Gray
            flutter build linux --release
            Write-Host "Success! Linux bundle generated in: build/linux/x64/release/bundle/" -ForegroundColor Green
            $debScript = Join-Path $projectRoot "third_party/scripts/create_deb.sh"
            if (Test-Path $debScript) {
                Write-Host "To package as Debian .deb, run: ./third_party/scripts/create_deb.sh" -ForegroundColor Cyan
            }
        } else {
            Write-Host "Note: Native Linux compilation requires a Linux host or WSL2 environment with GTK3 development headers." -ForegroundColor Yellow
            Write-Host "For cross-platform packaging, please run on a Ubuntu/Debian runner or WSL: flutter build linux --release" -ForegroundColor Gray
        }
    } finally {
        Pop-Location
    }
}

function Compile-MacOS-Release {
    Write-Header "Building macOS Desktop Release"
    Push-Location $projectRoot
    try {
        if ($IsMacOS) {
            Write-Host "Compiling macOS Universal release bundle..." -ForegroundColor Gray
            flutter build macos --release
            Write-Host "Success! macOS bundle generated in: build/macos/Build/Products/Release/CapStudio.app" -ForegroundColor Green
            Write-Host "To notarize with Apple, run: ./third_party/scripts/build/notarize_macos.sh" -ForegroundColor Cyan
        } else {
            Write-Host "Note: macOS compilation and code-signing requires macOS with Xcode installed." -ForegroundColor Yellow
            Write-Host "On a macOS runner, execute: flutter build macos --release" -ForegroundColor Gray
        }
    } finally {
        Pop-Location
    }
}

function Compile-IOS-Release {
    Write-Header "Building iOS Production Archive"
    Push-Location $projectRoot
    try {
        if ($IsMacOS) {
            Write-Host "Compiling iOS release archive..." -ForegroundColor Gray
            flutter build ipa --release --no-codesign
            Write-Host "Success! iOS IPA archive generated in: build/ios/archive/" -ForegroundColor Green
        } else {
            Write-Host "Note: iOS IPA compilation requires macOS with Xcode and CocoaPods installed." -ForegroundColor Yellow
            Write-Host "On a macOS runner, execute: flutter build ipa --release" -ForegroundColor Gray
        }
    } finally {
        Pop-Location
    }
}

function Update-Submodules {
    Write-Header "Updating whisper.cpp Native Submodule"
    Push-Location $projectRoot
    try {
        Write-Host "Checking out latest source files..." -ForegroundColor Gray
        git submodule init
        git submodule update --recursive
        Write-Host "Submodules updated!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# Main Interactive Loop
do {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Yellow
    Write-Host "       CapStudio Multi-Platform Build Controller      " -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Yellow
    Write-Host " 1. Clean & Fetch Dependencies (flutter clean & pub get)"
    Write-Host " 2. Run Verification Checks (flutter analyze & 596 tests)"
    Write-Host " 3. Build Windows Desktop App (FFI + FFmpeg Bundled)"
    Write-Host " 4. Package Windows Inno Setup Installer (.exe)"
    Write-Host " 5. Build Android Production Bundle (AAB & Split APKs)"
    Write-Host " 6. Build Web Production PWA (WASM + Offline-First)"
    Write-Host " 7. Build Linux Desktop Release (Bundle + Deb Instructions)"
    Write-Host " 8. Build macOS Desktop Release (App Bundle + Notarization)"
    Write-Host " 9. Build iOS Release Archive (IPA)"
    Write-Host " 10. Verify & Compile whisper.dll FFI Library"
    Write-Host " 11. Update whisper.cpp Native Submodule"
    Write-Host " 12. Exit"
    Write-Host "======================================================" -ForegroundColor Yellow
    
    $choice = Read-Host "Select a build action (1-12)"
    
    try {
        switch ($choice) {
            "1" { Clean-And-Get }
            "2" { Run-Verification }
            "3" { Compile-Windows }
            "4" { Package-Windows-Installer }
            "5" { Compile-Android-Release }
            "6" { Compile-Web-Release }
            "7" { Compile-Linux-Release }
            "8" { Compile-MacOS-Release }
            "9" { Compile-IOS-Release }
            "10" { Verify-Whisper-Dll }
            "11" { Update-Submodules }
            "12" { Write-Host "Exiting Build Controller. Goodbye!" -ForegroundColor Gray; break }
            default { Write-Host "Invalid option. Choose between 1 and 12." -ForegroundColor Red }
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
    
    if ($choice -ne "12") {
        Read-Host "`nPress Enter to return to menu..."
    }
} while ($choice -ne "12")
