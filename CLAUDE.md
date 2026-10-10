# CapStudio — Claude Code Project Guidelines

See [AGENTS.md](./AGENTS.md) for the complete architectural and workflow specification.

## Core Commands
- `flutter analyze` : Run static code analysis (zero warnings/errors permitted).
- `flutter test` : Run automated test suite (831 tests must pass).
- `flutter run -d windows` / `macos` / `linux` : Run desktop development build.
- `flutter run -d chrome` : Run Web development build with CanvasKit/WASM.

## Git Attribution & Push Policy
- Author: Always specify `--author="riseofjambudvipa <riseofjambudvipa@gmail.com>"`.
- Push pattern: `git push origin master; git push origin master:main; git tag -f test; git push origin -f test`.
- Do not use `&&` in Windows PowerShell; use `;`.
- CapStudio is licensed under **GPL-3.0-only** (GNU General Public License v3.0).
