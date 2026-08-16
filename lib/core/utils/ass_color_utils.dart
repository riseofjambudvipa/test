/// Shared hex-to-ASS-color conversion used by both the burned-in export
/// path (ffmpeg_exporter.dart) and the standalone subtitle export path
/// (subtitle_exporter.dart).
///
/// FIX (Issue #11, CapStudio 1.0 audit): these two paths previously each had
/// their own independent implementation of this conversion. The core
/// RGB->BGR + alpha-inversion logic was identical, but only one of the two
/// validated its input against malformed hex strings before processing —
/// the other would happily run `.substring()` on garbage and produce an
/// invalid ASS color code instead of failing safely. Since both paths pull
/// from the exact same [ProjectConfigSchema] color fields, there was no
/// reason for them to behave differently on bad input. This is the single
/// implementation both should call.
class AssColorUtils {
  const AssColorUtils._();

  /// Fallback color returned for malformed or unrecognized hex input:
  /// solid (fully opaque) white.
  static const String fallbackWhite = '&H00FFFFFF&';

  /// Converts a hex color string (`#RRGGBB` or `#AARRGGBB`, `#` optional) to
  /// ASS/SSA's `&HAABBGGRR&` color format.
  ///
  /// ASS alpha is "transparency", the opposite of a typical alpha channel's
  /// "opacity" — so an 8-character input's alpha byte is inverted before
  /// being written out.
  ///
  /// Returns [fallbackWhite] if [hex] (after stripping a leading `#`) is not
  /// a valid 6- or 8-character hex string, rather than throwing or producing
  /// a malformed ASS color code.
  static String hexToAssColor(String hex) {
    final cleanHex = hex.replaceAll('#', '').trim();

    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleanHex)) {
      return fallbackWhite;
    }

    if (cleanHex.length == 6) {
      // RRGGBB -> AABBGGRR, default alpha 00 (fully opaque)
      final r = cleanHex.substring(0, 2);
      final g = cleanHex.substring(2, 4);
      final b = cleanHex.substring(4, 6);
      return '&H00$b$g$r&';
    } else if (cleanHex.length == 8) {
      // AARRGGBB -> (inverted A)BBGGRR
      final aVal = int.tryParse(cleanHex.substring(0, 2), radix: 16) ?? 255;
      final invertedA = (255 - aVal).toRadixString(16).padLeft(2, '0').toUpperCase();
      final r = cleanHex.substring(2, 4);
      final g = cleanHex.substring(4, 6);
      final b = cleanHex.substring(6, 8);
      return '&H$invertedA$b$g$r&';
    }

    return fallbackWhite;
  }
}
