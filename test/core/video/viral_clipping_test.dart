import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/viral_clip_models.dart';
import 'package:capstudio/core/video/aspect_ratio_converter.dart';
import 'package:capstudio/core/video/silence_detector.dart';
import 'package:capstudio/core/video/viral_hook_detector.dart';
import 'package:capstudio/core/database/schemas/word.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Viral Video Clipping Engine Tests', () {
    test('AspectRatioConverter generates valid FFmpeg filters', () {
      final blurFilter = AspectRatioConverter.buildBlurPillarboxFilter(
        inputWidth: 1920,
        inputHeight: 1080,
        targetWidth: 1080,
        targetHeight: 1920,
      );
      expect(blurFilter, contains('boxblur'));
      expect(blurFilter, contains('scale=1080:1920'));
      expect(blurFilter, contains('overlay='));

      final cropFilter = AspectRatioConverter.buildCenterCropFilter(
        inputWidth: 1920,
        inputHeight: 1080,
        targetWidth: 1080,
        targetHeight: 1920,
      );
      expect(cropFilter, contains('crop='));
      expect(cropFilter, contains('1080'));
      expect(cropFilter, contains('1920'));

      final splitFilter = AspectRatioConverter.buildSplitScreenFilter(
        topInputWidth: 1920,
        topInputHeight: 1080,
        bottomInputWidth: 1920,
        bottomInputHeight: 1080,
        targetWidth: 1080,
        targetHeight: 1920,
      );
      expect(splitFilter, contains('vstack=inputs=2'));
      expect(splitFilter, contains('crop='));

      final faceTrackFilter = AspectRatioConverter.buildSmartFaceTrackFilter(
        inputWidth: 1920,
        inputHeight: 1080,
        targetWidth: 1080,
        targetHeight: 1920,
        focalX: 0.5,
        focalY: 0.25,
      );
      expect(faceTrackFilter, contains('scale=1080:1920:force_original_aspect_ratio=increase'));
      expect(faceTrackFilter, contains('crop=1080:1920:(in_w-1080)*0.5:(in_h-1920)*0.25'));
    });

    test('SilenceDetector generateActiveSegments inverts silence segments accurately', () {
      final detector = SilenceDetector();

      // Video is 10.0 seconds long with silence from 2.0 to 4.0 and 7.0 to 8.5
      final silences = [
        SilenceSegment(start: 2.0, end: 4.0, duration: 2.0),
        SilenceSegment(start: 7.0, end: 8.5, duration: 1.5),
      ];

      final active = detector.generateActiveSegments(
        silenceSegments: silences,
        totalDuration: 10.0,
      );

      expect(active.length, 3);
      // Segment 1: 0.0 - 2.0 (2.0s)
      expect(active[0].start, 0.0);
      expect(active[0].end, 2.0);
      expect(active[0].duration, 2.0);

      // Segment 2: 4.0 - 7.0 (3.0s)
      expect(active[1].start, 4.0);
      expect(active[1].end, 7.0);
      expect(active[1].duration, 3.0);

      // Segment 3: 8.5 - 10.0 (1.5s)
      expect(active[2].start, 8.5);
      expect(active[2].end, 10.0);
      expect(active[2].duration, 1.5);
    });

    test('SilenceDetector handles silence at video boundaries', () {
      final detector = SilenceDetector();

      // Silence at start (0.0 - 1.0) and at end (9.0 - 10.0)
      final silences = [
        SilenceSegment(start: 0.0, end: 1.0, duration: 1.0),
        SilenceSegment(start: 9.0, end: 10.0, duration: 1.0),
      ];

      final active = detector.generateActiveSegments(
        silenceSegments: silences,
        totalDuration: 10.0,
      );

      expect(active.length, 1);
      expect(active[0].start, 1.0);
      expect(active[0].end, 9.0);
      expect(active[0].duration, 8.0);
    });

    test('ViralHookDetector detects high-energy hooks and calculates WPM', () {
      final detector = ViralHookDetector();

      final words = <WordSchema>[
        WordSchema()..wordId = '1'..text = 'The'..start = 0.0..end = 0.3,
        WordSchema()..wordId = '2'..text = 'secret'..start = 0.3..end = 0.7,
        WordSchema()..wordId = '3'..text = 'to'..start = 0.7..end = 0.9,
        WordSchema()..wordId = '4'..text = 'viral'..start = 0.9..end = 1.4,
        WordSchema()..wordId = '5'..text = 'growth'..start = 1.4..end = 1.9,
        WordSchema()..wordId = '6'..text = 'is'..start = 1.9..end = 2.2,
        WordSchema()..wordId = '7'..text = 'simple.'..start = 2.2..end = 2.8,
      ];

      // Pad out to meet 30s min duration requirement
      for (int i = 8; i <= 80; i++) {
        final t = 2.8 + (i - 7) * 0.4;
        words.add(WordSchema()
          ..wordId = '$i'
          ..text = 'word$i'
          ..start = t
          ..end = t + 0.35);
      }

      final candidates = detector.detectHooks(
        words: words,
        minDuration: 20.0,
        maxDuration: 60.0,
      );

      expect(candidates, isNotEmpty);
      final topCandidate = candidates.first;
      expect(topCandidate.hookText, equals('the secret to'));
      expect(topCandidate.score, greaterThan(50.0));
      expect(topCandidate.wordsPerMinute, greaterThan(100.0));
      expect(topCandidate.duration, greaterThanOrEqualTo(20.0));
    });

    test('ViralHookDetector detects multilingual hooks (Spanish, Hindi, French)', () {
      final detector = ViralHookDetector();

      // Spanish hook: "sabías que"
      final spanishWords = <WordSchema>[
        WordSchema()..wordId = 's1'..text = 'sabías'..start = 0.0..end = 0.4,
        WordSchema()..wordId = 's2'..text = 'que'..start = 0.4..end = 0.8,
        WordSchema()..wordId = 's3'..text = 'este'..start = 0.8..end = 1.2,
        WordSchema()..wordId = 's4'..text = 'truco'..start = 1.2..end = 1.6,
        WordSchema()..wordId = 's5'..text = 'funciona?'..start = 1.6..end = 2.2,
      ];
      for (int i = 6; i <= 65; i++) {
        final t = 2.2 + (i - 5) * 0.4;
        spanishWords.add(WordSchema()
          ..wordId = 's$i'
          ..text = 'palabra$i'
          ..start = t
          ..end = t + 0.35);
      }
      final spanishCandidates = detector.detectHooks(
        words: spanishWords,
        minDuration: 20.0,
        maxDuration: 60.0,
      );
      expect(spanishCandidates, isNotEmpty);
      expect(spanishCandidates.first.hookText, equals('sabías que'));
      expect(spanishCandidates.first.hookCategory, equals('Curiosity Gap'));

      // Hindi hook: "kya aapko pata hai"
      final hindiWords = <WordSchema>[
        WordSchema()..wordId = 'h1'..text = 'kya'..start = 0.0..end = 0.3,
        WordSchema()..wordId = 'h2'..text = 'aapko'..start = 0.3..end = 0.7,
        WordSchema()..wordId = 'h3'..text = 'pata'..start = 0.7..end = 1.0,
        WordSchema()..wordId = 'h4'..text = 'hai'..start = 1.0..end = 1.4,
        WordSchema()..wordId = 'h5'..text = 'dosto?'..start = 1.4..end = 1.9,
      ];
      for (int i = 6; i <= 65; i++) {
        final t = 1.9 + (i - 5) * 0.4;
        hindiWords.add(WordSchema()
          ..wordId = 'h$i'
          ..text = 'shabd$i'
          ..start = t
          ..end = t + 0.35);
      }
      final hindiCandidates = detector.detectHooks(
        words: hindiWords,
        minDuration: 20.0,
        maxDuration: 60.0,
      );
      expect(hindiCandidates, isNotEmpty);
      expect(hindiCandidates.first.hookText, equals('kya aapko pata hai'));
      expect(hindiCandidates.first.hookCategory, equals('Curiosity Gap'));
    });

    test('ViralHookDetector calculateAcousticEnergy differentiates dynamic vs silent audio', () {
      final detector = ViralHookDetector();

      // Flat silent audio
      final flatAmplitudes = List<double>.filled(100, 0.01);
      final flatScore = detector.calculateAcousticEnergy(0.0, 10.0, flatAmplitudes, 10.0);

      // Punchy dynamic audio with varied speech cadence and enthusiastic peaks
      final dynamicAmplitudes = <double>[
        for (int i = 0; i < 100; i++) (i % 5 == 0) ? 0.9 : ((i % 2 == 0) ? 0.4 : 0.1),
      ];
      final dynamicScore = detector.calculateAcousticEnergy(0.0, 10.0, dynamicAmplitudes, 10.0);

      expect(dynamicScore, greaterThan(flatScore));
      expect(dynamicScore, greaterThan(15.0));

      // Graceful fallback on null or empty
      expect(detector.calculateAcousticEnergy(0.0, 10.0, null, 10.0), equals(12.5));
      expect(detector.calculateAcousticEnergy(0.0, 10.0, [], 10.0), equals(12.5));
    });

    test('ViralHookDetector calculateStoryArcScore detects 3-act narrative structure', () {
      final detector = ViralHookDetector();

      // 3-Act structured narrative: Opener -> Conflict -> Payoff
      final narrativeWords = <WordSchema>[
        // Act 1: Opener (0 - 8s)
        WordSchema()..text = 'Imagine'..start = 0.0..end = 1.0,
        WordSchema()..text = 'starting'..start = 1.0..end = 2.0,
        WordSchema()..text = 'a'..start = 2.0..end = 3.0,
        WordSchema()..text = 'channel'..start = 3.0..end = 4.0,
        // Act 2: Conflict / Tension (8 - 18s)
        WordSchema()..text = 'but'..start = 10.0..end = 11.0,
        WordSchema()..text = 'then'..start = 11.0..end = 12.0,
        WordSchema()..text = 'the'..start = 12.0..end = 13.0,
        WordSchema()..text = 'problem'..start = 13.0..end = 14.0,
        WordSchema()..text = 'hit'..start = 14.0..end = 15.0,
        // Act 3: Payoff / Resolution (18 - 25s)
        WordSchema()..text = 'finally'..start = 20.0..end = 21.0,
        WordSchema()..text = 'the'..start = 21.0..end = 22.0,
        WordSchema()..text = 'solution'..start = 22.0..end = 23.0,
        WordSchema()..text = 'worked'..start = 23.0..end = 25.0,
      ];

      final arcScore = detector.calculateStoryArcScore(narrativeWords);
      // Act 1 (9.0) + Act 2 (8.0) + Act 3 (8.0) = 25.0
      expect(arcScore, equals(25.0));

      // Monotone words without narrative arc
      final flatWords = <WordSchema>[
        WordSchema()..text = 'apple'..start = 0.0..end = 5.0,
        WordSchema()..text = 'banana'..start = 6.0..end = 12.0,
        WordSchema()..text = 'cherry'..start = 13.0..end = 25.0,
      ];
      final flatArcScore = detector.calculateStoryArcScore(flatWords);
      expect(flatArcScore, equals(0.0));
    });

    test('ViralHookDetector generateViralTitle produces high-CTR headlines', () {
      final words = <WordSchema>[
        WordSchema()..text = 'The'..start = 0.0..end = 0.5,
        WordSchema()..text = 'coding'..start = 0.5..end = 1.0,
        WordSchema()..text = 'coding'..start = 1.0..end = 1.5,
        WordSchema()..text = 'tips'..start = 1.5..end = 2.0,
      ];

      final curiosityTitle = ViralHookDetector.generateViralTitle(
        words,
        detectedCategory: 'Curiosity Gap',
      );
      expect(curiosityTitle, equals('The Truth About Coding'));

      final urgencyTitle = ViralHookDetector.generateViralTitle(
        words,
        detectedCategory: 'Action / Urgency',
      );
      expect(urgencyTitle, equals('Stop Making This Coding Mistake'));

      final valueTitle = ViralHookDetector.generateViralTitle(
        words,
        detectedCategory: 'Value Promise',
      );
      expect(valueTitle, equals('How To Master Coding'));
    });

    test('ViralHookDetector end-to-end detection populates acoustic & story arc scores and titles', () {
      final detector = ViralHookDetector();

      final words = <WordSchema>[
        WordSchema()..text = 'Did'..start = 0.0..end = 0.3,
        WordSchema()..text = 'you'..start = 0.3..end = 0.6,
        WordSchema()..text = 'know'..start = 0.6..end = 1.0,
        WordSchema()..text = 'coding'..start = 1.0..end = 1.4,
      ];
      for (int i = 5; i <= 60; i++) {
        final t = 1.4 + (i - 4) * 0.4;
        words.add(WordSchema()
          ..wordId = '$i'
          ..text = (i == 30) ? 'problem' : ((i == 55) ? 'solution.' : 'workflow$i')
          ..start = t
          ..end = t + 0.35);
      }

      final amplitudes = List<double>.generate(100, (i) => (i % 4 == 0) ? 0.8 : 0.2);

      final candidates = detector.detectHooks(
        words: words,
        amplitudes: amplitudes,
        totalDuration: 30.0,
        minDuration: 20.0,
        maxDuration: 60.0,
      );

      expect(candidates, isNotEmpty);
      final top = candidates.first;
      expect(top.acousticEnergyScore, greaterThan(0.0));
      expect(top.storyArcScore, greaterThan(0.0));
      expect(top.viralTitle, isNotEmpty);
      expect(top.displayTitle, isNotEmpty);
      expect(top.viralityReasons, isNotEmpty);
    });

    test('ViralHookDetector detects moments in short videos without needing 20s padding', () {
      final detector = ViralHookDetector();

      final words = <WordSchema>[
        WordSchema()..text = 'Never'..start = 0.0..end = 0.4,
        WordSchema()..text = 'do'..start = 0.4..end = 0.7,
        WordSchema()..text = 'this'..start = 0.7..end = 1.1,
        WordSchema()..text = 'again'..start = 1.1..end = 1.6,
        WordSchema()..text = 'when'..start = 1.6..end = 2.0,
        WordSchema()..text = 'editing'..start = 2.0..end = 2.5,
        WordSchema()..text = 'your'..start = 2.5..end = 2.9,
        WordSchema()..text = 'videos.'..start = 2.9..end = 3.5,
      ];

      final candidates = detector.detectHooks(
        words: words,
        totalDuration: 4.0,
        minDuration: 20.0,
        maxDuration: 60.0,
      );

      expect(candidates, isNotEmpty);
      expect(candidates.first.hookText, equals('never do this again'));
      expect(candidates.first.hookCategory, equals('Action / Urgency'));
      expect(candidates.first.score, greaterThan(40.0));
    });
  });
}
