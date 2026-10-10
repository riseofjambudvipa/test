import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/video/background_music_models.dart';
import '../../../../core/video/b_roll_models.dart';
import '../../../../core/video/chapter_models.dart';
import '../../../../app/theme.dart';


class TimelineWaveformPainter extends CustomPainter {
  // Layout Constants
  static const double rulerHeight = 24.0;
  static const double longNotchHeight = 12.0;
  static const double shortNotchHeight = 6.0;
  static const double textOffsetY = 2.0;
  static const double trackBottomMargin = 32.0;
  static const double trackHeight = 24.0;
  static const double handleWidth = 8.0;
  static const double handleHeight = 32.0;
  static const double handleCornerRadius = 4.0;
  static const double handleRidgeLength = 4.0;
  static const double handleRidgeThickness = 1.2;
  static const double handleRidgeOffset = 6.0;
  static const double stripeInterval = 20.0;
  static const double stripeWidth = 1.5;
  static const double splitLineDashLength = 4.0;
  static const double splitLineDashGap = 8.0;

  final TextPainter _rulerTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  final double duration;
  final double pixelsPerSecond;
  final double scrollOffset;
  final List<double> waveformAmplitudes;
  final double trimStart;
  final double trimEnd;
  final List<VideoSegmentSchema>? segments;
  final BackgroundMusicConfig? backgroundMusic;
  final List<BRollClip>? bRollClips;
  final List<WordSchema>? words;
  final List<VideoChapter>? chapters;
  final AppThemeData theme;
  final bool isAudioMuted;
  final bool isCaptionsVisible;

  TimelineWaveformPainter({
    required this.duration,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.waveformAmplitudes,
    required this.trimStart,
    required this.trimEnd,
    required this.theme,
    this.segments,
    this.backgroundMusic,
    this.bRollClips,
    this.words,
    this.chapters,
    this.isAudioMuted = false,
    this.isCaptionsVisible = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelsPerSecond <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    
    // Background
    final bgPaint = Paint()..color = theme.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final captionTrackTop = math.max(rulerHeight + 14.0, size.height - trackBottomMargin);
    final captionTrackBg = Paint()
      ..color = theme.cardBg.withValues(alpha: isCaptionsVisible ? 0.35 : 0.15);
    canvas.drawRect(
      Rect.fromLTWH(0, captionTrackTop, size.width, math.max(0.0, size.height - captionTrackTop)),
      captionTrackBg,
    );

    final hasMusic = backgroundMusic != null && backgroundMusic!.hasMusic;
    const double musicLaneHeight = 20.0;
    final double musicLaneTop = hasMusic
        ? math.max(rulerHeight + 10.0, captionTrackTop - musicLaneHeight)
        : captionTrackTop;

    // Track lane divider lines
    final laneDividerPaint = Paint()
      ..color = theme.borderGlass
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, rulerHeight), Offset(size.width, rulerHeight), laneDividerPaint);
    canvas.drawLine(Offset(0, captionTrackTop), Offset(size.width, captionTrackTop), laneDividerPaint);

