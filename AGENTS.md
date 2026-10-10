# ABSOLUTE GIT & CONTRIBUTOR RULES: READ FIRST

## 1. Commit Attribution & Author Identity
- Every git commit MUST be authored by:
  ```bash
  --author="riseofjambudvipa <riseofjambudvipa@gmail.com>"
  ```
- NEVER use generic bot names, AI assistant signatures, co-authored-by trailers, or default runner names.
- Never add robot emojis (`🤖`), "Generated with AI", or similar trailers in commits or PRs.

## 2. Multi-Branch & Tag Release Push Rule
- CapStudio maintains synchronized development branches and release tags:
- Whenever pushing changes, ALWAYS push to `master`, `main`, AND force-update the `test` release tag in one sequential pipeline:
  ```powershell
  git push origin master; git push origin master:main; git tag -f test; git push origin -f test
  ```
- In Windows PowerShell environments, use `;` to sequence commands. Do NOT use `&&` (not supported in Windows PowerShell 5.1).

## 3. Strict Open Source License: GNU GPL v3.0 (GPL-3.0-only)
- CapStudio is strictly licensed under the **GNU General Public License v3.0 (`GPL-3.0-only`)**.
- It is **NOT MIT**, Apache-2.0, or BSD.
- Any new file, metadata, AppStream specification, package descriptor (`pubspec.yaml`, `debian/control`, `com.capstudio.app.metainfo.xml`), Inno Setup script, or MSIX manifest must state `GPL-3.0-only` (or `GPL-3.0+` where applicable). AppStream metadata license uses `CC0-1.0`.
- Never rebrand or strip copyright headers. Any derivative works must remain fully free and open source under GPL-3.0.

---

# CapStudio Project Architecture & Guidelines

CapStudio is a completely offline, local-first AI caption studio and video subtitle editor built with Flutter and Dart. It runs natively across **Windows, macOS, Linux, Android, iOS, and Web (WASM)**.

## Core Pillars
1. **100% Offline & Private**: Speech-to-text inference runs locally via `whisper.cpp` (C++ FFI on desktop/mobile, Transformers.js WASM on Web). No user audio or video leaves the machine.
2. **Deterministic Video Pipeline**: High-performance video rendering, audio extraction, hardware encoding (NVENC, VAAPI, VideoToolbox, QSV, AMF), and subtitle burning powered by static `FFmpeg` 7.x.
3. **Reactive Local Storage**: Embedded NoSQL database using `Isar Community 3.3.2` with project versioning, undo/redo stacks, and schema migration.
4. **Professional Caption Engine**: Frame-accurate word-level timestamps, animated karaoke highlighting (pop, bounce, typewriter, glow), custom TTF/OTF font loading, and Noto/APNG animated emojis.

---

## Repository Structure

