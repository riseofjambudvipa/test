@echo off
setlocal EnableDelayedExpansion
title CapStudio Build - Custom Cache and Disk Space Setup

:: Resolve project root directory (two levels up from third_party\scripts\)
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%..\.."
set "PROJECT_ROOT=%CD%"
popd

echo =====================================================================
echo           CapStudio: Custom Gradle / Cache Location Setup
echo =====================================================================
echo.
echo This utility configures custom Gradle and Pub cache locations to prevent
echo disk-space exhaustion on your primary system drive during builds.
echo.
echo Project Root: %PROJECT_ROOT%
echo.

:: Detect drive storage
echo Analyzing available drives and free storage...
set "DETECTED_DRIVE="
set "BEST_ALT_DRIVE="
set "C_FREE_GB=0"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "try { [math]::Round((Get-PSDrive -Name C -ErrorAction SilentlyContinue).Free / 1GB, 1) } catch { 0 }"`) do (
    set "C_FREE_GB=%%A"
)

echo Primary drive C: has %C_FREE_GB% GB free space.

:: Check for secondary drives with plenty of storage if C: is low or developer prefers offloading
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne 'C' -and $_.Free -gt 15GB } | Sort-Object Free -Descending | Select-Object -ExpandProperty Name -First 1"`) do (
    set "BEST_ALT_DRIVE=%%D:"
)

:: If C: has less than 15 GB free and a secondary drive exists, recommend the secondary drive
powershell -NoProfile -Command "if ([double]'%C_FREE_GB%' -lt 15.0 -and '%BEST_ALT_DRIVE%' -ne '') { exit 1 } else { exit 0 }"
if errorlevel 1 (
    echo [WARNING] Primary drive C: is low on free space (%C_FREE_GB% GB^)!
    echo Recommending secondary drive %BEST_ALT_DRIVE% to prevent build failure.
    set "DETECTED_DRIVE=%BEST_ALT_DRIVE%"
) else (
    set "DETECTED_DRIVE=%SystemDrive%"
    if not defined DETECTED_DRIVE set "DETECTED_DRIVE=C:"
)

