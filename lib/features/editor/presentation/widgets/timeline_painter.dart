import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../app/theme.dart';


class TimelinePainter extends CustomPainter {
  // Layout Constants (Hoisted from magic numbers)
  static const double rulerHeight = 24.0;
  static const double longNotchHeight = 12.0;
  static const double shortNotchHeight = 6.0;
  static const double textOffsetY = 2.0;
  static const double trackBottomMargin = 32.0;
  static const double trackHeight = 24.0;
  static const double wordBoxBorderRadius = 6.0;
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
  static const double activeWordGrabWidthThreshold = 12.0;
  static const double grabHandleOffset = 3.0;
  static const double grabHandleLength = 8.0;
  static const double grabHandleThickness = 2.0;
  static const double tooltipPaddingH = 8.0;
  static const double tooltipPaddingV = 4.0;
  static const double tooltipOffsetFromTrack = 6.0;
  static const double tooltipMinGap = 4.0;

  // Cached TextPainters to avoid allocations on paint frames
  final TextPainter _rulerTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
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
  final double scrollOffset; // Horizontal scroll position in pixels
  final List<double> waveformAmplitudes;
  final double trimStart;
  final double trimEnd;
  final List<VideoSegmentSchema>? segments;
  final String? hoveredWordId;
  final AppThemeData theme;

