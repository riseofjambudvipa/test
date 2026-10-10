# Contributing to CapStudio

Thank you for your interest in contributing to **CapStudio**! This is an open-source project dedicated to providing a 100% offline, privacy-first, professional AI video captioning and editing experience.

Contributions are welcome to fix bugs, optimize performance, improve localization, and enhance creator productivity.

Please review the guidelines below to ensure a smooth development process.

---

## 🛠️ Local Development Setup

To prepare your environment for contributing:

1. **Verify Prerequisites**: Ensure you have Flutter SDK (>= 3.22.0, recommended Flutter 3.44.0) and appropriate platform-specific compiler tools (Visual Studio C++ for Windows, Xcode for iOS/macOS, NDK for Android, or Linux dev headers) installed.
2. **Fork and Clone**: Fork the repository to your own GitHub account and clone it locally:
   ```bash
   git clone https://github.com/capstudio/capstudio.git
   cd capstudio
   ```
3. **Fetch Packages**:
   ```bash
   flutter pub get
   ```
4. **Vendored Dependencies & Schemas**:
   * Vendored third-party packages and submodules are kept under `third_party/` (such as `third_party/isar_community`, `third_party/whisper.cpp`, `third_party/cldr-json-main`). See [`third_party/README.md`](third_party/README.md) for details.
   * CapStudio uses pre-generated and hand-patched schemas for `isar_community`.
   > **CRITICAL WARNING:** `lib/core/database/schemas/word.g.dart` and `project.g.dart` contain 9 hand-patched `int.parse('...')` integer literals required for Web (dart2js) compilation. Do **not** run `build_runner` routinely unless you have modified schema models (`@collection`). If you must run `build_runner`, you must immediately re-apply the 9 `int.parse('...')` patches before compiling for Web.
   ```bash
   # ONLY run if you modified schemas in lib/core/database/schemas/
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## 🔄 Development & Contribution Workflow

We recommend the following steps when making changes:

### 1. Create a Branch
Create a descriptive local branch for your edits:
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b bugfix/issue-description
```

### 2. Code Quality & Formatting
* Keep the code clean, readable, and well-commented.
* Adhere to Flutter's official style guidelines.
* Run the formatter before committing:
  ```bash
  dart format lib/ test/
  ```

### 3. Verify Static Analysis
Ensure there are no compile-time warnings or analysis issues:
```bash
flutter analyze --no-pub
```

### 4. Run the Test Suite
Before opening a pull request, verify that all widget and unit tests pass successfully:
```bash
flutter test --no-pub
```

---

## 🧠 Architectural Guidelines

To maintain the core design principles of CapStudio, all contributions must respect the following rules:

1. **100% Offline Integrity**:
   * Do **not** add dependencies or code that make network requests to external APIs, metrics endpoints, or telemetry trackers. All data (videos, transcriptions, and database records) must remain strictly on the host device.
2. **Preserve Subsystem Separation**:
   * Keep low-level process managers (like `WhisperService` or `FFmpegService`) isolated inside `lib/core/`.
   * Keep feature screens, views, and UI controls isolated inside `lib/features/`.
3. **Strict Dual-Mode Theming & Contrast Integrity**:
   * Never hardcode `Colors.white`, `Colors.white70`, `Colors.black`, or raw hex colors for text and UI containers.
   * Always use semantic `AppTheme` tokens (`AppTheme.primaryText`, `AppTheme.secondaryText`, `AppTheme.cardBg`, `AppTheme.cardBgElevated`, `AppTheme.borderGlass`, `AppTheme.dividerColor`, `AppTheme.onAccentText`) so that Light and Dark modes maintain 100% readable contrast across all 5 studio palettes on all OS platforms.
4. **Multilingual-First Whisper Architecture**:
   * CapStudio is architected to be globally multilingual. All transcription modes resolve universally to standard multilingual models (`tiny`, `base`, `small`, `medium`, `large-v3-turbo`). Do not reintroduce separate `.en` single-language model branches.
5. **Whisper Compilation & Release Packaging**:
   * For Windows local builds (AVX2, generic non-AVX, and ARM64), use `third_party/scripts/build/package_whisper_windows.ps1`.
   * Cross-platform binaries (Windows x64/ARM64, macOS Universal M1–M4 & Intel, Linux x64/ARM64) are compiled and packaged automatically with SHA-256 checksums via the unified GitHub Actions CI workflow in `.github/workflows/build.yml`.
6. **File Size Limit**:
   * Keep source files modular and under 1,000 lines of code. Split complex controllers into clean mixins and decompose monolithic widgets into dedicated sub-widgets.

---

## 📜 Code of Conduct
Please review and follow our [Code of Conduct](CODE_OF_CONDUCT.md) in all project interactions.