    if (hasMusic) {
      canvas.drawRect(
        Rect.fromLTWH(0, musicLaneTop, size.width, musicLaneHeight),
        Paint()..color = theme.cardBg.withValues(alpha: 0.22),
      );
      canvas.drawLine(Offset(0, musicLaneTop), Offset(size.width, musicLaneTop), laneDividerPaint);

      // Draw subtle background music rhythm bars in A2 music lane
      final musicCenterY = musicLaneTop + musicLaneHeight / 2;
      final musicPaint = Paint()
        ..color = theme.accentCyan.withValues(alpha: 0.35)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5;

      final duckedPaint = Paint()
        ..color = theme.accentCyan.withValues(alpha: 0.12)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5;

      final wordsList = words;
      for (double x = 0; x < size.width; x += 4.0) {
        final t = (x + scrollOffset) / pixelsPerSecond;
        if (t < trimStart || t > trimEnd) continue;

        bool isDucked = false;
        if (backgroundMusic!.enableDucking && wordsList != null) {
          for (final w in wordsList) {
            final ws = w.start ?? 0.0;
            final we = w.end ?? 0.0;
            if (t >= ws && t <= we) {
              isDucked = true;
              break;
            }
            if (ws > t) break;
          }
        }

        final phase = t * 8.0;
        final rawAmp = 0.25 + 0.65 * math.sin(phase).abs();
        final amp = isDucked ? (rawAmp / backgroundMusic!.duckingRatio.clamp(1.5, 8.0)) : rawAmp;
        final halfH = (amp * (musicLaneHeight * 0.35)).clamp(1.0, musicLaneHeight * 0.45);

        canvas.drawLine(
          Offset(x, musicCenterY - halfH),
          Offset(x, musicCenterY + halfH),
          isDucked ? duckedPaint : musicPaint,
        );
      }
    }

    // Draw B-roll overlay indicators beneath ruler
    final clips = bRollClips;
    if (clips != null && clips.isNotEmpty) {
      for (final clip in clips) {
        final startX = (clip.startTime * pixelsPerSecond) - scrollOffset;
        final endX = (clip.endTime * pixelsPerSecond) - scrollOffset;
        if (endX < 0 || startX > size.width) continue;

        final left = math.max(0.0, startX);
        final right = math.min(size.width, endX);
        final width = right - left;
        if (width <= 0) continue;

        final brollRect = Rect.fromLTWH(left, rulerHeight + 2, width, 18);
        final brollBg = Paint()
          ..color = (clip.isPictureInPicture ? theme.accentOrange : theme.accentCyan)
              .withValues(alpha: 0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(brollRect, const Radius.circular(4)),
          brollBg,
        );

        final brollBorder = Paint()
          ..color = (clip.isPictureInPicture ? theme.accentOrange : theme.accentCyan)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(brollRect, const Radius.circular(4)),
          brollBorder,
        );

        if (width > 28) {
          final modeTag = clip.isPictureInPicture ? 'PiP' : 'CUT';
          _rulerTextPainter.text = TextSpan(
            text: '$modeTag • ${clip.name}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          );
          _rulerTextPainter.layout(maxWidth: math.max(10, width - 8));
          _rulerTextPainter.paint(canvas, Offset(left + 4, rulerHeight + 5));
        }
      }
    }

    final waveformBottom = hasMusic ? musicLaneTop : captionTrackTop;
    final waveformCenterY = rulerHeight + (waveformBottom - rulerHeight) / 2;
    final waveformMaxHeight = math.max(10.0, waveformBottom - rulerHeight);

    // --- 1. Draw Time Ruler Notch markings ---
    final rulerPaint = Paint()
      ..color = theme.mutedText.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    final startVisibleTime = scrollOffset / pixelsPerSecond;
    final endVisibleTime = (scrollOffset + size.width) / pixelsPerSecond;

    final startSec = startVisibleTime.floor().clamp(0, duration.ceil());
    final endSec = endVisibleTime.ceil().clamp(0, duration.ceil());

