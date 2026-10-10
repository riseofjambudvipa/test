import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../../../app/theme.dart';
import '../../../../../../core/video/background_music_models.dart';
import '../../../../../../core/audio/audio_mastering_models.dart';

export '../../../../../../core/audio/audio_mastering_models.dart'
    show AudioMasteringConfig, AudioMasteringPlatform;

/// Audio enhancement and vocal mastering controls for export:
/// - AI Studio Sound (highpass, lowpass, spectral de-noise, vocal compression, broadcast/shorts loudness mastering)
/// - Intelligent Vocal De-Esser (sibilance reduction for harsh "s" frequencies)
/// - Anti-Click Audio Crossfading (50ms transition between jump-cuts)
/// - Background Music Track with Smart Voice Ducking (-12dB ducking when speech is detected)
class AudioEnhancementCard extends StatelessWidget {
  final bool enableStudioSound;
  final ValueChanged<bool> onStudioSoundChanged;
  final AudioMasteringConfig? audioMastering;
  final ValueChanged<AudioMasteringConfig>? onAudioMasteringChanged;
  final bool enableAudioCrossfade;
  final ValueChanged<bool> onAudioCrossfadeChanged;
  final BackgroundMusicConfig? backgroundMusic;
  final ValueChanged<BackgroundMusicConfig>? onBackgroundMusicChanged;

  const AudioEnhancementCard({
    super.key,
    required this.enableStudioSound,
    required this.onStudioSoundChanged,
    this.audioMastering,
    this.onAudioMasteringChanged,
    required this.enableAudioCrossfade,
    required this.onAudioCrossfadeChanged,
    this.backgroundMusic,
    this.onBackgroundMusicChanged,
  });

