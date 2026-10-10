import '../database/schemas/project.dart';
import '../database/schemas/word.dart';

/// Shared, single-source-of-truth clone functions for the Project/Word
/// object graph.
///
/// FIX (Issue #1, CapStudio 1.0 audit): this exact field-by-field cloning
/// logic previously existed as independently hand-maintained copies in:
///   - `core/database/isar_service.dart` (`_deepCloneProject` and friends,
///     used before every native save so the persisted copy doesn't alias
///     the caller's live object)
///   - `features/editor/presentation/controllers/editor_controller.dart`
///     (`_cloneProject` and friends, used for undo/redo history snapshots)
///   - `features/editor/domain/caption_engine.dart` (`_cloneWord`, used
///     narrowly for punctuation-merging)
///
/// If a field were added to `Project`/`WordSchema`/the config schemas and a
/// developer forgot to update one of the 3 independent copies, the result
/// is a silent bug with a different symptom at each site: a field that
/// doesn't survive a save, doesn't survive an undo, or doesn't survive a
/// punctuation merge. Centralizing the *leaf-level* object cloning here
/// means there's exactly one place to update.
///
/// Note: this intentionally does NOT unify the *container-level* traversal
/// strategy (e.g. whether `Project.words` is deep-cloned or
/// reference-shared) — that varies correctly by use case (see
/// [cloneProjectDeep] vs. editor_controller's own shallow-words variant,
/// which stays where it is since it also depends on
/// [SchemaClones.cloneWord] here) and was verified safe for its specific
/// use case during the audit. Only the "how do I copy one X" logic is
/// shared.
class SchemaClones {
  const SchemaClones._();

  static WordSchema cloneWord(WordSchema w) {
    return WordSchema()
      ..wordId = w.wordId
      ..text = w.text
      ..start = w.start
      ..end = w.end
      ..type = w.type
      ..emoji = w.emoji
      ..className = w.className
      ..confidence = w.confidence
      ..splitBefore = w.splitBefore
      ..hidden = w.hidden
      ..emojiConfig = w.emojiConfig != null
          ? (EmojiConfigSchema()
            ..x = w.emojiConfig!.x
            ..y = w.emojiConfig!.y
            ..scale = w.emojiConfig!.scale
            ..speed = w.emojiConfig!.speed)
          : null
      ..soundEffect = w.soundEffect
      ..soundVolume = w.soundVolume
      ..speaker = w.speaker;
  }

  static StyleConfigSchema cloneStyle(StyleConfigSchema s) {
    return StyleConfigSchema()
      ..fontFamily = s.fontFamily
      ..fontWeight = s.fontWeight
      ..textTransform = s.textTransform
      ..color = s.color
      ..fontSize = s.fontSize
      ..top = s.top
      ..left = s.left
      ..highlightBackground = s.highlightBackground
      ..letterSpacing = s.letterSpacing
      ..lineHeight = s.lineHeight;
  }

  static HighlightStyleSchema cloneHighlightStyle(HighlightStyleSchema h) {
    return HighlightStyleSchema()
      ..mainColor = h.mainColor
      ..secondColor = h.secondColor
      ..thirdColor = h.thirdColor;
  }

  static SubtitleConfigSchema cloneSubs(SubtitleConfigSchema s) {
    return SubtitleConfigSchema()
      ..chunkSize = s.chunkSize
      ..chunkLineMaxLength = s.chunkLineMaxLength;
  }

  static VideoSegmentSchema cloneSegment(VideoSegmentSchema s) {
    return VideoSegmentSchema()
      ..start = s.start
      ..end = s.end
      ..isDeleted = s.isDeleted;
  }

  static ProjectConfigSchema cloneConfig(ProjectConfigSchema c) {
    return ProjectConfigSchema()
      ..name = c.name
      ..style = cloneStyle(c.style)
      ..highlightStyle = cloneHighlightStyle(c.highlightStyle)
      ..subs = cloneSubs(c.subs)
      ..animation = c.animation
      ..shadow = c.shadow
      ..stroke = c.stroke
      ..background = c.background
      ..emojiPack = c.emojiPack;
  }

  /// Full deep clone: every word and segment is independently cloned too.
  /// Used where the caller needs a copy with zero shared mutable state
  /// (e.g. before persisting, so a later in-place edit to the live project
  /// can't retroactively alter what was already saved).
  static Project cloneProjectDeep(Project p) {
    final clone = Project()
      ..id = p.id
      ..projectId = p.projectId
      ..name = p.name
      ..videoPath = p.videoPath
      ..duration = p.duration
      ..width = p.width
      ..height = p.height
      ..createdAt = p.createdAt
      ..trimStart = p.trimStart
      ..trimEnd = p.trimEnd
      ..status = p.status
      ..thumbnailPath = p.thumbnailPath
      ..config = cloneConfig(p.config)
      ..words = p.words.map(cloneWord).toList();

    if (p.segments != null) {
      clone.segments = p.segments!.map(cloneSegment).toList();
    }
    return clone;
  }
}
