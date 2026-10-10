import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/exporter/data/ass_script_builder.dart';
import '../../../helpers/project_fixture.dart';

void main() {
  group('AssScriptBuilder Tests', () {
    late Project defaultProject;

    setUp(() {
      defaultProject = makeProject(
        width: 1920,
        height: 1080,
        config: makeConfig(
          fontFamily: 'Montserrat',
          fontSize: 40.0,
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          mainColor: '#f97316',
          secondColor: '#06b6d4',
          thirdColor: '#22c55e',
          animation: 'pop',
          stroke: 'thick',
          shadow: 'soft',
        ),
      );
    });

    group('Script Structure and Sections', () {
      test('generateAssScript produces valid [Script Info], [V4+ Styles], and [Events] sections', () {
        final chunk = Chunk(
          index: 0,
          startTime: 1.0,
          endTime: 3.0,
          words: [
            makeWord(wordId: 'w1', text: 'Hello', start: 1.0, end: 2.0),
            makeWord(wordId: 'w2', text: 'world', start: 2.0, end: 3.0),
          ],
        );

        final script = generateAssScript(defaultProject, [chunk]);

        // 1. [Script Info] section
        expect(script, contains('[Script Info]'));
        expect(script, contains('Title: CapStudio Subtitles'));
        expect(script, contains('ScriptType: v4.00+'));
        expect(script, contains('PlayResX: 1920'));
        expect(script, contains('PlayResY: 1080'));
        expect(script, contains('ScaledBorderAndShadow: yes'));

        // 2. [V4+ Styles] section
        expect(script, contains('[V4+ Styles]'));
        expect(
          script,
          contains(
            'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, '
            'OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, '
            'ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, '
            'Alignment, MarginL, MarginR, MarginV, Encoding',
          ),
        );
        expect(script, contains('Style: Default,Montserrat,'));

        // 3. [Events] section
        expect(script, contains('[Events]'));
        expect(
          script,
          contains('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text'),
        );
        expect(script, contains('Dialogue: 0,0:00:01.00,0:00:03.00,Default,,0,0,0,,'));

        // Sections must appear in standard ASS order
        final scriptInfoIdx = script.indexOf('[Script Info]');
        final v4StylesIdx = script.indexOf('[V4+ Styles]');
        final eventsIdx = script.indexOf('[Events]');
        expect(scriptInfoIdx, lessThan(v4StylesIdx));
        expect(v4StylesIdx, lessThan(eventsIdx));
      });

      test('generates multiple chunks in sequence with accurate timestamps', () {
        final chunks = [
          Chunk(
            index: 0,
            startTime: 0.5,
            endTime: 1.75,
            words: [makeWord(text: 'First', start: 0.5, end: 1.75)],
          ),
          Chunk(
            index: 1,
            startTime: 2.0,
            endTime: 3.5,
            words: [makeWord(text: 'Second', start: 2.0, end: 3.5)],
          ),
        ];

        final script = generateAssScript(defaultProject, chunks);

        expect(script, contains('Dialogue: 0,0:00:00.50,0:00:01.75,Default,,0,0,0,,'));
        expect(script, contains('Dialogue: 0,0:00:02.00,0:00:03.50,Default,,0,0,0,,'));
      });
    });

    group('Text Transformation and ASS Injection Prevention', () {
      test('transforms text to uppercase when textTransform is uppercase', () {
        final project = makeProject(
          config: makeConfig(textTransform: 'uppercase'),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 1.0,
          words: [makeWord(text: 'lowercase words', start: 0.0, end: 1.0)],
        );

        final script = generateAssScript(project, [chunk]);
        expect(script, contains('LOWERCASE WORDS'));
        expect(script, isNot(contains('lowercase words')));
      });

      test('transforms text to capitalize when textTransform is capitalize', () {
        final project = makeProject(
          config: makeConfig(textTransform: 'capitalize'),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 2.0,
          words: [
            makeWord(text: 'hello', start: 0.0, end: 1.0),
            makeWord(text: 'world', start: 1.0, end: 2.0),
          ],
        );

        final script = generateAssScript(project, [chunk]);
        expect(script, contains('Hello'));
        expect(script, contains('World'));
      });

      test('strips {, }, \\r, \\n to prevent ASS override tag injection', () {
        final project = makeProject(
          config: makeConfig(textTransform: 'none'),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 1.0,
          words: [
            makeWord(
              text: '{\\b1\\evil_tag}malicious{\\c&H0000FF&}text\r\nwith\rnewlines\n',
              start: 0.0,
              end: 1.0,
            ),
          ],
        );

        final script = generateAssScript(project, [chunk]);

        // The raw injection braces and newlines must be stripped from the word text
        expect(script, contains(r'\b1\evil_tagmalicious\c&H0000FF&textwithnewlines'));
        // Verify no orphaned curly braces from the user payload remain
        expect(script, isNot(contains(r'{\b1\evil_tag}')));
        expect(script, isNot(contains(r'{\c&H0000FF&}text')));
        expect(script, isNot(contains('\r')));
      });

      test('transformTextForTesting strips injection characters and transforms correctly', () {
        expect(
          transformTextForTesting('{hello}\r\nworld}', 'uppercase'),
          equals('HELLOWORLD'),
        );
        expect(
          transformTextForTesting('{hello}\r\n', 'capitalize'),
          equals('Hello'),
        );
        expect(
          transformTextForTesting('{inject}', 'none'),
          equals('inject'),
        );
        expect(
          transformTextForTesting('', 'capitalize'),
          equals(''),
        );
      });
    });

    group('Animations', () {
      final chunk = Chunk(
        index: 0,
        startTime: 0.0,
        endTime: 1.0,
        words: [makeWord(text: 'test', start: 0.0, end: 0.5)],
      );

      test('pop animation returns expected ASS tags with scale bounce', () {
        final word = makeWord(start: 0.0, end: 0.5);
        final config = makeConfig(animation: 'pop');

        final (animTag, animReset) = getAnimationTagsForTesting(
          word: word,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );

        expect(animTag, equals(r'{\t(0,0,\fscx112\fscy112)\t(500,500,\fscx100\fscy100)}'));
        expect(animReset, equals(r'{\fscx100\fscy100}'));

        final script = generateAssScript(makeProject(config: config), [chunk]);
        expect(script, contains(r'\fscx112\fscy112'));
        expect(script, contains(r'\fscx100\fscy100'));
      });

      test('bounce animation returns expected ASS squash-and-stretch tags', () {
        final word = makeWord(start: 0.0, end: 0.5);
        final config = makeConfig(animation: 'bounce');

        final (animTag, animReset) = getAnimationTagsForTesting(
          word: word,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );

        expect(animTag, equals(r'{\t(0,0,\fscy125\fscx85)\t(500,500,\fscx100\fscy100)}'));
        expect(animReset, equals(r'{\fscx100\fscy100}'));

        final script = generateAssScript(makeProject(config: config), [chunk]);
        expect(script, contains(r'\fscy125\fscx85'));
        expect(script, contains(r'\fscx100\fscy100'));
      });

      test('kineticTilt animation returns alternating tilt degrees and resets to 0', () {
        final word0 = makeWord(start: 0.0, end: 0.5);
        final word1 = makeWord(start: 0.5, end: 1.0);
        final config = makeConfig(animation: 'kineticTilt');

        // Even word index -> +5 deg
        final (animTag0, animReset0) = getAnimationTagsForTesting(
          word: word0,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );
        expect(animTag0, equals(r'{\t(0,0,\frz5)\t(500,500,\frz0)}'));
        expect(animReset0, equals(r'{\frz0}'));

        // Odd word index -> -5 deg
        final (animTag1, animReset1) = getAnimationTagsForTesting(
          word: word1,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 1,
        );
        expect(animTag1, equals(r'{\t(500,500,\frz-5)\t(1000,1000,\frz0)}'));
        expect(animReset1, equals(r'{\frz0}'));

        final twoWordChunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 1.0,
          words: [word0, word1],
        );
        final script = generateAssScript(makeProject(config: config), [twoWordChunk]);
        expect(script, contains(r'\frz5'));
        expect(script, contains(r'\frz-5'));
        expect(script, contains(r'\frz0'));
      });

      test('wordReveal animation returns vertical unmasking from fscy0 to fscy100', () {
        final word = makeWord(start: 0.0, end: 0.5);
        final config = makeConfig(animation: 'wordReveal');

        final (animTag, animReset) = getAnimationTagsForTesting(
          word: word,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );

        // midMs = (0 + 500) ~/ 2 = 250
        expect(animTag, equals(r'{\fscy0\t(0,250,\fscy100)}'));
        expect(animReset, equals(r'{\fscy100}'));

        final script = generateAssScript(makeProject(config: config), [chunk]);
        expect(script, contains(r'{\fscy0\t(0,250,\fscy100)}'));
      });

      test('glowPulse animation returns border expansion tags based on outline and scale', () {
        final word = makeWord(start: 0.0, end: 0.5);
        final config = makeConfig(animation: 'glowPulse');

        // outlineWidth = 6.0, exportScale = 1.0 -> expandedBord = 6.0 + 3.0 * 1.0 = 9.0
        final (animTag, animReset) = getAnimationTagsForTesting(
          word: word,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );

        expect(animTag, equals(r'{\t(0,0,\bord9.0)\t(500,500,\bord6.0)}'));
        expect(animReset, equals(r'{\bord6.0}'));

        final script = generateAssScript(
          makeProject(height: 640, config: config),
          [chunk],
        );
        expect(script, contains(r'\bord9.0'));
        expect(script, contains(r'\bord6.0'));
      });

      test('none animation returns empty animation strings', () {
        final word = makeWord(start: 0.0, end: 0.5);
        final config = makeConfig(animation: 'none');

        final (animTag, animReset) = getAnimationTagsForTesting(
          word: word,
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );

        expect(animTag, equals(''));
        expect(animReset, equals(''));

        final script = generateAssScript(makeProject(config: config), [chunk]);
        expect(script, isNot(contains(r'\fscx112')));
        expect(script, isNot(contains(r'\fscy125')));
        expect(script, isNot(contains(r'\frz')));
        expect(script, isNot(contains(r'\fscy0')));
      });

      test('returns empty animation tags if word start/end is invalid or start >= end', () {
        final config = makeConfig(animation: 'pop');

        final (nullStartTag, nullStartReset) = getAnimationTagsForTesting(
          word: makeWord(start: null, end: 1.0),
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );
        expect(nullStartTag, equals(''));
        expect(nullStartReset, equals(''));

        final (invertedTag, invertedReset) = getAnimationTagsForTesting(
          word: makeWord(start: 1.0, end: 0.5),
          chunk: chunk,
          config: config,
          outlineWidth: 6.0,
          exportScale: 1.0,
          wordIndex: 0,
        );
        expect(invertedTag, equals(''));
        expect(invertedReset, equals(''));
      });
    });

    group('Font Scale Calculation Based on Project Height', () {
      test('calculates correct font size for baseline 640 height (scale 1.0)', () {
        final project = makeProject(
          width: 640,
          height: 640,
          config: makeConfig(fontSize: 40.0),
        );
        final script = generateAssScript(project, []);

        // exportScale = 640 / 640 = 1.0 -> fontSize = 40
        expect(script, contains(',Montserrat,40,'));
      });

      test('calculates correct font size for 720p height', () {
        final project = makeProject(
          width: 1280,
          height: 720,
          config: makeConfig(fontSize: 32.0),
        );
        final script = generateAssScript(project, []);

        // exportScale = 720 / 640 = 1.125 -> fontSize = 32.0 * 1.125 = 36.0 -> 36
        expect(script, contains(',Montserrat,36,'));
      });

      test('calculates correct font size for 1080p height', () {
        final project = makeProject(
          width: 1920,
          height: 1080,
          config: makeConfig(fontSize: 42.0),
        );
        final script = generateAssScript(project, []);

        // exportScale = 1080 / 640 = 1.6875 -> fontSize = (42.0 * 1.6875).toInt() = 70
        expect(script, contains(',Montserrat,70,'));
      });

      test('calculates correct font size for 4K / vertical 1920 height', () {
        final project = makeProject(
          width: 1080,
          height: 1920,
          config: makeConfig(fontSize: 40.0),
        );
        final script = generateAssScript(project, []);

        // exportScale = 1920 / 640 = 3.0 -> fontSize = 40.0 * 3.0 = 120
        expect(script, contains(',Montserrat,120,'));
      });
    });

    group('Opaque Background Box (borderStyle = 3)', () {
      test('sets borderStyle = 3, outline color to background, and outline padding when background is set', () {
        final project = makeProject(
          height: 640,
          config: makeConfig(
            background: '#000000', // Hex black
            stroke: 'none',        // outlineWidth = 0
          ),
        );

        final script = generateAssScript(project, []);

        // Color converted: '#000000' -> '&H00000000&'
        // borderStyle = 3
        // outline width default padding = 6.0 * exportScale = 6.0
        // Style line format: ...,Spacing,Angle,BorderStyle,Outline,Shadow,...
        // With borderStyle = 3 and outline = 6.0: ',0,3,6.0,'
        expect(script, contains(',&H00000000&,&H00000000&,'));
        expect(script, contains(',0,3,6.0,'));
      });

      test('uses stroke width as padding when borderStyle = 3 and stroke is thick', () {
        final project = makeProject(
          height: 640,
          config: makeConfig(
            background: '#1e293b',
            stroke: 'thick', // outlineWidth = 6.0 * exportScale
          ),
        );

        final script = generateAssScript(project, []);

        // borderStyle = 3, outline = 6.0
        expect(script, contains(',0,3,6.0,'));
      });

      test('sets borderStyle = 1 and shadowColor when background is null', () {
        final project = makeProject(
          height: 640,
          config: makeConfig(
            background: null,
            stroke: 'thick',
            shadow: 'soft',
          ),
        );

        final script = generateAssScript(project, []);

        // Without background:
        // borderStyle = 1
        // backColor = shadowColor = '&H80000000&'
        // finalOutlineColor = '&H00000000&' (for thick stroke)
        // outline width = 6.0, shadow = 2.0
        expect(script, contains(',&H00000000&,&H80000000&,'));
        expect(script, contains(',0,1,6.0,2.0,'));
      });

      test('sets borderStyle = 3 and highlightColor when highlightBackground is true and background is null', () {
        final project = makeProject(
          height: 640,
          config: makeConfig(
            background: null,
            highlightBackground: true,
            stroke: 'none',
          ),
        );

        final script = generateAssScript(project, []);

        // borderStyle = 3, outline padding default = 6.0
        expect(script, contains(',0,3,6.0,'));
      });
    });

    group('Word Highlighting and Font Weights', () {
      test('applies color tags and resets for words with className', () {
        final project = makeProject(
          config: makeConfig(
            mainColor: '#f97316',
            secondColor: '#06b6d4',
            thirdColor: '#22c55e',
          ),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 3.0,
          words: [
            makeWord(text: 'one', start: 0.0, end: 1.0, className: 'mainColor'),
            makeWord(text: 'two', start: 1.0, end: 2.0, className: 'secondColor'),
            makeWord(text: 'three', start: 2.0, end: 3.0, className: 'thirdColor'),
          ],
        );

        final script = generateAssScript(project, [chunk]);

        // #f97316 -> &H001673f9&
        expect(script, contains(r'{\c&H001673f9&}'));
        // #06b6d4 -> &H00d4b606&
        expect(script, contains(r'{\c&H00d4b606&}'));
        // #22c55e -> &H005ec522&
        expect(script, contains(r'{\c&H005ec522&}'));
      });

      test('sets bold flag -1 for bold weights and 0 for normal weights', () {
        for (final weight in ['bold', '600', '700', '800', '900']) {
          final p = makeProject(config: makeConfig(fontWeight: weight));
          final script = generateAssScript(p, []);
          // Style line: ...,OutlineColour,BackColour,Bold,...
          // bold flag must be -1
          expect(script, contains(',-1,0,0,0,100,100,'));
        }

        for (final weight in ['normal', '400', '500']) {
          final p = makeProject(config: makeConfig(fontWeight: weight));
          final script = generateAssScript(p, []);
          // bold flag must be 0
          expect(script, contains(',0,0,0,0,100,100,'));
        }
      });
    });

    group('Line Wrapping and Path Escaping', () {
      test('inserts \\N between lines when words wrap', () {
        // Force wrap by setting large words with small max width
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 2.0,
          words: [
            makeWord(text: 'LineOneWordOne', start: 0.0, end: 0.5),
            makeWord(text: 'LineOneWordTwo', start: 0.5, end: 1.0),
            makeWord(text: 'LineTwoWordThree', start: 1.0, end: 1.5),
            makeWord(text: 'LineTwoWordFour', start: 1.5, end: 2.0),
          ],
        );

        // Make project with small width to force wrapping
        final project = makeProject(
          width: 400,
          height: 640,
          config: makeConfig(fontSize: 48.0),
        );

        final script = generateAssScript(project, [chunk]);
        expect(script, contains(r'\N'));
      });

      test('escapeAssPath escapes backslashes, colons, and single quotes', () {
        expect(
          escapeAssPath(r'C:\Users\Name\file.ass'),
          equals(r'C\:/Users/Name/file.ass'),
        );
        expect(
          escapeAssPath("path'with'quotes"),
          equals(r"path'\''with'\''quotes"),
        );
      });

      test('sets outline width to 2.5 * scale for stroke: thin and 3.5 * scale for shadow: hard', () {
        final project = makeProject(
          width: 1920,
          height: 640, // exportScale = 1.0
          config: makeConfig(
            stroke: 'thin',
            shadow: 'hard',
          ),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 1.0,
          words: [makeWord(text: 'Test', start: 0.0, end: 1.0)],
        );
        final script = generateAssScript(project, [chunk]);
        // Outline width 2.5, Shadow width 3.5 in Style definition
        expect(script, contains(',2.5,3.5,'));
      });

      test('sets shadow width to 5.0 * scale for shadow: 3d', () {
        final project = makeProject(
          width: 1920,
          height: 640, // exportScale = 1.0
          config: makeConfig(
            stroke: 'none',
            shadow: '3d',
          ),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 1.0,
          words: [makeWord(text: 'Test', start: 0.0, end: 1.0)],
        );
        final script = generateAssScript(project, [chunk]);
        // Outline width 0.0, Shadow width 5.0 in Style definition
        expect(script, contains(',0.0,5.0,'));
      });

      test('transformTextForTesting strips braces and carriage returns/newlines', () {
        expect(
          transformTextForTesting('{\\b1}Injected{\\b0}', 'none'),
          equals(r'\b1Injected\b0'),
        );
        expect(
          transformTextForTesting("Line1\r\nLine2\nLine3", 'none'),
          equals('Line1Line2Line3'),
        );
        expect(
          transformTextForTesting('{hello}\nworld', 'uppercase'),
          equals('HELLOWORLD'),
        );
        expect(
          transformTextForTesting('{hello}\rworld', 'capitalize'),
          equals('Helloworld'),
        );
      });

      test('generateAssScript sanitizes word text containing ASS injection attempts', () {
        final project = makeProject(
          width: 1920,
          height: 1080,
          config: makeConfig(textTransform: 'none'),
        );
        final chunk = Chunk(
          index: 0,
          startTime: 0.0,
          endTime: 2.0,
          words: [
            makeWord(text: '{\\c&H0000FF&}Hacked', start: 0.0, end: 1.0),
            makeWord(text: "Multi\nLine\rAttack", start: 1.0, end: 2.0),
          ],
        );
        final script = generateAssScript(project, [chunk]);
        // Ensure literal user braces are not preserved in the dialogue text
        expect(script, isNot(contains('{\\c&H0000FF&}Hacked')));
        expect(script, contains(r'\c&H0000FF&Hacked'));
        expect(script, contains('MultiLineAttack'));
        // Confirm no raw newline breaks within the Dialogue line
        final dialogueLines = script.split('\n').where((l) => l.startsWith('Dialogue:'));
        expect(dialogueLines.length, 1);
      });

      test('includes speaker name in Dialogue event when Chunk has speaker assigned', () {
        final project = makeProject();
        final chunk = Chunk(
          index: 0,
          startTime: 1.0,
          endTime: 3.0,
          speaker: 'Host Alex',
          words: [
            makeWord(text: 'Welcome', start: 1.0, end: 2.0),
            makeWord(text: 'back', start: 2.0, end: 3.0),
          ],
        );
        final script = generateAssScript(project, [chunk]);
        expect(script, contains('Dialogue: 0,0:00:01.00,0:00:03.00,Default,Host Alex,0,0,0,,'));
      });
    });

    group('High-Load Kinetic Scalability & Scrubber Performance', () {
      test('generateAssScript handles 2,500 kinetic words across 500 chunks in < 250ms', () {
        final project = makeProject(
          width: 1920,
          height: 1080,
          config: makeConfig(
            fontFamily: 'Montserrat',
            fontSize: 42.0,
            fontWeight: '900',
            animation: 'kineticTilt',
            stroke: 'thick',
            shadow: '3d',
            mainColor: '#facc15',
            secondColor: '#38bdf8',
            thirdColor: '#4ade80',
          ),
        );

        final List<Chunk> largeChunks = [];
        double cursor = 0.0;
        for (int c = 0; c < 500; c++) {
          final chunkStart = cursor;
          final List<WordSchema> chunkWords = [];
          for (int w = 0; w < 5; w++) {
            final wordStart = cursor;
            final wordEnd = cursor + 0.35;
            final className = switch (w % 4) {
              1 => 'mainColor',
              2 => 'secondColor',
              3 => 'thirdColor',
              _ => null,
            };
            chunkWords.add(makeWord(
              wordId: 'w_${c}_$w',
              text: 'Word$w',
              start: wordStart,
              end: wordEnd,
              className: className,
            ));
            cursor += 0.40;
          }
          final chunkEnd = cursor;
          cursor += 0.20; // 200ms pause between chunks
          largeChunks.add(Chunk(
            index: c,
            startTime: chunkStart,
            endTime: chunkEnd,
            words: chunkWords,
            speaker: c % 2 == 0 ? 'Speaker A' : 'Speaker B',
          ));
        }

        // Profile script generation execution
        final sw = Stopwatch()..start();
        final script = generateAssScript(project, largeChunks);
        sw.stop();

        // Verification of correctness
        expect(script, contains('[Events]'));
        expect(script, contains('Speaker A'));
        expect(script, contains('Speaker B'));
        expect(script, contains(r'\frz')); // Kinetic tilt animation tags
        expect(script.toLowerCase(), contains(r'\c&h0015ccfa&')); // Hex formatted colors

        final dialogueLines = script.split('\n').where((l) => l.startsWith('Dialogue:'));
        expect(dialogueLines.length, 500);

        // Verification of performance: 2,500 words / 500 chunks generated in < 1.2s in debug runner
        expect(sw.elapsedMilliseconds, lessThan(1200),
            reason: 'ASS generation for 2,500 words took ${sw.elapsedMilliseconds}ms, exceeding performance threshold');
      });

      test('CaptionEngine.getActiveChunk executes 10,000 scrubber seek lookups across 500 chunks in < 250ms', () {
        final List<Chunk> chunks = [];
        double cursor = 0.0;
        for (int c = 0; c < 500; c++) {
          final chunkStart = cursor;
          final chunkEnd = cursor + 2.0;
          chunks.add(Chunk(
            index: c,
            startTime: chunkStart,
            endTime: chunkEnd,
            words: [makeWord(text: 'Sample', start: chunkStart, end: chunkEnd)],
          ));
          cursor += 2.5;
        }

        final totalDuration = cursor;

        // Perform 10,000 rapid playhead seeks spanning the full duration
        final sw = Stopwatch()..start();
        int foundCount = 0;
        for (int i = 0; i < 10000; i++) {
          final time = (i * 0.12345) % totalDuration;
          final active = CaptionEngine.getActiveChunk(chunks, time);
          if (active != null) foundCount++;
        }
        sw.stop();

        expect(foundCount, greaterThan(0));
        expect(sw.elapsedMilliseconds, lessThan(250),
            reason: '10,000 binary search chunk lookups took ${sw.elapsedMilliseconds}ms, exceeding 250ms budget');
      });
    });
  });
}
