/// Emoji pack catalog shared by the picker and settings dialogs.
///
/// FIX (Issue #6, CapStudio 1.0 audit): this was previously defined twice,
/// identically, as private `static const _packMeta` inside two separate
/// State classes (_EmojiPickerDialogState and _EmojiSettingsDialogState).
/// Both now reference this single shared copy.
const List<Map<String, String>> kEmojiPackMeta = [
  {'id': 'systemDefault', 'name': 'System Default'},
  {'id': 'googleAnimated', 'name': 'Google Noto 3D (Animated)'},
  {'id': 'googleNonAnimated', 'name': 'Google Noto Flat (Static)'},
  {'id': 'microsoftAnimated', 'name': 'Microsoft Fluent 3D (Animated)'},
  {'id': 'microsoftNonAnimated', 'name': 'Microsoft Fluent Flat (Static)'},
  {'id': 'openmoji', 'name': 'OpenMoji Color (Static)'},
  {'id': 'notoColorEmoji', 'name': 'Noto Color Emoji (Fallback)'},
];