    for (int sec = startSec; sec <= endSec; sec++) {
      final x = (sec * pixelsPerSecond) - scrollOffset;

      canvas.drawLine(Offset(x, 0), Offset(x, longNotchHeight), rulerPaint);

      if (pixelsPerSecond > 60.0) {
        final subNotchPaint = Paint()
          ..color = theme.mutedText.withValues(alpha: 0.15)
          ..strokeWidth = 1.0;
        for (int tenth = 1; tenth < 10; tenth++) {
          final subX = x + (tenth * (pixelsPerSecond / 10));
          canvas.drawLine(Offset(subX, 0), Offset(subX, shortNotchHeight), subNotchPaint);
        }
      }

      final labelIntervalSeconds = math.max(1, (50.0 / pixelsPerSecond).ceil());
      if (sec % labelIntervalSeconds == 0) {
        final min = sec ~/ 60;
        final remainingSec = sec % 60;
        final label = '$min:${remainingSec.toString().padLeft(2, '0')}';
        
        _rulerTextPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: theme.mutedText,
          ),
        );
        _rulerTextPainter.layout();
        _rulerTextPainter.paint(canvas, Offset(x + 4, textOffsetY));
      }
    }

    // --- 1.5 Ruler is kept clean without chapter overlays ---

    // --- 2. Draw Audio Waveform (Amplitudes) ---
    if (waveformAmplitudes.isNotEmpty && duration > 0) {
      final waveLength = waveformAmplitudes.length;
      final samplesPerSecond = waveLength / duration;

      final startSample = (startVisibleTime * samplesPerSecond).floor().clamp(0, waveLength - 1);
      final endSample = (endVisibleTime * samplesPerSecond).ceil().clamp(0, waveLength - 1);

      final untrimmedPath = Path();
      final upcomingPath = Path();

      for (int i = startSample; i <= endSample; i++) {
        final time = i / samplesPerSecond;
        final x = (time * pixelsPerSecond) - scrollOffset;
        final amplitude = waveformAmplitudes[i];
        final barHeight = amplitude * waveformMaxHeight;

        final top = waveformCenterY - barHeight / 2;
        final bottom = waveformCenterY + barHeight / 2;

        if (time < trimStart || time > trimEnd) {
          untrimmedPath.moveTo(x, top);
          untrimmedPath.lineTo(x, bottom);
        } else {
          upcomingPath.moveTo(x, top);
          upcomingPath.lineTo(x, bottom);
        }
      }

      canvas.drawPath(
        untrimmedPath,
        Paint()
          ..color = theme.mutedText.withValues(alpha: isAudioMuted ? 0.15 : 0.35)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      canvas.drawPath(
        upcomingPath,
        Paint()
          ..color = isAudioMuted
              ? theme.mutedText.withValues(alpha: 0.22)
              : theme.accentPrimary.withValues(alpha: 0.5)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }

    // --- 2.5 Draw Trim Shading, Split Segments, and Boundaries ---
    final trimStartX = (trimStart * pixelsPerSecond) - scrollOffset;
    final trimEndX = (trimEnd * pixelsPerSecond) - scrollOffset;

    final outerShadePaint = Paint()..color = const Color(0x9909090B);
    
    if (trimStartX > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, math.min(size.width, trimStartX), size.height),
        outerShadePaint,
      );
    }
    if (trimEndX < size.width) {
      canvas.drawRect(
        Rect.fromLTRB(math.max(0.0, trimEndX), 0, size.width, size.height),
        outerShadePaint,
      );
    }

    final segs = segments;
    if (segs != null && segs.isNotEmpty) {
      final deletedShadePaint = Paint()..color = const Color(0x44EF4444);
      final splitLinePaint = Paint()
        ..color = theme.mutedText
        ..strokeWidth = stripeWidth;

      for (int i = 0; i < segs.length; i++) {
        final seg = segs[i];
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        final isDel = seg.isDeleted ?? false;

        final segStartX = (start * pixelsPerSecond) - scrollOffset;
        final segEndX = (end * pixelsPerSecond) - scrollOffset;

        if (isDel) {
          final visibleLeft = math.max(0.0, segStartX);
          final visibleRight = math.min(size.width, segEndX);
          if (visibleRight > visibleLeft) {
            canvas.drawRect(
              Rect.fromLTRB(visibleLeft, 0, visibleRight, size.height),
              deletedShadePaint,
            );
            final stripePaint = Paint()
              ..color = theme.primaryText.withValues(alpha: 0.1)
              ..strokeWidth = stripeWidth;
            for (double sX = visibleLeft - (visibleLeft % stripeInterval); sX < visibleRight + stripeInterval; sX += stripeInterval) {
              canvas.drawLine(
                Offset(sX, 0),
                Offset(sX + stripeInterval, size.height),
                stripePaint,
              );
            }
          }
        }

        if (i > 0 && segStartX >= 0 && segStartX <= size.width) {
          double y = 0.0;
          while (y < size.height) {
            canvas.drawLine(
              Offset(segStartX, y),
              Offset(segStartX, y + splitLineDashLength),
              splitLinePaint,
            );
            y += splitLineDashLength + splitLineDashGap;
          }
        }
      }
    }

    final outlinePaint = Paint()
      ..color = theme.accentSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final activeRect = Rect.fromLTRB(trimStartX, 0, trimEndX, size.height);
    canvas.drawRect(activeRect, outlinePaint);

    final centerY = size.height / 2;
    
    if (trimStartX >= -10 && trimStartX <= size.width + 10) {
      final pillRect = Rect.fromCenter(
        center: Offset(trimStartX, centerY),
        width: handleWidth,
        height: handleHeight,
      );
      final pillPaint = Paint()..color = theme.accentSecondary;
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(handleCornerRadius)),
        pillPaint,
      );
      final ridgePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = handleRidgeThickness;
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY - handleRidgeOffset), Offset(trimStartX + handleRidgeLength / 2, centerY - handleRidgeOffset), ridgePaint);
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY), Offset(trimStartX + handleRidgeLength / 2, centerY), ridgePaint);
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY + handleRidgeOffset), Offset(trimStartX + handleRidgeLength / 2, centerY + handleRidgeOffset), ridgePaint);
    }

    if (trimEndX >= -10 && trimEndX <= size.width + 10) {
      final pillRect = Rect.fromCenter(
        center: Offset(trimEndX, centerY),
        width: handleWidth,
        height: handleHeight,
      );
      final pillPaint = Paint()..color = theme.accentSecondary;
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(handleCornerRadius)),
        pillPaint,
      );
      final ridgePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = handleRidgeThickness;
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY - handleRidgeOffset), Offset(trimEndX + handleRidgeLength / 2, centerY - handleRidgeOffset), ridgePaint);
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY), Offset(trimEndX + handleRidgeLength / 2, centerY), ridgePaint);
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY + handleRidgeOffset), Offset(trimEndX + handleRidgeLength / 2, centerY + handleRidgeOffset), ridgePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TimelineWaveformPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.duration != duration ||
        oldDelegate.trimStart != trimStart ||
        oldDelegate.trimEnd != trimEnd ||
        oldDelegate.segments != segments ||
        oldDelegate.backgroundMusic != backgroundMusic ||
        oldDelegate.words != words ||
        oldDelegate.chapters != chapters ||
        oldDelegate.waveformAmplitudes != waveformAmplitudes ||
        oldDelegate.isAudioMuted != isAudioMuted ||
        oldDelegate.isCaptionsVisible != isCaptionsVisible ||
        oldDelegate.theme != theme;
  }
}


