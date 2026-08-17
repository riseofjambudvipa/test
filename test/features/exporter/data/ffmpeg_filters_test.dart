import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/exporter/data/ffmpeg_exporter.dart';
import '../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project project;
  late FfmpegExporter exporter;

  setUp(() {
    exporter = FfmpegExporter();
    project = makeProject(
      projectId: 'proj_filters',
      name: 'Filter Test',
      videoPath: 'input.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
      config: makeConfig(
        name: 'default',
        fontFamily: 'Outfit',
        fontWeight: '900',
        textTransform: 'uppercase',
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
        stroke: 'thick',
      ),
      words: [
        makeWord(wordId: 'w1', text: 'Hello', start: 0.0, end: 0.5),
        makeWord(wordId: 'w2', text: 'world', start: 0.6, end: 1.6, className: 'mainColor'),
      ],
    );
  });

  VideoSegmentSchema segment(double start, double end) =>
      VideoSegmentSchema()..start = start..end = end;

  SfxExportItem sfx({double start = 0.5, double end = 1.5, int volume = 100}) =>
      SfxExportItem(
        soundEffect: 'pop.mp3',
        soundVolume: volume,
        start: start,
        end: end,
        resolvedPath: 'sfx/pop.mp3',
      );

  group('buildFilterComplexSlow', () {
    test('single segment: trims video and audio', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: const [],
      );

      expect(graph, contains('[0:v]trim=start=0.0:end=10.0,setpts=PTS-STARTPTS[v_trimmed]'));
      expect(graph, contains('[0:a]atrim=start=0.0:end=10.0,asetpts=PTS-STARTPTS[a_trimmed]'));
      // No split/concat for a single segment.
      expect(graph, isNot(contains('split=')));
      // Overlay + audio pass-through.
      expect(graph, contains('[v_trimmed][1:v]overlay=0:0[v_final]'));
      expect(graph, contains('[a_trimmed]anull[a_final]'));
    });

    test('multiple segments: splits and concatenates', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 2.0), segment(2.0, 4.0)],
        sfxItems: const [],
      );

      expect(graph, contains('[0:v]split=2[v_split_0][v_split_1]'));
      expect(graph, contains('[0:a]asplit=2[a_split_0][a_split_1]'));
      expect(graph, contains('[v_split_0]trim=start=0.0:end=2.0,setpts=PTS-STARTPTS[v_seg_0]'));
      expect(graph, contains('[v_split_1]trim=start=2.0:end=4.0,setpts=PTS-STARTPTS[v_seg_1]'));
      expect(graph, contains('[v_seg_0][a_seg_0][v_seg_1][a_seg_1]concat=n=2:v=1:a=1[v_trimmed][a_trimmed]'));
    });

    test('sfx items produce volume, fade, delay and amix chain', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: [sfx(start: 0.5, end: 1.5, volume: 80)],
      );

      // SFX is input index 2 (0 = video, 1 = PNG sequence).
      expect(graph, contains('[2:a]volume=volume=0.8'));
      expect(graph, contains('afade=t=in:ss=0:d='));
      expect(graph, contains('afade=t=out:ss='));
      expect(graph, contains('adelay=500|500[sfx_delayed_0]'));
      expect(graph, contains('[a_trimmed][sfx_delayed_0]amix=inputs=2:duration=first:normalize=0[a_final]'));
    });
  });

  group('buildFilterComplex', () {
    test('burns subtitles with fontsdir when assPath is provided', () {
      final graph = exporter.buildFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
      );

      expect(graph, contains('[v_trimmed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
      expect(graph, contains('[a_trimmed]anull[a_final]'));
      // No emoji overlays.
      expect(graph, isNot(contains('emoji_scaled')));
    });

    test('overlays emoji with scale, position and enable timing', () {
      final trimmedChunks = CaptionEngine.buildChunks(
        project.words,
        null,
        0.0,
        0.0,
        2,
        20,
      );
      final firstChunk = trimmedChunks.first;
      final firstWord = firstChunk.words.first;

      final graph = exporter.buildFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: trimmedChunks,
        validEmojiWords: [(firstWord, 'emoji/1f600.png')],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
      );

      // Emoji is input index 1 (0 = video).
      final exportScale = project.height / 640.0;
      final scaled = (80.0 * exportScale).round();
      expect(graph, contains('[1:v]scale=$scaled:$scaled,format=rgba'));
      expect(graph, contains('overlay=x='));
      // Enable timing uses the chunk's start/end (both words land in chunk 0).
      expect(graph, contains("enable='between(t,0.0,1.6)'[v_temp_0]"));
      // Subtitles burn in after the emoji overlay chain.
      expect(graph, contains('[v_temp_0]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('empty chunks produce no emoji overlay but still burn subtitles', () {
      final graph = exporter.buildFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
      );

      expect(graph, contains('[v_trimmed]subtitles='));
    });
  });
}
