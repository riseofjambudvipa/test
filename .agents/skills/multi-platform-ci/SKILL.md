---
name: multi-platform-ci
description: >-
  Runbook and reference for CapStudio's GitHub Actions build matrix, multi-architecture packaging,
  signing scripts, and release distribution pipeline.
---

# Multi-Platform CI/CD Build & Release Runbook

CapStudio uses a unified GitHub Actions matrix (`.github/workflows/build.yml`) to compile, package, and release for all 6 target platforms across both x64 and ARM64 architectures.

## Workflow Structure

The workflow is triggered via `workflow_dispatch` with toggle inputs:
- `create_release` (boolean): Publishes to GitHub Releases.
- `tag_name` (string): Release tag (e.g., `v1.1.0` or `test`).
- `run_tests` (boolean): Executes `flutter analyze` and `flutter test` (831 tests) before building.
- Platform toggles: `build_windows`, `build_android`, `build_web`, `build_macos`, `build_linux`, `build_ios`, `build_whispers`, `pack_ffmpeg`, `pack_source_code`.

## Platform Packaging Specifications

### 1. Windows Desktop (`windows-latest`)
- **Artifacts**:
  - `CapStudio-Windows-x64.zip`: Portable standalone package.
  - `CapStudio-Windows-x64.msix`: Windows UWP App package signed with a self-signed PFX generated per build (`third_party/scripts/certificate/windows/create_cert.ps1`).
  - `CapStudio-Setup-Windows-x64.exe`: Inno Setup installer (`third_party/scripts/capstudio_setup.iss`).
- **Dependencies**: Bundles static FFmpeg 7.1 essentials (`ffmpeg.exe`, `ffprobe.exe`).

### 2. Linux Desktop (`ubuntu-latest`)
- **Artifacts**:
  - `capstudio_<version>_amd64.deb`: Debian/Ubuntu package (`third_party/scripts/create_deb.sh`).
  - `CapStudio-Linux-x64.tar.gz`: Portable tarball for Fedora, Arch, openSUSE.
  - `CapStudio-Linux-x86_64.AppImage`: Universal AppImage bundled with AppStream metainfo (`com.capstudio.app.metainfo.xml`) and `.desktop` entry.
- **Dependencies**: Bundles John Van Sickle static amd64 FFmpeg.

### 3. macOS (`macos-14` Apple Silicon runner)
- **Artifact**:
  - `CapStudio-macOS-Universal.dmg`: Universal fat DMG supporting both Apple Silicon (M1-M4) and Intel (x86_64).
- **Signing**: Ad-hoc code signed via `codesign --force --deep --sign - CapStudio.app`.
- **Dependencies**: Bundles Evermeet static universal FFmpeg.

### 4. Android (`ubuntu-latest`)
- **Artifacts**:
  - `CapStudio-Android-Universal.apk`: Universal FAT APK supporting all ABIs.
  - `CapStudio-Android-arm64-v8a.apk`: Modern 64-bit devices.
  - `CapStudio-Android-armeabi-v7a.apk`: 32-bit legacy devices.
  - `CapStudio-Android-x86_64.apk`: Chromebooks and Android emulators.
  - `CapStudio-Android.aab`: Google Play Store App Bundle.
- **Gradle Config**: NDK `28.2.13676358` (`r28b`), `splits.abi` enabled, `org.gradle.vfs.watch=false`.

### 5. iOS (`macos-14`)
- **Artifact**:
  - `CapStudio-iOS-arm64.tar.gz`: Un-codesigned `Runner.app` archive for ad-hoc re-signing or AltStore deployment.
- **Build Pre-step**: Compiles `third_party/whisper.cpp` into universal `whisper.xcframework` using `third_party/scripts/build/build_whisper_ios.sh -quiet`.

### 6. Web (`ubuntu-latest`)
- **Artifact**:
  - `CapStudio-Web.zip`: Compiled CanvasKit/WASM web application.
  - Excludes 75 MB native models from bundle (browser uses Transformers.js client-side).
  - Uses `--no-wasm-dry-run`.

### 7. Standalone Binaries (Category B)
- **Whisper CLI**:
  - Windows: AVX2, No-AVX, ARM64 (`whisper-cli-win-*.zip`).
  - macOS: Universal Metal (`whisper-cli-mac-universal.zip`).
  - Linux: x64, ARM64 (`whisper-cli-linux-*.zip`).
- **FFmpeg Binaries**:
  - Windows: x64 (GyanD), ARM64 (BtbN GPL).
  - macOS: Universal (Evermeet).
  - Linux: amd64 and aarch64 (BtbN GPL).

## CI Rules
- Build steps must pass `--no-pub` because an explicit `flutter pub get` step runs beforehand.
- Pub cache paths must match platform layouts (`~\AppData\Local\Pub\Cache` on Windows, `~/.pub-cache` on Linux/macOS).
