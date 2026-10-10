import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../database/isar_service.dart';
import '../database/schemas/project.dart';
import '../database/schemas/word.dart';
import '../video/retention_progress_bar_models.dart';
import '../video/retention_progress_bar_service.dart';
import '../collaboration/project_comment.dart';
import '../collaboration/project_collaboration_service.dart';
import '../logger/logger_service.dart';

/// Bundle packaging service for exporting, sharing, and importing
/// complete CapStudio projects (.capstudio / .json).
class ProjectBundleService {
  ProjectBundleService._();
  static final ProjectBundleService instance = ProjectBundleService._();

  static const String currentBundleVersion = '1.0';
  static final _uuid = const Uuid();

  /// Serializes a [Project] and its entire schema graph into a structured Map.
  Map<String, dynamic> serialize(Project project) {
    final style = project.config.style;
    final hs = project.config.highlightStyle;
    final subs = project.config.subs;

    return {
      'format': 'CapStudioProject',
      'bundleVersion': currentBundleVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'project': {
        'projectId': project.projectId,
        'name': project.name,
        'videoPath': project.videoPath,
        'duration': project.duration,
        'width': project.width,
        'height': project.height,
        'trimStart': project.trimStart,
        'trimEnd': project.trimEnd,
        'status': project.status,
        'thumbnailPath': project.thumbnailPath,
        'config': {
          'name': project.config.name,
          'animation': project.config.animation,
          'shadow': project.config.shadow,
          'stroke': project.config.stroke,
          'background': project.config.background,
          'emojiPack': project.config.emojiPack,
          'style': {
            'fontFamily': style.fontFamily,
            'fontWeight': style.fontWeight,
            'textTransform': style.textTransform,
            'color': style.color,
            'fontSize': style.fontSize,
            'top': style.top,
            'left': style.left,
            'highlightBackground': style.highlightBackground,
            'letterSpacing': style.letterSpacing,
            'lineHeight': style.lineHeight,
          },
          'highlightStyle': {
            'mainColor': hs.mainColor,
            'secondColor': hs.secondColor,
            'thirdColor': hs.thirdColor,
          },
          'subs': {
            'chunkSize': subs.chunkSize,
            'chunkLineMaxLength': subs.chunkLineMaxLength,
          },
        },
        'words': project.words.map((w) => {
          'wordId': w.wordId,
          'text': w.text,
          'start': w.start,
          'end': w.end,
          'type': w.type,
          'speaker': w.speaker,
          'emoji': w.emoji,
          'className': w.className,
          'confidence': w.confidence,
          'splitBefore': w.splitBefore,
          'hidden': w.hidden,
          'soundEffect': w.soundEffect,
          'soundVolume': w.soundVolume,
        }).toList(),
        'segments': project.segments?.map((s) => {
          'start': s.start,
          'end': s.end,
          'isDeleted': s.isDeleted,
        }).toList() ?? [],
        'retentionBar': RetentionProgressBarService.instance.getConfig(project.projectId).toJson(),
        'comments': ProjectCollaborationService.instance.getCommentsSync(project.projectId).map((c) => c.toJson()).toList(),
      },
    };
  }

