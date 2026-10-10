import 'package:flutter/material.dart';

/// Centralized utility for color hex parsing, formatting, and manipulation.
class ColorUtils {
  ColorUtils._();

  /// Parses a hex color string (e.g. `#FFFFFF`, `FFFFFF`, `#AARRGGBB`, `#RRGGBB`)
  /// into a Flutter [Color]. Returns [fallback] if parsing fails.
  static Color fromHex(String? hex, {Color fallback = Colors.white}) {
    if (hex == null || hex.isEmpty) return fallback;
    var clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      clean = 'FF$clean';
    } else if (clean.length == 3) {
      clean = 'FF${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    } else if (clean.length != 8) {
      return fallback;
    }
    final val = int.tryParse(clean, radix: 16);
    if (val == null) return fallback;
    return Color(val);
  }

  /// Converts a [Color] into an 8-character `#AARRGGBB` hex string.
  static String toHex8(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Converts a [Color] into a 6-character `#RRGGBB` hex string (ignoring alpha).
  static String toHex6(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Returns high-contrast text color ([Colors.white] or [Colors.black])
  /// calculated from relative luminance.
  static Color contrastColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