```
CapStudio/
├── .agents/                          # Project-specific AI agent runbooks & skills
│   └── skills/                       # Deep workflow runbooks (whisper, ffmpeg, styling, etc.)
├── .github/
│   └── workflows/
│       └── build.yml                 # Multi-platform CI/CD build & release matrix
├── android/                          # Android native project (AGP 8.8, NDK 28.2, CMake C++17)
├── ios/                              # iOS native project (Xcode 16, CocoaPods, whisper.xcframework)
├── macos/                            # macOS native project (Universal arm64/x86_64, Runner.xcodeproj)
├── linux/                            # Linux desktop shell (GTK3, CMake, packaging metadata)
├── windows/                          # Windows native runner (MSVC C++20, runner.rc, MSIX config)
├── web/                              # Web frontend (CanvasKit, WASM, Transformers.js, Web Worker STT)
├── assets/                           # Application assets
│   ├── fonts/                        # Bundled system & typography fonts
│   ├── logo/                         # Branding and application icons
│   └── sfx/                          # UI sound effects (wav)
├── third_party/                      # Patched dependencies, sidecars, and build scripts
│   ├── isar_community/               # Custom patched local Isar engine
│   ├── whisper.cpp/                  # Vendored whisper.cpp source (submodule)
│   └── scripts/                      # Platform packaging & automation scripts
│       ├── build/                    # Native build helpers (build_whisper_ios.sh, etc.)
│       ├── certificate/              # Windows MSIX certificate generator
│       ├── capstudio_setup.iss       # Inno Setup Windows installer script
│       └── create_deb.sh             # Debian Linux package builder
└── lib/                              # Flutter & Dart application source
    ├── app/                          # App lifecycle, routing, theme system
    │   ├── routes.dart               # GoRouter declarative navigation
    │   ├── theme.dart                # AppTheme design tokens & glassmorphism
    │   ├── theme_palettes.dart       # Accent palettes (Emerald, Violet, Sunset, Cyan, etc.)
    │   └── theme_provider.dart       # Theme mode state notifier (Dark / Light / OLED)
    ├── core/                         # Cross-cutting foundational services
    │   ├── assets/                   # Asset packaging & pack download service
    │   ├── audio/                    # Waveform generation, audio mastering, SFX synthesizer
    │   ├── brand/                    # Brand kit presets, custom watermarks, logos
    │   ├── collaboration/            # Local collaborative editing & comment markers
    │   ├── database/                 # Isar service, schemas (Project, Word), Web DB helper
    │   ├── downloader/               # Robust HTTP binary downloader with SHA-256 verifier
    │   ├── emoji/                    # Twemoji / Noto / APNG animated emoji engine
    │   ├── ffmpeg/                   # FFmpeg detection, verification, and path locator
    │   ├── fonts/                    # Dynamic TTF/OTF font registry & loader
    │   ├── initialization/           # App bootstrap orchestrator & disk health probe
    │   ├── logger/                   # Tiered logger (Trace, Debug, Info, Warn, Error)
    │   ├── plugins/                  # Dynamic plugin architecture & hooks
    │   ├── project/                  # Project file serialization (.capstudio export/import)
    │   ├── settings/                 # Local preferences & settings service
    │   ├── subtitle/                 # SRT, VTT, and ASS subtitle parsers and formatters
    │   ├── utils/                    # AppDirs path resolver, CPU AVX detector, native helpers
    │   ├── video/                    # Video probe, silence detector, aspect ratio reframe, viral hooks
    │   └── whisper/                  # Whisper FFI bindings, models catalog, cancellation tokens
    └── features/                     # Feature modules (Clean Architecture)
        ├── dashboard/                # Project library, import dialog, disk space banners
        ├── editor/                   # Main caption studio
        │   ├── domain/               # CaptionEngine, style templates, B-roll models
        │   └── presentation/
        │       ├── controllers/      # EditorController + Mixins (core, word, history, trim, etc.)
        │       └── widgets/          # Timeline, video player, caption overlay, panels/
        ├── exporter/                 # Export modal, ASS script generation, FFmpeg filters, progress sheet
        ├── onboarding/               # First-run walkthrough & asset folder recovery
        └── settings/                 # App settings, language selection, hardware encoder diagnostics
```

---

## Coding Standards & Architectural Guidelines

### 1. State Management: Riverpod Pattern
- Riverpod 2.6+ is the primary state management solution across CapStudio.
- Controllers inherit from `StateNotifier<T>` or `Notifier<T>`.
- The main `EditorController` employs mixins to maintain modularity:
  - `EditorCoreMixin`: Playhead position, playback state, project reference.
  - `EditorWordOpsMixin`: Subtitle chunk splitting, merging, timing adjustment, text editing.
  - `EditorTrimStyleMixin`: Video range trimming, global style application.
  - `EditorHistoryMixin`: Unlimited undo/redo stack via snapshots.
  - `EditorProjectOpsMixin`: Auto-saving, project rename, export triggering.
  - `EditorCollaborationMixin`: Comment markers and review tracking.

### 2. Design System: Semantic AppTheme Tokens
- **NEVER hardcode raw colors** like `Colors.white`, `Colors.black`, `Colors.grey`, or `Color(0xFF...)` in UI widgets.
- Always reference theme tokens from `AppTheme`:
  - `AppTheme.primaryText` / `AppTheme.secondaryText` / `AppTheme.mutedText`
  - `AppTheme.cardBg` / `AppTheme.cardBgLight` / `AppTheme.modalBg`
  - `AppTheme.borderGlass` / `AppTheme.borderLight`
  - `AppTheme.accent` / `AppTheme.accentGlow`
  - `AppTheme.cardDecoration` / `AppTheme.glassDecoration`
  - `AppTheme.premiumSliderTheme(context)`

