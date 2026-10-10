import 'viral_clip_models.dart';
import '../audio/speaker_diarization_service.dart';

export 'viral_clip_models.dart' show AspectConversionMode;
export '../audio/speaker_diarization_service.dart' show SpeakerInterval;

class AspectRatioConverter {
  static String buildBlurPillarboxFilter({
    required int inputWidth,
    required int inputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    String inputStream = '[0:v]',
    String outputStream = '',
  }) {
    // Generate ffmpeg filter complex for blurred background pillarbox.
    // Background is scaled to fill canvas, cropped to exact target canvas (1080x1920),
    // and blurred with a subtle dimming pass to make the foreground video stand out.
    final out = outputStream.isNotEmpty ? outputStream : '';
    return '${inputStream}split=2[v_bp_bg_in][v_bp_fg_in];'
        '[v_bp_bg_in]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$targetHeight,boxblur=35:5,eq=brightness=-0.08:saturation=1.1[bg];'
        '[v_bp_fg_in]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[fg];'
        '[bg][fg]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2$out';
  }

  static String buildCenterCropFilter({
    required int inputWidth,
    required int inputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    String inputStream = '[0:v]',
    String outputStream = '',
  }) {
    // Generate ffmpeg filter complex for center crop
    final out = outputStream.isNotEmpty ? outputStream : '';
    return '${inputStream}scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,'
        'crop=$targetWidth:$targetHeight:(in_w-$targetWidth)/2:(in_h-$targetHeight)/2$out';
  }

  static String buildSplitScreenFilter({
    required int topInputWidth,
    required int topInputHeight,
    required int bottomInputWidth,
    required int bottomInputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    String topStream = '[0:v]',
    String bottomStream = '[1:v]',
    String outputStream = '',
  }) {
    // Top half is top stream, bottom half is bottom stream
    final halfHeight = targetHeight ~/ 2;
    final out = outputStream.isNotEmpty ? outputStream : '';
    return '${topStream}scale=$targetWidth:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:(in_w-$targetWidth)/2:(in_h-$halfHeight)/2[top];'
        '${bottomStream}scale=$targetWidth:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:(in_w-$targetWidth)/2:(in_h-$halfHeight)/2[bottom];'
        '[top][bottom]vstack=inputs=2$out';
  }

  static String buildSingleSourceSplitScreenFilter({
    required int inputWidth,
    required int inputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    String inputStream = '[0:v]',
    String outputStream = '',
    bool podcastSpeakerMode = true,
  }) {
    final halfHeight = targetHeight ~/ 2;
    final out = outputStream.isNotEmpty ? outputStream : '';
    if (podcastSpeakerMode && inputWidth > inputHeight) {
      // In 16:9 landscape podcast mode (two speakers sitting left and right),
      // crop top from left speaker and bottom from right speaker for authentic multi-cam layout!
      return '${inputStream}split=2[split_top_in][split_bottom_in];'
          '[split_top_in]scale=-2:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:0:(in_h-$halfHeight)/2[top];'
          '[split_bottom_in]scale=-2:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:(in_w-$targetWidth):(in_h-$halfHeight)/2[bottom];'
          '[top][bottom]vstack=inputs=2$out';
    }
    return '${inputStream}split=2[split_top_in][split_bottom_in];'
        '[split_top_in]scale=$targetWidth:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:(in_w-$targetWidth)/2:(in_h-$halfHeight)/2[top];'
        '[split_bottom_in]scale=$targetWidth:$halfHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$halfHeight:(in_w-$targetWidth)/2:(in_h-$halfHeight)/2[bottom];'
        '[top][bottom]vstack=inputs=2$out';
  }

  static String buildFilterForMode({
    required AspectConversionMode mode,
    required int inputWidth,
    required int inputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    String inputStream = '[0:v]',
    String? bottomStream,
    List<SpeakerInterval>? speakerIntervals,
    String outputStream = '',
  }) {
    switch (mode) {
      case AspectConversionMode.blurPillarbox:
        return buildBlurPillarboxFilter(
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          inputStream: inputStream,
          outputStream: outputStream,
        );
      case AspectConversionMode.centerCrop:
        return buildCenterCropFilter(
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          inputStream: inputStream,
          outputStream: outputStream,
        );
      case AspectConversionMode.splitScreen:
        if (bottomStream != null) {
          return buildSplitScreenFilter(
            topInputWidth: inputWidth,
            topInputHeight: inputHeight,
            bottomInputWidth: inputWidth,
            bottomInputHeight: inputHeight,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            topStream: inputStream,
            bottomStream: bottomStream,
            outputStream: outputStream,
          );
        } else {
          return buildSingleSourceSplitScreenFilter(
            inputWidth: inputWidth,
            inputHeight: inputHeight,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            inputStream: inputStream,
            outputStream: outputStream,
          );
        }
      case AspectConversionMode.smartFaceTrack:
        return buildSmartFaceTrackFilter(
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          inputStream: inputStream,
          outputStream: outputStream,
        );
      case AspectConversionMode.speakerTrack:
        if (speakerIntervals != null && speakerIntervals.isNotEmpty) {
          return buildDynamicSpeakerTrackFilter(
            inputWidth: inputWidth,
            inputHeight: inputHeight,
            speakerIntervals: speakerIntervals,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            inputStream: inputStream,
            outputStream: outputStream,
          );
        } else {
          return buildSmartFaceTrackFilter(
            inputWidth: inputWidth,
            inputHeight: inputHeight,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            inputStream: inputStream,
            outputStream: outputStream,
          );
        }
    }
  }

  static String buildDynamicSpeakerTrackFilter({
    required int inputWidth,
    required int inputHeight,
    required List<SpeakerInterval> speakerIntervals,
    int targetWidth = 1080,
    int targetHeight = 1920,
    double focalY = 0.25,
    String inputStream = '[0:v]',
    String outputStream = '',
  }) {
    final out = outputStream.isNotEmpty ? outputStream : '';
    final fy = focalY.clamp(0.0, 1.0);
    final cropExprX = SpeakerDiarizationService.instance.buildSpeakerCropExpression(
      intervals: speakerIntervals,
    );

    return '${inputStream}scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,'
        'crop=$targetWidth:$targetHeight:x=\'$cropExprX\':y=(in_h-$targetHeight)*$fy$out';
  }

  static String buildSmartFaceTrackFilter({
    required int inputWidth,
    required int inputHeight,
    int targetWidth = 1080,
    int targetHeight = 1920,
    double focalX = 0.5,
    double focalY = 0.25,
    String inputStream = '[0:v]',
    String outputStream = '',
  }) {
    // Generate ffmpeg filter complex for smart face tracking & rule-of-thirds framing.
    // In talking-head or podcast videos, centering the crop vertically cuts off the forehead/hair.
    // By biasing the vertical framing towards the upper third (focalY ~ 0.20-0.30), the speaker's
    // face and upper chest are cinematographically framed without awkward head chops.
    final out = outputStream.isNotEmpty ? outputStream : '';
    final fx = focalX.clamp(0.0, 1.0);
    final fy = focalY.clamp(0.0, 1.0);

    return '${inputStream}scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,'
        'crop=$targetWidth:$targetHeight:(in_w-$targetWidth)*$fx:(in_h-$targetHeight)*$fy$out';
  }
}
