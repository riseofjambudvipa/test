import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../controllers/editor_controller.dart';
import '../../../../../../l10n/app_localizations.dart';
import 'color_picker_row.dart';

class BorderSettingsSection extends ConsumerWidget {
  final ProjectConfigSchema config;
  const BorderSettingsSection({super.key, required this.config});

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.secondaryText,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OUTLINES & EFFECTS'),
        const SizedBox(height: 12),

        // Stroke Outline Selector
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Outline Stroke',
            border: AppTheme.defaultBorder(),
            focusedBorder: AppTheme.focusedBorder(),
          ),
          initialValue: const ['thick', 'thin', 'none'].contains(config.stroke)
              ? config.stroke
              : 'none',
          items: [
            DropdownMenuItem(value: 'thick', child: Text(l10n?.strokeStyleThickOutline ?? 'Thick Outline')),
            const DropdownMenuItem(value: 'thin', child: Text('Thin Outline')),
            DropdownMenuItem(value: 'none', child: Text(l10n?.strokeStyleNoneFlat ?? 'None (Flat)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('stroke', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Text Animation Selector
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Active Word Animation',
            border: AppTheme.defaultBorder(),
            focusedBorder: AppTheme.focusedBorder(),
          ),
          initialValue: const ['pop', 'bounce', 'kineticTilt', 'glowPulse', 'wordReveal', 'none'].contains(config.animation)
              ? config.animation
              : 'none',
          items: [
            DropdownMenuItem(value: 'pop', child: Text(l10n?.animStyleActivePop ?? 'Active Pop')),
            DropdownMenuItem(value: 'bounce', child: Text(l10n?.animStyleActiveBounce ?? 'Active Bounce Jump')),
            DropdownMenuItem(value: 'kineticTilt', child: Text(l10n?.animStyleKineticTilt ?? 'Kinetic Bouncy Tilt')),
            DropdownMenuItem(value: 'glowPulse', child: Text(l10n?.animStyleGlowPulse ?? 'Glowing Active Pulse')),
            DropdownMenuItem(value: 'wordReveal', child: Text(l10n?.animStyleWordReveal ?? 'Word Reveal Stagger')),
            DropdownMenuItem(value: 'none', child: Text(l10n?.animStyleNoneStatic ?? 'None (Static)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('animation', val);
            }
          },
        ),
        if (config.animation != 'none' || config.stroke != 'none' || config.shadow != 'none')
          _LiveAnimationPreviewCard(
            animationMode: config.animation,
            stroke: config.stroke,
            shadow: config.shadow,
          ),
        const SizedBox(height: 12),

        // Shadow Toggle
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Drop Shadow',
            border: AppTheme.defaultBorder(),
            focusedBorder: AppTheme.focusedBorder(),
          ),
          initialValue: const ['3d', 'hard', 'soft', 'none'].contains(config.shadow)
              ? config.shadow
              : 'none',
          items: [
            const DropdownMenuItem(value: '3d', child: Text('3D Extruded')),
            const DropdownMenuItem(value: 'hard', child: Text('Hard Shadow')),
            DropdownMenuItem(value: 'soft', child: Text(l10n?.shadowStyleSoft ?? 'Soft Shadow')),
            DropdownMenuItem(value: 'none', child: Text(l10n?.shadowStyleNone ?? 'None')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('shadow', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Background Fill Color
        ColorPickerRow(
          label: 'Background Fill (Optional)',
          currentHex: config.background ?? '#000000',
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateStyleProp('background', hex);
          },
        ),
        if (config.background != null)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: Icon(Icons.clear_rounded, size: 14, color: AppTheme.accentRed),
              label: Text('REMOVE BACKGROUND FILL', style: TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(editorProvider.notifier).updateStyleProp('background', null);
              },
            ),
          ),
      ],
    );
  }
}

class _LiveAnimationPreviewCard extends StatefulWidget {
  final String animationMode;
  final String stroke;
  final String shadow;

  const _LiveAnimationPreviewCard({
    required this.animationMode,
    required this.stroke,
    required this.shadow,
  });

  @override
  State<_LiveAnimationPreviewCard> createState() => _LiveAnimationPreviewCardState();
}

class _LiveAnimationPreviewCardState extends State<_LiveAnimationPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _activeWordIndex = 1;
  Timer? _stepTimer;

  static const _sampleWords = ['MAKE', 'VIDEOS', 'VIRAL'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (mounted) {
        setState(() {
          _activeWordIndex = (_activeWordIndex + 1) % _sampleWords.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: 8,
        borderOpacity: 0.12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.accentOrange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.animationMode.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_sampleWords.length, (idx) {
                final isActive = idx == _activeWordIndex;
                final text = _sampleWords[idx];

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = 1.0;
                    double tilt = 0.0;
                    Offset translate = Offset.zero;
                    final List<Shadow> shadows = [];

                    // Shadow calculation
                    if (widget.shadow == '3d' || widget.shadow == 'extruded') {
                      for (double step = 1.0; step <= 4.0; step += 1.0) {
                        shadows.add(
                          Shadow(
                            color: Colors.black.withValues(alpha: (0.8 - (step * 0.12)).clamp(0.2, 1.0)),
                            blurRadius: 0,
                            offset: Offset(step * 1.5, step * 1.5),
                          ),
                        );
                      }
                    } else if (widget.shadow == 'hard') {
                      shadows.add(
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 0,
                          offset: const Offset(3.0, 3.0),
                        ),
                      );
                    } else if (widget.shadow == 'soft') {
                      shadows.add(
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 3.0,
                          offset: const Offset(2.0, 2.0),
                        ),
                      );
                    }

                    if (isActive && widget.animationMode != 'none') {
                      final val = _controller.value;
                      switch (widget.animationMode) {
                        case 'pop':
                          scale = 1.0 + (0.28 * (1.0 - (val - 0.5).abs() * 2));
                          break;
                        case 'bounce':
                          final bounceY = -8.0 * (1.0 - (val - 0.5).abs() * 2);
                          translate = Offset(0, bounceY);
                          scale = 1.12;
                          break;
                        case 'kineticTilt':
                          tilt = (idx % 2 == 0 ? -0.1 : 0.1) * (1.0 - val * 0.3);
                          scale = 1.15;
                          break;
                        case 'glowPulse':
                          shadows.add(
                            Shadow(
                              color: AppTheme.accentOrange.withValues(alpha: 0.8),
                              blurRadius: 12.0 * val,
                            ),
                          );
                          scale = 1.1;
                          break;
                        case 'wordReveal':
                          scale = 0.8 + (0.3 * val);
                          translate = Offset(0, 4.0 * (1.0 - val));
                          break;
                      }
                    }

                    final strokeW = widget.stroke == 'thick' ? 3.0 : (widget.stroke == 'thin' ? 1.5 : 0.0);
                    Widget wordContent = Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isActive ? AppTheme.accentOrange : AppTheme.primaryText,
                        shadows: shadows,
                      ),
                    );

                    if (strokeW > 0) {
                      wordContent = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = strokeW
                                ..strokeCap = StrokeCap.round
                                ..strokeJoin = StrokeJoin.round
                                ..color = Colors.black,
                            ),
                          ),
                          wordContent,
                        ],
                      );
                    }

                    return Transform.translate(
                      offset: translate,
                      child: Transform.rotate(
                        angle: tilt,
                        child: Transform.scale(
                          scale: scale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: wordContent,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
