/// Emoji picker UI — split into focused modules:
///
///   emoji_pack_meta.dart         — shared pack catalog ([kEmojiPackMeta])
///   emoji_tile.dart              — single-emoji tile with skin-tone popup
///   emoji_picker_dialog.dart     — full picker dialog ([EmojiPickerDialog])
///   emoji_settings_dialog.dart   — per-word emoji settings ([EmojiSettingsDialog])
///
/// This file is kept as a barrel so existing imports (`word_panel.dart`)
/// keep working unchanged.
library;

export 'emoji_pack_meta.dart';
export 'emoji_picker_dialog.dart';
export 'emoji_settings_dialog.dart';
export 'emoji_tile.dart';
