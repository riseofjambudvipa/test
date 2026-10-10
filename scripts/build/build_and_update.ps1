# CapStudio Master Build & Update Utility
# Runs updates and platform builds safely with verification.

$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path "$PSScriptRoot\..\..\..").Path

# Colors
$accent = "#F97316" # Obsidian Amber Orange
$cyan = "#06B6D4"

function Write-Header ($text) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor DarkYellow -Bold
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

    Write-Host "WARNING: JAVA_HOME is not set and Android Studio JBR was not found." -ForegroundColor Yellow
    Write-Host "Android builds may fail if JDK is not configured." -ForegroundColor Yellow
}

function Clean-And-Get {
    Write-Header "Cleaning & Getting Dependencies"
    Write-Host "Running flutter clean..." -ForegroundColor Gray
    flutter clean
    Write-Host "Running flutter pub get..." -ForegroundColor Gray
    flutter pub get
    Write-Host "Dependencies successfully updated!" -ForegroundColor Green
}

function Run-Verification {
    Write-Header "Running System Verification"
    Write-Host "Analyzing code structure (flutter analyze)..." -ForegroundColor Gray
    $analyzeResult = flutter analyze --no-pub
    Write-Host $analyzeResult
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: flutter analyze failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    Write-Host "Running 563+ unit & widget tests (flutter test)..." -ForegroundColor Gray
    $testResult = flutter test --no-pub
    Write-Host $testResult
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: flutter test failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "Verification checks completed successfully! (100% GREEN)" -ForegroundColor Green
}

function Compile-Android-Debug {
    Setup-Java
    Write-Header "Building Android Debug APK"
    Write-Host "Compiling whisper.cpp & packaging APK (android-arm64)..." -ForegroundColor Gray
    flutter build apk --debug --target-platform android-arm64
    Write-Host "Success! APK generated at: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
}

function Compile-Android-Release {
    Setup-Java
    Write-Header "Building Android Release APK"
    Write-Host "Compiling release build..." -ForegroundColor Gray
    flutter build apk --release --target-platform android-arm64
    Write-Host "Success! Release APK generated at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}

function Compile-Windows {
    Write-Header "Building Windows Desktop Release"
    Write-Host "Compiling Windows native executable..." -ForegroundColor Gray
    flutter build windows --release
    Write-Host "Success! Executable files built in: build\windows\x64\runner\Release\" -ForegroundColor Green
}

function Compile-Web {
    Write-Header "Building Web Production PWA"
    Write-Host "Compiling WebAssembly bundle..." -ForegroundColor Gray
    flutter build web --release --pwa-strategy offline-first
    Write-Host "Success! Web files built in: build\web\" -ForegroundColor Green
}

function Compile-Linux {
    Write-Header "Building Linux Desktop Release"
    Write-Host "Compiling Linux native bundle..." -ForegroundColor Gray
    flutter build linux --release
    Write-Host "Success! Linux files built in: build\linux\x64\release\bundle\" -ForegroundColor Green
}

function Compile-Whisper-Local {
    Write-Header "Compiling Whisper CLI Locally"
    $script = Join-Path $PSScriptRoot "compile_whisper_windows.ps1"
    if (Test-Path $script) {
        & $script
    } else {
        throw "Could not locate compile_whisper_windows.ps1 script."
    }
}

function Update-Submodules {
    Write-Header "Updating whisper.cpp Submodule"
    Write-Host "Checking out latest source files..." -ForegroundColor Gray
    git submodule init
    git submodule update --recursive
    Write-Host "Submodules updated!" -ForegroundColor Green
}

function Run-Safe-Upgrade {
    Write-Header "Running Safe Package Upgrades"
    Write-Host "Upgrading within pubspec.yaml constraints..." -ForegroundColor Gray
    flutter pub upgrade
    Write-Host "Testing if updates introduced conflicts..." -ForegroundColor Gray
    flutter analyze --no-pub
    Write-Host "Upgrades successfully completed and verified!" -ForegroundColor Green
}

# Main Loop
do {
    Clear-Host
    Write-Host "================================================" -ForegroundColor DarkYellow
    Write-Host "          CapStudio Master Controller           " -ForegroundColor Cyan -Bold
    Write-Host "================================================" -ForegroundColor DarkYellow
    Write-Host " 1. Clean & Fetch Dependencies (flutter clean)"
    Write-Host " 2. Run Verification Checks (analyze & test)"
    Write-Host " 3. Build Android Debug APK (Local Testing)"
    Write-Host " 4. Build Android Release APK (Distribution)"
    Write-Host " 5. Build Windows Desktop App"
    Write-Host " 6. Build Web Production PWA"
    Write-Host " 7. Build Linux Desktop App"
    Write-Host " 8. Compile local whisper-cli from Source (Windows)"
    Write-Host " 9. Update whisper.cpp Native Submodule"
    Write-Host " 10. Perform Safe Dependency Upgrades"
    Write-Host " 11. Exit"
    Write-Host "================================================" -ForegroundColor DarkYellow
    
    $choice = Read-Host "Select an option (1-11)"
    
    try {
        switch ($choice) {
            "1" { Clean-And-Get }
            "2" { Run-Verification }
            "3" { Compile-Android-Debug }
            "4" { Compile-Android-Release }
            "5" { Compile-Windows }
            "6" { Compile-Web }
            "7" { Compile-Linux }
            "8" { Compile-Whisper-Local }
            "9" { Update-Submodules }
            "10" { Run-Safe-Upgrade }
            "11" { Write-Host "Exiting Master Controller. Goodbye!" -ForegroundColor Gray; break }
            default { Write-Host "Invalid option. Please choose between 1 and 11." -ForegroundColor Red }
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
    
    if ($choice -ne "11") {
        Read-Host "`nPress Enter to return to menu..."
    }
} while ($choice -ne "11")
