import 'package:flutter/foundation.dart';

/// Represents an attached B-roll video or image overlay placed on the timeline.
///
/// In commercial video editing (CapCut, Submagic, Descript), B-roll overlays
/// cut away from the talking head or appear as a picture-in-picture (PiP) window
/// during visual keywords, drastically improving viewer retention.
@immutable
class BRollClip {
  final String id;
  final String mediaPath;
  final double startTime;
  final double endTime;
  final String name;
  final String category;
  final bool isPictureInPicture;
  final String pipPosition; // 'top_right', 'top_left', 'bottom_right', 'bottom_left'
  final double volume; // 0.0 = muted, 1.0 = full volume
  final bool hasAudio;

  const BRollClip({
    required this.id,
    required this.mediaPath,
    required this.startTime,
    required this.endTime,
    this.name = '',
    this.category = 'General',
    this.isPictureInPicture = false,
    this.pipPosition = 'top_right',
    this.volume = 0.0,
    this.hasAudio = true,
  });

  /// Duration of the B-roll overlay in seconds
  double get duration => (endTime - startTime).clamp(0.0, double.infinity);

  /// Whether the attached media is a video file as opposed to a still image
  bool get isVideo {
    final lower = mediaPath.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi');
  }

  BRollClip copyWith({
    String? id,
    String? mediaPath,
    double? startTime,
    double? endTime,
    String? name,
    String? category,
    bool? isPictureInPicture,
    String? pipPosition,
    double? volume,
    bool? hasAudio,
  }) {
    return BRollClip(
      id: id ?? this.id,
      mediaPath: mediaPath ?? this.mediaPath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      name: name ?? this.name,
      category: category ?? this.category,
      isPictureInPicture: isPictureInPicture ?? this.isPictureInPicture,
      pipPosition: pipPosition ?? this.pipPosition,
      volume: volume ?? this.volume,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaPath': mediaPath,
        'startTime': startTime,
        'endTime': endTime,
        'name': name,
        'category': category,
        'isPictureInPicture': isPictureInPicture,
        'pipPosition': pipPosition,
        'volume': volume,
        'hasAudio': hasAudio,
      };

  factory BRollClip.fromJson(Map<String, dynamic> json) {
    return BRollClip(
      id: json['id'] as String? ?? '',
      mediaPath: json['mediaPath'] as String? ?? '',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      isPictureInPicture: json['isPictureInPicture'] as bool? ?? false,
      pipPosition: json['pipPosition'] as String? ?? 'top_right',
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      hasAudio: json['hasAudio'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BRollClip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mediaPath == other.mediaPath &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          name == other.name &&
          category == other.category &&
          isPictureInPicture == other.isPictureInPicture &&
          pipPosition == other.pipPosition &&
          volume == other.volume &&
          hasAudio == other.hasAudio;

  @override
  int get hashCode => Object.hash(
        id,
        mediaPath,
        startTime,
        endTime,
        name,
        category,
        isPictureInPicture,
        pipPosition,
        volume,
        hasAudio,
      );
}
