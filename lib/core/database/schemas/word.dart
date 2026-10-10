import 'package:isar_community/isar.dart';

part 'word.g.dart';

@embedded
class WordSchema {
  String? wordId;
  String? text;
  double? start;
  double? end;
  String? type; // 'word' | 'punctuation'
  
  String? emoji;
  /// The slot/key for the highlight color.
  /// Valid values: 'mainColor' | 'secondColor' | 'thirdColor'.
  String? className;

  double? confidence;
  bool? splitBefore;
  bool? hidden;
  
  EmojiConfigSchema? emojiConfig;
  String? soundEffect;

  /// Sound effect playback volume (clamped between 0 and 100).
  int? soundVolume;

  /// Speaker identification label (e.g. 'Speaker 1', 'Host', 'Guest').
  String? speaker;
}

@embedded
class EmojiConfigSchema {
  double? x;
  double? y;
  double? scale;
  double? speed;
}
