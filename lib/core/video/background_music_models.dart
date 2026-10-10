import 'package:flutter/foundation.dart';

/// Configuration for background music track and voice ducking.
///
/// In modern viral creator workflows (CapCut, Submagic, Descript),
/// adding subtle background music with sidechain speech ducking (-12dB)
/// keeps audience engagement high without drowning out the spoken voiceover.
@immutable
class BackgroundMusicConfig {
  /// Path to the music file (.mp3, .wav, .m4a, .aac). If null or empty, no music is mixed.
  final String? musicPath;

  /// Background music volume (0.0 to 1.0, e.g. 0.20 = 20%).
  final double volume;

  /// Whether to loop the music track if the video is longer than the music file.
  final bool loop;

  /// Whether to enable smart voice ducking (-12dB ducking when speech is detected).
  final bool enableDucking;

  /// Ducking compression ratio (e.g. 4.0 for -12dB attenuation).
  final double duckingRatio;

  const BackgroundMusicConfig({
    this.musicPath,
    this.volume = 0.20,
    this.loop = true,
    this.enableDucking = true,
    this.duckingRatio = 4.0,
  });

  /// Whether a valid music track is configured
  bool get hasMusic => musicPath != null && musicPath!.trim().isNotEmpty;

  BackgroundMusicConfig copyWith({
    String? musicPath,
    double? volume,
    bool? loop,
    bool? enableDucking,
    double? duckingRatio,
  }) {
    return BackgroundMusicConfig(
      musicPath: musicPath ?? this.musicPath,
      volume: volume ?? this.volume,
      loop: loop ?? this.loop,
      enableDucking: enableDucking ?? this.enableDucking,
      duckingRatio: duckingRatio ?? this.duckingRatio,
    );
  }

  /// Converts configuration to a JSON map for persistence.
  Map<String, dynamic> toJson() => {
        'musicPath': musicPath,
        'volume': volume,
        'loop': loop,
        'enableDucking': enableDucking,
        'duckingRatio': duckingRatio,
      };

  /// Constructs a [BackgroundMusicConfig] from a decoded JSON map.
  factory BackgroundMusicConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundMusicConfig(
      musicPath: json['musicPath'] as String?,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.20,
      loop: json['loop'] as bool? ?? true,
      enableDucking: json['enableDucking'] as bool? ?? true,
      duckingRatio: (json['duckingRatio'] as num?)?.toDouble() ?? 4.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundMusicConfig &&
          runtimeType == other.runtimeType &&
          musicPath == other.musicPath &&
          volume == other.volume &&
          loop == other.loop &&
          enableDucking == other.enableDucking &&
          duckingRatio == other.duckingRatio;

  @override
  int get hashCode => Object.hash(
        musicPath,
        volume,
        loop,
        enableDucking,
        duckingRatio,
      );
}

