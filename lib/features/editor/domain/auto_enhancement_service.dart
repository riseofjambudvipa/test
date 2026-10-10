import '../../../../core/database/schemas/word.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../../../core/plugins/plugin_manager_service.dart';

/// Service providing AI/algorithmic enhancement for captions:
/// 1. Magic Emojis — auto-assigns contextual emojis to keywords (like Submagic)
/// 2. Magic SFX — auto-assigns punchy sound effects to transition/impact words
/// 3. Filler Word Remover — auto-detects and hides speech hesitations (like Descript)
class AutoEnhancementService {
  AutoEnhancementService._internal();
  static final AutoEnhancementService instance = AutoEnhancementService._internal();

  /// Curated keyword-to-emoji dictionary mapping high-frequency English/international
  /// hook & emotion words to their universal unicode emoji glyphs.
  static const Map<String, String> emojiKeywordDictionary = {
    // Fire & Energy
    'fire': '🔥',
    'hot': '🔥',
    'lit': '🔥',
    'burn': '🔥',
    'flame': '🔥',
    'energy': '⚡',
    'fast': '⚡',
    'speed': '⚡',
    'power': '⚡',
    'electric': '⚡',
    'rocket': '🚀',
    'launch': '🚀',
    'scale': '🚀',
    'grow': '📈',
    'growth': '📈',

    // Money & Wealth
    'money': '💰',
    'cash': '💵',
    'dollar': '💵',
    'dollars': '💵',
    'rich': '🤑',
    'wealth': '💎',
    'diamond': '💎',
    'crypto': '🪙',
    'bitcoin': '🪙',
    'profit': '💸',
    'income': '💰',
    'revenue': '📊',
    'sales': '📈',
    'cost': '🏷️',
    'price': '🏷️',
    'expensive': '💳',
    'bank': '🏦',

    // Success & Winning
    'win': '🏆',
    'winner': '🏆',
    'victory': '🏆',
    'champion': '👑',
    'king': '👑',
    'queen': '👑',
    'crown': '👑',
    'best': '🥇',
    'first': '🥇',
    'top': '🔝',
    'star': '⭐',
    'goal': '🎯',
    'target': '🎯',
    'focus': '🎯',

    // Mind & Ideas
    'brain': '🧠',
    'mind': '🧠',
    'think': '🤔',
    'idea': '💡',
    'secret': '🤫',
    'trick': '🪄',
    'magic': '✨',
    'solution': '🔑',
    'key': '🔑',
    'hack': '⚡',
    'strategy': '♟️',
    'plan': '📋',

    // Danger & Warnings
    'danger': '⚠️',
    'warning': '⚠️',
    'alert': '🚨',
    'stop': '🛑',
    'never': '🚫',
    'fake': '❌',
    'wrong': '❌',
    'mistake': '🤦',
    'error': '💥',
    'risk': '💣',
    'dead': '💀',
    'skull': '💀',

    // Emotions & Reactions
    'love': '❤️',
    'heart': '❤️',
    'happy': '😊',
    'smile': '😄',
    'laugh': '😂',
    'funny': '🤣',
    'cry': '😭',
    'sad': '😢',
    'angry': '😡',
    'shocked': '😱',
    'shock': '😲',
    'wow': '🤯',
    'crazy': '🤪',
    'cool': '😎',
    'party': '🎉',
    'celebrate': '🥳',

    // Technology & Media
    'ai': '🤖',
    'robot': '🤖',
    'code': '💻',
    'computer': '💻',
    'laptop': '💻',
    'phone': '📱',
    'mobile': '📱',
    'video': '🎥',
    'camera': '📸',
    'audio': '🎙️',
    'music': '🎵',
    'podcast': '🎙️',
    'internet': '🌐',
    'world': '🌍',
    'earth': '🌍',

    // Lifestyle & Action
    'gym': '💪',
    'workout': '🏋️',
    'strong': '💪',
    'health': '🥗',
    'food': '🍕',
    'coffee': '☕',
    'drink': '🥤',
    'sleep': '😴',
    'travel': '✈️',
    'car': '🚗',
    'time': '⏰',
    'clock': '⏳',
    'future': '🔮',
    'book': '📖',
    'read': '📚',
    'learn': '🎓',
  };

