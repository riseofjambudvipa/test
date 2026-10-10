# 🎨 CapStudio — 100% Offline AI Caption Studio & Video Editor

CapStudio is a professional, **100% on-device, offline-first open-source AI video caption editor and shorts clipping studio**. Built with Flutter, Riverpod, Isar DB, and native media engines, it empowers content creators to generate frame-accurate animated captions, perform AI-assisted viral shorts clipping, remove awkward silences, organize multi-speaker dialogs, import custom stickers, and burn in production-grade subtitle templates — with zero cloud subscriptions, zero telemetry, and zero data leaving your machine.

> [!IMPORTANT]
> **Open-Source & Licensing:** CapStudio is a **free, open-source project** licensed under the **GNU General Public License v3 (GPL-3.0)**. It integrates copyleft and permissive open-source packages, fonts, and binaries (documented in [`CREDITS.md`](CREDITS.md)). It is designed for private on-device video creation and community contribution.

---

## 🌟 Key Subsystems & Capabilities

### 1. 🎙️ On-Device AI Speech-to-Text (`WhisperService`)
* **Desktop (Windows / macOS / Linux)**: Spawns high-performance `whisper-cli` with real-time progress streaming and atomic cancellation. Automatically selects AVX2 optimized binaries for modern CPUs or universal non-AVX fallbacks for legacy processors.
* **Mobile (Android / iOS)**: Runs embedded neural inference via native compiled C dynamic libraries (`libwhisper.so` on Android JNI with NEON acceleration; `whisper.xcframework` on iOS with Apple Metal support).
* **Web (Browser PWA)**: Executes client-side offline WASM (`transformers.js` / `whisper.wasm`) with on-demand Hugging Face model caching.
* **Multilingual Model Ecosystem**: Seamlessly downloads and manages official GGML universal models (`tiny`, `base`, `small`, `medium`, `large-v3-turbo`) with integrity verification.

### 2. ✂️ Viral Shorts Clipper & AI Silence Removal
* **Viral Hook & Moment Detector**: Scans speech transcripts with heuristic hook algorithms to score and extract 15–60s high-engagement segments.
* **Smart Silence Removal**: Noise-gated audio analysis automatically detects pauses and gaps, enabling one-click ripple-deleting of dead air.
* **Auto-Reframing**: Crops and centers landscape (16:9) footage into TikTok/Reels/Shorts vertical aspect ratio (9:16).

### 3. 🎨 Vector Subtitle Styling & Rendering Engine
* **SubStation Alpha (`.ass`) Pipeline**: Generates advanced ASS dialogue events with exact character-level karaoke timings (`\k`), rotation, drop shadows, borders, and position coordinates.
* **Custom Brand Kits & Community Presets**: Save and export custom typography palettes, borders, fonts, and layout presets (`.cappreset`).
* **Retention Progress Bars**: Configurable animated retention bars (gradient, glow, height, opacity) burned directly into exported videos to maximize social media watch time.
* **52 Built-in Offline Fonts**: Bundles 26 designer subtitle fonts, 25 Noto script fonts, and 1 Noto Color Emoji font — requiring zero network access or Google Fonts CDN queries at runtime.

### 4. 😀 Comprehensive Emoji & Custom Sticker System
* **5 Emoji Style Packs**: Supports OpenMoji, Google Noto (Static & 3D Animated), and Microsoft Fluent UI (Static & 3D Animated) with multi-language keyword search indices.
* **Custom Sticker Import**: Import PNG, WEBP, GIF, and JPG graphics from disk as custom overlay stickers with adjustable scaling, positioning, and animation timing.

### 5. 👥 Speaker Diarization & Audio Mastering
* **Multi-Speaker Identification**: Label speakers per chunk with custom color tags and avatars.
* **44 Synthesized Sound Effects**: Built-in sound effects library with dynamic polyphonic wave synthesis fallback if asset files are absent.
* **Background Music Ducking**: Automatic sidechain ducking lowers background audio during spoken dialogue.

### 6. 🌓 Dual-Mode Studio Theming
* Features instant switching between **Studio Dark** and high-contrast **Studio Light** across 5 distinct color palettes:
  - **Obsidian Amber** (Default Studio)
  - **Neon Cyberpunk**
  - **Obsidian Emerald**
  - **Royal Amethyst**
  - **Sunset Sunrise**

### 7. 🚀 Hardware-Accelerated Video Export
* **Desktop**: Direct standalone FFmpeg subprocess isolation with GPU hardware encoder auto-detection (NVIDIA NVENC, Intel QuickSync, Apple VideoToolbox, AMD AMF).
* **Mobile**: Native hardware acceleration via `ffmpeg_kit_flutter_new`.
* **Batch Export Sheet**: Queue and export multiple resolutions (1080p, 4K, 720p), framerates, and aspect ratios simultaneously.

---

## 💻 Platform Support Matrix

