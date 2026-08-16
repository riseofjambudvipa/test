import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';

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

class _SfxPickerDialogState extends State<SfxPickerDialog> {
  late String selectedSfx;
  late double sfxVolume;
  String activeCategory = 'Transitions';
  String? playingSfxId;

  final List<Map<String, dynamic>> sfxCategories = [
    {
      'label': 'Transitions',
      'sounds': [
        {'id': 'whoosh_fast',  'name': 'Fast Whoosh',  'icon': '💨', 'desc': 'Fast sweep transition'},
        {'id': 'whoosh_slow',  'name': 'Slow Whoosh',  'icon': '🌬️', 'desc': 'Slow sweep transition'},
        {'id': 'swipe_left',   'name': 'Swipe Left',   'icon': '👈', 'desc': 'Left sliding whoosh'},
        {'id': 'swipe_right',  'name': 'Swipe Right',  'icon': '👉', 'desc': 'Right sliding whoosh'},
        {'id': 'sweep_up',     'name': 'Sweep Up',     'icon': '⬆️', 'desc': 'Ascending pitch sweep'},
        {'id': 'sweep_down',   'name': 'Sweep Down',   'icon': '⬇️', 'desc': 'Descending pitch sweep'},
      ],
    },
    {
      'label': 'Impacts',
      'sounds': [
        {'id': 'pop',       'name': 'Pop',      'icon': '💥', 'desc': 'Bubble pop sound'},
        {'id': 'pop_deep',  'name': 'Deep Pop', 'icon': '🎈', 'desc': 'Low bubble pop'},
        {'id': 'boom',      'name': 'Boom',     'icon': '💣', 'desc': 'Explosion bass impact'},
        {'id': 'thud',      'name': 'Thud',     'icon': '🪨', 'desc': 'Heavy thud hit'},
        {'id': 'punch',     'name': 'Punch',    'icon': '👊', 'desc': 'Comic punch impact'},
        {'id': 'stamp',     'name': 'Stamp',    'icon': '📢', 'desc': 'Heavy stamp sound'},
      ],
    },
    {
      'label': 'Notifications',
      'sounds': [
        {'id': 'bell',   'name': 'Bell',       'icon': '🔔', 'desc': 'High frequency bell ding'},
        {'id': 'chime',  'name': 'Chime',      'icon': '🎵', 'desc': 'Soft magic sweep chime'},
        {'id': 'blip',   'name': 'Blip',       'icon': '📡', 'desc': 'Short retro synth blip'},
        {'id': 'ding',   'name': 'Ding',       'icon': '✨', 'desc': 'High frequency ding'},
        {'id': 'ping',   'name': 'Ping',       'icon': '🏓', 'desc': 'Table tennis ping'},
        {'id': 'drop',   'name': 'Water Drop', 'icon': '💧', 'desc': 'Water drop sound'},
      ],
    },
    {
      'label': 'Playful',
      'sounds': [
        {'id': 'boing',    'name': 'Boing',    'icon': '🎪', 'desc': 'Comical cartoon boing'},
        {'id': 'bounce',   'name': 'Bounce',   'icon': '⚽', 'desc': 'Series of bouncing hits'},
        {'id': 'squeak',   'name': 'Squeak',   'icon': '🐭', 'desc': 'Mouse squeak sound'},
        {'id': 'coin',     'name': 'Coin',     'icon': '🪙', 'desc': 'Retro game coin collect'},
        {'id': 'sparkle',  'name': 'Sparkle',  'icon': '⭐', 'desc': 'Shimmering sparkle sound'},
        {'id': 'glitch',   'name': 'Glitch',   'icon': '📺', 'desc': 'Digital glitch noise'},
      ],
    },
    {
      'label': 'Cinematic',
      'sounds': [
        {'id': 'rise',       'name': 'Rise',       'icon': '🚀', 'desc': 'Tension building riser'},
        {'id': 'tension',    'name': 'Tension',    'icon': '😰', 'desc': 'Suspenseful horror beat'},
        {'id': 'drop_bass',  'name': 'Bass Drop',  'icon': '🔊', 'desc': 'Sub-bass drop slam'},
        {'id': 'reverse',    'name': 'Reverse',    'icon': '⏪', 'desc': 'Swell whoosh reverse'},
        {'id': 'echo',       'name': 'Echo',       'icon': '🌀', 'desc': 'Gentle sweep echo'},
        {'id': 'tape_stop',  'name': 'Tape Stop',  'icon': '📼', 'desc': 'Decaying tape stop'},
      ],
    },
    {
      'label': 'Viral',
      'sounds': [
        {'id': 'level_up',   'name': 'Level Up',   'icon': '🎮', 'desc': 'Video game level up'},
        {'id': 'fail',       'name': 'Fail',       'icon': '😭', 'desc': 'Sad trombone fail'},
        {'id': 'correct',    'name': 'Correct',    'icon': '✅', 'desc': 'Double success ding'},
        {'id': 'wrong',      'name': 'Wrong',      'icon': '❌', 'desc': 'Wrong buzzer sound'},
        {'id': 'power_up',   'name': 'Power Up',   'icon': '⚡', 'desc': 'Sci-fi power up sound'},
        {'id': 'game_over',  'name': 'Game Over',  'icon': '💀', 'desc': 'Game over sad tune'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedSfx = widget.initialSfx;
    sfxVolume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    final activeSounds = (sfxCategories.firstWhere((cat) => cat['label'] == activeCategory)['sounds'] as List)
        .map((s) => Map<String, String>.from(s as Map))
        .toList();

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
                icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
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
                  const Divider(height: 16, color: Colors.white12),
                  
                  // Category Chips Bar
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: sfxCategories.map((cat) {
                      final label = cat['label'] as String;
                      final isSelected = activeCategory == label;
                      return ChoiceChip(
                        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
                        selected: isSelected,
                        selectedColor: AppTheme.accentCyan,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
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
                        final soundId = s['id']!;
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
                                child: Center(child: Text(s['icon']!, style: const TextStyle(fontSize: 16))),
                              ),
                              title: Text(s['name']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryText)),
                              subtitle: Text(s['desc']!, style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
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
                                        setState(() {
                                          playingSfxId = soundId;
                                        });
                                        await AudioService.instance.playSfx(soundId, sfxVolume / 100.0);
                                        if (playingSfxId == soundId) {
                                          setState(() {
                                            playingSfxId = null;
                                          });
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
                  child: const Text('REMOVE SOUND', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (widget.onRemove != null) const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  widget.onSelect(selectedSfx, sfxVolume);
                  Navigator.pop(context);
                },
                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