  /// Curated keyword-to-SFX mapping for short-form video impact.
  static const Map<String, String> sfxKeywordDictionary = {
    // Money / Rewards -> Coin
    'money': 'coin',
    'cash': 'coin',
    'dollar': 'coin',
    'dollars': 'coin',
    'rich': 'coin',
    'profit': 'coin',
    'revenue': 'coin',
    'win': 'coin',
    'winner': 'coin',
    'winning': 'coin',
    'earn': 'coin',
    'price': 'coin',
    'paid': 'coin',

    // Pop / Clicks -> Pop
    'click': 'pop',
    'pop': 'pop',
    'look': 'pop',
    'see': 'pop',
    'here': 'pop',
    'check': 'pop',
    'simple': 'pop',
    'one': 'pop',
    'first': 'pop',
    'step': 'pop',

    // Fast transitions -> Whoosh
    'fast': 'whoosh_fast',
    'quick': 'whoosh_fast',
    'speed': 'whoosh_fast',
    'next': 'whoosh_fast',
    'then': 'whoosh_fast',
    'suddenly': 'whoosh_fast',
    'now': 'whoosh_fast',
    'switch': 'whoosh_fast',
    'change': 'whoosh_fast',
    'jump': 'whoosh_fast',

    // Ideas / Solutions -> Ding / Chime
    'idea': 'ding',
    'tip': 'ding',
    'smart': 'ding',
    'remember': 'ding',
    'rule': 'ding',
    'solution': 'ding',
    'answer': 'ding',
    'key': 'ding',
    'secret': 'ding',
    'magic': 'chime',
    'sparkle': 'sparkle',
    'perfect': 'sparkle',

    // High Impact / Shock -> Boom / Thud
    'crazy': 'boom',
    'huge': 'boom',
    'massive': 'boom',
    'insane': 'boom',
    'exploded': 'boom',
    'danger': 'boom',
    'shock': 'boom',
    'never': 'boom',
    'destroy': 'boom',
    'stop': 'stamp',
    'heavy': 'thud',

    // Warnings / Errors -> Bell / Glitch
    'warning': 'bell',
    'alert': 'bell',
    'notice': 'bell',
    'urgent': 'bell',
    'error': 'glitch',
    'mistake': 'glitch',
    'wrong': 'glitch',
    'fail': 'glitch',
    'glitch': 'glitch',
    'bug': 'glitch',
  };

  /// Common speech hesitations and filler phrases to detect and remove.
  static const Set<String> fillerWords = {
    'um',
    'uh',
    'umm',
    'uhm',
    'er',
    'ah',
    'like',
    'basically',
    'literally',
    'actually',
    'honestly',
    'sorta',
    'kinda',
    'you know',
  };

  /// Automatically assigns contextual emojis to matching words.
  /// Enforces spacing so at most 1 emoji is added every [minWordSpacing] words
  /// (default 4 words) to keep subtitles clean and professional.
  int autoApplyEmojis(
    List<WordSchema> words, {
    String pack = 'notoColorEmoji',
    int minWordSpacing = 4,
    bool overwriteExisting = false,
  }) {
    int addedCount = 0;
    int wordsSinceLastEmoji = minWordSpacing;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.hidden == true) continue;

      wordsSinceLastEmoji++;

      // Skip if already has an emoji and not overwriting
      if (!overwriteExisting && word.emoji != null && word.emoji!.isNotEmpty && word.emoji != 'none') {
        wordsSinceLastEmoji = 0;
        continue;
      }

      if (wordsSinceLastEmoji < minWordSpacing) continue;

      final clean = _cleanWord(word.text);
      if (clean.isEmpty) continue;

      String? matchedGlyph = emojiKeywordDictionary[clean];

      // Check active plugin custom emoji dictionaries
      if (matchedGlyph == null) {
        final pluginEmojis = PluginManagerService.instance.getActiveCustomEmojis();
        matchedGlyph = pluginEmojis[clean];
      }

