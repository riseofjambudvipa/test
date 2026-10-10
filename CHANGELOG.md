# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Full 6-Platform Multi-Architecture Support**: Integrated smart CPU architecture probing across all desktop and mobile platforms. Automatically detects and downloads architecture-specific bundles: Windows x64 (AVX2 & No-AVX) and Windows ARM64 (Snapdragon X Elite / Surface), macOS Universal (Apple Silicon M1–M4 & Intel), Linux amd64 and Linux arm64 (aarch64).
- **Side-by-Side Open-Source License Preservation**: Enforced namespaced license file preservation (`whisper_LICENSE.txt` and `ffmpeg_LICENSE.txt`) within `AppDirs.bin`, preventing collision or overwrite between MIT and GPL licenses.
- **Companion SHA-256 Checksum Manifests**: Generated companion `.sha256` checksums for all emoji packs in `assets/archive/` and tracked them in Git while ignoring multi-gigabyte ZIP archives.
- **Test Suite Expansion**: Added comprehensive widget & unit test coverage for `ExportProgressSheet`, `TranscriptionPanel`, `DebugPanel`, `BatchExportSheet`, `AssetsFolderRecoveryScreen`, `AboutAppScreen`, `PackManagerScreen`, `ManualInstallBanner`, and license preservation, raising verified test suite to 598 passing tests (100% GREEN).
- **Editor Header Bar Localization**: Added localized tooltips and button text for Undo, Redo, Theme Palette, Settings, Return to Dashboard, and dynamic Save/Export controls.

### Changed
- **Downloader Architecture Modularization**: Refactored `BinaryDownloaderService` down to 856 lines (< 1,000 lines standard), extracting `ManualInstallStepsHelper` and `HttpFileDownloader` with HTTP 206 range resumption and exponential backoff.
- **Open-Source Documentation Accuracy**: Overhauled `docs/Monetization/MONETIZATION.md` to accurately document ethical open-source sustainability (store convenience packaging, BYOK AI, sponsorship) and eliminated inaccurate advertising SDK and offline blocking references.
- **Git Normalization & Binary Protection**: Audited `.gitattributes` and `.gitignore` across all 6 platforms, ensuring LF line endings for scripts/code, CRLF for Windows batch files, and preventing accidental commits of large asset zips.
- **Teardown & Import Resilience**: Enriched silent catch blocks during app teardown and style preset importing with contextual debug logging.
- **Audio Service Boot Optimization**: Lowered 44 startup SFX registration logs to debug level, eliminating console noise on initial boot.

## [1.1.0] - 2026-09-26

### Added
- **Dual-Mode Studio Theming Engine**: High-contrast true Studio Light mode (`ThemeType.cleanLight`) alongside 5 rich dark studio palettes (`obsidianAmber`, `neonCyberpunk`, `obsidianEmerald`, `royalAmethyst`, `sunsetSunrise`) with live gradient preview cards and header toggles.
- **NLE-Grade Timeline Zoom Bar**: Premiere/DaVinci style 28px compact zoom toolbar with incremental stepped zoom, continuous mini-slider, `1.0x` quick-reset badge, and zoom-to-fit action.
- **Centralized Architectural Utilities**: Centralized hex color conversions in `ColorUtils`, unified duration string formatting in `TimeFormatUtils`, and standardized `AppSectionHeader` & `AppSnackbar` components.

### Changed
- **Architectural File Modularization**: 100% of hand-written Dart files in `lib/` refactored strictly under 1,000 lines (all under 950 lines), extracting `TimelineControls`, `ThemePalettes`, `GlassContainer`, `BinaryDownloadModels`, `BinaryVerifier`, `HoverableImportCard`, `BatchExportSheet`, and `ViralClippingCandidateCards`.
- **Complete Hardcoded Color Sweep**: Replaced 300+ hardcoded colors with dynamic semantic theme tokens across font settings, chunk headers, transcription panels, debug views, import sheets, viral batch export sheets, and startup error screens.

### Verified
- **Static Analysis**: Clean repository analysis with 0 errors, 0 warnings, and 0 lints (`flutter analyze --no-pub`).
- **Test Suite**: 583 automated unit and widget tests passing (100% GREEN, `flutter test --no-pub`).

## [1.0.0] - 2026-09-23

### Added
- **Universal 6-Platform Architecture**: Production-ready support for Windows (x64), macOS (Apple Silicon / Intel), Linux (Debian / tarball), Android (API 24–36, AAB / split APKs), iOS (iPhone / iPad, PhotoKit integration), and Web (offline-first PWA with SharedArrayBuffer).
- **Offline AI Transcription**: 100% on-device speech-to-text powered by `whisper.cpp` with Apple Silicon Metal, Android NEON, and x86 AVX2 acceleration.
- **Whisper FFI Progress Streaming & Atomic Cancellation**: Real-time progress updates (0%–100%) and instant abort via atomic thread-safe cancellation tokens.
- **Dynamic Tool Auto-Discovery**: Centralized `WhisperLocator` and `FfmpegLocator` dynamically discovering system paths, `AppDirs.bin`, `%PROGRAMFILES%`, and Homebrew without hardcoded paths or fixed drive letters.
- **Smart SFX Loading with SHA-256 Manifest**: Audio synthesis engine verifies `.sfx_manifest.json` checksums on launch to eliminate duplicate disk synthesis and editor opening latency.
- **Offline Viral Short-Form Clipping Engine**: Automated silence detection and viral hook scoring with customizable segment durations and 9:16 vertical video conversion.
- **Dynamic Audio Waveform Caching**: Float32 binary disk cache (`.wf`) with dynamic sample density and responsive zooming.
- **Expanded Professional Keyboard Shortcuts**: Quick tab switching (`Ctrl+1`..`Ctrl+4`), quick export (`Ctrl+E`), timeline scrubbing (`Home`, `End`, `Shift+Arrows`), and categorized shortcut overlay.
- **Full 12-Language ARB Localization**: Complete UI localization scaffolding across English, Arabic, German, Spanish, French, Hindi, Japanese, Korean, Portuguese, Russian, Turkish, and Simplified Chinese.
- **Store Readiness & Distribution Packaging**: Complete Google Play Data Safety declaration, Apple App Review notes with zero-red-flag permissions, Microsoft Store `runFullTrust` justification, Inno Setup installer script, and Debian package generator.

### Optimized
- **UI/UX Elevation**: Modernized dark theme palettes with elevated card tokens, refined glass alpha borders, and consistent spacing constants.
- **Rendering Performance**: Repaint isolation separating static waveform rendering (`TimelineWaveformPainter`) from dynamic playhead animation (`TimelinePlayheadPainter`).
- **Asset Footprint**: Pruned 2.34 GB of redundant unreferenced emoji packs; on-demand dynamic font downloading for CJK language subsets.

### Security & Privacy
- **100% On-Device Privacy**: Zero telemetry, zero cloud uploads, zero background tracking.
- **Automatic Path PII Scrubbing**: All logs, errors, and subprocess commands scrub user home directory paths and sensitive identifiers.
- **Fail-Closed Checksum Verification**: Enforced SHA-256/SHA-1 verification for all on-demand model and binary downloads.
