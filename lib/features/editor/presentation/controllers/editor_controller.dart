import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/assets/asset_path_service.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/whisper/whisper_service.dart';
import '../../../../core/whisper/whisper_mobile_service.dart';
import '../../../../core/ffmpeg/ffmpeg_locator.dart';
import '../../../../core/video/video_probe.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/utils/mock_transcription.dart';
import '../../../../core/utils/schema_clones.dart';
import '../../../../core/subtitle/srt_importer.dart';
import '../../domain/auto_enhancement_service.dart';
import '../../domain/caption_engine.dart';
import '../../../../core/audio/speaker_diarization_service.dart';
import '../../../../core/video/retention_progress_bar_models.dart';
import '../../../../core/video/retention_progress_bar_service.dart';
import '../../../../core/video/background_music_models.dart';
import '../../../../core/video/background_music_service.dart';
import '../../../../core/video/b_roll_models.dart';
import '../../../../core/video/b_roll_storage_service.dart';
import '../../../../core/video/chapter_models.dart';
import '../../../../core/video/video_proxy_service.dart';
import '../../../../core/collaboration/project_comment.dart';
import '../../../../core/collaboration/project_collaboration_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/safe_zone_overlay.dart';
import 'editor_state.dart';

// The controller is split across focused part files. Parts share this library,
// so private members stay private and the public API is unchanged:
//
//   editor_core_mixin.dart          — shared state, clone helpers, save, session
//   editor_history_mixin.dart       — undo/redo history stack + HistoryEntry
//   editor_language_fonts.dart      — pure language -> font mapping helpers
//   editor_word_ops_mixin.dart      — word/chunk editing operations
//   editor_trim_style_mixin.dart    — trim/segment + style operations
//   editor_project_ops_mixin.dart   — re-transcription + auto font application
//   editor_collaboration_mixin.dart — review comments + collaboration notes
part 'editor_core_mixin.dart';
part 'editor_history_mixin.dart';
part 'editor_language_fonts.dart';
part 'editor_word_ops_mixin.dart';
part 'editor_trim_style_mixin.dart';
part 'editor_project_ops_mixin.dart';
part 'editor_collaboration_mixin.dart';

class EditorController extends StateNotifier<EditorState>
    with
        EditorCoreMixin,
        EditorHistoryMixin,
        EditorWordOpsMixin,
        EditorTrimStyleOpsMixin,
        EditorProjectOpsMixin,
        EditorCollaborationOpsMixin {
  EditorController(this.ref) : super(const EditorState());

  @override
  final Ref ref;

  /// Current project revision, incremented on every mutation. Exposed for
  /// callers that need to detect concurrent edits (e.g. dialog cancel-revert
  /// guards) — StateNotifier.state is otherwise protected.
  int get revision => state.revision;
}

// Riverpod provider definition
final editorProvider =
    StateNotifierProvider<EditorController, EditorState>((ref) {
  return EditorController(ref);
});
