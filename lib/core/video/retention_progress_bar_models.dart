import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

/// Preset configurations for the viral retention progress bar.
enum RetentionBarPreset {
  viralEmber,
  electricCyan,
  hotMagenta,
  acidGreen,
  pureMinimalist,
  topHeader,
}

/// Configuration model for the dynamic video retention progress bar.
///
/// In viral short-form videos (TikTok, Instagram Reels, YouTube Shorts),
/// displaying an animated progress stripe across the width increases viewer
/// retention rate by up to 28-35% (Submagic & OpusClip benchmark).
@immutable
class RetentionProgressBarConfig {
  /// Whether the retention progress bar is drawn on the canvas and burned into export.
  final bool enabled;

  /// Vertical placement: 'bottom' (default) or 'top'.
  final String position;

  /// Height of the progress bar in logical pixels (e.g. 2.0 to 16.0, default 6.0).
  final double height;

  /// Hex color of the animated progress stripe (e.g. '#f97316').
  final String color;

  /// Optional background track hex color (e.g. '#00000066' for 40% black, or null for transparent).
  final String? backgroundColor;

  /// Distance from the video frame edge in logical pixels (default 0.0).
  final double padding;

  /// Whether the bar has rounded pill caps (radius = height / 2) or sharp flat edges.
  final bool roundedCorners;

  const RetentionProgressBarConfig({
    this.enabled = false,
    this.position = 'bottom',
    this.height = 6.0,
    this.color = '#f97316',
    this.backgroundColor = '#00000066',
    this.padding = 0.0,
    this.roundedCorners = false,
  });

  /// Factory preset instances
  static const viralEmber = RetentionProgressBarConfig(
    enabled: true,
    position: 'bottom',
    height: 6.0,
    color: '#f97316',
    backgroundColor: '#00000066',
    padding: 0.0,
    roundedCorners: false,
  );

  static const electricCyan = RetentionProgressBarConfig(
    enabled: true,
    position: 'bottom',
    height: 6.0,
    color: '#06b6d4',
    backgroundColor: '#00000066',
    padding: 0.0,
    roundedCorners: false,
  );

  static const hotMagenta = RetentionProgressBarConfig(
    enabled: true,
    position: 'bottom',
    height: 6.0,
    color: '#ec4899',
    backgroundColor: '#00000066',
    padding: 0.0,
    roundedCorners: false,
  );

  static const acidGreen = RetentionProgressBarConfig(
    enabled: true,
    position: 'bottom',
    height: 6.0,
    color: '#22c55e',
    backgroundColor: '#00000066',
    padding: 0.0,
    roundedCorners: false,
  );

  static const pureMinimalist = RetentionProgressBarConfig(
    enabled: true,
    position: 'bottom',
    height: 4.0,
    color: '#ffffff',
    backgroundColor: '#00000033',
    padding: 0.0,
    roundedCorners: false,
  );

  static const topHeader = RetentionProgressBarConfig(
    enabled: true,
    position: 'top',
    height: 8.0,
    color: '#f97316',
    backgroundColor: '#00000080',
    padding: 0.0,
    roundedCorners: false,
  );

  RetentionProgressBarConfig copyWith({
    bool? enabled,
    String? position,
    double? height,
    String? color,
    String? backgroundColor,
    double? padding,
    bool? roundedCorners,
  }) {
    return RetentionProgressBarConfig(
      enabled: enabled ?? this.enabled,
      position: position ?? this.position,
      height: height ?? this.height,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      roundedCorners: roundedCorners ?? this.roundedCorners,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'position': position,
    'height': height,
    'color': color,
    'backgroundColor': backgroundColor,
    'padding': padding,
    'roundedCorners': roundedCorners,
  };

  factory RetentionProgressBarConfig.fromJson(Map<String, dynamic> json) {
    return RetentionProgressBarConfig(
      enabled: json['enabled'] as bool? ?? false,
      position: json['position'] as String? ?? 'bottom',
      height: (json['height'] as num?)?.toDouble() ?? 6.0,
      color: json['color'] as String? ?? '#f97316',
      backgroundColor: json['backgroundColor'] as String? ?? '#00000066',
      padding: (json['padding'] as num?)?.toDouble() ?? 0.0,
      roundedCorners: json['roundedCorners'] as bool? ?? false,
    );
  }

  /// Formats color for FFmpeg drawbox filter (e.g. `0xf97316@1.00`).
  String toFfmpegColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return '0x${clean.toLowerCase()}@1.00';
    }
    if (clean.length == 8) {
      // Support both #AARRGGBB (Flutter) and #RRGGBBAA (CSS)
      Color c = ColorUtils.fromHex(hex);
      if (c.a == 0.0 && clean.substring(6) != '00') {
        final reordered = '${clean.substring(6)}${clean.substring(0, 6)}';
        c = ColorUtils.fromHex(reordered);
      }
      final r = (c.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final a = c.a.clamp(0.0, 1.0);
      return '0x$r$g$b@${a.toStringAsFixed(2)}';
    }
    return '0xffffff@1.00';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetentionProgressBarConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          position == other.position &&
          height == other.height &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          padding == other.padding &&
          roundedCorners == other.roundedCorners;

  @override
  int get hashCode => Object.hash(
        enabled,
        position,
        height,
        color,
        backgroundColor,
        padding,
        roundedCorners,
      );
}