class TimelinePlayheadPainter extends CustomPainter {
  static const double trackBottomMargin = 32.0;
  static const double trackHeight = 24.0;
  static const double wordBoxBorderRadius = 6.0;
  static const double activeWordGrabWidthThreshold = 12.0;
  static const double grabHandleOffset = 3.0;
  static const double grabHandleLength = 8.0;
  static const double grabHandleThickness = 2.0;
  static const double tooltipPaddingH = 8.0;
  static const double tooltipPaddingV = 4.0;
  static const double tooltipOffsetFromTrack = 6.0;
  static const double tooltipMinGap = 4.0;

  final TextPainter _wordTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '...',
  );
  final TextPainter _tooltipTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  final List<WordSchema> words;
  final double currentTime;
  final double duration;
  final double pixelsPerSecond;
  final double scrollOffset;
  final String? hoveredWordId;
  final AppThemeData theme;
  final bool wordsAreOrdered;
  final List<VideoSegmentSchema>? segments;
  final bool isCaptionsVisible;

  TimelinePlayheadPainter({
    required this.words,
    required this.currentTime,
    required this.duration,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.theme,
    this.hoveredWordId,
    this.wordsAreOrdered = true,
    this.segments,
    this.isCaptionsVisible = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelsPerSecond <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final startVisibleTime = scrollOffset / pixelsPerSecond;
    final endVisibleTime = (scrollOffset + size.width) / pixelsPerSecond;
    final trackTop = math.max(TimelineWaveformPainter.rulerHeight + 14.0, size.height - trackBottomMargin);

    int startIndex = words.length;
    int endIndex = words.length - 1;

    if (words.isNotEmpty) {
      if (wordsAreOrdered) {
        int low = 0;
        int high = words.length - 1;
        int firstVisible = -1;

        while (low <= high) {
          final int mid = low + ((high - low) >> 1);
          if ((words[mid].end ?? 0.0) < startVisibleTime) {
            low = mid + 1;
          } else {
            firstVisible = mid;
            high = mid - 1;
          }
        }

        if (firstVisible == -1) {
          startIndex = words.length;
          endIndex = -1;
        } else {
          startIndex = firstVisible;
          low = startIndex;
          high = words.length - 1;
          int lastVisible = -1;

          while (low <= high) {
            final int mid = low + ((high - low) >> 1);
            if ((words[mid].start ?? 0.0) <= endVisibleTime) {
              lastVisible = mid;
              low = mid + 1;
            } else {
              high = mid - 1;
            }
          }
          endIndex = lastVisible;
        }

        if (startIndex <= endIndex && startIndex >= 0 && endIndex < words.length) {
          for (int i = startIndex; i <= endIndex; i++) {
            _drawWordChip(canvas, words[i], startVisibleTime, endVisibleTime, trackTop, trackHeight);
          }
        }
      } else {
        for (int i = 0; i < words.length; i++) {
          _drawWordChip(canvas, words[i], startVisibleTime, endVisibleTime, trackTop, trackHeight);
        }
      }
    }

    final playheadX = (currentTime * pixelsPerSecond) - scrollOffset;
    
    if (playheadX >= 0 && playheadX <= size.width) {
      final playheadPaint = Paint()
        ..color = theme.accentPrimary
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );

      final headPaint = Paint()..color = theme.accentPrimary;
      final path = Path()
        ..moveTo(playheadX - 6, 0)
        ..lineTo(playheadX + 6, 0)
        ..lineTo(playheadX + 6, 8)
        ..lineTo(playheadX, 14)
        ..lineTo(playheadX - 6, 8)
        ..close();
      canvas.drawPath(path, headPaint);
    }

    if (hoveredWordId != null) {
      WordSchema? hoveredWord;
      if (wordsAreOrdered && startIndex <= endIndex) {
        for (int i = startIndex; i <= endIndex; i++) {
          if (words[i].wordId == hoveredWordId) {
            hoveredWord = words[i];
            break;
          }
        }
      }
      if (hoveredWord == null) {
        for (final w in words) {
          if (w.wordId == hoveredWordId) {
            hoveredWord = w;
            break;
          }
        }
      }
      if (hoveredWord != null) {
        final start = hoveredWord.start ?? 0.0;
        final end = hoveredWord.end ?? 0.0;
        final text = hoveredWord.text ?? '';
        if (text.isNotEmpty) {
          final x = (start * pixelsPerSecond) - scrollOffset;
          final wWidth = (end - start) * pixelsPerSecond;
          
          final sfxInfo = (hoveredWord.soundEffect != null && hoveredWord.soundEffect!.isNotEmpty)
              ? ' 🔊 ${hoveredWord.soundEffect}'
              : '';
          final emojiInfo = (hoveredWord.emoji != null && hoveredWord.emoji!.isNotEmpty)
              ? ' ${hoveredWord.emoji}'
              : '';
          final speakerInfo = (hoveredWord.speaker != null && hoveredWord.speaker!.isNotEmpty)
              ? ' [${hoveredWord.speaker}]'
              : '';
          final timeInfo = ' (${start.toStringAsFixed(2)}s – ${end.toStringAsFixed(2)}s)';
          final tooltipText = '$text$emojiInfo$sfxInfo$speakerInfo$timeInfo';

          _tooltipTextPainter.text = TextSpan(
            text: tooltipText,
            style: TextStyle(
              fontSize: 10,
              color: theme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          );
          _tooltipTextPainter.layout();

          final tooltipW = _tooltipTextPainter.width + tooltipPaddingH * 2;
          final tooltipH = _tooltipTextPainter.height + tooltipPaddingV * 2;
          
          final tooltipX = (x + wWidth / 2 - tooltipW / 2).clamp(tooltipMinGap, size.width - tooltipW - tooltipMinGap);
          final tooltipY = trackTop - tooltipH - tooltipOffsetFromTrack;

          final tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH);
          
          final rrect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6.0));
          final tooltipBgPaint = Paint()
            ..color = theme.cardBg
            ..style = PaintingStyle.fill;
          final tooltipBorderPaint = Paint()
            ..color = theme.accentSecondary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          
          canvas.drawRRect(rrect, tooltipBgPaint);
          canvas.drawRRect(rrect, tooltipBorderPaint);
          
          _tooltipTextPainter.paint(
            canvas,
            Offset(tooltipX + tooltipPaddingH, tooltipY + tooltipPaddingV),
          );
        }
      }
    }

    canvas.restore();
  }

  void _drawWordChip(
    Canvas canvas,
    WordSchema word,
    double startVisibleTime,
    double endVisibleTime,
    double trackTop,
    double trackHeight,
  ) {
    final start = word.start ?? 0.0;
    final end = word.end ?? 0.0;

    if (end < startVisibleTime || start > endVisibleTime) return;

    final x = (start * pixelsPerSecond) - scrollOffset;
    final wWidth = (end - start) * pixelsPerSecond;
    final rect = Rect.fromLTWH(x, trackTop, wWidth - 2.0, trackHeight);

    final isWordActive = currentTime >= start && currentTime <= end;
    final isHidden = word.hidden == true;

    // Check if word falls inside an excluded/deleted video segment
    bool isInsideDeletedSegment = false;
    if (segments != null && segments!.isNotEmpty) {
      for (final seg in segments!) {
        if (seg.isDeleted == true) {
          final segStart = seg.start ?? 0.0;
          final segEnd = seg.end ?? 0.0;
          if (start < segEnd && end > segStart) {
            isInsideDeletedSegment = true;
            break;
          }
        }
      }
    }

    Color blockColor = theme.cardBgElevated;
    Color textColor = theme.secondaryText;

    if (isInsideDeletedSegment) {
      blockColor = AppTheme.accentRed.withValues(alpha: 0.08);
      textColor = theme.mutedText.withValues(alpha: 0.4);
    } else if (isWordActive) {
      blockColor = theme.accentPrimary.withValues(alpha: 0.15);
      textColor = theme.accentPrimary;
    } else if (word.className != null) {
      if (word.className == 'mainColor') blockColor = theme.accentPrimary.withValues(alpha: 0.08);
      if (word.className == 'secondColor') blockColor = theme.accentSecondary.withValues(alpha: 0.08);
      if (word.className == 'thirdColor') blockColor = theme.accentQuaternary.withValues(alpha: 0.08);
    }

    if (isHidden || !isCaptionsVisible) {
      blockColor = blockColor.withValues(alpha: 0.02);
      textColor = textColor.withValues(alpha: 0.2);
    }

    final boxPaint = Paint()..color = blockColor;
    final borderPaint = Paint()
      ..color = isInsideDeletedSegment
          ? AppTheme.accentRed.withValues(alpha: 0.35)
          : (isWordActive
              ? theme.accentSecondary
              : theme.mutedText.withValues(alpha: 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWordActive ? 1.5 : 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(wordBoxBorderRadius)),
      boxPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(wordBoxBorderRadius)),
      borderPaint,
    );

    // Speaker diarization color accent bar on top of the word chip
    if (word.speaker != null && word.speaker!.isNotEmpty && rect.width >= 8.0) {
      Color speakerColor = theme.accentSecondary;
      final spk = word.speaker!.toLowerCase();
      if (spk.contains('1') || spk.contains('host')) {
        speakerColor = theme.accentPrimary;
      } else if (spk.contains('2') || spk.contains('guest')) {
        speakerColor = theme.accentSecondary;
      } else {
        speakerColor = theme.accentTertiary;
      }
      final speakerBarPaint = Paint()
        ..color = speakerColor
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(rect.left + 3, rect.top + 1),
        Offset(rect.right - 3, rect.top + 1),
        speakerBarPaint,
      );
    }

    // Audio SFX indicator pip (cyan dot at top-right)
    if (word.soundEffect != null && word.soundEffect!.isNotEmpty && rect.width >= 16.0) {
      final sfxPipPaint = Paint()..color = AppTheme.accentCyan;
      canvas.drawCircle(Offset(rect.right - 4.5, rect.top + 4.5), 2.2, sfxPipPaint);
    }

    // Emoji/Sticker indicator pip (orange dot at top-left)
    if (word.emoji != null && word.emoji!.isNotEmpty && rect.width >= 20.0) {
      final emojiPipPaint = Paint()..color = AppTheme.accentOrange;
      canvas.drawCircle(Offset(rect.left + 4.5, rect.top + 4.5), 2.2, emojiPipPaint);
    }

    // Strikethrough line for words inside excluded/deleted video segments
    if (isInsideDeletedSegment && rect.width > 4.0) {
      final strikePaint = Paint()
        ..color = AppTheme.accentRed.withValues(alpha: 0.5)
        ..strokeWidth = 1.2;
      final midY = rect.top + rect.height / 2;
      canvas.drawLine(
        Offset(rect.left + 2, midY),
        Offset(rect.right - 2, midY),
        strikePaint,
      );
    }

    if (isWordActive && !isInsideDeletedSegment && rect.width > activeWordGrabWidthThreshold) {
      final grabPaint = Paint()
        ..color = theme.accentSecondary
        ..strokeCap = StrokeCap.round
        ..strokeWidth = grabHandleThickness;
      final midY = rect.top + rect.height / 2;
      canvas.drawLine(
        Offset(rect.left + grabHandleOffset, midY - grabHandleLength / 2),
        Offset(rect.left + grabHandleOffset, midY + grabHandleLength / 2),
        grabPaint,
      );
      canvas.drawLine(
        Offset(rect.right - grabHandleOffset, midY - grabHandleLength / 2),
        Offset(rect.right - grabHandleOffset, midY + grabHandleLength / 2),
        grabPaint,
      );
    }

    if (rect.width >= 18.0) {
      final wordText = word.text ?? '';
      final fontSize = rect.width < 32.0 ? 8.5 : 10.0;
      _wordTextPainter.text = TextSpan(
        text: wordText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      );
      _wordTextPainter.layout(maxWidth: math.max(0.0, rect.width - 2.0));

      final textX = rect.left + (rect.width - _wordTextPainter.width) / 2;
      final textY = rect.top + (rect.height - _wordTextPainter.height) / 2;
      _wordTextPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePlayheadPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.words != words ||
        oldDelegate.segments != segments ||
        oldDelegate.hoveredWordId != hoveredWordId ||
        oldDelegate.wordsAreOrdered != wordsAreOrdered ||
        oldDelegate.isCaptionsVisible != isCaptionsVisible ||
        oldDelegate.theme != theme;
  }
}