echo.
echo Available storage partitions:
powershell -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | ForEach-Object { \"  Drive \" + $_.Name + \":  \" + [math]::Round($_.Free/1GB, 1) + \" GB free\" }"
echo.

set "DEFAULT_GRADLE_DIR=%DETECTED_DRIVE%\gradle_cache"
set "DEFAULT_PUB_DIR=%DETECTED_DRIVE%\pub_cache"

echo Suggested build cache location: %DETECTED_DRIVE%
echo.

:: Ask for custom Gradle Cache directory
set /p "USER_GRADLE_DIR=Enter directory for Gradle Cache [Default: %DEFAULT_GRADLE_DIR%]: "
if "%USER_GRADLE_DIR%"=="" set "USER_GRADLE_DIR=%DEFAULT_GRADLE_DIR%"

:: Remove trailing slash if provided
if "%USER_GRADLE_DIR:~-1%"=="\" set "USER_GRADLE_DIR=%USER_GRADLE_DIR:~0,-1%"

:: Create Gradle directory & tmp subfolder
if not exist "%USER_GRADLE_DIR%" (
    echo Creating directory: "%USER_GRADLE_DIR%"...
    mkdir "%USER_GRADLE_DIR%" 2>nul
)
if not exist "%USER_GRADLE_DIR%\tmp" (
    mkdir "%USER_GRADLE_DIR%\tmp" 2>nul
)

:: Ask for custom Pub Cache directory
set /p "USER_PUB_DIR=Enter directory for Flutter Pub Cache [Default: %DEFAULT_PUB_DIR%]: "
if "%USER_PUB_DIR%"=="" set "USER_PUB_DIR=%DEFAULT_PUB_DIR%"

if "%USER_PUB_DIR:~-1%"=="\" set "USER_PUB_DIR=%USER_PUB_DIR:~0,-1%"

if not exist "%USER_PUB_DIR%" (
    echo Creating directory: "%USER_PUB_DIR%"...
    mkdir "%USER_PUB_DIR%" 2>nul
)

echo.
echo =====================================================================
echo Active Configuration:
echo  - GRADLE_USER_HOME : %USER_GRADLE_DIR%
echo  - PUB_CACHE        : %USER_PUB_DIR%
echo  - JAVA Temp Dir    : %USER_GRADLE_DIR%\tmp
echo =====================================================================
echo.

:: Save permanently in Windows user registry
set /p "SET_PERM=Save these locations permanently for your user account? (Y/N) [Default: N]: "
if /i "%SET_PERM%"=="Y" (
    echo Saving environment variables permanently...
    setx GRADLE_USER_HOME "%USER_GRADLE_DIR%" >nul
    setx PUB_CACHE "%USER_PUB_DIR%" >nul
    echo [OK] Permanent environment variables saved!
)

:: Apply for this current running session
set "GRADLE_USER_HOME=%USER_GRADLE_DIR%"
set "PUB_CACHE=%USER_PUB_DIR%"
set "TEMP=%USER_GRADLE_DIR%\tmp"
set "TMP=%USER_GRADLE_DIR%\tmp"
set "_JAVA_OPTIONS=-Djava.io.tmpdir=%USER_GRADLE_DIR%\tmp"
set "GRADLE_OPTS=-Dgradle.user.home=%USER_GRADLE_DIR% -Djava.io.tmpdir=%USER_GRADLE_DIR%\tmp"

cd /d "%PROJECT_ROOT%"

:: Update android/gradle.properties with forward-slash path
set "FORWARD_SLASH_GRADLE_DIR=%USER_GRADLE_DIR:\=/%"
if exist "android" (
    (
    echo org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m -Djava.io.tmpdir=%FORWARD_SLASH_GRADLE_DIR%/tmp -XX:+HeapDumpOnOutOfMemoryError
    echo android.useAndroidX=true
    echo android.newDsl=false
    echo android.builtInKotlin=false
    echo kotlin.incremental=false
    echo.
    echo systemProp.gradle.user.home=%FORWARD_SLASH_GRADLE_DIR%
    echo systemProp.java.io.tmpdir=%FORWARD_SLASH_GRADLE_DIR%/tmp
    ) > "android\gradle.properties"
    echo [OK] Updated android\gradle.properties
)

:: Stop old Gradle daemons that might still be using C:
echo.
echo Stopping any running Gradle background daemons...
if exist "android\gradlew.bat" (
    cd android
    call gradlew.bat --stop >nul 2>&1
    cd ..
)

echo.
echo =====================================================================
echo Choose Build Action:
echo  [1] Build Release APK (Universal Fat APK)
echo  [2] Build Release Split APKs (arm64-v8a, armeabi-v7a, x86_64)
echo  [3] Build Release App Bundle (AAB for Google Play Store)
echo  [4] Build Debug APK (Local Device Testing)
echo  [5] Clean + Pub Get + Build Release APK
echo  [6] Exit
echo =====================================================================
echo.
set /p "BUILD_CHOICE=Enter choice (1-6) [Default: 1]: "
if "%BUILD_CHOICE%"=="" set "BUILD_CHOICE=1"

if "%BUILD_CHOICE%"=="1" (
    echo.
    echo Building Universal Release APK...
    call flutter build apk --release
) else if "%BUILD_CHOICE%"=="2" (
    echo.
    echo Building Split-per-ABI Release APKs...
    call flutter build apk --release --split-per-abi
) else if "%BUILD_CHOICE%"=="3" (
    echo.
    echo Building Release App Bundle (AAB)...
    call flutter build appbundle --release
) else if "%BUILD_CHOICE%"=="4" (
    echo.
    echo Building Debug APK...
    call flutter build apk --debug
) else if "%BUILD_CHOICE%"=="5" (
    echo.
    echo Running flutter clean...
    call flutter clean
    echo Running flutter pub get...
    call flutter pub get
    echo Running flutter build apk --release...
    call flutter build apk --release
) else (
    echo Exiting.
)

echo.
echo =====================================================================
echo Build Script Finished!
echo =====================================================================
pause
