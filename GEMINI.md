# CapStudio — Gemini & Antigravity Guide

This repository uses [AGENTS.md](./AGENTS.md) as its primary source of truth for AI agents.

## Quick Context
- **Framework**: Flutter 3.44.0 (Channel stable), Dart 3.9+
- **Architecture**: Clean Architecture with Riverpod 2.6+ state management
- **Database**: Isar Community 3.3.2 (embedded reactive NoSQL)
- **Speech-to-Text**: Whisper.cpp C++ FFI (native) & Transformers.js WASM (Web)
- **Video Rendering**: FFmpeg 7.1 static binaries & filters pipeline
- **License**: Strictly **GNU General Public License v3.0 (GPL-3.0-only)**. Never MIT.

## Mandatory Git Rules
- Author must ALWAYS be:
  `--author="riseofjambudvipa <riseofjambudvipa@gmail.com>"`
- Git push synchronization across branches and tag:
  `git push origin master; git push origin master:main; git tag -f test; git push origin -f test`
- Use `;` instead of `&&` in Windows PowerShell.

## Specialized Skills Available
Check the `.agents/skills/` directory for deep domain runbooks:
- `whisper-stt`: Speech recognition, quantized models, cancellation tokens, language detection.
- `ffmpeg-pipeline`: Video filtering, hardware acceleration probes, ASS subtitle burning, audio mastering.
- `caption-engine`: Styling templates, karaoke word animations, font registration, emoji support.
- `capstudio-architecture`: Riverpod controller mixins, Isar schemas, AppDirs directory standards, semantic AppTheme tokens.
- `multi-platform-ci`: Multi-architecture release matrix, GitHub Actions workflow, packaging scripts.

## Quality Assurance Commands
```bash
# Static analysis
flutter analyze

# Run complete test suite (831 tests)
flutter test
```
Both must pass with zero issues before finishing any task.