### 3. File System & Path Resolution: AppDirs Singleton
- Never call `getApplicationSupportDirectory()` or hardcode `%APPDATA%` directly in feature code.
- Always use the centralized `AppDirs` helper (`lib/core/utils/app_dirs.dart`):
  - `AppDirs.support`: Root data directory (`%APPDATA%\CapStudio\` on Windows, `~/Library/Application Support/CapStudio/` on macOS, `~/.local/share/CapStudio/` on Linux).
  - `AppDirs.models`: Model weights storage (`.../models/`).
  - `AppDirs.fonts`: Custom and system fonts (`.../fonts/`).
  - `AppDirs.bin`: Platform-specific standalone binaries (`.../bin/`).
  - `AppDirs.logs`: Application diagnostic log files (`.../logs/`).
- Always verify `AppDirs.isInitialized` before accessing directories in unit tests or headless contexts.

### 4. Database Layer: Isar Community
- Schemas (`ProjectSchema`, `WordSchema`, `VideoSegmentSchema`, `StyleConfigSchema`) are defined in `lib/core/database/schemas/`.
- Never execute long-running database transactions on the UI thread.
- For web builds, the Isar service gracefully routes to `WebDbHelper` using indexedDB / local storage fallback.

---

## Testing & Quality Verification

Before declaring any task or PR complete, run the verification pipeline:

1. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   Must pass with **zero warnings and zero errors**.

2. **Automated Unit & Widget Tests**:
   ```bash
   flutter test
   ```
   All tests (831+) must pass.
   - Tests validating error handling or security boundaries (Zip slip prevention, checksum verification, process failure recovery) intentionally emit `ERROR` or `WARN` log statements. These are expected when wrapped in test assertions.

3. **No-Pub Enforcement in CI**:
   - In `.github/workflows/build.yml`, build steps use `--no-pub` because an explicit `flutter pub get` step runs beforehand. Do not remove `--no-pub` from compile tasks.

---

## Multi-Platform Release Matrix

| Category | Platform | Target Architecture | Distribution Artifact |
| :--- | :--- | :--- | :--- |
| **Category A: App Packages** | Windows | x64 | `CapStudio-Windows-x64.zip` (Portable), `CapStudio-Windows-x64.msix` (UWP Store), `CapStudio-Setup-Windows-x64.exe` (Inno Setup) |
| | macOS | Universal (Apple Silicon M1-M4 & Intel x86_64) | `CapStudio-macOS-Universal.dmg` |
| | Linux | x86_64 (amd64) | `capstudio_*.deb` (Debian/Ubuntu), `CapStudio-Linux-x64.tar.gz` (Portable), `CapStudio-Linux-x86_64.AppImage` (Universal) |
| | Android | Universal FAT & Split ABIs | `CapStudio-Android-Universal.apk`, `CapStudio-Android-arm64-v8a.apk`, `CapStudio-Android-armeabi-v7a.apk`, `CapStudio-Android-x86_64.apk`, `CapStudio-Android.aab` (Google Play) |
| | iOS | arm64 (iOS 16.0+) | `CapStudio-iOS-arm64.tar.gz` (`Runner.app`) |
| | Web | WASM / CanvasKit | `CapStudio-Web.zip` |
| **Category B: Standalone Binaries** | Windows | x64 (AVX2), x64 (No-AVX), ARM64 | `whisper-cli-win-x64-avx.zip`, `whisper-cli-win-x64-noavx.zip`, `whisper-cli-win-arm64.zip`, `ffmpeg-windows.zip`, `ffmpeg-windows-arm64.zip` |
| | macOS | Universal (arm64 + x86_64) | `whisper-cli-mac-universal.zip`, `ffmpeg-macos.zip` |
| | Linux | x86_64, aarch64 (ARM64) | `whisper-cli-linux-x64.zip`, `whisper-cli-linux-arm64.zip`, `ffmpeg-linux.zip`, `ffmpeg-linux-arm64.zip` |
