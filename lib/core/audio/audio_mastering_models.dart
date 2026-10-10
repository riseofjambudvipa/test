/// Platform loudness mastering and vocal processing configurations for export.
enum AudioMasteringPlatform {
  /// YouTube Shorts, Instagram Reels, and TikTok loudness (-14 LUFS, TP -1.0, LRA 7).
  socialShorts(
    'Social Shorts / Reels / TikTok (-14 LUFS)',
    'loudnorm=I=-14:TP=-1.0:LRA=7',
    -14.0,
    'Optimized for mobile speakers and short-form algorithms with punchy vocal presence.',
  ),

  /// EBU R128 / ITU-R BS.1770 broadcast & podcast loudness standard (-16 LUFS, TP -1.5, LRA 11).
  broadcastPodcast(
    'Podcast & Broadcast (-16 LUFS)',
    'loudnorm=I=-16:TP=-1.5:LRA=11',
    -16.0,
    'Standard broadcast mastering for podcasts, YouTube long-form, and streaming.',
  ),

  /// Cinema & wide dynamic headroom standard (-23 LUFS, TP -2.0, LRA 14).
  cinemaHeadroom(
    'Cinematic Wide Headroom (-23 LUFS)',
    'loudnorm=I=-23:TP=-2.0:LRA=14',
    -23.0,
    'Maximum dynamic range preserving dramatic whispered-to-loud audio contrast.',
  );

  final String label;
  final String loudnormFilter;
  final double targetLufs;
  final String description;

  const AudioMasteringPlatform(
    this.label,
    this.loudnormFilter,
    this.targetLufs,
    this.description,
  );
}

/// Vocal processing and audio mastering configuration for export.
class AudioMasteringConfig {
  /// Whether AI Studio Sound voice polishing is enabled.
  final bool enableStudioSound;

  /// Target loudness platform standard.
  final AudioMasteringPlatform platform;

  /// Whether the intelligent vocal de-esser is active to tame harsh sibilance.
  final bool enableDeEsser;

  /// Intensity of the vocal de-essing filter (0.1 to 1.0, default 0.40).
  final double deEsserIntensity;

  const AudioMasteringConfig({
    this.enableStudioSound = false,
    this.platform = AudioMasteringPlatform.socialShorts,
    this.enableDeEsser = true,
    this.deEsserIntensity = 0.40,
  });

  AudioMasteringConfig copyWith({
    bool? enableStudioSound,
    AudioMasteringPlatform? platform,
    bool? enableDeEsser,
    double? deEsserIntensity,
  }) {
    return AudioMasteringConfig(
      enableStudioSound: enableStudioSound ?? this.enableStudioSound,
      platform: platform ?? this.platform,
      enableDeEsser: enableDeEsser ?? this.enableDeEsser,
      deEsserIntensity: deEsserIntensity ?? this.deEsserIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableStudioSound': enableStudioSound,
      'platform': platform.name,
      'enableDeEsser': enableDeEsser,
      'deEsserIntensity': deEsserIntensity,
    };
  }

  factory AudioMasteringConfig.fromJson(Map<String, dynamic> json) {
    AudioMasteringPlatform targetPlatform = AudioMasteringPlatform.socialShorts;
    if (json['platform'] is String) {
      for (final p in AudioMasteringPlatform.values) {
        if (p.name == json['platform']) {
          targetPlatform = p;
          break;
        }
      }
    }

    return AudioMasteringConfig(
      enableStudioSound: json['enableStudioSound'] as bool? ?? false,
      platform: targetPlatform,
      enableDeEsser: json['enableDeEsser'] as bool? ?? true,
      deEsserIntensity: (json['deEsserIntensity'] as num?)?.toDouble() ?? 0.40,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioMasteringConfig &&
          runtimeType == other.runtimeType &&
          enableStudioSound == other.enableStudioSound &&
          platform == other.platform &&
          enableDeEsser == other.enableDeEsser &&
          (deEsserIntensity - other.deEsserIntensity).abs() < 0.001;

  @override
  int get hashCode =>
      enableStudioSound.hashCode ^
      platform.hashCode ^
      enableDeEsser.hashCode ^
      deEsserIntensity.hashCode;
}
