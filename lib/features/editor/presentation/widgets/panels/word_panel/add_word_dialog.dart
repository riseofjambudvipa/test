import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/color_utils.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';
import 'emoji_picker_dialog.dart';
import '../../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
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
                (l10n?.editTiming ?? 'Edit Timing').toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 16),
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
                child: Text(l10n?.btnCancel ?? 'CANCEL'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
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
                      SnackBar(
                        content: Text(
                          l10n?.invalidTimingError ??
                              'Invalid start/end timings. Start must be >= 0, and end must be >= start and <= video duration.',
                        ),
                        backgroundColor: AppTheme.accentRed,
                      ),
                    );
                  }
                },
                child: Text(l10n?.btnSave ?? 'SAVE'),
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
  String? selectedEmoji;
  double emojiX = 0.0;
  double emojiY = 0.0;
  double emojiScale = 1.0;
  double emojiSpeed = 1.0;

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

    selectedEmoji = widget.word.emoji;
    emojiX = widget.word.emojiConfig?.x ?? 0.0;
    emojiY = widget.word.emojiConfig?.y ?? 0.0;
    emojiScale = widget.word.emojiConfig?.scale ?? 1.0;
    emojiSpeed = widget.word.emojiConfig?.speed ?? 1.0;
  }

  @override
  void dispose() {
    textController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hs = widget.project.config.highlightStyle;
    final style = widget.project.config.style;

    final baseColor = ColorUtils.fromHex(style.color, fallback: AppTheme.primaryText);
    final highlight1Color = ColorUtils.fromHex(hs.mainColor, fallback: AppTheme.accentOrange);
    final highlight2Color = ColorUtils.fromHex(hs.secondColor, fallback: AppTheme.accentCyan);
    final highlight3Color = ColorUtils.fromHex(hs.thirdColor, fallback: AppTheme.accentGreen);

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
                    : AppTheme.borderGlass,
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
                      color: AppTheme.borderGlass,
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
                      color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
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
                  (l10n?.wordSettingsTitle ?? 'Word Settings').toUpperCase(),
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
                    icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 16),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.remove, size: 14, color: AppTheme.secondaryText),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(startController.text) ?? 0.0) + 0.05;
                                    startController.text = val.toStringAsFixed(3);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.add, size: 14, color: AppTheme.secondaryText),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.remove, size: 14, color: AppTheme.secondaryText),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final val = (double.tryParse(endController.text) ?? 0.0) + 0.05;
                                    endController.text = val.toStringAsFixed(3);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Icon(Icons.add, size: 14, color: AppTheme.secondaryText),
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
                  Text(
                    'EMOJI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg.withValues(alpha: 0.25),
                      borderRadius: 8,
                      borderOpacity: 0.08,
                    ),
                    child: Row(
                      children: [
                        if (selectedEmoji != null && selectedEmoji!.isNotEmpty && selectedEmoji != 'none') ...[
                          Builder(
                            builder: (context) {
                              final parsed = EmojiPackParser.parse(selectedEmoji!, '');
                              final isSticker = !kIsWeb &&
                                  (File(parsed.glyph).existsSync() ||
                                      parsed.glyph.startsWith('/') ||
                                      RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(parsed.glyph));
                              if (isSticker) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(parsed.glyph),
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_outlined,
                                      size: 20,
                                    ),
                                  ),
                                );
                              }
                              return Text(
                                parsed.glyph,
                                style: const TextStyle(fontSize: 22, fontFamily: 'Noto Color Emoji'),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final parsed = EmojiPackParser.parse(selectedEmoji!, '');
                                final isSticker = !kIsWeb &&
                                    (File(parsed.glyph).existsSync() ||
                                        parsed.glyph.startsWith('/') ||
                                        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(parsed.glyph));
                                final label = isSticker
                                    ? p.basenameWithoutExtension(parsed.glyph)
                                    : selectedEmoji!;
                                return Text(
                                  label,
                                  style: TextStyle(fontSize: 11, color: AppTheme.primaryText),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear, size: 16, color: AppTheme.accentRed),
                            tooltip: 'Remove Emoji',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                selectedEmoji = 'none';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          Expanded(
                            child: Text(
                              'No emoji attached',
                              style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentOrange,
                            side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.add_reaction_outlined, size: 14),
                          label: Text(
                            (selectedEmoji != null && selectedEmoji!.isNotEmpty && selectedEmoji != 'none')
                                ? 'Change'
                                : 'Choose',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => EmojiPickerDialog(
                                project: widget.project,
                                chunk: Chunk(index: 0, startTime: 0, endTime: 0, words: [widget.word]),
                                targetWord: widget.word,
                                onEmojiSelected: (pack, glyph) {
                                  final isSticker = !kIsWeb &&
                                      (glyph.endsWith('.png') ||
                                          glyph.endsWith('.webp') ||
                                          glyph.endsWith('.jpg') ||
                                          glyph.endsWith('.jpeg') ||
                                          glyph.endsWith('.gif') ||
                                          glyph.startsWith('/') ||
                                          RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(glyph) ||
                                          EmojiService.resolveStickerPath(glyph) != null);
                                  setState(() {
                                    selectedEmoji = isSticker ? 'custom:$glyph' : '$pack:$glyph';
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
                                  // FIX (audit): an unhandled play failure left
                                  // playingSfxId stuck so the button stayed in
                                  // "pause" state forever. Always reset it.
                                  try {
                                    await AudioService.instance.playSfx(sfx, sfxVolume / 100.0);
                                  } catch (e) {
                                    LoggerService.instance.log(LogLevel.error, 'AddWordDialog', 'Failed to play sound effect: $e');
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        playingSfxId = null;
                                      });
                                    }
                                  }
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
                  foregroundColor: AppTheme.accentRed,
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
                child: Text(l10n?.btnDelete ?? 'DELETE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.content_cut_rounded, size: 14),
                label: const Text('CUT FOOTAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final wordId = widget.word.wordId;
                  final start = widget.word.start;
                  final end = widget.word.end;
                  if (start != null && end != null && start < end) {
                    ref.read(editorProvider.notifier).cutVideoSegmentForTimeRange(start, end, hideWords: true);
                    if (wordId != null) {
                      ref.read(editorProvider.notifier).deleteWords([wordId]);
                    }
                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Cut word & video footage between ${start.toStringAsFixed(2)}s and ${end.toStringAsFixed(2)}s');
                  }
                  Navigator.pop(context);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange, 
                  foregroundColor: AppTheme.onAccentText,
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
                      emoji: selectedEmoji,
                      emojiX: emojiX,
                      emojiY: emojiY,
                      emojiScale: emojiScale,
                      emojiSpeed: emojiSpeed,
                    );
                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Updated word settings: "${newText.isNotEmpty ? newText : widget.word.text}"');
                  }
                  Navigator.pop(context);
                },
                child: Text(l10n?.btnSave ?? 'SAVE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
