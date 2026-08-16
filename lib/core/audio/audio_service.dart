import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart' as mk;
import '../logger/logger_service.dart';
import '../assets/asset_path_service.dart';
import 'audio_synthesizer.dart';

abstract class BaseAudioPlayer {
  Future<void> setVolume(double volume);
  Future<void> setFilePath(String path);
  Future<void> setAsset(String assetPath);
  Future<void> setUri(String uri);
  Future<void> setBufferSource(List<int> bytes);
  Future<void> play();
  Future<void> waitTillCompleted(Duration timeout);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioPlayerImplementation implements BaseAudioPlayer {
  final AudioPlayer _player;
  JustAudioPlayerImplementation(this._player);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setFilePath(String path) => _player.setFilePath(path);

  @override
  Future<void> setAsset(String assetPath) => _player.setAsset(assetPath);

  @override
  Future<void> setUri(String uri) => _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));

  @override
  Future<void> setBufferSource(List<int> bytes) => _player.setAudioSource(MyBufferAudioSource(bytes));

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> waitTillCompleted(Duration timeout) async {
    await _player.playerStateStream.firstWhere(
      (state) => state.processingState == ProcessingState.completed,
    ).timeout(
      timeout,
      onTimeout: () => PlayerState(false, ProcessingState.completed),
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class MediaKitPlayerImplementation implements BaseAudioPlayer {
  final mk.Player _player;
  MediaKitPlayerImplementation(this._player);

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100.0);
  }

  @override
  Future<void> setFilePath(String path) async {
    await _player.open(mk.Media(path), play: false);
  }

  @override
  Future<void> setAsset(String assetPath) async {
    await _player.open(mk.Media('asset://$assetPath'), play: false);
  }

  @override
  Future<void> setUri(String uri) async {
    await _player.open(mk.Media(uri), play: false);
  }

  @override
  Future<void> setBufferSource(List<int> bytes) async {
    throw UnsupportedError("Buffer source is not supported on desktop platforms with media_kit");
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> waitTillCompleted(Duration timeout) async {
    await _player.stream.completed.firstWhere(
      (completed) => completed,
    ).timeout(
      timeout,
      onTimeout: () => true,
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _sfxPathCache.clear();
    _sfxBytesCache.clear();
    _activePlayers.clear();
    playerFactory = null;
    _isStopping = false;
  }

  Future<void> init() async {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (_isInitialized && !isTesting) return;
    _isInitialized = true;
    LoggerService.instance.log(LogLevel.info, 'AudioService', 'AudioService successfully initialized.');
  }

  /// Mockable factory for AudioPlayer instantiations in testing
  AudioPlayer Function()? playerFactory;

  // Cache to store preloaded asset/file paths
  final Map<String, String> _sfxPathCache = {};
  
  // In-memory bytes cache for Web and Fallbacks
  final Map<String, List<int>> _sfxBytesCache = {};
  
  // Active playing players pool to support polyphony (overlapping sounds)
  final Set<BaseAudioPlayer> _activePlayers = {};

  bool _isStopping = false;

  // Maximum concurrent players to prevent resource exhaustion
  static const int _maxConcurrentPlayers = 8;

  /// Registers a sound effect mapping (e.g. 'whoosh' -> 'path/to/whoosh.wav')
  void registerSfx(String sfxId, String filePathOrAsset) {
    _sfxPathCache[sfxId] = filePathOrAsset;
    LoggerService.instance.log(LogLevel.info, 'AudioService', 'Registered SFX: $sfxId -> $filePathOrAsset');
  }

  /// Get registered SFX path
  String? getSfxPath(String sfxId) {
    final cleanSfxId = sfxId.startsWith('chunk:') ? sfxId.replaceFirst('chunk:', '') : sfxId;
    return _sfxPathCache[cleanSfxId];
  }

  /// Plays a registered sound effect with polyphonic support and custom volume scaling.
  /// Completes the returned Future when the playback is fully finished (with safety timeout).
  Future<void> playSfx(String sfxId, double volume) async {
    if (_isStopping) return;
    final cleanSfxId = sfxId.startsWith('chunk:') ? sfxId.replaceFirst('chunk:', '') : sfxId;
    final path = _sfxPathCache[cleanSfxId];
    final inMemoryBytes = _sfxBytesCache[cleanSfxId];
    if (path == null && inMemoryBytes == null) {
      LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Cannot play SFX: $sfxId (not registered)');
      return;
    }

    BaseAudioPlayer? player;
    try {
      // Enforce player pool limit — dispose the oldest player if at capacity
      if (_activePlayers.length >= _maxConcurrentPlayers) {
        final oldest = _activePlayers.first;
        _activePlayers.remove(oldest);
        try {
          await oldest.stop();
          await oldest.dispose();
          LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Polyphonic pool limit reached. Disposed oldest player.');
        } catch (e, stackTrace) {
          LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Failed to stop or dispose oldest player: $e', stackTrace: stackTrace);
        }
      }

      if (playerFactory != null) {
        player = JustAudioPlayerImplementation(playerFactory!());
      } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        player = MediaKitPlayerImplementation(mk.Player());
      } else {
        player = JustAudioPlayerImplementation(AudioPlayer());
      }
      _activePlayers.add(player);

      // Set volume (0.0 to 1.0 range)
      await player.setVolume(volume.clamp(0.0, 1.0));

      LoggerService.instance.log(LogLevel.action, 'AudioService', 'Playing SFX: $sfxId (Volume: ${(volume * 100).toInt()}%)');

      if (inMemoryBytes != null) {
        await player.setBufferSource(inMemoryBytes);
      } else if (path != null) {
        // Handle asset vs local file path
        if (path.startsWith('memory://')) {
          final key = path.replaceFirst('memory://', '');
          final bytes = _sfxBytesCache[key];
          if (bytes != null) {
            await player.setBufferSource(bytes);
          } else {
            throw Exception('In-memory bytes not found for $key');
          }
        } else if (!kIsWeb && File(path).existsSync()) {
          await player.setFilePath(path);
        } else if (path.startsWith('assets/')) {
          await player.setAsset(path);
        } else if (path.startsWith('blob:') || path.startsWith('data:')) {
          await player.setUri(path);
        } else if (!kIsWeb) {
          // Fallback: check if the file is in the configured sfxDir directory
          final filename = p.basename(path);
          final localSfxFile = File(p.join(AssetPathService.instance.sfxDir, filename));
          if (localSfxFile.existsSync()) {
            await player.setFilePath(localSfxFile.path);
          } else {
            throw FileSystemException("Sound effect file not found on disk: $path");
          }
        } else {
          throw Exception("Sound effect source not supported on Web: $path");
        }
      }

      // Play the audio
      await player.play();

      // Wait for playback to fully finish
      await player.waitTillCompleted(const Duration(seconds: 4));
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'AudioService', 'Failed to play SFX $sfxId: $e');
    } finally {
      if (player != null) {
        final wasActive = _activePlayers.remove(player);
        if (wasActive) {
          try {
            await player.dispose();
          } catch (e, stackTrace) {
            LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Failed to dispose player in playSfx finally block: $e', stackTrace: stackTrace);
          }
        }
      }
    }
  }

  /// Stops all active sound effects immediately (parallel teardown).
  Future<void> stopAll() async {
    _isStopping = true;
    final playersToDispose = List<BaseAudioPlayer>.from(_activePlayers);
    _activePlayers.clear();

    if (playersToDispose.isEmpty) {
      _isStopping = false;
      return;
    }

    LoggerService.instance.log(LogLevel.info, 'AudioService',
        'Stopping ${playersToDispose.length} active SFX players (parallel).');

    // Dispose all players concurrently instead of sequentially.
    // Sequential disposal at ~150ms each was the main cause of 1-2s shutdown lag.
    try {
      await Future.wait(
        playersToDispose.map((player) async {
          try {
            await player.stop();
            await player.dispose();
          } catch (e, stackTrace) {
            LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Failed to stop/dispose player during mass teardown: $e', stackTrace: stackTrace);
          }
        }),
      ).timeout(const Duration(milliseconds: 800), onTimeout: () => []);
    } finally {
      _isStopping = false;
    }
  }

  /// Synthesizes and writes default SFX files offline if they do not exist.
  /// Generates sound effects based on the configuration and registers them.
  Future<void> ensureDefaultSfx(String sfxDirPath) async {
    // Guard: Avoid redundant disk checks and log spam if already registered in this session
    if (_sfxPathCache.length >= 44) {
      return;
    }

    const int sampleRate = 22050;
    final Map<String, List<int> Function(int)> generators = {
      // ── Whoosh family ───────────────────────────────────────────────
      'whoosh_fast':  AudioSynthesizer.generateWhooshFast,
      'whoosh_slow':  AudioSynthesizer.generateWhooshSlow,
      'whoosh':       AudioSynthesizer.generateWhoosh,       // unique: mid-speed air turbulence
      // ── Swipe & Sweep family ────────────────────────────────────────
      'swipe_left':   (int sr) => AudioSynthesizer.generateSwipe(sr, true),
      'swipe_right':  (int sr) => AudioSynthesizer.generateSwipe(sr, false),
      'sweep_up':     AudioSynthesizer.generateSweepUp,
      'sweep_down':   AudioSynthesizer.generateSweepDown,
      'sweep':        AudioSynthesizer.generateSweep,        // unique: harmonic sine sweep
      'echo':         AudioSynthesizer.generateEcho,         // unique: delay echo sweep
      // ── Impact family ───────────────────────────────────────────────
      'pop':          AudioSynthesizer.generatePop,
      'pop_deep':     AudioSynthesizer.generatePopDeep,
      'boom':         AudioSynthesizer.generateBoom,
      'thud':         AudioSynthesizer.generateThud,
      'punch':        AudioSynthesizer.generatePunch,
      'stamp':        AudioSynthesizer.generateStamp,
      // ── Tonal / Bell family ─────────────────────────────────────────
      'bell':         AudioSynthesizer.generateBell,
      'chime':        AudioSynthesizer.generateChime,
      'blip':         AudioSynthesizer.generateBlip,
      'ding':         AudioSynthesizer.generateDing,
      'ping':         AudioSynthesizer.generatePing,
      // ── Quirky / Fun family ─────────────────────────────────────────
      'drop':         AudioSynthesizer.generateDrop,
      'boing':        AudioSynthesizer.generateBoing,
      'bounce':       AudioSynthesizer.generateBounce,
      'squeak':       AudioSynthesizer.generateSqueak,
      'coin':         AudioSynthesizer.generateCoin,
      'sparkle':      AudioSynthesizer.generateSparkle,
      'glitch':       AudioSynthesizer.generateGlitch,
      // ── Cinematic / Mood family ─────────────────────────────────────
      'rise':         AudioSynthesizer.generateRise,
      'tension':      AudioSynthesizer.generateTension,
      'drop_bass':    AudioSynthesizer.generateBassDrop,
      'reverse':      (int sr) => AudioSynthesizer.generateReverse(sr),
      'tape_stop':    AudioSynthesizer.generateTapeStop,
      // ── Game / UI family ────────────────────────────────────────────
      'level_up':     AudioSynthesizer.generateLevelUp,
      'fail':         AudioSynthesizer.generateFail,
      'correct':      AudioSynthesizer.generateCorrect,
      'wrong':        AudioSynthesizer.generateWrong,
      'power_up':     AudioSynthesizer.generatePowerUp,
      'game_over':    AudioSynthesizer.generateGameOver,
      // ── Premium SFX ─────────────────────────────────────────────────
      'swish_futuristic': AudioSynthesizer.generateSwishFuturistic,
      'sparkle_magical':  AudioSynthesizer.generateSparkleMagical,
      'cymbal_swell':     AudioSynthesizer.generateCymbalSwell,
      'laser_shot':       AudioSynthesizer.generateLaserShot,
      'heavy_impact':     AudioSynthesizer.generateHeavyImpact,
      'synth_chime':      AudioSynthesizer.generateSynthChime,
    };
    // All 44 sounds are uniquely synthesized — no aliases needed.

    LoggerService.instance.log(LogLevel.info, 'AudioService', 'Verifying default SFX files: $sfxDirPath');
    for (final entry in generators.entries) {
      final sfxId = entry.key;
      try {
        if (kIsWeb) {
          final bytes = entry.value(sampleRate);
          _sfxBytesCache[sfxId] = bytes;
          registerSfx(sfxId, 'memory://$sfxId');
          continue;
        }
        final file = File(p.join(sfxDirPath, '$sfxId.wav'));
        if (!await file.exists()) {
          try {
            // Attempt to load from pre-bundled assets first (incredibly fast, zero startup lag)
            final byteData = await rootBundle.load('assets/sfx/$sfxId.wav');
            final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
            await file.writeAsBytes(bytes);
            LoggerService.instance.log(LogLevel.info, 'AudioService', 'Copied pre-bundled SFX from assets: $sfxId');
          } catch (e) {
            // Fallback to dynamic mathematical wave synthesis if the asset is missing
            LoggerService.instance.log(LogLevel.warning, 'AudioService', 'Pre-bundled asset not found for $sfxId. Synthesizing...');
            final bytes = entry.value(sampleRate);
            await file.writeAsBytes(bytes);
          }
        }
        registerSfx(sfxId, file.path);
      } catch (e, stackTrace) {
        LoggerService.instance.log(LogLevel.error, 'AudioService', 'Failed to generate default SFX $sfxId: $e', stackTrace: stackTrace);
      }
    }
  }
}

