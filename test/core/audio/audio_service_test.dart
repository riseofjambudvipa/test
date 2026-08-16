import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:capstudio/core/audio/audio_service.dart';
import '../../mocks/mocks.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(silenceLogs: true);

  late AudioService audioService;
  late List<MockAudioPlayer> createdPlayers;

  setUpAll(() {
    registerFallbackValue(Uri.parse(''));
  });

  setUp(() {
    audioService = AudioService.instance;
    createdPlayers = [];
    audioService.playerFactory = () {
      final mock = MockAudioPlayer();
      createdPlayers.add(mock);

      // Default stubs
      when(() => mock.setVolume(any())).thenAnswer((_) async {});
      when(() => mock.setFilePath(any(), initialPosition: any(named: 'initialPosition')))
          .thenAnswer((_) async => const Duration(seconds: 1));
      when(() => mock.setAsset(any(), preload: any(named: 'preload'), initialPosition: any(named: 'initialPosition')))
          .thenAnswer((_) async => const Duration(seconds: 1));
      when(() => mock.play()).thenAnswer((_) async {});
      when(() => mock.stop()).thenAnswer((_) async {});
      when(() => mock.dispose()).thenAnswer((_) async {});
      when(() => mock.playerStateStream).thenAnswer((_) => Stream.value(PlayerState(true, ProcessingState.completed)));

      return mock;
    };
  });

  tearDown(() async {
    await audioService.stopAll();
    audioService.playerFactory = null;
  });

  group('AudioService SFX Tests', () {
    test('should register and retrieve sound effect paths', () {
      audioService.registerSfx('test_pop', 'assets/audio/pop.wav');
      expect(audioService.getSfxPath('test_pop'), 'assets/audio/pop.wav');
    });

    test('should return null for unregistered SFX', () {
      expect(audioService.getSfxPath('unknown'), isNull);
    });

    test('should log warning and return early if playing unregistered SFX', () async {
      await audioService.playSfx('non_existent', 0.5);
      expect(createdPlayers.isEmpty, true);
    });

    test('should configure volume and play asset SFX when path is registered', () async {
      audioService.registerSfx('pop', 'assets/audio/pop.wav');

      await audioService.playSfx('pop', 0.85);

      expect(createdPlayers.length, 1);
      final player = createdPlayers.first;
      verify(() => player.setVolume(0.85)).called(1);
      verify(() => player.setAsset('assets/audio/pop.wav')).called(1);
      verify(() => player.play()).called(1);
      verify(() => player.dispose()).called(1);
    });

    test('should clamp playSfx volumes to valid 0.0 to 1.0 ranges', () async {
      audioService.registerSfx('pop', 'assets/audio/pop.wav');

      await audioService.playSfx('pop', 1.5);
      await audioService.playSfx('pop', -0.5);

      expect(createdPlayers.length, 2);
      verify(() => createdPlayers[0].setVolume(1.0)).called(1);
      verify(() => createdPlayers[1].setVolume(0.0)).called(1);
    });

    test('should evict and dispose the oldest player if polyphonic pool exceeds max capacity of 8', () async {
      audioService.registerSfx('loop', 'assets/audio/ding.wav');

      // Stub playerStateStream to remain in playing state so players stay active in the pool
      final activeMockPlayers = <MockAudioPlayer>[];
      audioService.playerFactory = () {
        final mock = MockAudioPlayer();
        activeMockPlayers.add(mock);
        when(() => mock.setVolume(any())).thenAnswer((_) async {});
        when(() => mock.setAsset(any(), preload: any(named: 'preload'), initialPosition: any(named: 'initialPosition')))
            .thenAnswer((_) async => const Duration(seconds: 1));
        when(() => mock.play()).thenAnswer((_) async {});
        when(() => mock.stop()).thenAnswer((_) async {});
        when(() => mock.dispose()).thenAnswer((_) async {});
        // Make the stream hang/stay loading/playing so they don't auto-dispose
        when(() => mock.playerStateStream).thenAnswer((_) => StreamController<PlayerState>().stream);
        return mock;
      };

      // Play 8 concurrent SFX to fill the pool
      final futures = <Future<void>>[];
      for (int i = 0; i < 8; i++) {
        futures.add(audioService.playSfx('loop', 0.5));
      }

      // Allow event loops to process and setup active players
      await Future.delayed(const Duration(milliseconds: 50));
      expect(activeMockPlayers.length, 8);

      // Play the 9th SFX which must trigger pool eviction of the 1st player
      futures.add(audioService.playSfx('loop', 0.5));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(activeMockPlayers.length, 9);
      // The oldest player (activeMockPlayers[0]) should have been stopped and disposed
      verify(() => activeMockPlayers[0].stop()).called(1);
      verify(() => activeMockPlayers[0].dispose()).called(1);
    });

    test('should concurrently stop and dispose all active players on stopAll()', () async {
      audioService.registerSfx('pop', 'assets/audio/pop.wav');

      // Set players to hang in active state
      audioService.playerFactory = () {
        final mock = MockAudioPlayer();
        when(() => mock.setVolume(any())).thenAnswer((_) async {});
        when(() => mock.setAsset(any(), preload: any(named: 'preload'), initialPosition: any(named: 'initialPosition')))
            .thenAnswer((_) async => const Duration(seconds: 1));
        when(() => mock.play()).thenAnswer((_) async {});
        when(() => mock.stop()).thenAnswer((_) async {});
        when(() => mock.dispose()).thenAnswer((_) async {});
        when(() => mock.playerStateStream).thenAnswer((_) => StreamController<PlayerState>().stream);
        createdPlayers.add(mock);
        return mock;
      };

      // Start 3 active players
      unawaited(audioService.playSfx('pop', 0.5));
      unawaited(audioService.playSfx('pop', 0.5));
      unawaited(audioService.playSfx('pop', 0.5));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(createdPlayers.length, 3);

      await audioService.stopAll();

      for (final player in createdPlayers) {
        verify(() => player.stop()).called(1);
        verify(() => player.dispose()).called(1);
      }
    });

    test('ensureDefaultSfx should synthesize exactly 44 unique WAV files and register them all', () async {
      final tempDir = Directory.systemTemp.createTempSync('capstudio_sfx_test_');

      try {
        await audioService.ensureDefaultSfx(tempDir.path);

        // All 44 sounds are uniquely synthesized — no aliases or file copies
        final generatedFiles = tempDir.listSync().whereType<File>().toList();
        expect(generatedFiles.length, equals(44),
            reason: 'Expected exactly 44 unique WAV files (42 original + whoosh + sweep)');

        // Core sounds registered and exist on disk
        for (final sfxId in ['whoosh_fast', 'whoosh_slow', 'whoosh',
                              'sweep_up', 'sweep_down', 'sweep', 'echo',
                              'pop', 'boom', 'bell', 'coin', 'glitch']) {
          final path = audioService.getSfxPath(sfxId);
          expect(path, isNotNull, reason: '$sfxId should be registered');
          expect(File(path!).existsSync(), true, reason: '$sfxId WAV should exist');
          expect(File(path).lengthSync(), greaterThan(44),
              reason: '$sfxId should have synthesized PCM data beyond the 44-byte header');
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('whoosh, sweep and echo should be unique files — not aliases of each other', () async {
      final tempDir = Directory.systemTemp.createTempSync('capstudio_sfx_unique_test_');

      try {
        await audioService.ensureDefaultSfx(tempDir.path);

        final whooshBytes      = File(audioService.getSfxPath('whoosh')!).readAsBytesSync();
        final whooshFastBytes  = File(audioService.getSfxPath('whoosh_fast')!).readAsBytesSync();
        final sweepBytes       = File(audioService.getSfxPath('sweep')!).readAsBytesSync();
        final echoBytes        = File(audioService.getSfxPath('echo')!).readAsBytesSync();

        // whoosh must differ from whoosh_fast in length or content
        final whooshIsUnique = whooshBytes.length != whooshFastBytes.length ||
            whooshBytes.sublist(44, 50).toString() != whooshFastBytes.sublist(44, 50).toString();
        expect(whooshIsUnique, true,
            reason: 'whoosh.wav must be a unique synthesis, not a copy of whoosh_fast.wav');

        // sweep must differ from echo
        final sweepIsUnique = sweepBytes.length != echoBytes.length ||
            sweepBytes.sublist(44, 50).toString() != echoBytes.sublist(44, 50).toString();
        expect(sweepIsUnique, true,
            reason: 'sweep.wav must be a unique synthesis, not a copy of echo.wav');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ensureDefaultSfx should synthesize and register the 6 new premium sound effects', () async {
      final tempDir = Directory.systemTemp.createTempSync('capstudio_premium_sfx_test_');

      try {
        await audioService.ensureDefaultSfx(tempDir.path);

        final premiumSfxIds = [
          'swish_futuristic',
          'sparkle_magical',
          'cymbal_swell',
          'laser_shot',
          'heavy_impact',
          'synth_chime',
        ];

        for (final sfxId in premiumSfxIds) {
          final sfxPath = audioService.getSfxPath(sfxId);
          expect(sfxPath, isNotNull, reason: 'SFX $sfxId path should be registered');
          final sfxFile = File(sfxPath!);
          expect(sfxFile.existsSync(), true, reason: 'SFX $sfxId WAV file should exist on disk');
          expect(sfxFile.lengthSync(), greaterThan(44),
              reason: 'SFX $sfxId WAV file should contain synthesized samples beyond 44-byte header');
          // Each premium SFX must differ from each other (no duplicate generators)
          for (final otherId in premiumSfxIds.where((id) => id != sfxId)) {
            final otherPath = audioService.getSfxPath(otherId)!;
            final isSameLength = sfxFile.lengthSync() == File(otherPath).lengthSync();
            if (isSameLength) {
              final a = sfxFile.readAsBytesSync().sublist(44, 60);
              final b = File(otherPath).readAsBytesSync().sublist(44, 60);
              expect(a.toString() == b.toString(), false,
                  reason: '$sfxId and $otherId must have distinct PCM content');
            }
          }
        }

        // Verify playback integration for one premium SFX
        await audioService.playSfx('swish_futuristic', 0.9);
        expect(createdPlayers.length, 1);
        final player = createdPlayers.first;
        verify(() => player.setVolume(0.9)).called(1);
        verify(() => player.setFilePath(any())).called(1);
        verify(() => player.play()).called(1);
        verify(() => player.dispose()).called(1);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('SfxData serialization & parsing tests', () {
      test('should parse empty and null strings correctly', () {
        final dataNull = SfxData.parse(null);
        expect(dataNull.chunk, isNull);
        expect(dataNull.word, isNull);

        final dataEmpty = SfxData.parse('');
        expect(dataEmpty.chunk, isNull);
        expect(dataEmpty.word, isNull);
      });

      test('should parse legacy raw word sfx correctly', () {
        final data = SfxData.parse('pop', fallbackVolume: 75);
        expect(data.chunk, isNull);
        expect(data.word, isNotNull);
        expect(data.word!.name, 'pop');
        expect(data.word!.volume, 75);
      });

      test('should parse legacy raw chunk sfx correctly', () {
        final data = SfxData.parse('chunk:whoosh', fallbackVolume: 80);
        expect(data.word, isNull);
        expect(data.chunk, isNotNull);
        expect(data.chunk!.name, 'whoosh');
        expect(data.chunk!.volume, 80);
      });

      test('should parse inline volume formats correctly', () {
        final data = SfxData.parse('pop:60');
        expect(data.chunk, isNull);
        expect(data.word, isNotNull);
        expect(data.word!.name, 'pop');
        expect(data.word!.volume, 60);
      });

      test('should parse compound chunk and word sfx formats correctly', () {
        final data1 = SfxData.parse('chunk:whoosh:80|pop:90');
        expect(data1.chunk!.name, 'whoosh');
        expect(data1.chunk!.volume, 80);
        expect(data1.word!.name, 'pop');
        expect(data1.word!.volume, 90);

        final data2 = SfxData.parse('chunk:whoosh:80|');
        expect(data2.chunk!.name, 'whoosh');
        expect(data2.chunk!.volume, 80);
        expect(data2.word, isNull);

        final data3 = SfxData.parse('|pop:90');
        expect(data3.chunk, isNull);
        expect(data3.word!.name, 'pop');
        expect(data3.word!.volume, 90);
      });

      test('should serialize correctly using toRaw()', () {
        final data1 = SfxData(
          chunk: SfxItem('whoosh', 80),
          word: SfxItem('pop', 95),
        );
        expect(data1.toRaw(), 'chunk:whoosh:80|pop:95');

        final data2 = SfxData(
          chunk: SfxItem('whoosh', 80),
        );
        expect(data2.toRaw(), 'chunk:whoosh:80');

        final data3 = SfxData(
          word: SfxItem('pop', 95),
        );
        expect(data3.toRaw(), 'pop:95');

        final data4 = SfxData();
        expect(data4.toRaw(), '');
      });
    });
  });
}
