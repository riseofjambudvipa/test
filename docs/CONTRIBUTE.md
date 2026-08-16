# Contributing to CapStudio

Thank you for your interest in contributing to **CapStudio**! This is a personal, open-source project. Contributions are welcome to fix bugs, optimize performance, and improve the offline-first creator experience.

Please review the guidelines below to ensure a smooth development process.

---

## 🛠️ Local Development Setup

To prepare your environment for contributing:

1. **Verify Prerequisites**: Ensure you have Flutter SDK (>= 3.22.0) and appropriate platform-specific compiler tools (Visual Studio C++ for Windows, Xcode for iOS/macOS, NDK for Android, or Linux dev headers) installed.
2. **Fork and Clone**: Fork the repository to your own GitHub account and clone it locally.
3. **Fetch Packages**:
   ```bash
   flutter pub get
   ```
4. **Generate Schemas and Mocks**:
   CapStudio uses `isar_generator` and `build_runner` for database mapping and code generation. Run the build command before running the app:
   ```bash
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
  flutter format lib/ test/
  ```

### 3. Verify Static Analysis
Ensure there are no compile-time warnings or analysis issues:
```bash
flutter analyze
```

### 4. Run the Test Suite
Before opening a pull request, verify that all widget and unit tests pass successfully:
```bash
flutter test
```

---

## 🧠 Architectural Guidelines

To maintain the core design principles of CapStudio, all contributions must respect the following rules:

1. **100% Offline Integrity**:
   * Do **not** add dependencies or code that make network requests to external APIs, metrics endpoints, or telemetry trackers. All data (videos, transcriptions, and database records) must remain strictly on the host device.
2. **Preserve Subsystem Separation**:
   * Keep low-level process managers (like `WhisperService` or `FFmpegService`) isolated inside `lib/core/`.
   * Keep feature screens, views, and UI controls isolated inside `lib/features/`.
3. **Optimize Asset Loading**:
   * Do not commit raw media or model files directly to the core assets folder unless they are essential default mock assets. Emojis and large Whisper models should be managed through the downloading paths or manual folder mapping.
