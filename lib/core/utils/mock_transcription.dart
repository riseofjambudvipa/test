import '../database/schemas/word.dart';

/// Generates mock transcription words for demo/testing purposes.
/// Note: This is intentionally kept in production builds to power the
/// "Instant Demo" feature, allowing users to try the editor without setting up local Whisper first.
/// Used by both DashboardController and EditorController.
List<WordSchema> generateMockWords(double duration) {
  final phrases = [
    'This', 'is', 'a', 'demo', 'timeline', 'preview', 'to', 'test',
    'caption', 'styles', 'and', 'animations', 'offline',
  ];

  final words = <WordSchema>[];
  double cursor = 0.1;
  // FIX (audit): the loop was bounded by phrases.length, so a 10-minute demo
  // video got captions only for the first few seconds and looked broken.
  // Cycle the phrases so the mock transcript covers the whole duration.
  int i = 0;
  while (cursor < duration - 0.5) {
    final text = phrases[i % phrases.length];
    final wordDuration = 0.2 + (text.length * 0.04);
    final w = WordSchema()
      ..wordId = 'w_${i}_${(cursor * 1000).toInt()}'
      ..text = text
      ..start = cursor
      ..end = cursor + wordDuration
      ..type = 'word'
      ..confidence = 0.95
      ..splitBefore = (i % 4 == 0 && i > 0);
    words.add(w);
    cursor += wordDuration + 0.05;
    i++;
  }
  return words;
}
