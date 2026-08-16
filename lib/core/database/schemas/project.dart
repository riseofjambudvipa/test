import 'package:isar_community/isar.dart';
import 'word.dart';

part 'project.g.dart';

@collection
class Project {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String projectId = ''; // Unique uuid: proj_timestamp_uuid

  String name = '';
  String videoPath = '';
  double duration = 0.0;
  int width = 0;
  int height = 0;
  DateTime createdAt = DateTime.now();
  double trimStart = 0.0;
  double trimEnd = 0.0;
  String status = 'draft'; // 'draft' | 'completed'
  String? thumbnailPath;

  ProjectConfigSchema config = ProjectConfigSchema();
  List<WordSchema> words = [];
  
  List<VideoSegmentSchema>? segments;
}

@embedded
class ProjectConfigSchema {
  String name = '';
  
  StyleConfigSchema style = StyleConfigSchema();
  HighlightStyleSchema highlightStyle = HighlightStyleSchema();
  SubtitleConfigSchema subs = SubtitleConfigSchema();
  
  String animation = 'none';
  String shadow = 'none';
  String stroke = 'none';
  String? background;
  String? emojiPack;
}

@embedded
class StyleConfigSchema {
  String fontFamily = 'Arial';
  String fontWeight = '500'; // '500', '900', etc.
  String textTransform = 'none'; // 'uppercase' | 'none' | 'capitalize'
  String color = '#ffffff'; // Hex string e.g. '#ffffff'
  double fontSize = 24.0;
  double top = 50.0; // position percentage (Y offset)
  
  bool? highlightBackground;
  double? letterSpacing;
  double? lineHeight;
}

@embedded
class HighlightStyleSchema {
  String mainColor = '#f97316'; // Hex string e.g. '#f97316'
  String secondColor = '#ffffff';
  String thirdColor = '#ffffff';
}

@embedded
class SubtitleConfigSchema {
  int chunkSize = 3;
  int chunkLineMaxLength = 20;
}

@embedded
class VideoSegmentSchema {
  double? start;
  double? end;
  bool? isDeleted;
}
