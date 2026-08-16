# 🎨 CapStudio — Free Local AI Caption Studio

CapStudio is a professional, **100% offline, local-first open-source AI caption editor** for video creators. Built with Flutter, Riverpod, and Isar DB, it empowers creators to generate high-fidelity, word-level animated captions, mix immersive sound effects, and burn in gorgeous subtitle templates without subscription fees, external servers, or data ever leaving the host device.

> [!IMPORTANT]
> **Open-Source & Licensing:** CapStudio is a **free, open-source personal project** shared under the **GNU General Public License v3 (GPL-3.0)**. It leverages and acknowledges open-source packages, fonts, and tools (detailed in `CREDITS.md`). Because it integrates copyleft libraries (such as FFmpeg compiled with `libass`), it is distributed as open-source code and is meant for local use and improvement of your own repository, rather than proprietary commercial store distribution.

---

## 🚀 Key Architectural Subsystems

* **Local Speech-to-Text (`WhisperService`)**: 
  - **Desktop (Windows/macOS/Linux)**: Attempts dynamic execution via native C-bindings using Dart FFI. If unavailable, it falls back to executing a locally compiled `whisper-cli` binary in a subprocess.
  - **Mobile (Android/iOS)**: Executes through compiled JNI dynamic libraries (`libwhisper.so` on Android) or native frameworks (`whisper.xcframework` on iOS).
* **Video rendering (`FFmpegService`)**: Burns SubStation Alpha (`.ass`) subtitle files with custom styles directly into video files. Uses static subprocesses on desktop and `ffmpeg-kit` on mobile targets.
* **Intelligent Auto-Save (`IsarService`)**: Features a silent, debounced 3-second auto-save pipeline using transactional Isar DB records. On Web, it falls back to an IndexedDB storage wrapper.
* **Zero CDN Typography**: Bundles all **52 designer and multi-language fonts** (26 styled fonts, 25 Noto script fonts, and 1 Noto Color Emoji font) inside the binary asset package to ensure complete offline independence.
* **Polyphonic Wave Synthesis (`AudioService`)**: Synthesizes all 44 classic editor sound effects dynamically using mathematical wave generators on boot if the pre-bundled asset files are missing, ensuring sound effects are always available.
* **Client-Side WebAssembly**: Fully supports Web Browser builds running client-side WASM (`transformers.js` / `whisper.wasm` and `ffmpeg.wasm`). *Note: Unlike native offline desktop/mobile builds, the Web build requires an active internet connection to load script libraries from CDNs and fetch Whisper model weights from Hugging Face.*

---

## 💻 Platform Support Matrix

| Platform | Setup Experience | Speech-to-Text (Whisper) | Video Rendering (FFmpeg) | Local DB (Isar) |
| :--- | :--- | :--- | :--- | :--- |
| **Windows x64** | 🟢 **Out-of-the-Box** | Auto-Downloads (AVX2 or generic fallback) | Auto-Downloads (Gyan.dev static build) | Local Embedded (Isar) |
| **Google Android** | 🟢 **Out-of-the-Box** | Pre-Bundled JNI (`libwhisper.so`) | Pre-Bundled Library (`FFmpegKit`) | Local Embedded (Isar) |
| **Apple iOS** | 🟢 **Out-of-the-Box** | Pre-Bundled Framework (`xcframework`) | Pre-Bundled Library (`FFmpegKit`) | Local Embedded (Isar) |
| **macOS (Intel/M-chips)**| 🟡 **Manual Link Required** | Manual Homebrew linking (`brew install whisper-cpp`) | Auto-Downloads (Evermeet build) | Local Embedded (Isar) |
| **Linux (Ubuntu/Arch)**  | 🟡 **Manual Link Required** | Manual distribution compile & link | Auto-Downloads (Static release) | Local Embedded (Isar) |
| **Web Browser** | 🟡 **Active (requires Internet)** | WASM/JS (`transformers.js` / `whisper.wasm` via CDN) | WASM/JS (`ffmpeg.wasm` client via CDN) | IndexedDB JSON shim |

