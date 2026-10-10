import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../l10n/app_localizations.dart';

class SfxPickerDialog extends StatefulWidget {
  final String initialSfx;
  final double initialVolume;
  final void Function(String sfxId, double volume) onSelect;
  final VoidCallback? onRemove;

  const SfxPickerDialog({
    super.key,
    required this.initialSfx,
    required this.initialVolume,
    required this.onSelect,
    this.onRemove,
  });

  @override
  State<SfxPickerDialog> createState() => _SfxPickerDialogState();
}

class SfxSoundItem {
  final String id;
  final String name;
  final String icon;
  final String desc;

  const SfxSoundItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
  });
}

class SfxCategoryItem {
  final String label;
  final List<SfxSoundItem> sounds;

  const SfxCategoryItem({
    required this.label,
    required this.sounds,
  });
}

class _SfxPickerDialogState extends State<SfxPickerDialog> {
  late String selectedSfx;
  late double sfxVolume;
  String activeCategory = 'Transitions';
  String? playingSfxId;

  static const List<SfxCategoryItem> sfxCategories = [
    SfxCategoryItem(
      label: 'Transitions',
      sounds: [
        SfxSoundItem(id: 'whoosh_fast', name: 'Fast Whoosh', icon: '💨', desc: 'Fast sweep transition'),
        SfxSoundItem(id: 'whoosh_slow', name: 'Slow Whoosh', icon: '🌬️', desc: 'Slow sweep transition'),
        SfxSoundItem(id: 'swipe_left', name: 'Swipe Left', icon: '👈', desc: 'Left sliding whoosh'),
        SfxSoundItem(id: 'swipe_right', name: 'Swipe Right', icon: '👉', desc: 'Right sliding whoosh'),
        SfxSoundItem(id: 'sweep_up', name: 'Sweep Up', icon: '⬆️', desc: 'Ascending pitch sweep'),
        SfxSoundItem(id: 'sweep_down', name: 'Sweep Down', icon: '⬇️', desc: 'Descending pitch sweep'),
      ],
    ),
    SfxCategoryItem(
      label: 'Impacts',
      sounds: [
        SfxSoundItem(id: 'pop', name: 'Pop', icon: '💥', desc: 'Bubble pop sound'),
        SfxSoundItem(id: 'pop_deep', name: 'Deep Pop', icon: '🎈', desc: 'Low bubble pop'),
        SfxSoundItem(id: 'boom', name: 'Boom', icon: '💣', desc: 'Explosion bass impact'),
        SfxSoundItem(id: 'thud', name: 'Thud', icon: '🪨', desc: 'Heavy thud hit'),
        SfxSoundItem(id: 'punch', name: 'Punch', icon: '👊', desc: 'Comic punch impact'),
        SfxSoundItem(id: 'stamp', name: 'Stamp', icon: '📢', desc: 'Heavy stamp sound'),
      ],
    ),
    SfxCategoryItem(
      label: 'Notifications',
      sounds: [
        SfxSoundItem(id: 'bell', name: 'Bell', icon: '🔔', desc: 'High frequency bell ding'),
        SfxSoundItem(id: 'chime', name: 'Chime', icon: '🎵', desc: 'Soft magic sweep chime'),
        SfxSoundItem(id: 'blip', name: 'Blip', icon: '📡', desc: 'Short retro synth blip'),
        SfxSoundItem(id: 'ding', name: 'Ding', icon: '✨', desc: 'High frequency ding'),
        SfxSoundItem(id: 'ping', name: 'Ping', icon: '🏓', desc: 'Table tennis ping'),
        SfxSoundItem(id: 'drop', name: 'Water Drop', icon: '💧', desc: 'Water drop sound'),
      ],
    ),
    SfxCategoryItem(
      label: 'Playful',
      sounds: [
        SfxSoundItem(id: 'boing', name: 'Boing', icon: '🎪', desc: 'Comical cartoon boing'),
        SfxSoundItem(id: 'bounce', name: 'Bounce', icon: '⚽', desc: 'Series of bouncing hits'),
        SfxSoundItem(id: 'squeak', name: 'Squeak', icon: '🐭', desc: 'Mouse squeak sound'),
        SfxSoundItem(id: 'coin', name: 'Coin', icon: '🪙', desc: 'Retro game coin collect'),
        SfxSoundItem(id: 'sparkle', name: 'Sparkle', icon: '⭐', desc: 'Shimmering sparkle sound'),
        SfxSoundItem(id: 'glitch', name: 'Glitch', icon: '📺', desc: 'Digital glitch noise'),
      ],
    ),
    SfxCategoryItem(
      label: 'Cinematic',
      sounds: [
        SfxSoundItem(id: 'rise', name: 'Rise', icon: '🚀', desc: 'Tension building riser'),
        SfxSoundItem(id: 'tension', name: 'Tension', icon: '😰', desc: 'Suspenseful horror beat'),
        SfxSoundItem(id: 'drop_bass', name: 'Bass Drop', icon: '🔊', desc: 'Sub-bass drop slam'),
        SfxSoundItem(id: 'reverse', name: 'Reverse', icon: '⏪', desc: 'Swell whoosh reverse'),
        SfxSoundItem(id: 'echo', name: 'Echo', icon: '🌀', desc: 'Gentle sweep echo'),
        SfxSoundItem(id: 'tape_stop', name: 'Tape Stop', icon: '📼', desc: 'Decaying tape stop'),
      ],
    ),
    SfxCategoryItem(
      label: 'Viral',
      sounds: [
        SfxSoundItem(id: 'level_up', name: 'Level Up', icon: '🎮', desc: 'Video game level up'),
        SfxSoundItem(id: 'fail', name: 'Fail', icon: '😭', desc: 'Sad trombone fail'),
        SfxSoundItem(id: 'correct', name: 'Correct', icon: '✅', desc: 'Double success ding'),
        SfxSoundItem(id: 'wrong', name: 'Wrong', icon: '❌', desc: 'Wrong buzzer sound'),
        SfxSoundItem(id: 'power_up', name: 'Power Up', icon: '⚡', desc: 'Sci-fi power up sound'),
        SfxSoundItem(id: 'game_over', name: 'Game Over', icon: '💀', desc: 'Game over sad tune'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedSfx = widget.initialSfx;
    sfxVolume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeSounds = sfxCategories
        .firstWhere(
          (c) => c.label == activeCategory,
          orElse: () => sfxCategories.first,
        )
        .sounds;

    return PremiumBlurDialog(
      maxWidth: 400,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOUND LIBRARY',
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
          Divider(color: AppTheme.borderGlass, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SFX VOLUME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.volume_up, size: 16, color: AppTheme.secondaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
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
                      ),
                      Text('${sfxVolume.toInt()}%', style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.secondaryText)),
                    ],
                  ),
                  Divider(height: 16, color: AppTheme.borderGlass),
                  
                  // Category Chips Bar
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: sfxCategories.map((cat) {
                      final label = cat.label;
                      final isSelected = activeCategory == label;
                      return ChoiceChip(
                        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.onAccentText : AppTheme.primaryText)),
                        selected: isSelected,
                        selectedColor: AppTheme.accentCyan,
                        backgroundColor: AppTheme.hoverBg,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              activeCategory = label;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('CHOOSE SOUND EFFECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.of(context).size.height * 0.45).clamp(180.0, 300.0),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeSounds.length,
                      itemBuilder: (context, idx) {
                        final s = activeSounds[idx];
                        final soundId = s.id;
                        final isSelected = selectedSfx == soundId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: AppTheme.glassDecoration(
                            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.08) : AppTheme.cardBg.withValues(alpha: 0.25),
                            borderRadius: 10,
                            borderOpacity: isSelected ? 0.3 : 0.06,
                            glowColor: isSelected ? AppTheme.accentCyan : null,
                            glowOpacity: isSelected ? 0.06 : 0.0,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(10),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: AppTheme.glassDecoration(
                                  color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.2) : AppTheme.cardBg.withValues(alpha: 0.4),
                                  borderRadius: 8,
                                  borderOpacity: isSelected ? 0.3 : 0.08,
                                ),
                                child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 16))),
                              ),
                              title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryText)),
                              subtitle: Text(s.desc, style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      playingSfxId == soundId
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppTheme.accentCyan,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      if (playingSfxId == soundId) {
                                        await AudioService.instance.stopAll();
                                        setState(() {
                                          playingSfxId = null;
                                        });
                                      } else {
                                        // FIX (audit): stop any currently
                                        // playing sound before starting a new
                                        // one so two sounds can't overlap.
                                        await AudioService.instance.stopAll();
                                        setState(() {
                                          playingSfxId = soundId;
                                        });
                                        // FIX (audit): an unhandled play
                                        // failure left the button stuck in
                                        // "pause" state; always reset it.
                                        try {
                                          await AudioService.instance.playSfx(soundId, sfxVolume / 100.0);
                                        } catch (e) {
                                          LoggerService.instance.log(LogLevel.error, 'SfxPickerDialog', 'Failed to play sound effect: $e');
                                        } finally {
                                          if (mounted && playingSfxId == soundId) {
                                            setState(() {
                                              playingSfxId = null;
                                            });
                                          }
                                        }
                                      }
                                    },
                                  ),
                                  // ignore: deprecated_member_use
                                  Radio<String>(
                                    value: soundId,
                                    // ignore: deprecated_member_use
                                    groupValue: selectedSfx,
                                    activeColor: AppTheme.accentCyan,
                                    // ignore: deprecated_member_use
                                    onChanged: (val) {
                                      setState(() {
                                        if (val != null) {
                                          selectedSfx = val;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  selectedSfx = soundId;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onRemove != null)
                TextButton(
                  onPressed: () {
                    widget.onRemove!();
                    Navigator.pop(context);
                  },
                  child: Text(l10n?.btnDelete != null ? '${l10n!.btnDelete} SOUND' : 'REMOVE SOUND', style: TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (widget.onRemove != null) const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: AppTheme.onAccentText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  widget.onSelect(selectedSfx, sfxVolume);
                  Navigator.pop(context);
                },
                child: Text(l10n?.btnSave ?? 'SAVE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
