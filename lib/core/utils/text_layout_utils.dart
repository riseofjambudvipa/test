// lib/core/utils/text_layout_utils.dart
import 'package:flutter/material.dart';
import '../database/schemas/word.dart';

class TextLayoutUtils {
  TextLayoutUtils._();

  static FontWeight parseFontWeight(String w) => switch (w) {
    '900'  => FontWeight.w900,
    '800'  => FontWeight.w800,
    '700' || 'bold' => FontWeight.bold,
    '600'  => FontWeight.w600,
    '500'  => FontWeight.w500,
    '300'  => FontWeight.w300,
    _      => FontWeight.normal,
  };

  /// Splits a list of words into lines using Flutter's TextPainter, ensuring that
  /// wrapping is calculated identically based on actual typography and max pixel width.
  static List<List<WordSchema>> splitWordsIntoLines({
    required List<WordSchema> words,
    required String fontFamily,
    required double fontSize,
    required String fontWeight,
    required double letterSpacing,
    required double maxPixelWidth,
  }) {
    final visibleWords = words.where((w) => w.hidden != true).toList();
    if (visibleWords.isEmpty) return [];

    final List<List<WordSchema>> result = [];
    List<WordSchema> currentLine = [];
    final fw = parseFontWeight(fontWeight);

    // Helper to calculate width of a line if we append a word to it
    double measureLineWidth(List<WordSchema> lineWords, [WordSchema? nextWord]) {
      final buffer = StringBuffer();
      for (int i = 0; i < lineWords.length; i++) {
        if (i > 0) buffer.write(' ');
        buffer.write(lineWords[i].text ?? '');
      }
      if (nextWord != null) {
        if (lineWords.isNotEmpty) buffer.write(' ');
        buffer.write(nextWord.text ?? '');
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: buffer.toString(),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fw,
            letterSpacing: letterSpacing,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      return textPainter.width;
    }

    for (final word in visibleWords) {
      if (currentLine.isEmpty) {
        currentLine.add(word);
      } else {
        final width = measureLineWidth(currentLine, word);
        if (width > maxPixelWidth) {
          result.add(currentLine);
          currentLine = [word];
        } else {
          currentLine.add(word);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      result.add(currentLine);
    }

    // Balance lines if there are exactly 2 lines to make it look premium
    if (result.length == 2) {
      final line1 = result[0];
      final line2 = result[1];
      final w1 = measureLineWidth(line1);
      final w2 = measureLineWidth(line2);

      final combined = [...line1, ...line2];
      if ((w1 - w2).abs() > (fontSize * 1.5) && combined.length >= 3) {
        int bestSplit = 1;
        double minDiff = 999999.0;
        for (int i = 1; i < combined.length; i++) {
          final l1 = combined.sublist(0, i);
          final l2 = combined.sublist(i);
          final width1 = measureLineWidth(l1);
          final width2 = measureLineWidth(l2);
          final diff = (width1 - width2).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestSplit = i;
          }
        }
        return [combined.sublist(0, bestSplit), combined.sublist(bestSplit)];
      }
    }

    return result;
  }
}
