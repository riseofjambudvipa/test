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
  for (int i = 0; i < phrases.length && cursor < duration - 0.5; i++) {
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
  }
  return words;
}
