import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:isar_community/isar.dart';

WordSchema makeWord({
  String? wordId,
  String? text = 'hello',
  double? start = 0.0,
  double? end = 1.0,
  String? type = 'word',
  String? emoji,
  String? className,
  double? confidence = 1.0,
  bool? splitBefore = false,
  bool? hidden = false,
  EmojiConfigSchema? emojiConfig,
  String? soundEffect,
  int? soundVolume,
}) {
  return WordSchema()
    ..wordId = wordId ?? 'word_${DateTime.now().microsecondsSinceEpoch}'
    ..text = text
    ..start = start
    ..end = end
    ..type = type
    ..emoji = emoji
    ..className = className
    ..confidence = confidence
    ..splitBefore = splitBefore
    ..hidden = hidden
    ..emojiConfig = emojiConfig
    ..soundEffect = soundEffect
    ..soundVolume = soundVolume;
}

ProjectConfigSchema makeConfig({
  String? name = 'Trending Theme',
  String? fontFamily = 'Montserrat',
  String? fontWeight = '900',
  String? textTransform = 'uppercase',
  String? color = '#ffffff',
  double? fontSize = 42.0,
  double? top = 55.0,
  bool? highlightBackground = false,
  double? letterSpacing = 0.0,
  double? lineHeight = 1.2,
  String? mainColor = '#f97316',
  String? secondColor = '#06b6d4',
  String? thirdColor = '#22c55e',
  int? chunkSize = 4,
  int? chunkLineMaxLength = 30,
  String? animation = 'pop',
  String? shadow = 'none',
  String? stroke = 'thick',
  String? background,
  String? emojiPack = 'googleAnimated',
}) {
  return ProjectConfigSchema()
    ..name = name ?? ''
    ..style = (StyleConfigSchema()
      ..fontFamily = fontFamily ?? 'Montserrat'
      ..fontWeight = fontWeight ?? '900'
      ..textTransform = textTransform ?? 'uppercase'
      ..color = color ?? '#ffffff'
      ..fontSize = fontSize ?? 42.0
      ..top = top ?? 55.0
      ..highlightBackground = highlightBackground
      ..letterSpacing = letterSpacing
      ..lineHeight = lineHeight)
    ..highlightStyle = (HighlightStyleSchema()
      ..mainColor = mainColor ?? '#f97316'
      ..secondColor = secondColor ?? '#06b6d4'
      ..thirdColor = thirdColor ?? '#22c55e')
    ..subs = (SubtitleConfigSchema()
      ..chunkSize = chunkSize ?? 4
      ..chunkLineMaxLength = chunkLineMaxLength ?? 30)
    ..animation = animation ?? 'pop'
    ..shadow = shadow ?? 'none'
    ..stroke = stroke ?? 'thick'
    ..background = background
    ..emojiPack = emojiPack;
}

Project makeProject({
  int? id,
  String? projectId,
  String? name = 'Test Project',
  String? videoPath = 'path/to/video.mp4',
  double? duration = 10.0,
  int? width = 1920,
  int? height = 1080,
  DateTime? createdAt,
  double? trimStart = 0.0,
  double? trimEnd = 10.0,
  String? status = 'draft',
  String? thumbnailPath,
  ProjectConfigSchema? config,
  List<WordSchema>? words,
  List<VideoSegmentSchema>? segments,
}) {
  return Project()
    ..id = id ?? Isar.autoIncrement
    ..projectId = projectId ?? 'proj_${DateTime.now().microsecondsSinceEpoch}'
    ..name = name ?? 'Test Project'
    ..videoPath = videoPath ?? 'path/to/video.mp4'
    ..duration = duration ?? 10.0
    ..width = width ?? 1920
    ..height = height ?? 1080
    ..createdAt = createdAt ?? DateTime.now()
    ..trimStart = trimStart ?? 0.0
    ..trimEnd = trimEnd ?? 10.0
    ..status = status ?? 'draft'
    ..thumbnailPath = thumbnailPath
    ..config = config ?? makeConfig()
    ..words = words ?? []
    ..segments = segments ?? [];
}
