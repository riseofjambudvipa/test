---
name: capstudio-architecture
description: >-
  Architectural blueprint and coding standards for CapStudio: Riverpod controller mixins,
  Isar database schemas, AppDirs storage paths, and AppTheme design tokens.
---

# CapStudio Architecture & Clean Code Standards

CapStudio follows **Clean Architecture** principles combined with Flutter Riverpod state management and an embedded NoSQL database.

## Layer Boundaries

```
lib/
├── app/          # App initialization, routing, theme system
├── core/         # Cross-cutting foundational services & utilities
└── features/     # Feature modules (Domain, Presentation, Data)
```

1. **Domain Layer**: Pure Dart entities, value objects, and business algorithms (`lib/features/editor/domain/`). Free of Flutter UI dependencies.
2. **Data Layer**: Repositories, database services, network clients, and OS bridges (`lib/core/database/`, `lib/features/exporter/data/`).
3. **Presentation Layer**: State management (Riverpod controllers), responsive layouts, and UI widgets (`lib/features/editor/presentation/`).

## Riverpod Controller Mixin Architecture

To prevent massive "God controllers", `EditorController` (`lib/features/editor/presentation/controllers/editor_controller.dart`) decomposes operations across specialized mixins:

```dart
class EditorController extends StateNotifier<EditorState>
    with
        EditorCoreMixin,
        EditorWordOpsMixin,
        EditorTrimStyleMixin,
        EditorHistoryMixin,
        EditorProjectOpsMixin,
        EditorCollaborationMixin {
  EditorController(this.ref) : super(EditorState.initial());
  final Ref ref;
}
```

- **`EditorCoreMixin`**: Playhead scrub, play/pause, volume, zoom level.
- **`EditorWordOpsMixin`**: Add caption chunk, delete chunk, merge adjacent chunks, split at cursor, edit text, toggle highlight.
- **`EditorTrimStyleMixin`**: Video in/out trim handles, style presets, color adjustments.
- **`EditorHistoryMixin`**: Snapshot-based undo and redo history stack.
- **`EditorProjectOpsMixin`**: Reactive project saving, renaming, deleting, asset relinking.
- **`EditorCollaborationMixin`**: Marker comments and team review flags.

## Database Guidelines (`Isar Community 3.3.2`)

- Primary schema: `Project` (`lib/core/database/schemas/project.dart`).
- Contains embedded sub-schemas:
  - `List<Word>`: Complete transcription words.
  - `StyleConfigSchema`: Font family, font size, colors, animations, alignment.
  - `List<VideoSegmentSchema>`: Video trim cuts and timeline sequences.
- On Web (`kIsWeb`), `WebDbHelper` transparently backs storage using IndexedDB.
- Never block the UI thread with synchronous schema migrations.

## Centralized Path Management (`AppDirs`)

`lib/core/utils/app_dirs.dart` is the sole source of truth for platform paths:

```dart
// Check initialization before accessing in tests/headless routines:
if (AppDirs.isInitialized) {
  final fontPath = AppDirs.fonts;
}
```

- **Windows**: `%APPDATA%\CapStudio\` (Clean single folder, avoids double-nested `CapStudio\CapStudio`).
- **macOS**: `~/Library/Application Support/CapStudio/`.
- **Linux**: `~/.local/share/CapStudio/`.
- Subdirectories: `bin/`, `models/`, `fonts/`, `logs/`.

## Design System Tokens (`AppTheme`)

- **Never use hardcoded `Colors.*`** (`Colors.white`, `Colors.black`, etc.).
- Always use semantic tokens:
  ```dart
  // Correct:
  color: AppTheme.primaryText
  decoration: AppTheme.cardDecoration
  border: Border.all(color: AppTheme.borderGlass)

  // Incorrect:
  color: Colors.white
  decoration: BoxDecoration(color: Color(0xFF1E1E1E))
  ```
- Support for accent palettes (`Emerald`, `Violet`, `Sunset`, `Cyan`) via `ThemePalettes`.
