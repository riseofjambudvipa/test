# CapStudio Script Suite Reference Manual

This directory contains the automation scripts, compiler wrappers, asset downloaders, testing helpers, and packaging tools used to build CapStudio, manage dependencies, and sync assets across different target platforms.

---

## Script Suite Index

The suite consists of **39 utility scripts** divided into functional domains:

| Category | File Path | Target OS | Description |
| :--- | :--- | :--- | :--- |
| **Root Packaging & Setup** | [`capstudio_setup.iss`](capstudio_setup.iss) | Windows | Inno Setup configuration for compiling the Windows `.exe` desktop installer. |
| | [`create_deb.sh`](create_deb.sh) | Linux | Packages the Flutter Linux release bundle into a Debian/Ubuntu `.deb` installer. |
| | [`build_with_custom_location.bat`](build_with_custom_location.bat) | Windows | Interactive multi-drive build launcher for storage-constrained environments. |
| | [`build_with_custom_location.sh`](build_with_custom_location.sh) | macOS/Linux | Shell multi-drive builder for storage-constrained Unix environments. |
| | [`download_whisper_model.sh`](download_whisper_model.sh) | macOS/Linux | Downloads Whisper GGML model files from Hugging Face into `assets/models/`. |
| | [`download_whisper_source.ps1`](download_whisper_source.ps1) | Windows | Downloads the whisper.cpp source zip for offline local compile setups. |
| | [`generate_sfx.dart`](generate_sfx.dart) | Cross-Platform | Synthesizes/Pre-bakes the 44 built-in wav sound effects into `assets/sfx/`. |
| | [`analyze_packs.py`](analyze_packs.py) | Cross-Platform | Audits emoji pack completeness, JSON integrity, and file counts. |
| **Build & Compile** | [`build/build_all.sh`](build/build_all.sh) | macOS/Linux | Compiles release builds sequentially for all target operating systems. |
| | [`build/build_and_update.ps1`](build/build_and_update.ps1) | Windows | Master Developer Command Suite (clean, pub get, test, compile, update). |
| | [`build/build_and_update.sh`](build/build_and_update.sh) | macOS/Linux | Shell equivalent of the Master Developer Command Suite. |
| | [`build/build_ffmpeg_mobile.sh`](build/build_ffmpeg_mobile.sh) | Android/iOS | Compiles size-reduced mobile FFmpeg dynamic libraries including `libass`. |
| | [`build/build_production.ps1`](build/build_production.ps1) | Windows | Master 6-Platform Production Build & Packaging Controller. |
| | [`build/build_whisper_android.sh`](build/build_whisper_android.sh) | Android | Compiles native JNI `libwhisper.so` dynamic libraries via NDK. |
| | [`build/build_whisper_desktop_generic.ps1`](build/build_whisper_desktop_generic.ps1) | Windows | Compiles fallback generic (non-AVX2) static builds of `whisper-cli.exe`. |
| | [`build/build_whisper_ios.sh`](build/build_whisper_ios.sh) | iOS | Compiles iOS static libraries and outputs `whisper.xcframework`. |
| | [`build/compile_whisper_shared.ps1`](build/compile_whisper_shared.ps1) | Windows | Compiles whisper.cpp as a shared dynamic library (`whisper.dll`) for FFI. |
| | [`build/compile_whisper_shared.sh`](build/compile_whisper_shared.sh) | macOS/Linux | Compiles whisper.cpp as a shared dynamic library (`.dylib`/`.so`) for FFI. |
| | [`build/compile_whisper_windows.ps1`](build/compile_whisper_windows.ps1) | Windows | Compiles local `whisper-cli.exe` statically from local submodule source. |
| | [`build/notarize_macos.sh`](build/notarize_macos.sh) | macOS | Automates deep-signing, Apple notarization, and DMG stapling. |
| **Release & Keystore Setup** | [`setup/generate_android_keystore.ps1`](setup/generate_android_keystore.ps1) | Windows | Generates release keystore & prints GitHub Actions secret base64. |
| | [`setup/generate_android_keystore.sh`](setup/generate_android_keystore.sh) | macOS/Linux | Bash equivalent for Android release keystore generation. |
| | [`certificate/windows/create_cert.ps1`](certificate/windows/create_cert.ps1) | Windows | Generates self-signed Authenticode certificate for local MSIX development. |
| **Font Fetchers** | [`fonts/download_fonts.ps1`](fonts/download_fonts.ps1) | Windows | Downloads standard stylish design fonts into `assets/fonts/`. |
| | [`fonts/download_fonts.sh`](fonts/download_fonts.sh) | macOS/Linux | Shell equivalent to download standard design fonts. |
| | [`fonts/download_cjk.ps1`](fonts/download_cjk.ps1) | Windows | Downloads Chinese, Japanese, and Korean (CJK) language fonts into assets. |
| | [`fonts/download_cjk_full.ps1`](fonts/download_cjk_full.ps1) | Windows | Downloads a wider set of CJK fonts for comprehensive glyph coverage. |
| **Emoji Tooling** | [`emoji/categorize_emojis.py`](emoji/categorize_emojis.py) | Cross-Platform | Categorizes emoji sets into standard groups. |
| | [`emoji/inspect_digit_files.py`](emoji/inspect_digit_files.py) | Cross-Platform | Inspects numeric and symbol emoji file mappings. |
| | [`emoji/reorganize_emoji_packs.py`](emoji/reorganize_emoji_packs.py) | Cross-Platform | Reorganizes and normalizes pack directory layouts. |
| | [`emoji/verify_emoji_categories.py`](emoji/verify_emoji_categories.py) | Cross-Platform | Validates emoji pack integrity against category manifests. |
| | [`emoji/keyword/generate_emoji_index.py`](emoji/keyword/generate_emoji_index.py) | Cross-Platform | Generates multi-language search indices. |
| | [`emoji/keyword/generate_emoji_registry.py`](emoji/keyword/generate_emoji_registry.py) | Cross-Platform | Compiles emoji keyword registry JSON files. |
| | [`emoji/keyword/pretty_print_emoji_files.py`](emoji/keyword/pretty_print_emoji_files.py) | Cross-Platform | Formats and validates emoji mapping files. |
| **Testing** | [`test/generate_test_dashboard.dart`](test/generate_test_dashboard.dart) | Cross-Platform | Runs test suite and formats execution metrics into `test_dashboard.html`. |
| | [`test/reorganize_tests.dart`](test/reorganize_tests.dart) | Cross-Platform | Reorganizes `test/` directory to mirror the hierarchical layout of `lib/`. |
| **Update & Sync** | [`update/update_binaries.ps1`](update/update_binaries.ps1) | Windows | Audits CPU capabilities (AVX2) and downloads/repairs required CLI binaries. |
| | [`update/update_binaries.sh`](update/update_binaries.sh) | macOS/Linux | Shell-based CLI setup and permissions manager (`chmod +x`). |
| | [`update/update_mobile_dependencies.ps1`](update/update_mobile_dependencies.ps1) | Windows | Syncs compiled mobile library targets to Gradle/CocoaPods. |
| | [`update/update_mobile_dependencies.sh`](update/update_mobile_dependencies.sh) | macOS/Linux | Shell equivalent to sync compiled mobile libraries into Flutter targets. |

