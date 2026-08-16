import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/subtitle/srt_importer.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('srt_test_');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  File createTempFile(String name, String content) {
    final file = File(p.join(tempDir.path, name));
    file.writeAsStringSync(content);
    return file;
  }

  File createTempFileWithBytes(String name, List<int> bytes) {
    final file = File(p.join(tempDir.path, name));
    file.writeAsBytesSync(bytes);
    return file;
  }

  group('SrtImporter Tests', () {
    test('parses standard SRT files correctly', () async {
      final file = createTempFile('test.srt', '''
1
00:00:01,000 --> 00:00:03,500
Hello world

2
00:00:04,100 --> 00:00:06,100
This is a test
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 6);
      expect(words[0].text, 'Hello');
      expect(words[0].start, closeTo(1.0, 0.001));
      expect(words[0].end, closeTo(2.25, 0.001));

      expect(words[1].text, 'world');
      expect(words[1].start, closeTo(2.25, 0.001));
      expect(words[1].end, closeTo(3.5, 0.001));

      expect(words[5].text, 'test');
      expect(words[5].start, closeTo(5.6, 0.001));
      expect(words[5].end, closeTo(6.1, 0.001));
    });

    test('parses WebVTT files correctly with dots in timestamp and WEBVTT header', () async {
      final file = createTempFile('test.vtt', '''
WEBVTT

1
00:00:01.000 --> 00:00:03.500
Hello world
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 2);
      expect(words[0].text, 'Hello');
      expect(words[0].start, closeTo(1.0, 0.001));
      expect(words[1].text, 'world');
      expect(words[1].end, closeTo(3.5, 0.001));
    });

    test('parses WebVTT files without block indices successfully', () async {
      final file = createTempFile('no_indices.vtt', '''
WEBVTT

00:00:01.200 --> 00:00:02.800
Dynamic subtitles

00:00:03.000 --> 00:00:04.000
No numbers
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 4);
      expect(words[0].text, 'Dynamic');
      expect(words[1].text, 'subtitles');
      expect(words[2].text, 'No');
      expect(words[3].text, 'numbers');
    });

    test('ignores blocks with malformed or missing timecodes gracefully', () async {
      final file = createTempFile('malformed.srt', '''
1
00:00:01,000 -> 00:00:03,500
No arrow pointer here

2
00:00:04,100 --> 00:00:06,100
This one is good

3
00:xx:07,000 --> 00:00:08,000
Letters in time stamp
''');

      final words = await SrtImporter.importSrt(file.path);
      // Only block 2 should be parsed: "This", "one", "is", "good" (4 words)
      expect(words.length, 4);
      expect(words[0].text, 'This');
      expect(words[3].text, 'good');
    });

    test('strips HTML styling tags from text', () async {
      final file = createTempFile('html.srt', '''
1
00:00:01,000 --> 00:00:03,000
<b>Bold</b> and <i>italic</i> with <font color="red">color</font>
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 5);
      expect(words[0].text, 'Bold');
      expect(words[2].text, 'italic');
      expect(words[4].text, 'color');
    });

    test('strips ASS styling tags from text', () async {
      final file = createTempFile('ass.srt', r'''
1
00:00:01,000 --> 00:00:03,000
{\an8}Centered text with {\blur3}blur effect
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 5);
      expect(words[0].text, 'Centered');
      expect(words[1].text, 'text');
      expect(words[3].text, 'blur');
      expect(words[4].text, 'effect');
    });

    test('handles empty or whitespace-only block text safely by omitting it', () async {
      final file = createTempFile('empty_blocks.srt', '''
1
00:00:01,000 --> 00:00:02,000


2
00:00:03,000 --> 00:00:04,000
   

3
00:00:05,000 --> 00:00:06,000
Valid text
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 2);
      expect(words[0].text, 'Valid');
      expect(words[1].text, 'text');
    });

    test('handles completely empty or garbage files without throwing exceptions', () async {
      final emptyFile = createTempFile('empty.srt', '');
      final garbageFile = createTempFile('garbage.srt', 'This is random junk content not matching SRT structure.');

      expect(await SrtImporter.importSrt(emptyFile.path), isEmpty);
      expect(await SrtImporter.importSrt(garbageFile.path), isEmpty);
    });

    test('handles inverted or zero time windows gracefully by falling back to positive duration', () async {
      final file = createTempFile('inverted.srt', '''
1
00:00:05,000 --> 00:00:02,000
Valid words with bad timings
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 5);
      expect(words[0].start, 5.0);
      expect(words[4].end, 6.0); // 5.0 + 1.0s fallback duration
      expect(words[0].end, greaterThan(words[0].start!)); // valid positive duration
    });

    test('skips blocks containing only styling tags and whitespace after cleanup', () async {
      final file = createTempFile('style_only.srt', '''
1
00:00:01,000 --> 00:00:03,000
<b><i> </i></b>

2
00:00:04,000 --> 00:00:05,000
Valid word
''');

      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 2);
      expect(words[0].text, 'Valid');
      expect(words[1].text, 'word');
    });

    test('parses UTF-8 with BOM correctly', () async {
      final bom = [0xEF, 0xBB, 0xBF];
      final utf8Bytes = utf8.encode('''1
00:00:01,000 --> 00:00:03,000
UTF8 BOM Test''');
      final file = createTempFileWithBytes('utf8_bom.srt', [...bom, ...utf8Bytes]);
      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 3);
      expect(words[0].text, 'UTF8');
    });

    test('parses UTF-16 LE with BOM correctly', () async {
      final bom = [0xFF, 0xFE];
      final content = '''1
00:00:01,000 --> 00:00:03,000
UTF16 LE Test''';
      final List<int> utf16Bytes = [];
      for (final char in content.codeUnits) {
        utf16Bytes.add(char & 0xFF);
        utf16Bytes.add((char >> 8) & 0xFF);
      }
      final file = createTempFileWithBytes('utf16_le.srt', [...bom, ...utf16Bytes]);
      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 3);
      expect(words[0].text, 'UTF16');
    });

    test('parses UTF-16 BE with BOM correctly', () async {
      final bom = [0xFE, 0xFF];
      final content = '''1
00:00:01,000 --> 00:00:03,000
UTF16 BE Test''';
      final List<int> utf16Bytes = [];
      for (final char in content.codeUnits) {
        utf16Bytes.add((char >> 8) & 0xFF);
        utf16Bytes.add(char & 0xFF);
      }
      final file = createTempFileWithBytes('utf16_be.srt', [...bom, ...utf16Bytes]);
      final words = await SrtImporter.importSrt(file.path);
      expect(words.length, 3);
      expect(words[0].text, 'UTF16');
    });

    test('falls back to Latin1 decoding when UTF-8 decoding throws FormatException', () async {
      // Byte 0xFF is invalid UTF-8 sequence, but valid Latin1
      final latin1Bytes = [
        ...utf8.encode('1\n00:00:01,000 --> 00:00:03,000\n'),
        0xFF, 0xFE, 0xFC,
      ];
      final file = createTempFileWithBytes('latin1.srt', latin1Bytes);
      final words = await SrtImporter.importSrt(file.path);
      expect(words, isNotEmpty);
    });
  });
}

