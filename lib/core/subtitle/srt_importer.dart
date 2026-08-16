import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../database/schemas/word.dart';
import 'package:uuid/uuid.dart';

class SrtImporter {
  static const _uuid = Uuid();

  /// Parse an SRT or VTT file and return a list of WordSchema objects
  static Future<List<WordSchema>> importSrt(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return parseSrtBytes(bytes);
  }

  /// Parse SRT or VTT bytes and return a list of WordSchema objects
  static List<WordSchema> parseSrtBytes(Uint8List bytes) {
    if (bytes.isEmpty) return [];

    String content = "";
    // 1. UTF-8 BOM check: 0xEF, 0xBB, 0xBF
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      content = utf8.decode(bytes.sublist(3));
    }
    // 2. UTF-16 LE BOM check: 0xFF, 0xFE
    else if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      content = _decodeUtf16Le(bytes.sublist(2));
    }
    // 3. UTF-16 BE BOM check: 0xFE, 0xFF
    else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      content = _decodeUtf16Be(bytes.sublist(2));
    }
    // 4. Default to standard UTF-8, fallback to Latin1 if it fails
    else {
      try {
        content = utf8.decode(bytes);
      } on FormatException {
        content = latin1.decode(bytes);
      }
    }

    final List<WordSchema> words = [];
    
    // Normalize line endings and split by double line breaks (subtitle blocks)
    final String normalized = content.replaceAll('\r\n', '\n');
    final List<String> blocks = normalized.trim().split(RegExp(r'\n\s*\n'));

    for (final String block in blocks) {
      final List<String> lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      // Find the timecode line (usually line index 1, but VTT or bad formatting could push it)
      String? timecode;
      int textStartIndex = 2;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timecode = lines[i];
          textStartIndex = i + 1;
          break;
        }
      }
      
      if (timecode == null) continue;

      final parts = timecode.split('-->');
      if (parts.length != 2) continue;

      final double? startSec = _parseTimecode(parts[0]);
      final double? endSec = _parseTimecode(parts[1]);

      if (startSec == null || endSec == null) continue;

      if (textStartIndex >= lines.length) continue;
      
      final String text = lines.sublist(textStartIndex).join(' ').trim();
      if (text.isEmpty) continue;
      
      // Clean HTML/style tags (common in ASS or styled VTT)
      final String cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'{[^}]*}'), '').trim();
      if (cleanText.isEmpty) continue;
      
      // Enforce valid positive timecode windows to prevent timeline overlaps and layout crashes
      var activeEnd = endSec;
      if (activeEnd <= startSec) {
        activeEnd = startSec + 1.0; // fallback to 1-second duration
      }
      
      // Split text into individual words
      final List<String> textWords = cleanText.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
      if (textWords.isEmpty) continue;
      
      final double wordDuration = (activeEnd - startSec) / textWords.length;

      for (int i = 0; i < textWords.length; i++) {
        final word = WordSchema()
          ..wordId = _uuid.v4()
          ..text = textWords[i]
          ..start = startSec + i * wordDuration
          ..end = startSec + (i + 1) * wordDuration
          ..type = 'word'
          ..confidence = 1.0;
        words.add(word);
      }
    }
    return words;
  }

  static String _decodeUtf16Le(List<int> bytes) {
    final codeUnits = <int>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final unit = bytes[i] | (bytes[i + 1] << 8);
      codeUnits.add(unit);
    }
    return _convertUtf16CodeUnitsToString(codeUnits);
  }

  static String _decodeUtf16Be(List<int> bytes) {
    final codeUnits = <int>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final unit = (bytes[i] << 8) | bytes[i + 1];
      codeUnits.add(unit);
    }
    return _convertUtf16CodeUnitsToString(codeUnits);
  }

  static String _convertUtf16CodeUnitsToString(List<int> units) {
    final codePoints = <int>[];
    for (int i = 0; i < units.length; i++) {
      final value = units[i];
      if (value >= 0xD800 && value <= 0xDBFF && i + 1 < units.length) {
        final next = units[i + 1];
        if (next >= 0xDC00 && next <= 0xDFFF) {
          final codePoint = 0x10000 + ((value - 0xD800) << 10) + (next - 0xDC00);
          codePoints.add(codePoint);
          i++; // skip low surrogate
          continue;
        }
      }
      codePoints.add(value);
    }
    return String.fromCharCodes(codePoints);
  }

  static double? _parseTimecode(String tc) {
    tc = tc.trim();
    final match = RegExp(r'^(?:(?:(\d+):)?(\d+):)?(\d+)[,.](\d+)$').firstMatch(tc);
    if (match == null) return null;

    final hoursStr = match.group(1);
    final minsStr = match.group(2);
    final secsStr = match.group(3)!;
    final msStr = match.group(4)!;

    final double hours = hoursStr != null ? double.parse(hoursStr) : 0.0;
    final double mins = minsStr != null ? double.parse(minsStr) : 0.0;
    final double secs = double.parse(secsStr);
    final double msFraction = double.parse('0.$msStr');

    return hours * 3600.0 + mins * 60.0 + secs + msFraction;
  }
}