  TimelinePainter({
    required this.words,
    required this.currentTime,
    required this.duration,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.waveformAmplitudes,
    required this.trimStart,
    required this.trimEnd,
    required this.theme,
    this.segments,
    this.hoveredWordId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelsPerSecond <= 0) return;
    // Save state for clipping
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    
    // Draw background grid/track
    final bgPaint = Paint()..color = theme.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final waveformCenterY = rulerHeight + (size.height - rulerHeight - trackBottomMargin) / 2;
    final waveformMaxHeight = size.height - rulerHeight - trackBottomMargin;

    // --- 1. Draw Time Ruler Notch markings ---
    final rulerPaint = Paint()
      ..color = theme.mutedText.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Calculate time bounds visible in current viewport
    final startVisibleTime = scrollOffset / pixelsPerSecond;
    final endVisibleTime = (scrollOffset + size.width) / pixelsPerSecond;

    final startSec = startVisibleTime.floor().clamp(0, duration.ceil());
    final endSec = endVisibleTime.ceil().clamp(0, duration.ceil());

    for (int sec = startSec; sec <= endSec; sec++) {
      final x = (sec * pixelsPerSecond) - scrollOffset;

      // Major second notch
      canvas.drawLine(Offset(x, 0), Offset(x, longNotchHeight), rulerPaint);

      // Sub-second notches (tenths of a second)
      if (pixelsPerSecond > 60.0) {
        final subNotchPaint = Paint()
          ..color = theme.cardBg
          ..strokeWidth = 1.0;
        for (int tenth = 1; tenth < 10; tenth++) {
          final subX = x + (tenth * (pixelsPerSecond / 10));
          canvas.drawLine(Offset(subX, 0), Offset(subX, shortNotchHeight), subNotchPaint);
        }
      }

      // Time label e.g., '0:03'
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

    // --- 2. Draw Audio Waveform (Amplitudes) ---
    if (waveformAmplitudes.isNotEmpty) {
      final waveLength = waveformAmplitudes.length;
      final samplesPerSecond = waveLength / duration;

      final startSample = (startVisibleTime * samplesPerSecond).floor().clamp(0, waveLength - 1);
      final endSample = (endVisibleTime * samplesPerSecond).ceil().clamp(0, waveLength - 1);

      final untrimmedPath = Path();
      final playedPath = Path();
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
        } else if (time <= currentTime) {
          playedPath.moveTo(x, top);
          playedPath.lineTo(x, bottom);
        } else {
          upcomingPath.moveTo(x, top);
          upcomingPath.lineTo(x, bottom);
        }
      }

      canvas.drawPath(
        untrimmedPath,
        Paint()
          ..color = theme.cardBg.withValues(alpha: 0.5)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      canvas.drawPath(
        playedPath,
        Paint()
          ..color = theme.accentPrimary.withValues(alpha: 0.85)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      canvas.drawPath(
        upcomingPath,
        Paint()
          ..color = theme.mutedText.withValues(alpha: 0.4)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }

    // --- 2.5 Draw Trim Shading, Split Segments, and Boundaries ---
    final trimStartX = (trimStart * pixelsPerSecond) - scrollOffset;
    final trimEndX = (trimEnd * pixelsPerSecond) - scrollOffset;

    // A. Shading for outer untrimmed regions (outside trimStart and trimEnd)
    final outerShadePaint = Paint()..color = const Color(0x9909090B);
    
    // Left shade: from 0 to trimStartX
    if (trimStartX > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, math.min(size.width, trimStartX), size.height),
        outerShadePaint,
      );
    }
    // Right shade: from trimEndX to size.width
    if (trimEndX < size.width) {
      canvas.drawRect(
        Rect.fromLTRB(math.max(0.0, trimEndX), 0, size.width, size.height),
        outerShadePaint,
      );
    }

    // B. Draw individual segments: shading deleted ones and drawing split lines
    final segs = segments;
    if (segs != null && segs.isNotEmpty) {
      final deletedShadePaint = Paint()..color = const Color(0x44EF4444); // Translucent red
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

        // If the segment is deleted, draw shade overlay and hashes
        if (isDel) {
          final visibleLeft = math.max(0.0, segStartX);
          final visibleRight = math.min(size.width, segEndX);
          if (visibleRight > visibleLeft) {
            canvas.drawRect(
              Rect.fromLTRB(visibleLeft, 0, visibleRight, size.height),
              deletedShadePaint,
            );
            // Draw diagonal stripes/hashes inside deleted region
            final stripePaint = Paint()
              ..color = const Color(0x18FFFFFF)
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

        // Draw vertical split lines between adjacent segments
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

    // B. Cyan border outline around active region
    final outlinePaint = Paint()
      ..color = theme.accentSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final activeRect = Rect.fromLTRB(trimStartX, 0, trimEndX, size.height);
    canvas.drawRect(activeRect, outlinePaint);

    // C. Draw Left/Right Pill Grip Handles
    final centerY = size.height / 2;
    
    // Left Grip Handle (only if visible or close to screen)
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
      // Black grip ridges inside pill (3 horizontal lines)
      final ridgePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = handleRidgeThickness;
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY - handleRidgeOffset), Offset(trimStartX + handleRidgeLength / 2, centerY - handleRidgeOffset), ridgePaint);
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY), Offset(trimStartX + handleRidgeLength / 2, centerY), ridgePaint);
      canvas.drawLine(Offset(trimStartX - handleRidgeLength / 2, centerY + handleRidgeOffset), Offset(trimStartX + handleRidgeLength / 2, centerY + handleRidgeOffset), ridgePaint);
    }

    // Right Grip Handle (only if visible or close to screen)
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
      // Black grip ridges inside pill (3 horizontal lines)
      final ridgePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = handleRidgeThickness;
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY - handleRidgeOffset), Offset(trimEndX + handleRidgeLength / 2, centerY - handleRidgeOffset), ridgePaint);
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY), Offset(trimEndX + handleRidgeLength / 2, centerY), ridgePaint);
      canvas.drawLine(Offset(trimEndX - handleRidgeLength / 2, centerY + handleRidgeOffset), Offset(trimEndX + handleRidgeLength / 2, centerY + handleRidgeOffset), ridgePaint);
    }

    // --- 3. Draw Word caption blocks on track ---
    final trackTop = size.height - trackBottomMargin;

    if (words.isNotEmpty) {
      // Binary search for first visible word (where end >= startVisibleTime)
      int low = 0;
      int high = words.length - 1;
      int startIndex = 0;
      
      while (low <= high) {
        final int mid = low + ((high - low) >> 1);
        if ((words[mid].end ?? 0.0) < startVisibleTime) {
          low = mid + 1;
        } else {
          startIndex = mid;
          high = mid - 1;
        }
      }

      // Binary search for last visible word (where start > endVisibleTime)
      low = startIndex;
      high = words.length - 1;
      int endIndex = words.length - 1;
      
      while (low <= high) {
        final int mid = low + ((high - low) >> 1);
        if ((words[mid].start ?? 0.0) > endVisibleTime) {
          endIndex = mid;
          high = mid - 1;
        } else {
          low = mid + 1;
        }
      }

      for (int i = startIndex; i <= endIndex; i++) {
        final word = words[i];
        final start = word.start ?? 0.0;
        final end = word.end ?? 0.0;
        
        // Skip offscreen words
        if (end < startVisibleTime || start > endVisibleTime) continue;

      final x = (start * pixelsPerSecond) - scrollOffset;
      final wWidth = (end - start) * pixelsPerSecond;
      final rect = Rect.fromLTWH(x, trackTop, wWidth - 2.0, trackHeight);

      final isWordActive = currentTime >= start && currentTime <= end;
      final isHidden = word.hidden == true;

      // Determine background color of the word chip segment
      Color blockColor = theme.cardBg;
      Color textColor = theme.mutedText;

      if (isWordActive) {
        blockColor = theme.accentPrimary.withValues(alpha: 0.15); // Accent primary tint
        textColor = theme.accentPrimary; // Accent primary
      } else if (word.className != null) {
        if (word.className == 'mainColor') blockColor = theme.accentPrimary.withValues(alpha: 0.08);
        if (word.className == 'secondColor') blockColor = theme.accentSecondary.withValues(alpha: 0.08);
        if (word.className == 'thirdColor') blockColor = theme.accentQuaternary.withValues(alpha: 0.08);
      }

      if (isHidden) {
        blockColor = blockColor.withValues(alpha: 0.02);
        textColor = textColor.withValues(alpha: 0.2);
      }

      // Draw word box
      final boxPaint = Paint()..color = blockColor;
      final borderPaint = Paint()
        ..color = isWordActive 
            ? theme.accentSecondary // Accent secondary active border to group with resize handles
            : theme.mutedText.withValues(alpha: 0.3) // Themed border
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

      // Visual Grab Handles: Draw visual grab notches on the left and right edges if active
      if (isWordActive && rect.width > activeWordGrabWidthThreshold) {
        final grabPaint = Paint()
          ..color = theme.accentSecondary
          ..strokeCap = StrokeCap.round
          ..strokeWidth = grabHandleThickness;
        final midY = rect.top + rect.height / 2;
        // Left visual grab handle (2 vertical dots or tiny line)
        canvas.drawLine(
          Offset(rect.left + grabHandleOffset, midY - grabHandleLength / 2),
          Offset(rect.left + grabHandleOffset, midY + grabHandleLength / 2),
          grabPaint,
        );
        // Right visual grab handle
        canvas.drawLine(
          Offset(rect.right - grabHandleOffset, midY - grabHandleLength / 2),
          Offset(rect.right - grabHandleOffset, midY + grabHandleLength / 2),
          grabPaint,
        );
      }

      // Draw word text (only if box is wide enough for legibility)
      if (rect.width >= 24.0) {
        final wordText = word.text ?? '';
        _wordTextPainter.text = TextSpan(
          text: wordText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        );
        _wordTextPainter.layout(maxWidth: math.max(0.0, rect.width - 4.0));
        
        // Center text in box
        final textX = rect.left + (rect.width - _wordTextPainter.width) / 2;
        final textY = rect.top + (rect.height - _wordTextPainter.height) / 2;
        _wordTextPainter.paint(canvas, Offset(textX, textY));
      }
    }
    }

    // --- 4. Draw Current Playhead (Vertical Red Line) ---
    final playheadX = (currentTime * pixelsPerSecond) - scrollOffset;
    
    // Only draw if playhead is visible inside current viewport
    if (playheadX >= 0 && playheadX <= size.width) {
      final playheadPaint = Paint()
        ..color = theme.accentPrimary // Accent Primary playhead
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );

      // Draw playhead head notch
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

    // --- 4.5 Draw Hover Tooltip on Top ---
    if (hoveredWordId != null) {
      WordSchema? hoveredWord;
      for (final w in words) {
        if (w.wordId == hoveredWordId) {
          hoveredWord = w;
          break;
        }
      }
      if (hoveredWord != null) {
        final start = hoveredWord.start ?? 0.0;
        final end = hoveredWord.end ?? 0.0;
        final text = hoveredWord.text ?? '';
        if (text.isNotEmpty) {
          final x = (start * pixelsPerSecond) - scrollOffset;
          final wWidth = (end - start) * pixelsPerSecond;
          
          _tooltipTextPainter.text = TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
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
            ..color = theme.accentSecondary // Accent Secondary border
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

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.words != words ||
        oldDelegate.trimStart != trimStart ||
        oldDelegate.trimEnd != trimEnd ||
        oldDelegate.segments != segments ||
        oldDelegate.waveformAmplitudes != waveformAmplitudes ||
        oldDelegate.hoveredWordId != hoveredWordId ||
        oldDelegate.theme != theme;
  }
}
