import 'dart:math' as math;
import '../../../core/database/schemas/word.dart';
import '../../../core/database/schemas/project.dart';
import '../../../core/utils/schema_clones.dart';

class Chunk {
  final int index;
  final double startTime;
  final double endTime;
  final List<WordSchema> words;
  final String? speaker;

  const Chunk({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.words,
    this.speaker,
  });
}

class CaptionEngine {
  static const double minChunkDuration = 0.1;
  static const double defaultPauseGapThreshold = 0.4;

  static List<Chunk> buildChunks(
    List<WordSchema> words,
    List<VideoSegmentSchema>? segments,
    double trimStart,
    double trimEnd,
    int chunkSize,
    int chunkLineMaxLength, {
    bool includeHidden = false,
    double pauseGapThreshold = defaultPauseGapThreshold,
  }) {
    final filtered = <WordSchema>[];
    for (final w in words) {
      if (!includeHidden && w.hidden == true) continue;
      final s = w.start ?? 0.0;
      final e = w.end ?? 0.0;

      bool inBounds = true;
      if (segments != null && segments.isNotEmpty) {
        bool inActiveSegment = false;
        final mid = (s + e) / 2;
        for (final seg in segments) {
          final segStart = seg.start ?? 0.0;
          final segEnd = seg.end ?? 0.0;
          final isDel = seg.isDeleted ?? false;
          if (!isDel && mid >= segStart && mid <= segEnd) {
            inActiveSegment = true;
            break;
          }
        }
        if (!inActiveSegment) inBounds = false;
      } else {
        if (trimStart > 0 && s < trimStart) inBounds = false;
        if (trimEnd > 0 && e > trimEnd) inBounds = false;
      }

      if (!inBounds) continue;

      if (w.type == 'punctuation') {
        if (filtered.isNotEmpty) {
          final lastIdx = filtered.length - 1;
          final lastWord = filtered[lastIdx];
          final cloned = _cloneWord(lastWord);
          final puncText = w.text ?? '';
          final existing = cloned.text ?? '';
          // FIX (audit, CRITICAL data corruption): the merge happens on a
          // clone, and saving that merged word via Word Settings persists the
          // merged text while the separate punctuation word still exists in
          // the DB. Without this guard the next buildChunks would merge the
          // punctuation again ("Hello." -> "Hello.."). Detect the already-
          // absorbed case: the previous word's text already ends with the
          // punctuation AND its end time already covers this punctuation word
          // (the merge also extends the previous word's end). A bare endsWith
          // check is not enough — "this" + "is" is a legitimate merge.
          final alreadyAbsorbed = existing.endsWith(puncText) &&
              cloned.end != null &&
              w.end != null &&
              cloned.end! >= w.end!;
          if (!alreadyAbsorbed) {
            cloned.text = existing + puncText;
          }
          if (w.end != null && (cloned.end == null || w.end! > cloned.end!)) {
            cloned.end = w.end;
          }
          filtered[lastIdx] = cloned;
        }
        // A punctuation word with no merge target (caption start / only
        // punctuation) is intentionally dropped — matches existing behavior
        // and tests; the chunking flushes on sentence-ending punctuation.
      } else {
        filtered.add(w);
      }
    }

    if (filtered.isEmpty) return [];

    final chunks = <Chunk>[];
    var current = <WordSchema>[];
    var charCount = 0;
    var chunkIdx = 0;

    void flush() {
      if (current.isEmpty) return;
      String? chunkSpeaker;
      for (final w in current) {
        if (w.speaker != null && w.speaker!.isNotEmpty) {
          chunkSpeaker = w.speaker;
          break;
        }
      }
      chunks.add(Chunk(
        index: chunkIdx++,
        startTime: current.first.start ?? 0.0,
        endTime: math.max(
          current.last.end ?? 0.0,
          (current.first.start ?? 0.0) + minChunkDuration,
        ),
        words: List.from(current),
        speaker: chunkSpeaker,
      ));
      current = [];
      charCount = 0;
    }

    for (int i = 0; i < filtered.length; i++) {
      final word = filtered[i];
      final text = word.text ?? '';
      final isLast = i == filtered.length - 1;

      // 1. Force split flag set by user
      if (word.splitBefore == true && current.isNotEmpty) flush();

      // 1b. Speaker turn boundary (different speaker starting)
      if (current.isNotEmpty &&
          word.speaker != null &&
          word.speaker!.isNotEmpty &&
          current.last.speaker != null &&
          current.last.speaker!.isNotEmpty &&
          word.speaker != current.last.speaker) {
        flush();
      }

      // 2. Natural pause gap
      if (current.isNotEmpty && i > 0) {
        final prevEnd = filtered[i - 1].end ?? 0.0;
        final thisStart = word.start ?? 0.0;
        if (thisStart - prevEnd > pauseGapThreshold) flush();
      }

      // 3. Sentence-ending punctuation in previous word
      if (current.isNotEmpty) {
        final prevText = (current.last.text ?? '').trimRight();
        if (prevText.endsWith('.') || prevText.endsWith('!') ||
            prevText.endsWith('?')) {
          flush();
        }
      }

      // 4. Word count or char limit
      final wouldExceedChars = (charCount + (charCount > 0 ? 1 : 0) + text.length) > chunkLineMaxLength;
      if (current.isNotEmpty && (current.length >= chunkSize || wouldExceedChars)) {
        flush();
      }

      current.add(word);
      charCount += (charCount == 0 ? 0 : 1) + text.length;

      if (isLast) flush();
    }

    // Enforce strict monotonic non-overlapping chunk time boundaries.
    // Overlapping chunks cause subtitles and emojis to render simultaneously
    // on top of each other at identical screen coordinates.
    for (int i = 0; i < chunks.length - 1; i++) {
      final currentChunk = chunks[i];
      final nextChunk = chunks[i + 1];
      if (currentChunk.endTime > nextChunk.startTime) {
        final clampedEnd = math.max(currentChunk.startTime + 0.01, nextChunk.startTime);
        chunks[i] = Chunk(
          index: currentChunk.index,
          startTime: currentChunk.startTime,
          endTime: math.min(currentChunk.endTime, clampedEnd),
          words: currentChunk.words,
          speaker: currentChunk.speaker,
        );
      }
    }

    return chunks;
  }

  /// O(log n) binary search to find the active chunk at the current time
  static Chunk? getActiveChunk(List<Chunk> chunks, double currentTime) {
    if (chunks.isEmpty) return null;

    int low = 0;
    int high = chunks.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final chunk = chunks[mid];

      if (currentTime >= chunk.startTime && currentTime <= chunk.endTime) {
        return chunk;
      } else if (currentTime < chunk.startTime) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // Fallback linear scan for overlapping/non-contiguous chunks or timing gaps
    for (final chunk in chunks) {
      if (currentTime >= chunk.startTime && currentTime <= chunk.endTime) {
        return chunk;
      }
    }

    return null;
  }

  // FIX (Issue #1, CapStudio 1.0 audit): delegates to the shared
  // SchemaClones.cloneWord — this was the 4th independent hand-duplicate
  // of the same WordSchema field list (alongside isar_service.dart and
  // editor_controller.dart).
  static WordSchema _cloneWord(WordSchema w) => SchemaClones.cloneWord(w);
}