      // If no direct keyword match, fallback to EmojiService search if available
      if (matchedGlyph == null && clean.length >= 3) {
        try {
          final results = EmojiService.instance.search(clean, limit: 1);
          if (results.isNotEmpty) {
            matchedGlyph = results.first.glyph;
          }
        } catch (_) {}
      }

      if (matchedGlyph != null && matchedGlyph.isNotEmpty) {
        word.emoji = '$pack:$matchedGlyph';
        word.emojiConfig = EmojiConfigSchema()
          ..x = 0.0
          ..y = 0.0
          ..scale = 1.0
          ..speed = 1.0;
        wordsSinceLastEmoji = 0;
        addedCount++;
      }
    }

    return addedCount;
  }

  /// Automatically assigns sound effects to transition and impact words.
  /// Enforces a minimum time gap of [minTimeGapSec] (default 3.0s) between SFX
  /// to ensure punchy pacing without audio fatigue.
  int autoApplySfx(
    List<WordSchema> words, {
    double minTimeGapSec = 3.0,
    int defaultVolume = 85,
    bool overwriteExisting = false,
  }) {
    int addedCount = 0;
    double lastSfxTimestamp = -minTimeGapSec;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.hidden == true) continue;

      final wordStart = word.start ?? 0.0;
      if (wordStart - lastSfxTimestamp < minTimeGapSec) continue;

      if (!overwriteExisting && word.soundEffect != null && word.soundEffect!.isNotEmpty) {
        lastSfxTimestamp = wordStart;
        continue;
      }

      final clean = _cleanWord(word.text);
      if (clean.isEmpty) continue;

      String? sfxId = sfxKeywordDictionary[clean];
      if (sfxId == null) {
        final pluginSfx = PluginManagerService.instance.getActiveCustomSfx();
        sfxId = pluginSfx[clean];
      }

      if (sfxId != null) {
        final sfxData = SfxData(
          word: SfxItem(sfxId, defaultVolume),
        );
        word.soundEffect = sfxData.toRaw();
        word.soundVolume = defaultVolume;
        lastSfxTimestamp = wordStart;
        addedCount++;
      }
    }

    return addedCount;
  }

  /// Detects filler words and marks them as hidden (`word.hidden = true`).
  /// Returns the number of filler words hidden.
  int removeFillerWords(List<WordSchema> words) {
    int removedCount = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.hidden == true) continue;

      final clean = _cleanWord(word.text);
      if (clean.isEmpty) continue;

      if (fillerWords.contains(clean)) {
        word.hidden = true;
        removedCount++;
      }
    }

    return removedCount;
  }

  /// Restores all hidden filler words.
  int restoreFillerWords(List<WordSchema> words) {
    int restoredCount = 0;

    for (final word in words) {
      if (word.hidden != true) continue;
      final clean = _cleanWord(word.text);
      if (fillerWords.contains(clean)) {
        word.hidden = false;
        restoredCount++;
      }
    }

    return restoredCount;
  }

  /// Counts the total number of detected filler words in the transcript.
  int countFillerWords(List<WordSchema> words) {
    int count = 0;
    for (final word in words) {
      final clean = _cleanWord(word.text);
      if (fillerWords.contains(clean)) {
        count++;
      }
    }
    return count;
  }

  /// Clears all emojis from all words.
  int clearAllEmojis(List<WordSchema> words) {
    int count = 0;
    for (final word in words) {
      if (word.emoji != null && word.emoji!.isNotEmpty && word.emoji != 'none') {
        word.emoji = null;
        word.emojiConfig = null;
        count++;
      }
    }
    return count;
  }

  /// Clears all sound effects from all words.
  int clearAllSfx(List<WordSchema> words) {
    int count = 0;
    for (final word in words) {
      if (word.soundEffect != null && word.soundEffect!.isNotEmpty) {
        word.soundEffect = null;
        word.soundVolume = null;
        count++;
      }
    }
    return count;
  }

  static String cleanWord(String? text) {
    if (text == null) return '';
    return text.toLowerCase().replaceAll(RegExp(r'[^\w]'), '').trim();
  }

  String _cleanWord(String? text) => cleanWord(text);
}
