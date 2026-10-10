class SilenceSegment {
  final double start;
  final double end;
  final double duration;

  SilenceSegment({
    required this.start,
    required this.end,
    required this.duration,
  });
}

class ViralClipCandidate {
  final String id;
  final double start;
  final double end;
  final double duration;

  /// Composite score 0–100
  final double score;

  /// The specific hook phrase found (empty if none)
  final String hookText;

  /// Short summary / preview of the clip text
  final String summary;

  final int wordCount;
  final double wordsPerMinute;

  /// Hook component score (0–40)
  final double hookScore;

  /// Energy component score (0–20): exclamation points + ALL-CAPS word ratio
  final double energyScore;

  /// WPM component score (0–20)
  final double wpmScore;

  /// Whether the hook keyword appeared in the first 5 seconds of the clip
  final bool hookInFirstFive;

  /// Number of questions (?) found in the clip text
  final int questionCount;

  /// Category of the hook (e.g. 'Curiosity Gap', 'Action / Urgency', etc.)
  final String hookCategory;

  /// Whether the clip cleanly starts and ends on sentence/thought boundaries
  final bool hasCleanBoundaries;

  /// OpusClip-style AI virality reasoning breakdown
  final List<String> viralityReasons;

  /// Auto-generated click-worthy viral title for Shorts/Reels/TikTok
  final String viralTitle;

  /// Hardware-extracted acoustic energy score (0–25)
  final double acousticEnergyScore;

  /// Narrative story-arc score: Inciting Hook -> Conflict -> Payoff (0–25)
  final double storyArcScore;

  String get displayTitle => viralTitle.isNotEmpty ? viralTitle : 'Viral Clip';

  String get viralityGrade {
    final s = score.round();
    if (s >= 85) return 'VIRAL GOLD';
    if (s >= 70) return 'HIGH POTENTIAL';
    if (s >= 55) return 'SOLID PERFORMER';
    return 'STANDARD';
  }

  ViralClipCandidate({
    required this.id,
    required this.start,
    required this.end,
    required this.duration,
    required this.score,
    required this.hookText,
    this.hookCategory = 'General Engagement',
    required this.summary,
    required this.wordCount,
    required this.wordsPerMinute,
    required this.hookScore,
    required this.energyScore,
    required this.wpmScore,
    required this.hookInFirstFive,
    required this.questionCount,
    this.hasCleanBoundaries = false,
    this.viralityReasons = const [],
    this.viralTitle = '',
    this.acousticEnergyScore = 0.0,
    this.storyArcScore = 0.0,
  });
}

enum AspectConversionMode {
  blurPillarbox,
  centerCrop,
  splitScreen,
  smartFaceTrack,
  speakerTrack,
}

enum SilenceAggressiveness {
  conservative,
  balanced,
  aggressive;

  double get noiseThreshold => switch (this) {
    SilenceAggressiveness.conservative => -40.0,
    SilenceAggressiveness.balanced => -35.0,
    SilenceAggressiveness.aggressive => -30.0,
  };

  double get minSilenceDuration => switch (this) {
    SilenceAggressiveness.conservative => 0.7,
    SilenceAggressiveness.balanced => 0.4,
    SilenceAggressiveness.aggressive => 0.25,
  };

  String get label => switch (this) {
    SilenceAggressiveness.conservative => 'Conservative (0.7s)',
    SilenceAggressiveness.balanced => 'Balanced (0.4s)',
    SilenceAggressiveness.aggressive => 'Aggressive (0.25s)',
  };

  String get description => switch (this) {
    SilenceAggressiveness.conservative => 'Only cuts long awkward pauses; keeps natural breaths.',
    SilenceAggressiveness.balanced => 'Standard podcast and YouTube cut; removes dead air.',
    SilenceAggressiveness.aggressive => 'Fast-paced TikTok/Reels pacing; tight jump-cuts.',
  };
}

class ClippingConfig {
  final double minClipDuration;
  final double maxClipDuration;
  final double silenceThreshold;
  final double minSilenceDuration;
  final SilenceAggressiveness aggressiveness;

  ClippingConfig({
    this.minClipDuration = 20.0,
    this.maxClipDuration = 60.0,
    this.silenceThreshold = -35.0,
    this.minSilenceDuration = 0.4,
    this.aggressiveness = SilenceAggressiveness.balanced,
  });
}
