import 'ffmpeg_font_preparer.dart';
import 'ffmpeg_filters.dart';
import 'ffmpeg_execution.dart';

// Public pure-function API extracted from the exporter class, re-exported so
// existing imports of this library keep working:
export 'ass_script_builder.dart' show generateAssScript;
export 'ffmpeg_execution.dart' show probeAvailableEncoders;
export 'ffmpeg_filters.dart' show FfmpegFilterBuilder;
export '../../../core/video/aspect_ratio_converter.dart' show AspectRatioConverter;
export '../../../core/video/viral_clip_models.dart' show AspectConversionMode;
export '../../../core/video/background_music_models.dart' show BackgroundMusicConfig;
export '../../../core/audio/audio_mastering_models.dart' show AudioMasteringConfig, AudioMasteringPlatform;

class ExportProgress {
  final double progress; // 0.0 to 1.0
  final String status;   // 'rendering' | 'completed' | 'failed'
  final String? error;

  const ExportProgress({
    required this.progress,
    required this.status,
    this.error,
  });
}

class SfxExportItem {
  final String soundEffect;
  final int soundVolume;
  final double start;
  final double end;
  final String resolvedPath;
  SfxExportItem({
    required this.soundEffect,
    required this.soundVolume,
    required this.start,
    required this.end,
    required this.resolvedPath,
  });
}

/// Facade for the video exporter. The implementation is split across focused
/// mixins, each in its own file:
///
///   [FfmpegFontPreparation] (ffmpeg_font_preparer.dart) — bundling fonts for
///     FFmpeg on each platform.
///   [FfmpegFilterBuilder]   (ffmpeg_filters.dart)       — `-filter_complex`
///     graphs plus emoji/SFX asset resolution.
///   [FfmpegExecutor]        (ffmpeg_execution.dart)     — the export pipeline
///     and mobile/desktop process execution.
///
/// Pure ASS script generation lives in `ass_script_builder.dart` and hardware
/// encoder probing is a top-level function in `ffmpeg_execution.dart`; both
/// are re-exported above.
class FfmpegExporter with FfmpegFontPreparation, FfmpegFilterBuilder, FfmpegExecutor {}
