import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/native_helper.dart';

class WhisperModel {
  final String name;
  final String displayName;
  final String description;
  final double sizeMb;
  final bool englishOnly;
  final int relativeSpeed; // 1-10 (higher is faster)
  final int relativeAccuracy; // 1-10 (higher is more accurate)

  const WhisperModel({
    required this.name,
    required this.displayName,
    required this.description,
    required this.sizeMb,
    required this.englishOnly,
    required this.relativeSpeed,
    required this.relativeAccuracy,
  });

  String get downloadUrl {
    // Basic validation to prevent URL injection/path traversal
    if (!RegExp(r'^[a-zA-Z0-9\.\-]+$').hasMatch(name)) {
      throw ArgumentError('Invalid whisper model name (must be alphanumeric/dots/hyphens): $name');
    }
    return 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$name.bin';
  }
}

const List<WhisperModel> kWhisperModels = [
  WhisperModel(
    name: 'tiny',
    displayName: 'Tiny (Multilingual)',
    description: 'Fastest multilingual model. Low accuracy, but supports all languages and has minimal size.',
    sizeMb: 75.0,
    englishOnly: false,
    relativeSpeed: 9,
    relativeAccuracy: 3,
  ),
  WhisperModel(
    name: 'base',
    displayName: 'Base (Multilingual)',
    description: 'Fast multilingual model with better accuracy than tiny. Perfect for lightweight devices.',
    sizeMb: 142.0,
    englishOnly: false,
    relativeSpeed: 7,
    relativeAccuracy: 5,
  ),
  WhisperModel(
    name: 'small',
    displayName: 'Small (Multilingual)',
    description: 'High quality multilingual transcription. Balanced choice for non-English creators.',
    sizeMb: 466.0,
    englishOnly: false,
    relativeSpeed: 4,
    relativeAccuracy: 7,
  ),
  WhisperModel(
    name: 'medium',
    displayName: 'Medium (Multilingual)',
    description: 'Superb accuracy, but demanding on RAM and CPU. Slow extraction unless on high-end hardware.',
    sizeMb: 1530.0,
    englishOnly: false,
    relativeSpeed: 2,
    relativeAccuracy: 9,
  ),
  WhisperModel(
    name: 'large-v3-turbo',
    displayName: 'Large v3 Turbo (Multilingual)',
    description: 'State-of-the-art accuracy with optimized performance. Incredible detail for professional production.',
    sizeMb: 1540.0,
    englishOnly: false,
    // large-v3-turbo uses fewer decoding steps/layers, making it significantly faster (speed index 3) 
    // than the standard medium model (speed index 2) despite having a similar parameter size.
    relativeSpeed: 3,
    relativeAccuracy: 10,
  ),
];

enum QualityMode {
  fast,
  standard,
  balanced,
  high,
  professional;

  static QualityMode getRecommended(SystemHardwareInfo info) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // For mobile devices, recommend Balanced (small) if they have 2.5GB+ RAM, Standard if they have 2GB+ RAM, otherwise Fast (tiny)
      if (info.ramGB >= 2.3) {
        return QualityMode.balanced;
      } else if (info.ramGB >= 1.8) {
        return QualityMode.standard;
      } else {
        return QualityMode.fast;
      }
    }
    // For desktop
    if (info.ramGB >= 9.5) {
      return QualityMode.professional; // 10GB+
    } else if (info.ramGB >= 5.5) {
      return QualityMode.high; // 6GB+
    } else if (info.ramGB >= 2.3) {
      return QualityMode.balanced; // 2.5GB+
    } else if (info.ramGB >= 1.8) {
      return QualityMode.standard; // 2GB+
    } else {
      return QualityMode.fast; // 1GB+
    }
  }
}

extension QualityModeExtension on QualityMode {
  String get displayName => switch (this) {
    QualityMode.fast => 'Fast Mode',
    QualityMode.standard => 'Standard Mode',
    QualityMode.balanced => 'Balanced Mode',
    QualityMode.high => 'High Quality Mode',
    QualityMode.professional => 'Professional Mode',
  };

  String get modelName => switch (this) {
    QualityMode.fast => 'tiny',
    QualityMode.standard => 'base',
    QualityMode.balanced => 'small',
    QualityMode.high => 'medium',
    QualityMode.professional => 'large-v3-turbo',
  };

  /// CapStudio is a 100% universal offline studio. Standard quality presets
  /// use universal multilingual models (tiny, base, small, medium, large-v3-turbo)
  /// so users never face language lockouts or duplicate model downloads.
  String get modelNameEn => modelName;

  double get sizeMb => switch (this) {
    QualityMode.fast => 75.0,
    QualityMode.standard => 142.0,
    QualityMode.balanced => 466.0,
    QualityMode.high => 1530.0,
    QualityMode.professional => 1540.0,
  };

  String get speedAccuracyText => switch (this) {
    QualityMode.fast => 'Fastest speed, basic accuracy',
    QualityMode.standard => 'Good speed, standard accuracy',
    QualityMode.balanced => 'Excellent balance of speed & accuracy',
    QualityMode.high => 'Superb accuracy, slower extraction',
    QualityMode.professional => 'Maximum accuracy, optimized speed',
  };
  
  String get details => switch (this) {
    QualityMode.fast => '1GB+ RAM. Best for quick drafts.',
    QualityMode.standard => '2GB+ RAM. Great for general use.',
    QualityMode.balanced => '2.5GB+ RAM. Perfect daily driver.',
    QualityMode.high => '6GB+ RAM. Superb quality, CPU heavy.',
    QualityMode.professional => '10GB+ RAM. Max accuracy & speed.',
  };

  bool isSupported(SystemHardwareInfo? info) {
    if (info == null) return true;
    final requiredRam = switch (this) {
      QualityMode.fast => 0.8,
      QualityMode.standard => 1.8,
      QualityMode.balanced => 2.3,
      QualityMode.high => 5.5,
      QualityMode.professional => 9.5,
    };
    return info.ramGB >= requiredRam;
  }

  String getDetailsWithSystemInfo(SystemHardwareInfo? info) {
    if (info == null) return details;
    final systemRamStr = '${info.ramGB.toStringAsFixed(1)} GB';
    if (isSupported(info)) {
      return '$details (Your system: $systemRamStr)';
    } else {
      return '$details (Your system: $systemRamStr - Locked)';
    }
  }
}
