import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/utils/ass_position_utils.dart';
import 'package:capstudio/core/database/schemas/word.dart';

void main() {
  group('AssPositionUtils Tests', () {
    test('calculatePosition calculates centered X and scaled Y for standard text without emojis', () {
      final words = [
        WordSchema()..text = 'Hello'..start = 0.0..end = 1.0,
        WordSchema()..text = 'world'..start = 1.0..end = 2.0,
      ];

      final position = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: 80.0, // 80% down
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );

      // Centered X coordinate should be width / 2
      expect(position.x, equals(640.0));

      // Height scale is 720 / 640 = 1.125
      // Font size scales to 32.0 * 1.125 = 36.0
      // 1 line of height T = 36.0 + 4.0 * 1.125 = 40.5
      // topFraction = 80 / 100 = 0.8
      // yTop = (720 - T) * topFraction = (720 - 40.5) * 0.8 = 679.5 * 0.8 = 543.6
      // yTextCenter = yTop + T / 2 = 543.6 + 20.25 = 563.85
      expect(position.y, closeTo(563.85, 0.01));
    });

    test('calculatePosition clamps styleTop to 5% and 95%', () {
      final words = [
        WordSchema()..text = 'Clamp'..start = 0.0..end = 1.0,
      ];

      // Test extreme low styleTop (clamped to 5% -> 0.05)
      final positionLow = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: -10.0,
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );

      // Test extreme high styleTop (clamped to 95% -> 0.95)
      final positionHigh = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: 150.0,
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );

      // Verify that the Y coordinate is different due to clamping
      expect(positionLow.y, isNot(equals(positionHigh.y)));

      // Lower bound check:
      // T = 40.5
      // yTopLow = (720 - 40.5) * 0.05 = 679.5 * 0.05 = 33.975
      // yTextCenterLow = 33.975 + 20.25 = 54.225
      expect(positionLow.y, closeTo(54.225, 0.01));

      // Upper bound check:
      // yTopHigh = (720 - 40.5) * 0.95 = 679.5 * 0.95 = 645.525
      // yTextCenterHigh = 645.525 + 20.25 = 665.775
      expect(positionHigh.y, closeTo(665.775, 0.01));
    });

    test('calculatePosition shifts Y down when emoji is present in the word list', () {
      final words = [
        WordSchema()
          ..text = 'Smile'
          ..start = 0.0
          ..end = 1.0
          ..emoji = 'smile_emoji_path'
          ..emojiConfig = (EmojiConfigSchema()..scale = 1.2),
      ];

      final position = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: 50.0, // 50%
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );

      // X should still be centered
      expect(position.x, equals(640.0));

      // Scale is 1.125
      // Text height T = 40.5
      // E = 80 * 1.125 = 90.0 (Layout height remains independent of scale)
      // G = 12 * 1.125 = 13.5
      // Total height H = E + G + T = 90.0 + 13.5 + 40.5 = 144.0
      // yTop = (720 - 144.0) * 0.5 = 576.0 * 0.5 = 288.0
      // yTextCenter = yTop + E + G + T / 2 = 288.0 + 90.0 + 13.5 + 20.25 = 411.75
      expect(position.y, closeTo(411.75, 0.01));
    });

    test('calculatePosition calculates custom X coordinate when styleLeft is provided', () {
      final words = [
        WordSchema()..text = 'LeftAlign'..start = 0.0..end = 1.0,
      ];

      // 20% from left edge of 1280 wide video
      final positionLeft = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: 50.0,
        styleLeft: 20.0,
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );
      expect(positionLeft.x, equals(256.0)); // 1280 * 0.20

      // 80% from left edge of 1280 wide video
      final positionRight = AssPositionUtils.calculatePosition(
        projectWidth: 1280,
        projectHeight: 720,
        styleTop: 50.0,
        styleLeft: 80.0,
        fontFamily: 'Montserrat',
        fontSize: 32.0,
        fontWeight: '700',
        letterSpacing: 0.0,
        words: words,
      );
      expect(positionRight.x, equals(1024.0)); // 1280 * 0.80
    });

    test('calculatePosition clamps styleLeft to 5% and 95%', () {
      final words = [
        WordSchema()..text = 'ClampX'..start = 0.0..end = 1.0,
      ];

      final positionMin = AssPositionUtils.calculatePosition(
        projectWidth: 1000,
        projectHeight: 640,
        styleTop: 50.0,
        styleLeft: -25.0, // should clamp to 5%
        fontFamily: 'Montserrat',
        fontSize: 24.0,
        fontWeight: '500',
        letterSpacing: 0.0,
        words: words,
      );
      expect(positionMin.x, equals(50.0)); // 1000 * 0.05

      final positionMax = AssPositionUtils.calculatePosition(
        projectWidth: 1000,
        projectHeight: 640,
        styleTop: 50.0,
        styleLeft: 150.0, // should clamp to 95%
        fontFamily: 'Montserrat',
        fontSize: 24.0,
        fontWeight: '500',
        letterSpacing: 0.0,
        words: words,
      );
      expect(positionMax.x, equals(950.0)); // 1000 * 0.95
    });
  });
}
