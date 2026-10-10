---
name: caption-engine
description: >-
  Comprehensive guide for CapStudio's caption and subtitle rendering engine:
  ASS script generation, karaoke animations, word-level highlights, style templates,
  typography, and animated emoji integration.
---

# CapStudio Caption & Subtitle Engine

CapStudio delivers frame-accurate, beautifully animated captions using the **Advanced SubStation Alpha (`.ass`)** subtitle standard.

## Subtitle Data Model

- **`Word` (`lib/core/database/schemas/word.dart`)**:
  - `text`: Word content (e.g., `"Unstoppable"`).
  - `start`: Start timestamp in seconds (e.g., `1.42`).
  - `end`: End timestamp in seconds (e.g., `1.85`).
  - `confidence`: Whisper decoder log-probability (0.0 to 1.0).
  - `isHighlighted`: User or AI emphatic highlight flag.
  - `customColor`: Optional per-word hex color override.

- **`CaptionStyle` (`lib/features/editor/domain/caption_style.dart`)**:
  - `fontFamily`: Primary font family (e.g., `Komika Axis`, `Montserrat`, `TheBoldFont`).
  - `fontSize`: Base font size (scaled relative to video height).
  - `primaryColor` & `secondaryColor`: Text face color & karaoke fill color.
  - `outlineColor` & `outlineWidth`: Border outline thickness.
  - `shadowColor` & `shadowDepth`: Drop shadow offset.
  - `alignment`: Screen placement (Bottom Center = 2, Middle Center = 5, Top Center = 8).
  - `animationType`: Dynamic animation mode.

## Animation & Karaoke Modes

`AssScriptBuilder` (`lib/features/exporter/data/ass_script_builder.dart`) translates timing into ASS override tags:

1. **Word-by-Word Karaoke (`{\k<duration>}`)**:
   - Sweeps the highlight color across each word in exact sync with audio:
     ```
     Dialogue: 0,0:00:01.42,0:00:03.10,Default,,0,0,0,,{\k43}Never {\k52}stop {\k73}building
     ```
2. **Pop & Bounce Scale Animation (`{\t(\fscx\fscy)}`)**:
   - The active word pops outward (115% scale) at trigger time, then bounces back to 100%:
     ```
     Dialogue: 0,0:00:01.42,0:00:01.85,Default,,0,0,0,,{\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Unstoppable
     ```
3. **Typewriter Effect**:
   - Words appear sequentially as they are spoken, with prior words remaining fixed.
4. **Glow / Neon Shadow (`{\blur<radius>}`)**:
   - High-intensity diffuse glow for cyber, gaming, and viral short aesthetics.
5. **Color Box Highlight**:
   - Places a rounded tinted bounding box behind the active word.

## Typography & Font Management

- Bundled fonts reside in `assets/fonts/` (Komika Axis, Montserrat Bold, TheBoldFont, Roboto, Oswald, Poppins).
- Custom user-imported fonts (`.ttf` / `.otf`) are registered via `FontService` (`lib/core/fonts/font_service.dart`) and copied to `AppDirs.fonts`.
- On Linux and Windows, ASS font names must match the font's internal PostScript / Full Name, not just the file basename.

## Emoji Engine (`EmojiService`)

- CapStudio supports inline emojis alongside captions:
  - **Noto Color Emoji**: Static high-res Unicode color glyphs.
  - **Animated APNG Emojis**: Dynamic Google animated emoji packs (`assets/emojis/`).
- `EmojiService` resolves shortcodes (e.g., `:fire:`, `:rocket:`, `:100:`) into cached APNG sequences.
- On export, animated emojis are rendered either via ASS graphic overlays or composite FFmpeg filter overlays.