class SfxItem {
  final String name;
  final int volume;
  SfxItem(this.name, this.volume);
}

class SfxData {
  final SfxItem? chunk;
  final SfxItem? word;

  SfxData({this.chunk, this.word});

  static SfxData parse(String? raw, {int fallbackVolume = 100}) {
    if (raw == null || raw.isEmpty) {
      return SfxData();
    }
    
    SfxItem? parseItem(String part, {required bool isChunk}) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) return null;
      String name = trimmed;
      if (isChunk && name.startsWith('chunk:')) {
        name = name.substring(6);
      }
      int volume = fallbackVolume;
      if (name.contains(':')) {
        final idx = name.lastIndexOf(':');
        final volStr = name.substring(idx + 1);
        final parsedVol = int.tryParse(volStr);
        if (parsedVol != null) {
          name = name.substring(0, idx);
          volume = parsedVol;
        }
      }
      if (name.isEmpty) return null;
      return SfxItem(name, volume);
    }

    if (raw.contains('|')) {
      final parts = raw.split('|');
      return SfxData(
        chunk: parseItem(parts[0], isChunk: true),
        word: parseItem(parts[1], isChunk: false),
      );
    }

    if (raw.startsWith('chunk:')) {
      return SfxData(chunk: parseItem(raw, isChunk: true));
    }
    
    return SfxData(word: parseItem(raw, isChunk: false));
  }

  String toRaw() {
    if (chunk == null && word == null) return '';
    final chunkStr = chunk != null ? 'chunk:${chunk!.name}:${chunk!.volume}' : '';
    final wordStr = word != null ? '${word!.name}:${word!.volume}' : '';
    if (chunkStr.isEmpty) return wordStr;
    if (wordStr.isEmpty) return chunkStr;
    return '$chunkStr|$wordStr';
  }
}

// ignore: experimental_member_use
class MyBufferAudioSource extends StreamAudioSource {
  final List<int> _bytes;
  MyBufferAudioSource(this._bytes);

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    // ignore: experimental_member_use
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