| Platform | Setup Experience | Speech-to-Text | Video Rendering | Local Database |
| :--- | :--- | :--- | :--- | :--- |
| **Windows (x64 & ARM64)** | 🟢 Native Desktop | Auto-detects AVX2 / No-AVX / ARM64 CLI | Static FFmpeg 7.1 (GyanD) | Embedded Isar DB |
| **macOS (Apple Silicon M1–M4 & Intel)** | 🟢 Universal App | Universal Metal `whisper-cli` (arm64 & x86_64) | Static FFmpeg (Evermeet) | Embedded Isar DB |
| **Linux (amd64 & arm64 / aarch64)** | 🟢 Native Desktop | Auto-detects amd64 / arm64 `whisper-cli` | Static FFmpeg amd64/arm64 (JohnVanSickle) | Embedded Isar DB |
| **Android (API 24–36)** | 🟢 Mobile App | Pre-bundled `libwhisper.so` (JNI) | Embedded `FFmpegKit` | Embedded Isar DB |
| **iOS (14+)** | 🟢 Mobile App | Pre-bundled `whisper.xcframework` | Embedded `FFmpegKit` | Embedded Isar DB |
| **Web Browser** | 🟢 Offline PWA | WebAssembly (`transformers.js`) | WebAssembly (`ffmpeg.wasm`) | IndexedDB Shim |

---

## 🛠️ Installation & Development Setup

### Prerequisites
1. **Flutter SDK**: Stable channel (`3.22.0`+ / Dart `3.4.0`+).
2. **C++ Native Toolchains**:
   - **Windows**: Visual Studio 2022 with *Desktop development with C++*.
   - **macOS / iOS**: Xcode and CocoaPods (`pod install`).
   - **Linux**: Development packages:
     ```bash
     sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libmpv-dev mpv
     ```
   - **Android**: Android Studio, SDK Platform 34/35, NDK.

### Cloning & Running
```bash
# Clone the repository
git clone https://github.com/capstudio/capstudio.git
cd capstudio

# Fetch dependencies
flutter pub get

# Run on your current desktop or connected device
flutter run
```

> [!WARNING]
> Database schema files (`word.g.dart` and `project.g.dart`) are pre-generated with critical 64-bit integer parsing patches for web and cross-platform compatibility. **Do not run `dart run build_runner build --delete-conflicting-outputs`**, as doing so overwrites these hand-crafted compatibility patches.

---

## 📦 Building & Packaging for Production

### 🟦 Windows
* **Portable Release Build**:
  ```bash
  flutter build windows --release
  ```
* **Compile Inno Setup Installer** (outputs `CapStudio-Setup.exe`):
  ```powershell
  iscc third_party/scripts/capstudio_setup.iss
  ```
* **Storage-Constrained Multi-Drive Build**:
  If primary drive `C:` is low on disk space, run the interactive multi-drive builder:
  ```powershell
  third_party/scripts/build_with_custom_location.bat
  ```

### 🤖 Android
* **Universal Release APK**:
  ```bash
  flutter build apk --release
  ```
* **Split ABI APKs** (arm64-v8a, armeabi-v7a, x86_64):
  ```bash
  flutter build apk --release --split-per-abi
  ```
* **Google Play App Bundle (AAB)**:
  ```bash
  flutter build appbundle --release
  ```

### 🍏 macOS & iOS
* **macOS Release**:
  ```bash
  flutter build macos --release
  ```
* **iOS Release**:
  ```bash
  flutter build ios --release --no-codesign
  ```
* **macOS / Linux Low-Storage Builder**:
  ```bash
  bash third_party/scripts/build_with_custom_location.sh
  ```

### 🐧 Linux
* **Debian / Ubuntu Package (`.deb`)**:
  ```bash
  flutter build linux --release
  chmod +x third_party/scripts/create_deb.sh
  ./third_party/scripts/create_deb.sh
  ```

---

## 📂 Codebase Architecture

```text
lib/
├── app/
│   ├── routes.dart                  # go_router configuration & route guards
│   ├── theme.dart                   # Ambient glowing design tokens & palettes
│   └── theme_provider.dart          # Riverpod state notifier for theme switching
├── core/
│   ├── assets/                      # Asset manifest, downloader pipeline & healing
│   ├── audio/                       # Waveform generation, audio ducking & SFX synthesis
│   ├── brand/                       # Custom brand kits & typography presets
│   ├── database/                    # Isar DB schemas, initialization & migrations
│   ├── downloader/                  # SHA-256 verified binary downloading & extraction
│   ├── emoji/                       # Emoji services, search indices & custom stickers
│   ├── ffmpeg/                      # Subprocess runner, GPU flags & filter graph builders
│   ├── logger/                      # Rolling disk logger with PII sanitization
│   ├── settings/                    # SharedPreferences persistence layer
│   ├── subtitle/                    # SRT, VTT, and ASS script parsers & exporters
│   ├── utils/                       # AppDirs, path migration & CPU feature detection
│   ├── video/                       # Silence detector, viral hook scorer & proxy cache
│   └── whisper/                     # whisper.cpp CLI, FFI streaming & cancellation
├── features/
│   ├── dashboard/                   # Project grid, creation wizard & media previews
│   ├── editor/                      # Interactive scrubber timeline, caption overlays & panels
│   ├── exporter/                    # FFmpeg rendering pipeline & batch export dialog
│   ├── onboarding/                  # First-run setup wizard for models and tools
│   └── settings/                    # Model manager, language picker & tool locators
third_party/                         # Vendored dependencies + all build/package/cert scripts (third_party/scripts/)
```

---

## 🧪 Verification & Quality Standards

Before submitting PRs or generating releases, ensure all verification gates pass:

1. **Static Analysis**:
   ```bash
   flutter analyze --no-pub
   ```
2. **Automated Test Suite**:
   ```bash
   flutter test --no-pub
   ```

---

## 📄 License & Credits

* CapStudio is licensed under the **GNU General Public License v3.0 (GPLv3)**.
* See [`LICENSE`](LICENSE) for complete legal terms.
* See [`CREDITS.md`](CREDITS.md) for full attributions of open-source fonts, libraries, and emoji assets.
