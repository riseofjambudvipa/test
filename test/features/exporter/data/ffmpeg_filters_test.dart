import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/exporter/data/ffmpeg_exporter.dart';
import 'package:capstudio/core/audio/speaker_diarization_service.dart' show SpeakerInterval;
import 'package:capstudio/core/video/b_roll_models.dart';
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

    test('reframe with blurPillarbox scales background, foreground and chains to subtitles', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        conversionMode: AspectConversionMode.blurPillarbox,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      // Verify blur pillarbox filter structure
      expect(graph, contains('[v_trimmed]split=2[v_bp_bg_in][v_bp_fg_in]'));
      expect(graph, contains('[v_bp_bg_in]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=35:5,eq=brightness=-0.08:saturation=1.1[bg]'));
      expect(graph, contains('[v_bp_fg_in]scale=1080:1920:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[fg]'));
      expect(graph, contains('[bg][fg]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[v_reframed]'));
      // Subtitles chained directly after reframe
      expect(graph, contains('[v_reframed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('reframe with centerCrop applies center crop filter and chains to subtitles', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        conversionMode: AspectConversionMode.centerCrop,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      expect(graph, contains('[v_trimmed]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920:(in_w-1080)/2:(in_h-1920)/2[v_reframed]'));
      expect(graph, contains('[v_reframed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('reframe with splitScreen stacks video and chains to subtitles', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        conversionMode: AspectConversionMode.splitScreen,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      expect(graph, contains('[v_trimmed]split=2[split_top_in][split_bottom_in]'));
      expect(graph, contains('[split_top_in]scale=-2:960:force_original_aspect_ratio=increase,crop=1080:960:0:(in_h-960)/2[top]'));
      expect(graph, contains('[split_bottom_in]scale=-2:960:force_original_aspect_ratio=increase,crop=1080:960:(in_w-1080):(in_h-960)/2[bottom]'));
      expect(graph, contains('[top][bottom]vstack=inputs=2[v_reframed]'));
      expect(graph, contains('[v_reframed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('auto-reframes to blurPillarbox when project is vertical 9:16 and source is landscape 16:9', () {
      final graph = exporter.buildFilterComplex(
        project: project, // 1080x1920
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      expect(graph, contains('[v_trimmed]split=2[v_bp_bg_in][v_bp_fg_in]'));
      expect(graph, contains('[v_reframed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('reframes landscape 16:9 project to 1080x1920 when conversionMode is set', () {
      final landscapeProject = makeProject(
        width: 1920,
        height: 1080,
      );

      final graph = exporter.buildVideoFilterComplex(
        project: landscapeProject,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        conversionMode: AspectConversionMode.blurPillarbox,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      expect(graph, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(graph, contains('[v_reframed]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('correctly chains reframe -> emoji overlay -> subtitles in sequence', () {
      final trimmedChunks = CaptionEngine.buildChunks(
        project.words,
        null,
        0.0,
        0.0,
        2,
        20,
      );
      final firstWord = trimmedChunks.first.words.first;

      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: trimmedChunks,
        validEmojiWords: [(firstWord, 'emoji/1f600.png')],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        tempFontsDir: 'fonts/dir',
        conversionMode: AspectConversionMode.blurPillarbox,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      // 1. Reframe produces [v_reframed]
      expect(graph, contains('[bg][fg]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[v_reframed]'));
      // 2. Emoji overlays on [v_reframed] -> [v_temp_0]
      expect(graph, contains('[v_reframed][emoji_scaled_0]overlay='));
      // 3. Subtitles chain after emoji overlay [v_temp_0] -> [v_final]
      expect(graph, contains('[v_temp_0]subtitles=\'subs/out.ass\':fontsdir=\'fonts/dir\'[v_final]'));
    });

    test('multiple emojis in the same chunk are laid out horizontally inline without overlapping', () {
      final chunk = Chunk(
        index: 0,
        startTime: 0.0,
        endTime: 2.0,
        words: [
          makeWord(wordId: 'w1', text: 'tennis', start: 0.0, end: 1.0, emoji: '🎾'),
          makeWord(wordId: 'w2', text: 'racket', start: 1.0, end: 2.0, emoji: '🏸'),
        ],
      );

      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: [chunk],
        validEmojiWords: [
          (chunk.words[0], 'emoji/tennis.png'),
          (chunk.words[1], 'emoji/racket.png'),
        ],
        sfxItems: const [],
        assPath: 'subs/out.ass',
      );

      // Verify both emojis are overlayed
      expect(graph, contains('[emoji_scaled_0]'));
      expect(graph, contains('[emoji_scaled_1]'));

      // Extract overlay x coordinates for both emojis: overlay=x=...:y=...
      final regex = RegExp(r'\[emoji_scaled_(\d+)\]overlay=x=(-?\d+):y=(-?\d+)');
      final matches = regex.allMatches(graph).toList();
      expect(matches.length, 2);

      final x0 = int.parse(matches[0].group(2)!);
      final x1 = int.parse(matches[1].group(2)!);

      // x1 must NOT equal x0 (they must NOT be rendered on top of each other)
      expect(x1, isNot(equals(x0)));
      // x1 should be to the right of x0
      expect(x1, greaterThan(x0));
    });

    test('audio crossfade creates acrossfade chain between multiple segments', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 2.0), segment(2.0, 4.0), segment(4.0, 6.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subs/out.ass',
        enableAudioCrossfade: true,
        audioCrossfadeDuration: 0.05,
      );

      // Video concatenation without audio
      expect(graph, contains('[v_seg_0][v_seg_1][v_seg_2]concat=n=3:v=1:a=0[v_trimmed]'));
      // Audio acrossfade chain
      expect(graph, contains('[a_seg_0][a_seg_1] acrossfade=d=0.050:c1=tri:c2=tri[a_xfade_1]'));
      expect(graph, contains('[a_xfade_1][a_seg_2] acrossfade=d=0.050:c1=tri:c2=tri[a_trimmed]'));
    });
  });

  group('buildFilterComplexSlow with reframe', () {
    test('reframes video before overlaying PNG sequence', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: const [],
        conversionMode: AspectConversionMode.centerCrop,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );

      expect(graph, contains('[v_trimmed]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920:(in_w-1080)/2:(in_h-1920)/2[v_reframed]'));
      expect(graph, contains('[v_reframed][1:v]overlay=0:0[v_final]'));
    });
  });

  group('AspectRatioConverter direct tests', () {
    test('buildBlurPillarboxFilter default produces valid FFmpeg filter', () {
      final filter = AspectRatioConverter.buildBlurPillarboxFilter(
        inputWidth: 1920,
        inputHeight: 1080,
      );
      expect(filter, contains('[v_bp_bg_in]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=35:5,eq=brightness=-0.08:saturation=1.1[bg]'));
      expect(filter, contains('[v_bp_fg_in]scale=1080:1920:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[fg]'));
      expect(filter, contains('[bg][fg]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2'));
    });

    test('buildCenterCropFilter default produces valid FFmpeg filter', () {
      final filter = AspectRatioConverter.buildCenterCropFilter(
        inputWidth: 1920,
        inputHeight: 1080,
      );
      expect(filter, contains('[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920:(in_w-1080)/2:(in_h-1920)/2'));
    });

    test('buildSplitScreenFilter dual inputs produces valid FFmpeg filter', () {
      final filter = AspectRatioConverter.buildSplitScreenFilter(
        topInputWidth: 1920,
        topInputHeight: 1080,
        bottomInputWidth: 1920,
        bottomInputHeight: 1080,
      );
      expect(filter, contains('[0:v]scale=1080:960:force_original_aspect_ratio=increase,crop=1080:960:(in_w-1080)/2:(in_h-960)/2[top]'));
      expect(filter, contains('[1:v]scale=1080:960:force_original_aspect_ratio=increase,crop=1080:960:(in_w-1080)/2:(in_h-960)/2[bottom]'));
      expect(filter, contains('[top][bottom]vstack=inputs=2'));
    });

    test('buildFilterForMode dispatches correctly to all modes', () {
      final blur = AspectRatioConverter.buildFilterForMode(
        mode: AspectConversionMode.blurPillarbox,
        inputWidth: 1920,
        inputHeight: 1080,
        inputStream: '[v_in]',
        outputStream: '[v_out]',
      );
      expect(blur, contains('[v_in]split=2[v_bp_bg_in][v_bp_fg_in]'));
      expect(blur, contains('[v_out]'));

      final crop = AspectRatioConverter.buildFilterForMode(
        mode: AspectConversionMode.centerCrop,
        inputWidth: 1920,
        inputHeight: 1080,
        inputStream: '[v_in]',
        outputStream: '[v_out]',
      );
      expect(crop, contains('[v_in]scale=1080:1920'));
      expect(crop, contains('[v_out]'));

      final split = AspectRatioConverter.buildFilterForMode(
        mode: AspectConversionMode.splitScreen,
        inputWidth: 1920,
        inputHeight: 1080,
        inputStream: '[v_in]',
        outputStream: '[v_out]',
      );
      expect(split, contains('[v_in]split=2[split_top_in][split_bottom_in]'));
      expect(split, contains('[top][bottom]vstack=inputs=2[v_out]'));

      final faceTrack = AspectRatioConverter.buildFilterForMode(
        mode: AspectConversionMode.smartFaceTrack,
        inputWidth: 1920,
        inputHeight: 1080,
        inputStream: '[v_in]',
        outputStream: '[v_out]',
      );
      expect(faceTrack, contains('[v_in]scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(faceTrack, contains('crop=1080:1920:(in_w-1080)*0.5:(in_h-1920)*0.25[v_out]'));

      final speakerTrack = AspectRatioConverter.buildFilterForMode(
        mode: AspectConversionMode.speakerTrack,
        inputWidth: 1920,
        inputHeight: 1080,
        inputStream: '[v_in]',
        outputStream: '[v_out]',
        speakerIntervals: const [
          SpeakerInterval(speaker: 'Host', speakerIndex: 0, start: 0.0, end: 3.0),
          SpeakerInterval(speaker: 'Guest', speakerIndex: 1, start: 3.0, end: 6.0),
        ],
      );
      expect(speakerTrack, contains('[v_in]scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(speakerTrack, contains('crop=1080:1920:x=\'if(between(t,0.00,3.00)'));
      expect(speakerTrack, contains('[v_out]'));
    });
  });

  group('AI Studio Sound & Voice Polish Filter', () {
    test('buildStudioSoundFilter returns broadcast DSP chain', () {
      final filter = FfmpegFilterBuilder.buildStudioSoundFilter();
      expect(filter, contains('highpass=f=80'));
      expect(filter, contains('lowpass=f=12000'));
      expect(filter, contains('afftdn=nf=-25'));
      expect(filter, contains('compand=attacks=0.02:decays=0.2'));
      expect(filter, contains('gain=3'));
      expect(filter, contains('loudnorm=I=-16:TP=-1.5:LRA=11'));
    });

    test('buildFilterComplexSlow with enableStudioSound without SFX routes directly to a_final', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: const [],
        enableStudioSound: true,
      );

      expect(graph, contains('[0:a]atrim=start=0.0:end=10.0,asetpts=PTS-STARTPTS[a_trimmed]'));
      expect(graph, contains('; [a_trimmed]${FfmpegFilterBuilder.buildStudioSoundFilter()}[a_final]'));
      expect(graph, isNot(contains('[a_trimmed]anull[a_final]')));
    });

    test('buildFilterComplexSlow with enableStudioSound with SFX polishes voice before amix', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: [sfx(start: 0.5, end: 1.5, volume: 80)],
        enableStudioSound: true,
      );

      expect(graph, contains('; [a_trimmed]${FfmpegFilterBuilder.buildStudioSoundFilter()}[a_polished]'));
      expect(graph, contains('[a_polished][sfx_delayed_0]amix=inputs=2:duration=first:normalize=0[a_final]'));
    });

    test('buildVideoFilterComplex with enableStudioSound polishes voice track', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: [Chunk(index: 0, startTime: 0.0, endTime: 1.0, words: [makeWord(text: 'Hello')])],
        validEmojiWords: const [],
        sfxItems: [sfx(start: 0.5, end: 1.5, volume: 90)],
        assPath: 'subtitles.ass',
        enableStudioSound: true,
      );

      expect(graph, contains('; [a_trimmed]${FfmpegFilterBuilder.buildStudioSoundFilter()}[a_polished]'));
      expect(graph, contains('[a_polished][sfx_delayed_0]amix=inputs=2:duration=first:normalize=0[a_final]'));
    });

    test('enableStudioSound with hasAudio false ignores studio sound DSP', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subtitles.ass',
        hasAudio: false,
        enableStudioSound: true,
      );

      expect(graph, contains('anullsrc=r=48000:cl=stereo:d=10.000[a_trimmed]'));
      expect(graph, isNot(contains(FfmpegFilterBuilder.buildStudioSoundFilter())));
      expect(graph, contains('; [a_trimmed]anull[a_final]'));
    });

    test('buildVideoFilterComplex with BackgroundMusicConfig and voice ducking', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: [sfx(start: 1.0, end: 2.0, volume: 80)],
        assPath: 'subtitles.ass',
        backgroundMusic: const BackgroundMusicConfig(
          musicPath: 'lofi_track.mp3',
          volume: 0.20,
          loop: true,
          enableDucking: true,
          duckingRatio: 4.0,
        ),
      );

      // BGM stream is looped and trimmed to project duration
      expect(graph, contains('[1:a]aloop=loop=-1:size=2e+09,atrim=0:10.000,asetpts=PTS-STARTPTS,volume=0.20[bgm_vol]'));
      // Voice ducking sidechain compressor attenuates music
      expect(graph, contains('[bgm_vol][a_trimmed] sidechaincompress=threshold=0.08:ratio=4.0:attack=50:release=300:makeup=1[bgm_ducked]'));
      // SFX input index is shifted from 1 to 2 because BGM is index 1 (no emojis)
      expect(graph, contains('[2:a]volume=volume=0.8'));
      // Final mix contains voice, ducked BGM and SFX
      expect(graph, contains('[a_trimmed][bgm_ducked][sfx_delayed_0]amix=inputs=3:duration=first:normalize=0[a_final]'));
    });

    test('buildFilterComplexSlow with BackgroundMusicConfig without ducking', () {
      final graph = exporter.buildFilterComplexSlow(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        sfxItems: const [],
        backgroundMusic: const BackgroundMusicConfig(
          musicPath: 'acoustic_beat.mp3',
          volume: 0.15,
          loop: false,
          enableDucking: false,
        ),
      );

      // BGM is at index 2 (0=video, 1=PNG seq)
      expect(graph, contains('[2:a]atrim=0:10.000,asetpts=PTS-STARTPTS,volume=0.15[bgm_vol]'));
      // No sidechain ducking filter
      expect(graph, isNot(contains('sidechaincompress')));
      // Final mix combines voice and music bed
      expect(graph, contains('[a_trimmed][bgm_vol]amix=inputs=2:duration=first:normalize=0[a_final]'));
    });

    test('buildStudioSoundFilter with socialShorts and de-esser returns -14 LUFS and deesser filter', () {
      final filter = FfmpegFilterBuilder.buildStudioSoundFilter(
        platform: AudioMasteringPlatform.socialShorts,
        enableDeEsser: true,
        deEsserIntensity: 0.50,
      );

      expect(filter, contains('highpass=f=80'));
      expect(filter, contains('deesser=i=0.50:m=0.5:f=0.5:s=o'));
      expect(filter, contains('compand='));
      expect(filter, contains('loudnorm=I=-14:TP=-1.0:LRA=7'));
    });

    test('buildStudioSoundFilter with cinemaHeadroom returns -23 LUFS', () {
      final filter = FfmpegFilterBuilder.buildStudioSoundFilter(
        platform: AudioMasteringPlatform.cinemaHeadroom,
        enableDeEsser: false,
      );

      expect(filter, contains('loudnorm=I=-23:TP=-2.0:LRA=14'));
      expect(filter, isNot(contains('deesser=')));
    });

    test('buildVideoFilterComplex with audioMastering config applies platform loudness and de-esser', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subtitles.ass',
        enableStudioSound: true,
        audioMastering: const AudioMasteringConfig(
          enableStudioSound: true,
          platform: AudioMasteringPlatform.socialShorts,
          enableDeEsser: true,
          deEsserIntensity: 0.45,
        ),
      );

      expect(graph, contains('deesser=i=0.45:m=0.5:f=0.5:s=o'));
      expect(graph, contains('loudnorm=I=-14:TP=-1.0:LRA=7'));
    });

    test('buildVideoFilterComplex with speakerTrack reframes according to speaker intervals', () {
      final graph = exporter.buildVideoFilterComplex(
        project: project,
        segmentsToUse: [segment(0.0, 10.0)],
        trimmedChunks: const [],
        validEmojiWords: const [],
        sfxItems: const [],
        assPath: 'subtitles.ass',
        conversionMode: AspectConversionMode.speakerTrack,
        sourceWidth: 1920,
        sourceHeight: 1080,
        speakerIntervals: const [
          SpeakerInterval(speaker: 'Host', speakerIndex: 0, start: 0.0, end: 4.0),
          SpeakerInterval(speaker: 'Guest', speakerIndex: 1, start: 4.0, end: 8.0),
        ],
      );

      expect(graph, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(graph, contains('crop=1080:1920:x=\'if(between(t,0.00,4.00)'));
      expect(graph, contains('between(t,4.00,8.00)'));
      expect(graph, contains('[v_reframed]'));
    });

    test('buildBRollOverlayFilter fullscreen cutaway produces scale and crop with repeat', () {
      const clip = BRollClip(
        id: 'broll_1',
        mediaPath: 'cutaway.mp4',
        startTime: 1.5,
        endTime: 4.5,
        isPictureInPicture: false,
      );

      final filter = FfmpegFilterBuilder.buildBRollOverlayFilter(
        clip: clip,
        inputIndex: 2,
        targetWidth: 1080,
        targetHeight: 1920,
        exportScale: 3.0,
        inputStream: '[v_trimmed]',
        outputStream: '[v_broll_0]',
      );

      expect(filter, contains('[2:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,format=rgba,setpts=PTS-STARTPTS+1.500/TB[broll_scaled_2]'));
      expect(filter, contains('[v_trimmed][broll_scaled_2]overlay=x=0:y=0:eof_action=repeat:enable=\'between(t,1.500,4.500)\'[v_broll_0]'));
    });

    test('buildBRollOverlayFilter picture-in-picture produces corner positions', () {
      for (final (pos, expr) in [
        ('top_right', 'x=W-w-60:y=60'),
        ('top_left', 'x=60:y=60'),
        ('bottom_right', 'x=W-w-60:y=H-h-60'),
        ('bottom_left', 'x=60:y=H-h-60'),
      ]) {
        final clip = BRollClip(
          id: 'broll_pip',
          mediaPath: 'pip_face.mp4',
          startTime: 2.0,
          endTime: 5.0,
          isPictureInPicture: true,
          pipPosition: pos,
        );

        final filter = FfmpegFilterBuilder.buildBRollOverlayFilter(
          clip: clip,
          inputIndex: 3,
          targetWidth: 1080,
          targetHeight: 1920,
          exportScale: 3.0,
          inputStream: '[v_base]',
          outputStream: '[v_pip]',
        );

        expect(filter, contains('[3:v]scale=389:-2,format=rgba,setpts=PTS-STARTPTS+2.000/TB[broll_scaled_3]'));
        expect(filter, contains('overlay=$expr:eof_action=repeat:enable=\'between(t,2.000,5.000)\''));
      }
    });

    test('buildVideoFilterComplex with B-roll overlays video stream and shifts bgm and sfx input indices', () {
      final tempDir = Directory.systemTemp.createTempSync('broll_test_');
      final fakeMediaFile = File('${tempDir.path}/fake_broll.mp4')..writeAsStringSync('fake');

      try {
        final brollClip = BRollClip(
          id: 'clip_real',
          mediaPath: fakeMediaFile.path,
          startTime: 1.0,
          endTime: 3.5,
          isPictureInPicture: false,
        );

        final graph = exporter.buildVideoFilterComplex(
          project: project,
          segmentsToUse: [segment(0.0, 10.0)],
          trimmedChunks: const [],
          validEmojiWords: const [],
          sfxItems: [
            SfxExportItem(
              soundEffect: 'whoosh',
              soundVolume: 100,
              start: 1.0,
              end: 1.5,
              resolvedPath: 'whoosh.mp3',
            ),
          ],
          assPath: 'subtitles.ass',
          backgroundMusic: const BackgroundMusicConfig(
            musicPath: 'music.mp3',
            volume: 0.25,
            enableDucking: true,
          ),
          bRollClips: [brollClip],
        );

        // B-roll input is index 1 (no emojis).
        expect(graph, contains('[1:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920'));
        expect(graph, contains('[v_trimmed][broll_scaled_1]overlay=x=0:y=0:eof_action=repeat:enable=\'between(t,1.000,3.500)\'[v_broll_0]'));
        // Subtitles applied on top of the B-roll output stream
        expect(graph, contains('[v_broll_0]subtitles='));
        // Background music index shifted to index 2 (1 base + 0 emoji + 1 broll)
        expect(graph, contains('[2:a]aloop='));
        // SFX index shifted to index 3 (2 BGM + 1)
        expect(graph, contains('[3:a]volume=volume=1.0'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('buildVideoFilterComplex mixes B-roll video audio stream when volume > 0', () {
      final tempDir = Directory.systemTemp.createTempSync('broll_audio_test_');
      final fakeMediaFile = File('${tempDir.path}/fake_broll_sound.mp4')..writeAsStringSync('fake');

      try {
        final brollClip = BRollClip(
          id: 'clip_with_sound',
          mediaPath: fakeMediaFile.path,
          startTime: 2.0,
          endTime: 5.0,
          volume: 0.8,
          hasAudio: true,
        );

        final graph = exporter.buildVideoFilterComplex(
          project: project,
          segmentsToUse: [segment(0.0, 10.0)],
          trimmedChunks: const [],
          validEmojiWords: const [],
          sfxItems: const [],
          assPath: 'subtitles.ass',
          bRollClips: [brollClip],
        );

        // B-roll audio is index 1:a, trimmed, volume scaled, delayed to 2000ms
        expect(graph, contains('[1:a]atrim=0:3.000,asetpts=PTS-STARTPTS,volume=0.80,adelay=2000|2000[broll_audio_0]'));
        expect(graph, contains('amix=inputs=2:duration=first:normalize=0[a_final]'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
