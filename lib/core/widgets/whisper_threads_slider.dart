import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Layout variants for [WhisperThreadsSlider].
enum WhisperThreadsSliderLayout {
  /// Title row (value on the right), slider below.
  /// Used by the transcription panel and the import sheet.
  stacked,

  /// Title + helper text, then slider with inline value.
  /// Used by the settings screen on narrow widths.
  compact,

  /// Title + helper text on the left, slider in the middle, value on the right.
  /// Used by the settings screen on wide widths.
  wide,
}

/// Shared "Whisper CPU Threads" slider used by the settings screen, the import
/// sheet, and the transcription panel. `0` means Auto (dynamic core detection).
///
/// Previously copy-pasted in three places with slightly different layouts,
/// styling, and (in one spot) a hardcoded max of 16. This widget unifies them;
/// the max defaults to the host's logical core count.
class WhisperThreadsSlider extends StatelessWidget {
  const WhisperThreadsSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxThreads,
    this.layout = WhisperThreadsSliderLayout.stacked,
    this.usePremiumTheme = false,
    this.showDescription = false,
    this.titleStyle,
    this.descriptionStyle,
    this.valueStyle = const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
  });

  /// Current thread count. `0` means Auto.
  final int value;

  /// Called with the new thread count. `0` means Auto — the slider's minimum
  /// is 0, so dragging fully to the left reaches it (the value is never
  /// written to settings until the user releases, so 0 only persists via
  /// "reset to defaults").
  final ValueChanged<int> onChanged;

  /// Upper slider bound. Defaults to the host's logical core count.
  final int? maxThreads;

  final WhisperThreadsSliderLayout layout;

  /// Wrap the slider in [AppTheme.premiumSliderTheme].
  final bool usePremiumTheme;

  /// Show the "Dynamic auto-detection / Logical cores" helper text.
  final bool showDescription;

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? valueStyle;

  int get _maxThreads => maxThreads ?? (kIsWeb ? 16 : Platform.numberOfProcessors);

  String get _valueLabel => value == 0 ? 'Auto' : '$value';

  String get _description => value == 0
      ? 'Dynamic auto-detection (recommended)'
      : 'Logical cores for transcription: $value';

  Widget _slider(BuildContext context) {
    final slider = Slider(
      value: value.clamp(0, _maxThreads).toDouble(),
      min: 0,
      max: _maxThreads.toDouble(),
      divisions: _maxThreads,
      activeColor: AppTheme.accentOrange,
      inactiveColor: AppTheme.dividerColor,
      onChanged: (v) => onChanged(v.toInt()),
    );
    return usePremiumTheme
        ? SliderTheme(data: AppTheme.premiumSliderTheme(context), child: slider)
        : slider;
  }

  Widget _title() => Text(
        'Whisper CPU Threads',
        style: (titleStyle ??
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))
            .copyWith(color: titleStyle?.color ?? AppTheme.primaryText),
      );

  Widget _descriptionWidget() => Text(
        _description,
        style: (descriptionStyle ?? const TextStyle(fontSize: 11))
            .copyWith(color: descriptionStyle?.color ?? AppTheme.mutedText),
      );

  Widget _valueWidget() => Text(
        _valueLabel,
        style: (valueStyle ??
                const TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.bold))
            .copyWith(color: valueStyle?.color ?? AppTheme.primaryText),
      );

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case WhisperThreadsSliderLayout.stacked:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _title(),
                _valueWidget(),
              ],
            ),
            const SizedBox(height: 4),
            _slider(context),
          ],
        );
      case WhisperThreadsSliderLayout.compact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(),
            if (showDescription) ...[
              const SizedBox(height: 4),
              _descriptionWidget(),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _slider(context)),
                const SizedBox(width: 8),
                _valueWidget(),
              ],
            ),
          ],
        );
      case WhisperThreadsSliderLayout.wide:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(),
                  if (showDescription) ...[
                    const SizedBox(height: 4),
                    _descriptionWidget(),
                  ],
                ],
              ),
            ),
            Expanded(flex: 3, child: _slider(context)),
            const SizedBox(width: 8),
            _valueWidget(),
          ],
        );
    }
  }
}