---

## Detailed Script Manual

### 📦 1. Root Packaging & Setup

#### Inno Setup Installer (`capstudio_setup.iss`)
An Inno Setup compiler script that packages the production Windows desktop bundle (`CapStudio-Setup.exe`). It gathers Flutter release builds, precompiled binaries (FFmpeg & Whisper CLI), and sets registry paths and shortcuts.

#### Debian Packager (`create_deb.sh`)
Automates building Debian/Ubuntu `.deb` installer packages. It compiles the Flutter Linux bundle, maps executable pathways into `/opt/capstudio` (including adjacent `lib/` and `data/` directories), establishes a `/usr/bin/capstudio` launch wrapper, and constructs the control files.

#### GGML Model Downloader (`download_whisper_model.sh`)
Downloads pre-quantized GGML Whisper model files directly from Hugging Face into `assets/models/`:
```bash
./scripts/download_whisper_model.sh [tiny | base | small | medium | large]
```

#### Whisper Source Downloader (`download_whisper_source.ps1`)
Downloads and extracts the correct zip source archive of Georgi Gerganov's whisper.cpp repository to satisfy native local builds when Git submodules are unavailable or fail to pull.

#### Audio Synthesizer (`generate_sfx.dart`)
Pre-bakes the 44 built-in standard Sound Effects (SFX) using mathematical wave generation formulas (sine/triangle synthesis). It writes clean `.wav` audio files directly to `assets/sfx/`.

---

### ⚙️ 2. Platform Compilation (Native Binaries)

