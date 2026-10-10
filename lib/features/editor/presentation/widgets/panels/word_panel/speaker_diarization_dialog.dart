import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/audio/speaker_diarization_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';

/// Shows the Multi-Speaker Diarization & Labeling Dialog.
/// If [targetChunk] is provided, focus is placed on assigning or editing
/// that specific chunk's speaker label.
Future<void> showSpeakerDiarizationDialog(
  BuildContext context,
  WidgetRef ref, {
  Chunk? targetChunk,
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SpeakerDiarizationDialog(targetChunk: targetChunk),
  );
}

class _SpeakerDiarizationDialog extends ConsumerStatefulWidget {
  final Chunk? targetChunk;

  const _SpeakerDiarizationDialog({this.targetChunk});

  @override
  ConsumerState<_SpeakerDiarizationDialog> createState() => _SpeakerDiarizationDialogState();
}

class _SpeakerDiarizationDialogState extends ConsumerState<_SpeakerDiarizationDialog> {
  int _speakerCount = 2;
  double _pauseThreshold = 0.65;
  final TextEditingController _customSpeakerCtrl = TextEditingController();
  bool _applyToMatchingChunks = false;

  @override
  void dispose() {
    _customSpeakerCtrl.dispose();
    super.dispose();
  }

  void _runAutoDetection() {
    final count = ref.read(editorProvider.notifier).autoDetectSpeakers(
      speakerCount: _speakerCount,
      pauseThresholdSeconds: _pauseThreshold,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-detected $count speakers across transcript!'),
        backgroundColor: AppTheme.cardBg,
      ),
    );
  }

  void _assignChunkSpeaker(String speaker) {
    if (widget.targetChunk != null) {
      ref.read(editorProvider.notifier).setChunkSpeaker(
        widget.targetChunk!,
        speaker,
        applyToMatching: _applyToMatchingChunks,
      );
    }
    Navigator.of(context).pop();
  }

  void _showRenameDialog(String oldSpeaker) {
    final ctrl = TextEditingController(text: oldSpeaker);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Rename "$oldSpeaker"',
          style: TextStyle(color: AppTheme.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.primaryText, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter new name (e.g. Host, Alex, Lex)',
            hintStyle: TextStyle(color: AppTheme.mutedText),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.borderGlass),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accentOrange),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: AppTheme.onAccentText,
            ),
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                ref.read(editorProvider.notifier).renameSpeaker(oldSpeaker, newName);
                setState(() {});
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('RENAME ALL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.read(editorProvider.notifier).getSpeakerStats();
    final existingSpeakers = ref.read(editorProvider.notifier).getUniqueSpeakers();

    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderGlass),
      ),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.12),
                    borderRadius: 8,
                    borderOpacity: 0.2,
                  ),
                  child: Icon(Icons.record_voice_over_rounded, color: AppTheme.accentCyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.targetChunk != null
                            ? 'Assign Speaker • Chunk ${widget.targetChunk!.index + 1}'
                            : 'Multi-Speaker Diarization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Descript-grade speaker attribution and talk-time analytics.',
                        style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.mutedText),
                  splashRadius: 18,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: 14),

            // Content Area (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single Chunk Assignment Mode
                    if (widget.targetChunk != null) ...[
                      Text(
                        'CHOOSE SPEAKER FOR THIS CHUNK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.mutedText,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...existingSpeakers.map((spk) {
                            final isCurrent = widget.targetChunk!.speaker == spk;
                            final color = SpeakerDiarizationService.getSpeakerColor(spk);
                            return InkWell(
                              onTap: () => _assignChunkSpeaker(spk),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: AppTheme.glassDecoration(
                                  color: isCurrent ? color.withValues(alpha: 0.25) : AppTheme.cardBg,
                                  borderRadius: 8,
                                  borderOpacity: isCurrent ? 0.35 : 0.08,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_rounded, size: 14, color: color),
                                    const SizedBox(width: 6),
                                    Text(
                                      spk,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        color: isCurrent ? color : AppTheme.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customSpeakerCtrl,
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                              decoration: InputDecoration(
                                hintText: 'Or enter new speaker name...',
                                hintStyle: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.borderGlass),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.accentOrange),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: AppTheme.onAccentText,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              final text = _customSpeakerCtrl.text.trim();
                              if (text.isNotEmpty) {
                                _assignChunkSpeaker(text);
                              }
                            },
                            child: const Text('ASSIGN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _applyToMatchingChunks,
                        onChanged: (val) => setState(() => _applyToMatchingChunks = val ?? false),
                        title: Text(
                          'Also update all matching chunks',
                          style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: AppTheme.dividerColor),
                      const SizedBox(height: 14),
                    ],

                    // Current Speaker Analytics & Talk Time
                    Text(
                      'SPEAKER ANALYTICS & TALK TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.mutedText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (stats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No speakers attributed yet. Click "Auto-Detect Speakers" below to analyze conversational turns.',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                        ),
                      )
                    else
                      ...stats.map((s) {
                        final color = SpeakerDiarizationService.getSpeakerColor(s.speaker);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: AppTheme.glassDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: 8,
                            borderOpacity: 0.08,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: color.withValues(alpha: 0.2),
                                    child: Icon(Icons.person_rounded, size: 14, color: color),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          s.speaker,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryText,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _showRenameDialog(s.speaker),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(Icons.edit_outlined, size: 12, color: AppTheme.mutedText),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${s.formattedTalkTime} (${s.percentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (s.percentage / 100.0).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.dividerColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${s.wordCount} words spoken',
                                style: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 14),

                    // AI Auto-Detection Section
                    Text(
                      'AI TURN-TAKING DETECTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.mutedText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyzes conversational pause pauses, interrogatives (?), and turn-taking response patterns.',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                    const SizedBox(height: 12),

                    // Speaker Count Selection
                    Row(
                      children: [
                        Text(
                          'Number of Speakers:',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                        ),
                        const Spacer(),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 2, label: Text('2 (Host & Guest)')),
                            ButtonSegment(value: 3, label: Text('3')),
                            ButtonSegment(value: 4, label: Text('4')),
                          ],
                          selected: {_speakerCount},
                          onSelectionChanged: (val) => setState(() => _speakerCount = val.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pause Sensitivity Slider
                    Row(
                      children: [
                        Text(
                          'Pause Turn Threshold: ${_pauseThreshold.toStringAsFixed(2)}s',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: AppTheme.premiumSliderTheme(context),
                      child: Slider(
                        value: _pauseThreshold,
                        min: 0.40,
                        max: 1.20,
                        divisions: 16,
                        label: '${_pauseThreshold.toStringAsFixed(2)}s',
                        onChanged: (val) => setState(() => _pauseThreshold = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: 12),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryText,
                    side: BorderSide(color: AppTheme.borderGlass),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: AppTheme.onAccentText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    'AUTO-DETECT SPEAKERS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: _runAutoDetection,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
