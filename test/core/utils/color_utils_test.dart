import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/utils/color_utils.dart';

void main() {
  group('ColorUtils.fromHex', () {
    test('parses 6-digit hex with hash', () {
      final color = ColorUtils.fromHex('#FF5722');
      expect(color.toARGB32(), equals(const Color(0xFFFF5722).toARGB32()));
    });

    test('parses 6-digit hex without hash', () {
      final color = ColorUtils.fromHex('FF5722');
      expect(color.toARGB32(), equals(const Color(0xFFFF5722).toARGB32()));
    });

    test('parses 8-digit hex (#AARRGGBB)', () {
      final color = ColorUtils.fromHex('#80FF5722');
      expect(color.toARGB32(), equals(const Color(0x80FF5722).toARGB32()));
    });

    test('parses 3-digit shorthand hex (#F52 -> #FF5522)', () {
      final color = ColorUtils.fromHex('#F52');
      expect(color.toARGB32(), equals(const Color(0xFFFF5522).toARGB32()));
    });

    test('returns fallback for null or empty string', () {
      expect(ColorUtils.fromHex(null, fallback: Colors.blue), equals(Colors.blue));
      expect(ColorUtils.fromHex('', fallback: Colors.green), equals(Colors.green));
    });

    test('returns fallback for invalid string length or chars', () {
      expect(ColorUtils.fromHex('invalid', fallback: Colors.red), equals(Colors.red));
      expect(ColorUtils.fromHex('#12', fallback: Colors.yellow), equals(Colors.yellow));
    });
  });

  group('ColorUtils toHex formatting', () {
    test('toHex6 formats correctly', () {
      expect(ColorUtils.toHex6(const Color(0xFFFF5722)), equals('#FF5722'));
      expect(ColorUtils.toHex6(const Color(0x80FF5722)), equals('#FF5722'));
    });

    test('toHex8 formats correctly', () {
      expect(ColorUtils.toHex8(const Color(0x80FF5722)), equals('#80FF5722'));
      expect(ColorUtils.toHex8(const Color(0xFFFF5722)), equals('#FFFF5722'));
    });
  });

  group('ColorUtils.contrastColor', () {
    test('returns black for light backgrounds', () {
      expect(ColorUtils.contrastColor(Colors.white), equals(Colors.black));
      expect(ColorUtils.contrastColor(Colors.yellow), equals(Colors.black));
      expect(ColorUtils.contrastColor(const Color(0xFFEEEEEE)), equals(Colors.black));
    });

    test('returns white for dark backgrounds', () {
      expect(ColorUtils.contrastColor(Colors.black), equals(Colors.white));
      expect(ColorUtils.contrastColor(const Color(0xFF1E1E1E)), equals(Colors.white));
      expect(ColorUtils.contrastColor(Colors.deepPurple), equals(Colors.white));
    });
  });
}
