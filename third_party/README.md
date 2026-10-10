# Third-Party Dependencies

This directory contains external open-source dependencies vendored directly into the CapStudio codebase.

---

## Directory Overview

| Directory | Upstream Project | License | Purpose in CapStudio |
| :--- | :--- | :--- | :--- |
| `cldr-json-main/` | [Unicode CLDR Project](https://github.com/unicode-org/cldr-json) | Unicode License Agreement | Localized language names, locale manifests, and script descriptors for multilingual captioning and translation. |
| `isar_community/` | [Isar Community Fork](https://github.com/isar-community/isar) | Apache-2.0 | Local embedded database. Vendored here with modern Dart JS-interop stubs enabling Flutter Web (Wasm/dart2js) builds without legacy `dart:js`/`dart:html` compilation failures. Referenced via `dependency_overrides` in `pubspec.yaml`. |
| `scripts/` | CapStudio Build & Automation Suite | GPL-3.0 | 39 utility scripts across compilation, packaging (Inno Setup, deb), keystores, font downloading, emoji index generation, and test dashboards. See [`third_party/scripts/README.md`](scripts/README.md) for full manual. |
| `whisper.cpp/` | [whisper.cpp](https://github.com/ggml-org/whisper.cpp) | MIT | High-performance C/C++ inference engine for OpenAI Whisper speech recognition models. Used across desktop and mobile platforms for local, privacy-first transcription. |

---

## Maintenance & Upstream Sync

* **`third_party/isar_community`**: When updating Isar schema definitions or upstream versions, ensure web bindings in `lib/src/web/` retain compatibility with modern Dart SDK targets.
* **`third_party/whisper.cpp`**: Compiled into platform-specific CLI binaries and shared libraries via automated CI/CD workflows defined in `.github/workflows/build.yml`.
* **`third_party/scripts`**: Contains first-party and vendored build tooling; execute via PowerShell (Windows) or Bash (macOS/Linux).