  /// Deserializes a CapStudio project JSON Map into a [Project] instance.
  /// Deserializes a CapStudio project JSON Map into a [Project] instance.
  Project deserialize(
    Map<String, dynamic> json, {
    bool generateNewId = true,
    String? overrideVideoPath,
  }) {
    final projMap = (json['project'] is Map)
        ? Map<String, dynamic>.from(json['project'] as Map)
        : json;

    final project = Project();

    if (generateNewId) {
      final now = DateTime.now().millisecondsSinceEpoch;
      project.projectId = 'proj_${now}_${_uuid.v4().substring(0, 8)}';
    } else {
      project.projectId = projMap['projectId']?.toString() ?? 'proj_${_uuid.v4()}';
    }

    project.name = projMap['name']?.toString() ?? 'Imported Project';
    project.videoPath = overrideVideoPath ?? (projMap['videoPath']?.toString() ?? '');
    project.duration = (projMap['duration'] as num?)?.toDouble() ?? 0.0;
    project.width = (projMap['width'] as num?)?.toInt() ?? 1080;
    project.height = (projMap['height'] as num?)?.toInt() ?? 1920;
    project.trimStart = (projMap['trimStart'] as num?)?.toDouble() ?? 0.0;
    project.trimEnd = (projMap['trimEnd'] as num?)?.toDouble() ?? project.duration;
    project.status = projMap['status']?.toString() ?? 'draft';
    project.thumbnailPath = projMap['thumbnailPath']?.toString();
    project.createdAt = DateTime.now();

    // Config deserialization
    final cfgMap = (projMap['config'] is Map)
        ? Map<String, dynamic>.from(projMap['config'] as Map)
        : <String, dynamic>{};
    final config = ProjectConfigSchema()
      ..name = cfgMap['name']?.toString() ?? ''
      ..animation = cfgMap['animation']?.toString() ?? 'none'
      ..shadow = cfgMap['shadow']?.toString() ?? 'none'
      ..stroke = cfgMap['stroke']?.toString() ?? 'none'
      ..background = cfgMap['background']?.toString()
      ..emojiPack = cfgMap['emojiPack']?.toString();

    // Style
    final styleMap = (cfgMap['style'] is Map)
        ? Map<String, dynamic>.from(cfgMap['style'] as Map)
        : <String, dynamic>{};
    config.style = StyleConfigSchema()
      ..fontFamily = styleMap['fontFamily']?.toString() ?? 'Arial'
      ..fontWeight = styleMap['fontWeight']?.toString() ?? '500'
      ..textTransform = styleMap['textTransform']?.toString() ?? 'none'
      ..color = styleMap['color']?.toString() ?? '#ffffff'
      ..fontSize = (styleMap['fontSize'] as num?)?.toDouble() ?? 24.0
      ..top = (styleMap['top'] as num?)?.toDouble() ?? 50.0
      ..left = (styleMap['left'] as num?)?.toDouble() ?? 50.0
      ..highlightBackground = styleMap['highlightBackground'] as bool?
      ..letterSpacing = (styleMap['letterSpacing'] as num?)?.toDouble()
      ..lineHeight = (styleMap['lineHeight'] as num?)?.toDouble();

    // Highlight Style
    final hsMap = (cfgMap['highlightStyle'] is Map)
        ? Map<String, dynamic>.from(cfgMap['highlightStyle'] as Map)
        : <String, dynamic>{};
    config.highlightStyle = HighlightStyleSchema()
      ..mainColor = hsMap['mainColor']?.toString() ?? '#f97316'
      ..secondColor = hsMap['secondColor']?.toString() ?? '#ffffff'
      ..thirdColor = hsMap['thirdColor']?.toString() ?? '#ffffff';

    // Subs
    final subsMap = (cfgMap['subs'] is Map)
        ? Map<String, dynamic>.from(cfgMap['subs'] as Map)
        : <String, dynamic>{};
    config.subs = SubtitleConfigSchema()
      ..chunkSize = (subsMap['chunkSize'] as num?)?.toInt() ?? 3
      ..chunkLineMaxLength = (subsMap['chunkLineMaxLength'] as num?)?.toInt() ?? 20;

    project.config = config;

    // Words
    final rawWords = projMap['words'] as List<dynamic>? ?? [];
    project.words = rawWords.map((raw) {
      final wMap = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      return WordSchema()
        ..wordId = wMap['wordId']?.toString() ?? _uuid.v4()
        ..text = wMap['text']?.toString() ?? ''
        ..start = (wMap['start'] as num?)?.toDouble()
        ..end = (wMap['end'] as num?)?.toDouble()
        ..type = wMap['type']?.toString() ?? 'word'
        ..speaker = wMap['speaker']?.toString()
        ..emoji = wMap['emoji']?.toString()
        ..className = wMap['className']?.toString()
        ..confidence = (wMap['confidence'] as num?)?.toDouble() ?? 1.0
        ..splitBefore = wMap['splitBefore'] as bool?
        ..hidden = wMap['hidden'] as bool?
        ..soundEffect = wMap['soundEffect']?.toString()
        ..soundVolume = (wMap['soundVolume'] as num?)?.toInt();
    }).toList();

    // Segments
    final rawSegments = projMap['segments'] as List<dynamic>? ?? [];
    if (rawSegments.isNotEmpty) {
      project.segments = rawSegments.map((raw) {
        final sMap = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        return VideoSegmentSchema()
          ..start = (sMap['start'] as num?)?.toDouble()
          ..end = (sMap['end'] as num?)?.toDouble()
          ..isDeleted = sMap['isDeleted'] as bool?;
      }).toList();
    }

    // Retention Progress Bar
    if (projMap['retentionBar'] is Map) {
      final rbConfig = RetentionProgressBarConfig.fromJson(
        Map<String, dynamic>.from(projMap['retentionBar'] as Map),
      );
      RetentionProgressBarService.instance.saveConfig(project.projectId, rbConfig);
    }

    // Collaboration / Review Comments
    final rawComments = projMap['comments'] as List<dynamic>? ?? [];
    if (rawComments.isNotEmpty) {
      final comments = rawComments
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => ProjectComment.fromJson(Map<String, dynamic>.from(m)).copyWith(projectId: project.projectId))
          .toList();
      ProjectCollaborationService.instance.saveComments(project.projectId, comments);
    }