---

## 🛠️ Step-by-Step Installation & Setup

### Prerequisites
1. **Git**: Install [Git](https://git-scm.com/) on your machine.
2. **Flutter SDK**: Install Flutter SDK (stable channel, version `3.22.0` or later / Dart SDK `3.4.0` or later) from [flutter.dev](https://docs.flutter.dev/get-started/install).
3. **Native Compiler Tools**:
   - **Windows**: Install Visual Studio with the **Desktop development with C++** workload.
   - **Android**: Install Android Studio, Android SDK, and Android NDK (match version specified in `android/app/build.gradle.kts`).
   - **macOS/iOS**: A Mac running macOS with Xcode and CocoaPods installed.
   - **Linux**: Install development headers: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libmpv-dev mpv`

### Project Initialization
1. **Clone the Repository**:
   ```bash
   git clone <your-repo-url>
   cd CapStudio
   ```
2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Compile Database Schemas** (required on fresh setup or after modifying schema files):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 💻 Compilation & Packaging Commands

### 🟦 Windows
* **Compile Build**:
  ```bash
  flutter build windows --release
  ```
* **Create Installer** (requires Inno Setup installed and on PATH):
  ```powershell
  iscc scripts/capstudio_setup.iss
  ```

### 🤖 Android
* **NDK & Java**: Set your `JAVA_HOME` environment variable to your JDK path (e.g. Android Studio's bundled JDK).
* **Compiling APK**:
  ```bash
  flutter build apk --release --target-platform android-arm64
  ```

### 🍏 macOS & iOS
1. **Compile Native iOS Whisper Library**:
   ```bash
   chmod +x scripts/build_whisper_ios.sh
   ./scripts/build_whisper_ios.sh
   ```
2. **Install CocoaPods Dependencies**:
   ```bash
   cd ios && pod install --repo-update && cd ../macos && pod install --repo-update && cd ..
   ```
3. **Run / Compile**:
   - **macOS**: `flutter build macos --release`
   - **iOS**: `flutter build ios --release --no-codesign`

### 🐧 Linux
* **Compile & Package**:
  ```bash
  flutter build linux --release
  # Create Debian package
  chmod +x scripts/create_deb.sh
  ./scripts/create_deb.sh
  ```

---

## 📂 Codebase Directory Map

```text
lib/
├── app/
│   ├── routes.dart          # go_router configuration & route guards
│   ├── theme.dart           # Ambient glowing painter & style systems
│   └── theme_provider.dart  # Riverpod notifier for global theme settings
├── core/
│   ├── assets/              # Asset manifest, download pipeline, and verification
│   ├── audio/               # Polyphonic WAV synthesizer and audio playback
│   ├── database/            # Isar local database initialization & transaction schemas
│   ├── downloader/          # Subprocess binary downloader & signature checker
│   ├── emoji/               # Emoji service and rendering maps
│   ├── ffmpeg/              # Subprocess execution & local process wrapping
│   ├── fonts/               # Custom font asset linking and loaders
│   ├── logger/              # Rotation file logging & memory ring-buffer
│   ├── settings/            # SharedPreferences configuration maps
│   ├── subtitle/            # Subtitle structures, parsing (SRT/VTT/ASS), and importers
│   ├── utils/               # AppDirs directories & CPU capability detection
│   └── whisper/             # whisper.cpp speech-to-text CLI/FFI wrappers
└── features/
    ├── dashboard/           # Dashboard UI and project management
    ├── editor/              # Scrubber timeline, caption overlays, styling panel
    ├── exporter/            # Video rendering and progress trackers
    ├── onboarding/          # Setup wizard screens for models and executables
    └── settings/            # Configuration editors & models picker widgets
```

---

## 🧪 Verification & Lint Compliance

Always run these verification commands before committing:

1. **Static Analysis**:
   ```bash
   flutter analyze
   ```
2. **Automated Test Suite**:
   ```bash
   flutter test
   ```
