import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../database/schemas/word.dart';
import '../utils/schema_clones.dart';

/// Represents a continuous temporal dialogue block spoken by a specific speaker.
class SpeakerInterval {
  final String speaker;
  final int speakerIndex;
  final double start;
  final double end;

  const SpeakerInterval({
    required this.speaker,
    required this.speakerIndex,
    required this.start,
    required this.end,
  });

  double get duration => (end - start).clamp(0.0, double.infinity);

  @override
  String toString() =>
      'SpeakerInterval($speaker [$speakerIndex]: ${start.toStringAsFixed(2)}s -> ${end.toStringAsFixed(2)}s)';
}

/// Analytical metrics for a speaker across the project transcript.
class SpeakerStats {
  final String speaker;
  final int wordCount;
  final double talkTimeSeconds;
  final double percentage;

  const SpeakerStats({
    required this.speaker,
    required this.wordCount,
    required this.talkTimeSeconds,
    required this.percentage,
  });

  String get formattedTalkTime {
    final totalSeconds = talkTimeSeconds.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// Service providing heuristic AI diarization, speaker attribution, and
/// turn-taking analysis for multi-speaker podcasts, interviews, and videos.
class SpeakerDiarizationService {
  SpeakerDiarizationService._();
  static final SpeakerDiarizationService instance = SpeakerDiarizationService._();

  /// Conversational turn-taking cues that typically mark the start of a response
  /// or change of speaker in podcasts and dialogues.
  static const Set<String> _conversationalCues = {
    'yeah',
    'yes',
    'yep',
    'exactly',
    'right',
    'no',
    'nope',
    'well',
    'so',
    'i think',
    'absolutely',
    'definitely',
    'totally',
    'true',
    'agree',
    'thank you',
    'thanks',
    'wow',
    'oh',
    'ok',
    'okay',
    'sure',
    'honestly',
    'actually',
    'look',
    'listen',
  };

  /// Returns design-token consistent accent colors for distinct speakers.
  static Color getSpeakerColor(String speaker, [int? index]) {
    final idx = index ?? _speakerIndexFromName(speaker);
    switch (idx % 5) {
      case 0:
        return AppTheme.accentCyan;
      case 1:
        return AppTheme.accentOrange;
      case 2:
        return AppTheme.accentGreen;
      case 3:
        return AppTheme.accentPink;
      default:
        return AppTheme.accentRed;
    }
  }

  /// Returns a distinctive icon for the speaker index.
  static IconData getSpeakerIcon(int index) {
    switch (index % 4) {
      case 0:
        return Icons.person_rounded;
      case 1:
        return Icons.person_outline_rounded;
      case 2:
        return Icons.record_voice_over_rounded;
      default:
        return Icons.mic_none_rounded;
    }
  }

  static int _speakerIndexFromName(String speaker) {
    final lower = speaker.toLowerCase();
    if (lower.contains('1') || lower.contains('host')) return 0;
    if (lower.contains('2') || lower.contains('guest 1') || lower.contains('guest')) return 1;
    if (lower.contains('3') || lower.contains('guest 2')) return 2;
    if (lower.contains('4') || lower.contains('guest 3')) return 3;
    return speaker.hashCode.abs() % 5;
  }

  /// Extracts unique non-empty speaker names present in the word list.
  List<String> getUniqueSpeakers(List<WordSchema> words) {
    final set = <String>{};
    for (final w in words) {
      final s = w.speaker?.trim();
      if (s != null && s.isNotEmpty) {
        set.add(s);
      }
    }
    return set.toList();
  }

  /// Calculates speaking time and word count statistics per speaker.
  List<SpeakerStats> calculateStats(List<WordSchema> words) {
    if (words.isEmpty) return [];

    final wordCountMap = <String, int>{};
    final talkTimeMap = <String, double>{};
    double totalTalkTime = 0.0;

    for (final w in words) {
      if (w.hidden == true) continue;
      final speaker = (w.speaker != null && w.speaker!.trim().isNotEmpty)
          ? w.speaker!.trim()
          : 'Unassigned';

      final duration = (w.end ?? 0.0) - (w.start ?? 0.0);
      final validDuration = duration > 0 ? duration : 0.2;

      wordCountMap[speaker] = (wordCountMap[speaker] ?? 0) + 1;
      talkTimeMap[speaker] = (talkTimeMap[speaker] ?? 0.0) + validDuration;
      totalTalkTime += validDuration;
    }

    final stats = <SpeakerStats>[];
    talkTimeMap.forEach((speaker, time) {
      final pct = totalTalkTime > 0 ? (time / totalTalkTime) * 100.0 : 0.0;
      stats.add(SpeakerStats(
        speaker: speaker,
        wordCount: wordCountMap[speaker] ?? 0,
        talkTimeSeconds: time,
        percentage: pct,
      ));
    });

    stats.sort((a, b) => b.talkTimeSeconds.compareTo(a.talkTimeSeconds));
    return stats;
  }

  /// Heuristically identifies conversational turns and attributes words to
  /// distinct speakers (`Speaker 1`, `Speaker 2`, etc.).
  ///
  /// Detection factors:
  /// 1. Inter-word pause gap > [pauseThresholdSeconds]
  /// 2. Question marks ('?') followed by a pause indicating an interrogation
  /// 3. Conversational response markers (e.g. "Yeah", "Exactly", "I think")
  List<WordSchema> detectSpeakers(
    List<WordSchema> words, {
    int speakerCount = 2,
    double pauseThresholdSeconds = 0.65,
    List<String>? speakerNames,
  }) {
    if (words.isEmpty) return [];
    final safeCount = speakerCount.clamp(2, 6);

    final names = speakerNames ?? List.generate(safeCount, (i) => 'Speaker ${i + 1}');

    final cloned = words.map(SchemaClones.cloneWord).toList();
    int currentSpeakerIdx = 0;

    for (int i = 0; i < cloned.length; i++) {
      final w = cloned[i];
      final text = (w.text ?? '').trim().toLowerCase();

      bool isTurnTransition = false;

      if (i > 0) {
        final prev = cloned[i - 1];
        final prevEnd = prev.end ?? 0.0;
        final thisStart = w.start ?? 0.0;
        final pauseGap = thisStart - prevEnd;

        final prevText = (prev.text ?? '').trim();
        final prevIsQuestion = prevText.endsWith('?');

        // Rule 1: A question mark followed by even a brief pause (>0.35s)
        // almost always signals the other person taking over the turn.
        if (prevIsQuestion && pauseGap >= 0.35) {
          isTurnTransition = true;
        }
        // Rule 2: Natural conversational silence pause gap.
        else if (pauseGap >= pauseThresholdSeconds) {
          isTurnTransition = true;
        }
        // Rule 3: Conversational cue preceded by an audible breath pause (>0.4s).
        else if (pauseGap >= 0.40 && _isConversationalCue(text)) {
          isTurnTransition = true;
        }
      }

      if (isTurnTransition) {
        currentSpeakerIdx = (currentSpeakerIdx + 1) % safeCount;
      }

      w.speaker = names[currentSpeakerIdx];
    }

    return cloned;
  }

  /// Replaces all instances of [oldSpeaker] with [newSpeaker].
  List<WordSchema> renameSpeaker(
    List<WordSchema> words,
    String oldSpeaker,
    String newSpeaker,
  ) {
    final cleanNew = newSpeaker.trim();
    if (cleanNew.isEmpty) return words;

    return words.map((w) {
      final clone = SchemaClones.cloneWord(w);
      if (clone.speaker == oldSpeaker) {
        clone.speaker = cleanNew;
      }
      return clone;
    }).toList();
  }

  /// Sets the speaker label for a specific list of words (e.g. from a chunk).
  List<WordSchema> assignSpeakerToWords(
    List<WordSchema> allWords,
    Set<String> wordIdsToUpdate,
    String newSpeaker,
  ) {
    final cleanSpeaker = newSpeaker.trim();
    return allWords.map((w) {
      final clone = SchemaClones.cloneWord(w);
      final id = clone.wordId;
      if (id != null && wordIdsToUpdate.contains(id)) {
        clone.speaker = cleanSpeaker;
      }
      return clone;
    }).toList();
  }

  /// Sets the speaker label for words falling within a time window.
  List<WordSchema> assignSpeakerToTimeRange(
    List<WordSchema> words,
    double startTime,
    double endTime,
    String newSpeaker,
  ) {
    final cleanSpeaker = newSpeaker.trim();
    return words.map((w) {
      final clone = SchemaClones.cloneWord(w);
      final s = clone.start ?? 0.0;
      final e = clone.end ?? 0.0;
      if (s >= startTime && e <= endTime) {
        clone.speaker = cleanSpeaker;
      }
      return clone;
    }).toList();
  }

  /// Groups chronological spoken words into continuous speaker intervals.
  List<SpeakerInterval> getSpeakerIntervals(
    List<WordSchema> words, {
    double minIntervalDuration = 0.35,
    double mergeGapThreshold = 0.85,
  }) {
    if (words.isEmpty) return [];

    final visible = words
        .where((w) => w.hidden != true && w.start != null && w.end != null)
        .toList()
      ..sort((a, b) => (a.start ?? 0.0).compareTo(b.start ?? 0.0));

    if (visible.isEmpty) return [];

    final intervals = <SpeakerInterval>[];
    String currentSpeaker = (visible.first.speaker != null && visible.first.speaker!.trim().isNotEmpty)
        ? visible.first.speaker!.trim()
        : 'Speaker 1';
    double currentStart = visible.first.start ?? 0.0;
    double currentEnd = visible.first.end ?? (currentStart + 0.3);

    for (int i = 1; i < visible.length; i++) {
      final w = visible[i];
      final speaker = (w.speaker != null && w.speaker!.trim().isNotEmpty)
          ? w.speaker!.trim()
          : 'Speaker 1';
      final start = w.start ?? currentEnd;
      final end = w.end ?? (start + 0.3);
      final gap = start - currentEnd;

      if (speaker == currentSpeaker && gap <= mergeGapThreshold) {
        currentEnd = math.max(currentEnd, end);
      } else {
        if ((currentEnd - currentStart) >= minIntervalDuration) {
          intervals.add(SpeakerInterval(
            speaker: currentSpeaker,
            speakerIndex: _speakerIndexFromName(currentSpeaker),
            start: currentStart,
            end: currentEnd,
          ));
        }
        currentSpeaker = speaker;
        currentStart = start;
        currentEnd = end;
      }
    }

    if ((currentEnd - currentStart) >= minIntervalDuration) {
      intervals.add(SpeakerInterval(
        speaker: currentSpeaker,
        speakerIndex: _speakerIndexFromName(currentSpeaker),
        start: currentStart,
        end: currentEnd,
      ));
    }

    return intervals;
  }

  /// Calculates horizontal focal points (0.0 to 1.0) across the landscape frame
  /// for each unique speaker in multi-speaker layouts.
  Map<String, double> computeSpeakerFocalPoints(List<String> speakers) {
    final unique = speakers.toSet().toList();
    if (unique.isEmpty) return {};
    if (unique.length == 1) {
      return {unique[0]: 0.50};
    }
    if (unique.length == 2) {
      // Standard two-person podcast/interview: Host left (0.20), Guest right (0.80)
      return {
        unique[0]: 0.20,
        unique[1]: 0.80,
      };
    }
    if (unique.length == 3) {
      return {
        unique[0]: 0.18,
        unique[1]: 0.50,
        unique[2]: 0.82,
      };
    }

    // N speakers: evenly distribute across safe horizontal frame (0.15 to 0.85)
    final map = <String, double>{};
    for (int i = 0; i < unique.length; i++) {
      final fraction = 0.15 + (0.70 * i / (unique.length - 1));
      map[unique[i]] = double.parse(fraction.toStringAsFixed(2));
    }
    return map;
  }

  /// Generates the FFmpeg `x` crop expression that dynamically switches horizontal
  /// framing to focus on the active speaker during their speaking intervals.
  String buildSpeakerCropExpression({
    required List<SpeakerInterval> intervals,
    Map<String, double>? customFocalPoints,
    double defaultFocalX = 0.50,
  }) {
    if (intervals.isEmpty) {
      return '(in_w-out_w)*$defaultFocalX';
    }

    final focalMap = customFocalPoints ??
        computeSpeakerFocalPoints(intervals.map((i) => i.speaker).toList());

    if (focalMap.length <= 1) {
      final fx = focalMap.values.isNotEmpty ? focalMap.values.first : defaultFocalX;
      return '(in_w-out_w)*$fx';
    }

    // Build nested if(between(t, start, end), focalX, fallback) expression
    String expr = '(in_w-out_w)*$defaultFocalX';
    for (int i = intervals.length - 1; i >= 0; i--) {
      final interval = intervals[i];
      final fx = focalMap[interval.speaker] ?? defaultFocalX;
      final s = interval.start.toStringAsFixed(2);
      final e = interval.end.toStringAsFixed(2);
      expr = 'if(between(t,$s,$e),(in_w-out_w)*$fx,$expr)';
    }

    return expr;
  }

  static bool _isConversationalCue(String text) {
    final clean = text.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    return _conversationalCues.contains(clean);
  }
}