    return project;
  }

  /// Safely deserializes any dynamic JSON representation (Map or List) into a [Project].
  /// Handles both standard project bundles, list-wrapped bundles, and raw caption lists.
  Project deserializeDynamic(
    dynamic rawJson, {
    bool generateNewId = true,
    String? overrideVideoPath,
    String? defaultName,
  }) {
    if (rawJson is Map) {
      return deserialize(
        Map<String, dynamic>.from(rawJson),
        generateNewId: generateNewId,
        overrideVideoPath: overrideVideoPath,
      );
    }

    if (rawJson is List) {
      if (rawJson.isEmpty) {
        throw const FormatException('The imported project file is empty.');
      }
      final firstItem = rawJson.first;
      if (firstItem is Map) {
        final itemMap = Map<String, dynamic>.from(firstItem);
        // Case A: array containing full project objects
        if (itemMap.containsKey('project') ||
            itemMap.containsKey('format') ||
            itemMap.containsKey('projectId') ||
            itemMap.containsKey('words') && itemMap['words'] is List) {
          return deserialize(
            itemMap,
            generateNewId: generateNewId,
            overrideVideoPath: overrideVideoPath,
          );
        }

        // Case B: array of caption words / subtitles: [{text: "Hello", start: 0.0, end: 1.0}, ...]
        if (itemMap.containsKey('text') || itemMap.containsKey('word') || itemMap.containsKey('start')) {
          final project = Project();
          final now = DateTime.now().millisecondsSinceEpoch;
          project.projectId = 'proj_${now}_${_uuid.v4().substring(0, 8)}';
          project.name = defaultName ?? 'Imported Captions';
          project.videoPath = overrideVideoPath ?? '';
          project.createdAt = DateTime.now();
          project.status = 'draft';

          project.config = ProjectConfigSchema()
            ..name = project.name
            ..animation = 'none'
            ..shadow = 'none'
            ..stroke = 'none'
            ..style = (StyleConfigSchema()
              ..fontFamily = 'Montserrat'
              ..fontWeight = '600'
              ..color = '#ffffff'
              ..fontSize = 28.0
              ..top = 75.0)
            ..highlightStyle = (HighlightStyleSchema()
              ..mainColor = '#ffffff'
              ..secondColor = '#ffffff'
              ..thirdColor = '#ffffff')
            ..subs = (SubtitleConfigSchema()
              ..chunkSize = 3
              ..chunkLineMaxLength = 15);

          double maxEnd = 0.0;
          project.words = rawJson.whereType<Map<dynamic, dynamic>>().map((m) {
            final wMap = Map<String, dynamic>.from(m);
            final text = (wMap['text'] ?? wMap['word'] ?? '').toString();
            final start = (wMap['start'] as num?)?.toDouble() ?? 0.0;
            final end = (wMap['end'] as num?)?.toDouble() ?? (start + 0.5);
            if (end > maxEnd) maxEnd = end;
            return WordSchema()
              ..wordId = wMap['wordId']?.toString() ?? _uuid.v4()
              ..text = text
              ..start = start
              ..end = end
              ..type = wMap['type']?.toString() ?? 'word'
              ..speaker = wMap['speaker']?.toString()
              ..emoji = wMap['emoji']?.toString()
              ..confidence = (wMap['confidence'] as num?)?.toDouble() ?? 1.0;
          }).toList();

          project.duration = maxEnd;
          project.trimEnd = maxEnd;
          return project;
        }

        // Fallback: deserialize first item
        return deserialize(
          itemMap,
          generateNewId: generateNewId,
          overrideVideoPath: overrideVideoPath,
        );
      }
      throw const FormatException('Unrecognized list format in project bundle.');
    }

    throw FormatException('Expected a JSON Object or List, but got ${rawJson.runtimeType}');
  }

  /// Exports a project to a .capstudio bundle file.
  Future<File> exportProjectToFile(Project project, String destinationFilePath) async {
    final map = serialize(project);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(map);
    final file = File(destinationFilePath);
    await file.writeAsString(jsonStr);
    LoggerService.instance.action('ProjectBundleService', 'Exported project "${project.name}" to $destinationFilePath');
    return file;
  }

  /// Imports a project from a .capstudio or .json file and saves it in the database.
  Future<Project> importProjectFromFile(
    String filePath, {
    bool generateNewId = true,
    String? overrideVideoPath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundException('Project bundle file not found at: $filePath');
    }

    final content = await file.readAsString();
    final dynamic decoded = json.decode(content);
    final baseName = p.basenameWithoutExtension(filePath);
    final project = deserializeDynamic(
      decoded,
      generateNewId: generateNewId,
      overrideVideoPath: overrideVideoPath,
      defaultName: baseName,
    );

    await IsarService.instance.saveProject(project);
    LoggerService.instance.action('ProjectBundleService', 'Imported project "${project.name}" with ID: ${project.projectId}');
    return project;
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => message;
}