  Future<void> _pickAudioTrack(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        dialogTitle: 'Select Background Music Track',
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null && path.isNotEmpty) {
          final current = backgroundMusic ?? const BackgroundMusicConfig();
          onBackgroundMusicChanged?.call(current.copyWith(musicPath: path));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgm = backgroundMusic ?? const BackgroundMusicConfig();
    final mastering = audioMastering ?? const AudioMasteringConfig();
    final hasMusic = bgm.hasMusic;

    return Column(
      children: [
        // AI Studio Sound & Voice Polish Toggle Card
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: 10,
          borderOpacity: enableStudioSound ? 0.35 : 0.1,
          glowColor: enableStudioSound ? AppTheme.accentOrange : null,
          glowOpacity: enableStudioSound ? 0.25 : 0.0,
          color: enableStudioSound
              ? AppTheme.accentOrange.withValues(alpha: 0.08)
              : AppTheme.cardBg.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppTheme.glassDecoration(
                      color: (enableStudioSound ? AppTheme.accentOrange : AppTheme.mutedText)
                          .withValues(alpha: 0.15),
                      borderRadius: 8,
                      borderOpacity: 0.2,
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: enableStudioSound ? AppTheme.accentOrange : AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Studio Sound',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: enableStudioSound ? AppTheme.accentOrange : AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRO AUDIO',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentOrange,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'De-noise, spectral repair, vocal leveling, platform loudness & de-essing',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondaryText,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: enableStudioSound,
                    activeThumbColor: AppTheme.accentOrange,
                    activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.35),
                    inactiveThumbColor: AppTheme.mutedText,
                    inactiveTrackColor: AppTheme.dividerColor,
                    onChanged: (val) {
                      onStudioSoundChanged(val);
                      onAudioMasteringChanged?.call(mastering.copyWith(enableStudioSound: val));
                    },
                  ),
                ],
              ),
              if (enableStudioSound) ...[
                const SizedBox(height: 12),
                Divider(color: AppTheme.accentOrange.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 10),
                // Platform Loudness Mastering Selector
                Row(
                  children: [
                    Text(
                      'Loudness Standard',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${mastering.platform.targetLufs.round()} LUFS',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  mastering.platform.description,
                  style: TextStyle(fontSize: 9, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AudioMasteringPlatform.values.map((plat) {
                    final isSelected = mastering.platform == plat;
                    final shortLabel = switch (plat) {
                      AudioMasteringPlatform.socialShorts => 'Shorts / TikTok (-14 LUFS)',
                      AudioMasteringPlatform.broadcastPodcast => 'Broadcast (-16 LUFS)',
                      AudioMasteringPlatform.cinemaHeadroom => 'Cinema (-23 LUFS)',
                    };
                    return InkWell(
                      onTap: () {
                        onAudioMasteringChanged?.call(mastering.copyWith(platform: plat));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentOrange.withValues(alpha: 0.22)
                              : AppTheme.cardBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentOrange.withValues(alpha: 0.6)
                                : AppTheme.dividerColor,
                          ),
                        ),
                        child: Text(
                          shortLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Vocal De-Esser Toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Vocal De-Esser',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'SIBILANCE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tames harsh high-frequency "s" and "sh" sibilance without dulling voice',
                            style: TextStyle(fontSize: 9, color: AppTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: mastering.enableDeEsser,
                      activeThumbColor: AppTheme.accentOrange,
                      activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.35),
                      inactiveThumbColor: AppTheme.mutedText,
                      inactiveTrackColor: AppTheme.dividerColor,
                      onChanged: (val) {
                        onAudioMasteringChanged?.call(mastering.copyWith(enableDeEsser: val));
                      },
                    ),
                  ],
                ),
                if (mastering.enableDeEsser) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'De-Esser Intensity',
                        style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                      ),
                      Text(
                        '${(mastering.deEsserIntensity * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: AppTheme.premiumSliderTheme(context).copyWith(
                      activeTrackColor: AppTheme.accentOrange,
                      thumbColor: AppTheme.accentOrange,
                    ),
                    child: Slider(
                      value: mastering.deEsserIntensity,
                      min: 0.10,
                      max: 1.0,
                      divisions: 18,
                      onChanged: (val) {
                        onAudioMasteringChanged?.call(mastering.copyWith(deEsserIntensity: val));
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Jump-Cut Audio Smoothing Toggle Card
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: 10,
          borderOpacity: enableAudioCrossfade ? 0.35 : 0.1,
          glowColor: enableAudioCrossfade ? AppTheme.accentCyan : null,
          glowOpacity: enableAudioCrossfade ? 0.25 : 0.0,
          color: enableAudioCrossfade
              ? AppTheme.accentCyan.withValues(alpha: 0.08)
              : AppTheme.cardBg.withValues(alpha: 0.5),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppTheme.glassDecoration(
                  color: (enableAudioCrossfade ? AppTheme.accentCyan : AppTheme.mutedText)
                      .withValues(alpha: 0.15),
                  borderRadius: 8,
                  borderOpacity: 0.2,
                ),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  color: enableAudioCrossfade ? AppTheme.accentCyan : AppTheme.mutedText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Smooth Cut Transitions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: enableAudioCrossfade ? AppTheme.accentCyan : AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ANTI-CLICK',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Applies 50ms audio crossfades between jump-cuts to eliminate audio pops and clicks',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: enableAudioCrossfade,
                activeThumbColor: AppTheme.accentCyan,
                activeTrackColor: AppTheme.accentCyan.withValues(alpha: 0.35),
                inactiveThumbColor: AppTheme.mutedText,
                inactiveTrackColor: AppTheme.dividerColor,
                onChanged: onAudioCrossfadeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Background Music Track & Smart Voice Ducking Card
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: 10,
          borderOpacity: hasMusic ? 0.35 : 0.1,
          glowColor: hasMusic ? AppTheme.accentGreen : null,
          glowOpacity: hasMusic ? 0.25 : 0.0,
          color: hasMusic
              ? AppTheme.accentGreen.withValues(alpha: 0.08)
              : AppTheme.cardBg.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppTheme.glassDecoration(
                      color: (hasMusic ? AppTheme.accentGreen : AppTheme.mutedText)
                          .withValues(alpha: 0.15),
                      borderRadius: 8,
                      borderOpacity: 0.2,
                    ),
                    child: Icon(
                      Icons.library_music_rounded,
                      color: hasMusic ? AppTheme.accentGreen : AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Background Music',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: hasMusic ? AppTheme.accentGreen : AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BGM DUCKING',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Layer background music bed with automatic -12dB voice ducking',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondaryText,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!hasMusic) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.audio_file_rounded, size: 16, color: AppTheme.accentGreen),
                    label: Text(
                      'ADD BACKGROUND MUSIC TRACK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pickAudioTrack(context),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note_rounded, size: 16, color: AppTheme.accentGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.basename(bgm.musicPath!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          onBackgroundMusicChanged?.call(bgm.copyWith(musicPath: ''));
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, size: 16, color: AppTheme.accentRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Music Volume Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Music Volume',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                    Text(
                      '${(bgm.volume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: AppTheme.premiumSliderTheme(context).copyWith(
                    activeTrackColor: AppTheme.accentGreen,
                    thumbColor: AppTheme.accentGreen,
                  ),
                  child: Slider(
                    value: bgm.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (val) {
                      onBackgroundMusicChanged?.call(bgm.copyWith(volume: val));
                    },
                  ),
                ),
                // Smart Voice Ducking Toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Smart Voice Ducking',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '-12 dB',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Smoothly attenuates music by -12dB when speech is detected',
                            style: TextStyle(fontSize: 9, color: AppTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: bgm.enableDucking,
                      activeThumbColor: AppTheme.accentGreen,
                      activeTrackColor: AppTheme.accentGreen.withValues(alpha: 0.35),
                      inactiveThumbColor: AppTheme.mutedText,
                      inactiveTrackColor: AppTheme.dividerColor,
                      onChanged: (val) {
                        onBackgroundMusicChanged?.call(bgm.copyWith(enableDucking: val));
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
