import '../database/schemas/word.dart';
import 'text_layout_utils.dart';

class AssPosition {
  final double x;
  final double y;
  
  const AssPosition(this.x, this.y);
}

class AssPositionUtils {
  /// Shared coordinate layout computation used by both standalone and burned-in ASS generators.
  static AssPosition calculatePosition({
    required double projectWidth,
    required double projectHeight,
    required double styleTop,
    double styleLeft = 50.0,
    required String fontFamily,
    required double fontSize,
    required String fontWeight,
    required double? letterSpacing,
    required List<WordSchema> words,
  }) {
    final double exportScale = projectHeight / 640.0;
    final double assFontSize = fontSize * exportScale;
    final double captionMaxW = projectWidth * 0.80;

    // 1. Check if chunk has emoji
    WordSchema? emojiWord;
    for (final w in words) {
      if (w.emoji != null && w.emoji!.isNotEmpty && w.emoji != 'none') {
        emojiWord = w;
        break;
      }
    }

    // 2. Wrap words into lines
    final lines = TextLayoutUtils.splitWordsIntoLines(
      words: words,
      fontFamily: fontFamily,
      fontSize: fontSize * exportScale,
      fontWeight: fontWeight,
      letterSpacing: (letterSpacing ?? 0.0) * exportScale,
      maxPixelWidth: captionMaxW,
    );

    // 3. Compute vertical center for text
    final double T = lines.length * (assFontSize + 4.0 * exportScale);
    final double topFraction = (styleTop / 100.0).clamp(0.05, 0.95);

    double yTextCenter;
    if (emojiWord != null) {
      final double E = 80.0 * exportScale;
      final double G = 12.0 * exportScale;
      final double H = E + G + T;
      final double yTop = (projectHeight - H) * topFraction;
      yTextCenter = yTop + E + G + T / 2.0;
    } else {
      final double H = T;
      final double yTop = (projectHeight - H) * topFraction;
      yTextCenter = yTop + T / 2.0;
    }

    // 4. Compute horizontal center for text using style.left
    final double leftFraction = (styleLeft / 100.0).clamp(0.05, 0.95);
    final double xTextCenter = projectWidth * leftFraction;

    return AssPosition(xTextCenter, yTextCenter);
  }
}
