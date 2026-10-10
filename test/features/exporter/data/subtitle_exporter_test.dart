import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/exporter/data/subtitle_exporter.dart';
import '../../../helpers/project_fixture.dart';

void main() {
  group('SubtitleExporter Tests', () {
    late Project testProject;

    setUp(() {
      testProject = makeProject(
        projectId: 'test_export_proj',
        name: 'Export Project',
        videoPath: 'video.mp4',
        duration: 10.0,
        width: 1920,
        height: 1080,
        trimStart: 0.0,
        trimEnd: 10.0,
        status: 'draft',
        config: makeConfig(
          name: 'default',
          fontFamily: 'Montserrat',
          fontWeight: '900',
          textTransform: 'none',
          color: '#ffffff',
          fontSize: 24.0,
          top: 70.0,
          mainColor: '#f97316',
          secondColor: '#06b6d4',
          thirdColor: '#22c55e',
          chunkSize: 2,
          chunkLineMaxLength: 20,
          animation: 'pop',
          shadow: 'soft',
          stroke: 'none',
        ),
        words: [
          makeWord(wordId: 'w1', text: 'Hello', start: 1.0, end: 2.0, confidence: 0.95),
          makeWord(wordId: 'w2', text: 'world', start: 2.0, end: 3.0, confidence: 0.99, className: 'mainColor'),
          makeWord(wordId: 'w3', text: 'hidden', start: 3.0, end: 4.0, confidence: 0.8, hidden: true),
          makeWord(wordId: 'w4', text: 'test', start: 4.5, end: 5.5, confidence: 0.92, className: 'secondColor'),
        ],
      );
    });

    test('toSrt formats subtitles correctly', () {
      final srt = SubtitleExporter.toSrt(testProject);
      
      // Expected chunks (chunk size = 2):
      // Chunk 1: w1, w2 (Hello world) -> 1.00s to 3.00s
      // w3 is hidden so it doesn't form a chunk or get outputted.
      // Chunk 2: w4 (test) -> 4.50s to 5.50s
      
      expect(srt, contains('1\n00:00:01,000 --> 00:00:03,000\nHello world\n'));
      expect(srt, contains('2\n00:00:04,500 --> 00:00:05,500\ntest\n'));
    });

    test('toSrt handles text transforms (uppercase, capitalize)', () {
      testProject.config.style.textTransform = 'uppercase';
      var srt = SubtitleExporter.toSrt(testProject);
      expect(srt, contains('HELLO WORLD'));

      testProject.config.style.textTransform = 'capitalize';
      srt = SubtitleExporter.toSrt(testProject);
      expect(srt, contains('Hello World')); // Capitalizes each word
    });

    test('toVtt formats subtitles correctly', () {
      final vtt = SubtitleExporter.toVtt(testProject);
      
      expect(vtt, startsWith('WEBVTT\n'));
      expect(vtt, contains('1\n00:00:01.000 --> 00:00:03.000\nHello world\n'));
    });

    test('toTxt formats subtitles correctly with timestamps', () {
      final txt = SubtitleExporter.toTxt(testProject);
      
      expect(txt, contains('[00:00:01,000] Hello world\n'));
      expect(txt, contains('[00:00:04,500] test\n'));
    });

    test('toAss formats subtitles with embedded style tags', () {
      final ass = SubtitleExporter.toAss(testProject);
      
      // Check headers
      expect(ass, contains('[Script Info]'));
      expect(ass, contains('PlayResX: 1920'));
      expect(ass, contains('PlayResY: 1080'));
      expect(ass, contains('[V4+ Styles]'));
      expect(ass, contains('Style: Default,Montserrat,40,&H00ffffff&,&H001673f9&,&H00FFFFFF&,&H80000000&,-1,0,0,0,100,100,0.0,0,1,0.0,3.4,5,10,10,0,1'));
      
      // Check dialogue lines with highlighting tags:
      // w1 (Hello) is normal. w2 (world) has mainColor highlight (#f97316 -> &H001673f9)
      expect(ass, contains(r'Dialogue: 0,0:00:01.00,0:00:03.00,Default,,0000,0000,0000,,{\an5\pos(960,747)}Hello {\c&H001673f9&}world{\c}'));
      // w4 (test) has secondColor highlight (#06b6d4 -> &H00d4b606)
      expect(ass, contains(r'Dialogue: 0,0:00:04.50,0:00:05.50,Default,,0000,0000,0000,,{\an5\pos(960,747)}{\c&H00d4b606&}test{\c}'));
    });

    test('saveToFile writes contents correctly', () async {
      final tempDir = Directory.systemTemp.createTempSync('subtitle_export_test_');
      final targetPath = '${tempDir.path}/subtitles.srt';
      
      try {
        final content = 'SRT Content';
        final resultPath = await SubtitleExporter.saveToFile(content, targetPath);
        
        expect(resultPath, equals(targetPath));
        final file = File(targetPath);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals(content));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('toSrt, toVtt, toTxt, toAss handle empty projects and only hidden words correctly', () {
      final emptyProject = makeProject(words: []);
      expect(SubtitleExporter.toSrt(emptyProject), isEmpty);
      expect(SubtitleExporter.toVtt(emptyProject), equals('WEBVTT\n\n'));
      expect(SubtitleExporter.toTxt(emptyProject), isEmpty);
      expect(SubtitleExporter.toAss(emptyProject), contains('[Script Info]'));

      final onlyHidden = makeProject(
        words: [makeWord(wordId: 'w1', text: 'hello', hidden: true)],
      );
      expect(SubtitleExporter.toSrt(onlyHidden), isEmpty);
      expect(SubtitleExporter.toVtt(onlyHidden), equals('WEBVTT\n\n'));
      expect(SubtitleExporter.toTxt(onlyHidden), isEmpty);
    });

    test('hexToAssColor converts hex format properly', () {
      // 6-char hex
      expect(SubtitleExporter.hexToAssColor('#ffffff'), '&H00ffffff&');
      expect(SubtitleExporter.hexToAssColor('#ff0000'), '&H000000ff&');
      expect(SubtitleExporter.hexToAssColor('#f97316'), '&H001673f9&'); // blue 16, green 73, red F9

      // 8-char hex (with alpha)
      // Opaque alpha
      expect(SubtitleExporter.hexToAssColor('#ff123456'), '&H00563412&');
      // Semi-transparent alpha (7f -> 127 opacity. In ASS, alpha = 255 - 127 = 128 = 0x80)
      expect(SubtitleExporter.hexToAssColor('#7f123456'), '&H80563412&');
      
      // Edge cases/fallbacks
      expect(SubtitleExporter.hexToAssColor('invalid'), '&H00FFFFFF&');
    });

    test('toSrt and toAss handle timing rollover correctly (e.g. 59.9997 seconds)', () {
      final rolloverProject = makeProject(
        trimStart: 0.0,
        trimEnd: 70.0,
        words: [
          makeWord(wordId: 'w1', text: 'Rollover', start: 59.9997, end: 60.0003, confidence: 0.99),
        ],
      );

      final srt = SubtitleExporter.toSrt(rolloverProject);
      expect(srt, contains('00:01:00,000 --> 00:01:00,100'));

      final ass = SubtitleExporter.toAss(rolloverProject);
      expect(ass, contains(r'Dialogue: 0,0:01:00.00,0:01:00.10,Default,,0000,0000,0000,,{\an5\pos(960,590)}ROLLOVER'));
    });

    test('toAss sanitizes word text containing braces and newlines', () {
      final injectionProject = makeProject(
        trimStart: 0.0,
        trimEnd: 5.0,
        config: makeConfig(textTransform: 'none'),
        words: [
          makeWord(
            wordId: 'w1',
            text: r'{\b1}Exploit{\b0}',
            start: 1.0,
            end: 2.0,
            confidence: 0.99,
            className: 'mainColor',
          ),
          makeWord(
            wordId: 'w2',
            text: "Line1\r\nLine2",
            start: 2.0,
            end: 3.0,
            confidence: 0.99,
          ),
        ],
      );

      final ass = SubtitleExporter.toAss(injectionProject);
      // Braces stripped from word text
      expect(ass, isNot(contains(r'{\b1}')));
      expect(ass, contains(r'\b1Exploit\b0'));
      expect(ass, contains('Line1Line2'));
    });

    test('toAss supports 3d shadow, thin outline, and highlightBackground', () {
      final customProject = makeProject(
        width: 1920,
        height: 640, // exportScale = 1.0
        config: makeConfig(
          stroke: 'thin', // outlineWidth = 2.5
          shadow: '3d',   // shadowWidth = 5.0
          highlightBackground: true, // borderStyle = 3
        ),
        words: [
          makeWord(wordId: 'w1', text: 'Styling', start: 1.0, end: 2.0),
        ],
      );

      final ass = SubtitleExporter.toAss(customProject);
      // borderStyle 3, outline 2.5, shadow 5.0
      expect(ass, contains(',3,2.5,5.0,'));
    });
  });
}