#### Sequential Build Runner (`build/build_all.sh`)
A Bash script that sequentially triggers building Flutter release targets across all operating systems. It runs static analysis, executes the unit/widget test suite, and runs Android, iOS, macOS, Windows, and Linux compilations.

#### Master Developer Command Suite (`build/build_and_update.*`)
An interactive CLI dashboard (`.ps1` for Windows, `.sh` for macOS/Linux) that acts as the developer control center:
1. Cleans build caches and gets dependencies (`flutter clean`).
2. Runs verification checks (`flutter analyze` and `flutter test`).
3. Compiles Android Debug/Release APKs.
4. Compiles Windows desktop executables.
5. Compiles local Whisper CLIs.
6. Synchronizes submodules.

#### Production Build Controller (`build/build_production.ps1`)
Main orchestrator for compiling production-ready FFI binaries, running automated code analysis, checking target configurations, compiling Windows release versions, and packaging `.aab`/`.apk` binaries for Android.

#### Mobile FFmpeg Customizer (`build/build_ffmpeg_mobile.sh`)
Strips down the mobile `ffmpeg-kit` compilation configurations to minimize output binary sizes. It compiles custom frameworks for Android and iOS that only preserve the codecs and filters needed for subtitle burning (`libass`, `freetype`, `fribidi`, `harfbuzz`, and `fontconfig`).

#### Android NDK Compiler (`build/build_whisper_android.sh`)
Compiles the native JNI libraries for Android. It runs CMake on top of the NDK toolchain to output size-reduced `libwhisper.so` shared libraries for all target ABIs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) and copies them to the Flutter JNI paths.

#### Apple Framework Builder (`build/build_whisper_ios.sh`)
Builds iOS static library bundles (`libwhisper.a`) for devices (arm64) and simulators (arm64/x86_64) using the Xcode toolchain, and packages them into a unified Apple `whisper.xcframework` inside `ios/whisper_xcframework/`.

#### Generic Windows Compiler (`build/build_whisper_desktop_generic.ps1`)
Disables CPU AVX2 instruction requirements and compiles a generic fallback static executable of `whisper-cli.exe` for legacy Windows processors. It packages it with Georgi Gerganov's MIT attribution credits and generates `.sha256` checksums.

#### Local Windows CLI Compiler (`build/compile_whisper_windows.ps1`)
Compiles `whisper-cli.exe` statically from local submodule source files using MSVC and installs it directly to the local application runtime binary folder.

#### Shared Library Compilers (`build/compile_whisper_shared.*`)
Compiles the core whisper.cpp library as a shared library (`whisper.dll` on Windows, `libwhisper.dylib`/`libwhisper.so` on macOS/Linux) for FFI-based direct FFI integration:
- `compile_whisper_shared.ps1` runs on Windows (compiling and copying to runner folders).
- `compile_whisper_shared.sh` runs on macOS and Linux.

---

### 🔤 3. Fonts Assets Automation

* **`fonts/download_fonts.*`**: Downloads stylish standard caption fonts (e.g. Montserrat, Anton, Bebas Neue, Raleway, Space Grotesk) and writes them to `assets/fonts/`.
* **`fonts/download_cjk.*`**: Downloads Noto Sans Chinese, Japanese, and Korean (CJK) language font glyphs to guarantee high-fidelity multi-language subtitle rendering offline.

---

### 🧪 4. Testing & Reorganization

#### Test Dashboard Builder (`test/generate_test_dashboard.dart`)
Runs the full Flutter test suite, parses the JSON output logs, and formats test summaries, assertions, and execution speeds into an interactive, searchable HTML report (`test_dashboard.html`).

#### Test Reorganization Utility (`test/reorganize_tests.dart`)
Parses and reorganizes the `test/` directory to mirror the exact folder structure of the `lib/` directory, moving files and repairing relative imports automatically.

---

### 🔄 5. Local Setup & Syncing

#### Binary Setup & Repair Utility (`update/update_binaries.*`)
Checks CPU capabilities (such as AVX2 instruction support) on boot and downloads the corresponding platform-specific precompiled binaries for FFmpeg and Whisper CLI.

#### Mobile Native Dependency Sync (`update/update_mobile_dependencies.*`)
Automatically copies compiled mobile shared frameworks (`.so` directories, `.aar` archives, and `.xcframework` bundles) from native build staging areas into Gradle and CocoaPods project directories.
