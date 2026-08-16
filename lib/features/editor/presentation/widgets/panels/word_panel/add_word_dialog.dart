import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../controllers/editor_controller.dart';

class TimeEditDialog extends StatefulWidget {
  final double initialStart;
  final double initialEnd;
  final double videoDuration;
  final void Function(double start, double end) onSave;

  const TimeEditDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.videoDuration,
    required this.onSave,
  });

  @override
  State<TimeEditDialog> createState() => _TimeEditDialogState();
}

class _TimeEditDialogState extends State<TimeEditDialog> {
  late double startTime;
  late double endTime;
  late TextEditingController startController;
  late TextEditingController endController;

  @override
  void initState() {
    super.initState();
    startTime = widget.initialStart;
    endTime = widget.initialEnd;
    startController = TextEditingController(text: startTime.toStringAsFixed(3));
    endController = TextEditingController(text: endTime.toStringAsFixed(3));
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 340,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDIT TIMING',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Start Time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 28,
                child: TextField(
                  controller: startController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: AppTheme.defaultBorder(radius: 6),
                    focusedBorder: AppTheme.focusedBorder(radius: 6),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed >= 0 && parsed <= endTime) {
                      setState(() {
                        startTime = parsed;
                      });
                    } else {
                      startController.text = startTime.toStringAsFixed(3);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: AppTheme.premiumSliderTheme(context),
            child: Slider(
              value: startTime.clamp(0.0, endTime > 0.0 ? endTime : 0.1),
              min: 0.0,
              max: endTime > 0.0 ? endTime : 0.1,
              onChanged: (val) {
                setState(() {
                  startTime = val;
                  startController.text = val.toStringAsFixed(3);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'End Time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 28,
                child: TextField(
                  controller: endController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: AppTheme.defaultBorder(radius: 6),
                    focusedBorder: AppTheme.focusedBorder(radius: 6),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed >= startTime && parsed <= widget.videoDuration) {
                      setState(() {
                        endTime = parsed;
                      });
                    } else {
                      endController.text = endTime.toStringAsFixed(3);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: AppTheme.premiumSliderTheme(context),
            child: Slider(
              value: endTime.clamp(startTime, widget.videoDuration > startTime ? widget.videoDuration : startTime + 0.1),
              min: startTime,
              max: widget.videoDuration > startTime ? widget.videoDuration : startTime + 0.1,
              onChanged: (val) {
                setState(() {
                  endTime = val;
                  endController.text = val.toStringAsFixed(3);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Duration: ${(endTime - startTime).toStringAsFixed(3)}s',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final parsedStart = double.tryParse(startController.text) ?? startTime;
                  final parsedEnd = double.tryParse(endController.text) ?? endTime;
                  if (parsedStart >= 0 && parsedEnd >= parsedStart && parsedEnd <= widget.videoDuration) {
                    widget.onSave(parsedStart, parsedEnd);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid start/end timings. Start must be >= 0, and end must be >= start and <= video duration.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WordSettingsDialog extends ConsumerStatefulWidget {
  final Project project;
  final WordSchema word;
  final bool isFirstWord;
  final void Function(
    BuildContext context,
    String initialSfx,
    double initialVolume,
    void Function(String sfxId, double volume) onSelect,
    VoidCallback? onRemove,
  ) onSoundLibraryTap;

  const WordSettingsDialog({
    super.key,
    required this.project,
    required this.word,
    required this.isFirstWord,
    required this.onSoundLibraryTap,
  });

  @override
  ConsumerState<WordSettingsDialog> createState() => _WordSettingsDialogState();
}

class _WordSettingsDialogState extends ConsumerState<WordSettingsDialog> {
  late TextEditingController textController;
  late TextEditingController startController;
  late TextEditingController endController;
  late String? highlightClass;
  late String? selectedSfx;
  late double sfxVolume;
  String? playingSfxId;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.word.text);
    startController = TextEditingController(text: widget.word.start?.toStringAsFixed(3) ?? '0.0');
    endController = TextEditingController(text: widget.word.end?.toStringAsFixed(3) ?? '0.0');
    highlightClass = widget.word.className;

    final sfxData = SfxData.parse(widget.word.soundEffect, fallbackVolume: widget.word.soundVolume ?? 100);
    selectedSfx = sfxData.word?.name ?? '';
    sfxVolume = (sfxData.word?.volume ?? 100).toDouble();
  }

  @override
  void dispose() {
    textController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hs = widget.project.config.highlightStyle;
    final style = widget.project.config.style;

    final baseColor = _parseHex(style.color, Colors.white);
    final highlight1Color = _parseHex(hs.mainColor, AppTheme.accentOrange);
    final highlight2Color = _parseHex(hs.secondColor, AppTheme.accentCyan);
    final highlight3Color = _parseHex(hs.thirdColor, AppTheme.accentGreen);

    final sfxData = SfxData.parse(widget.word.soundEffect, fallbackVolume: widget.word.soundVolume ?? 100);
    final sfx = selectedSfx ?? '';

    Widget buildHighlightOption({
      required String label,
      required Color color,
      required String value,
    }) {
      final isSelected = (value == 'none' && (highlightClass == null || highlightClass == 'none')) || (highlightClass == value);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              highlightClass = value;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: AppTheme.glassDecoration(
              color: isSelected 
                  ? color.withValues(alpha: 0.15)
                  : AppTheme.cardBg.withValues(alpha: 0.25),
              borderRadius: 8,
              borderOpacity: isSelected ? 0.35 : 0.06,
              glowColor: isSelected ? color : null,
              glowOpacity: isSelected ? 0.08 : 0.0,
            ).copyWith(
              border: Border.all(
                color: isSelected 
                    ? color 
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PremiumBlurDialog(
      maxWidth: 440,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'WORD SETTINGS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.word.hidden == true ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.secondaryText,
                    ),
                    tooltip: 'Toggle Hide',
                    onPressed: () {
                      final wordId = widget.word.wordId;
                      if (wordId != null) {
                        ref.read(editorProvider.notifier).updateWord(
                          wordId,
                          hidden: widget.word.hidden == true ? false : true,
                        );
                        LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Toggled visibility for: "${widget.word.text}"');
                      }
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
                    decoration: InputDecoration(
                      labelText: 'Word Text',
                      border: AppTheme.defaultBorder(),
                      focusedBorder: AppTheme.focusedBorder(),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                          decoration: InputDecoration(
                            labelText: 'Start (seconds)',
                            isDense: true,
                            border: AppTheme.defaultBorder(),
                            focusedBorder: AppTheme.focusedBorder(),
                            filled: true,
                            fillColor: AppTheme.cardBg,
                            contentPadding: const EdgeInsets.only(left: 8, right: 2, top: 10, bottom: 10),
                            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(startController.text) ?? 0.0) - 0.05;
                                    startController.text = val.toStringAsFixed(3);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.remove, size: 14, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(startController.text) ?? 0.0) + 0.05;
                                    startController.text = val.toStringAsFixed(3);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.add, size: 14, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                          decoration: InputDecoration(
                            labelText: 'End (seconds)',
                            isDense: true,
                            border: AppTheme.defaultBorder(),
                            focusedBorder: AppTheme.focusedBorder(),
                            filled: true,
                            fillColor: AppTheme.cardBg,
                            contentPadding: const EdgeInsets.only(left: 8, right: 2, top: 10, bottom: 10),
                            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(endController.text) ?? 0.0) - 0.05;
                                    endController.text = val.toStringAsFixed(3);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.remove, size: 14, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(endController.text) ?? 0.0) + 0.05;
                                    endController.text = val.toStringAsFixed(3);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.add, size: 14, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HIGHLIGHT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildHighlightOption(
                        label: 'Default',
                        color: baseColor,
                        value: 'none',
                      ),
                      buildHighlightOption(
                        label: 'Highlight 1',
                        color: highlight1Color,
                        value: 'mainColor',
                      ),
                      buildHighlightOption(
                        label: 'Highlight 2',
                        color: highlight2Color,
                        value: 'secondColor',
                      ),
                      buildHighlightOption(
                        label: 'Highlight 3',
                        color: highlight3Color,
                        value: 'thirdColor',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOUND EFFECTS (SFX)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentCyan,
                                side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(sfx.isNotEmpty ? Icons.volume_up : Icons.volume_mute, size: 16),
                              label: Text(
                                sfx.isEmpty ? 'Select Sound Effect...' : 'Sound: $sfx',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              onPressed: () {
                                widget.onSoundLibraryTap(
                                  context,
                                  sfx,
                                  sfxVolume,
                                  (sfxSelected, vol) {
                                    setState(() {
                                      selectedSfx = sfxSelected;
                                      sfxVolume = vol;
                                    });
                                  },
                                  sfx.isEmpty ? null : () {
                                    setState(() {
                                      selectedSfx = '';
                                      sfxVolume = 100;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (sfx.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Volume: ${sfxVolume.toInt()}%', style: Theme.of(context).textTheme.bodyMedium),
                                  SliderTheme(
                                    data: AppTheme.premiumSliderTheme(context).copyWith(
                                      activeTrackColor: AppTheme.accentCyan,
                                      thumbColor: AppTheme.accentCyan,
                                      overlayColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                                    ),
                                    child: Slider(
                                      value: sfxVolume,
                                      min: 10,
                                      max: 100,
                                      divisions: 9,
                                      onChanged: (val) {
                                        setState(() {
                                          sfxVolume = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                playingSfxId == sfx
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 16,
                                color: AppTheme.accentCyan,
                              ),
                              onPressed: () async {
                                if (playingSfxId == sfx) {
                                  await AudioService.instance.stopAll();
                                  setState(() {
                                    playingSfxId = null;
                                  });
                                } else {
                                  setState(() {
                                    playingSfxId = sfx;
                                  });
                                  await AudioService.instance.playSfx(sfx, sfxVolume / 100.0);
                                  setState(() {
                                    playingSfxId = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  final wordId = widget.word.wordId;
                  if (wordId != null) {
                    ref.read(editorProvider.notifier).deleteWords([wordId]);
                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Deleted word via settings dialog');
                  }
                  Navigator.pop(context);
                },
                child: const Text('DELETE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final newText = textController.text.trim();
                  final start = double.tryParse(startController.text) ?? widget.word.start;
                  final end = double.tryParse(endController.text) ?? widget.word.end;

                  final wordId = widget.word.wordId;
                  if (wordId != null) {
                    final String finalSfx;
                    final int finalVolume = sfxVolume.toInt();

                    final newSfxData = SfxData(
                      chunk: widget.isFirstWord ? sfxData.chunk : null,
                      word: (selectedSfx == null || selectedSfx!.isEmpty)
                          ? null
                          : SfxItem(selectedSfx!, sfxVolume.toInt()),
                    );
                    finalSfx = newSfxData.toRaw();

                    ref.read(editorProvider.notifier).updateWord(
                      wordId,
                      text: newText.isNotEmpty ? newText : widget.word.text,
                      start: start,
                      end: end,
                      soundEffect: finalSfx,
                      soundVolume: finalVolume,
                      className: highlightClass,
                    );
                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Updated word settings: "${newText.isNotEmpty ? newText : widget.word.text}"');
                  }
                  Navigator.pop(context);
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
