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
  // FIX (Issue #7, CapStudio 1.0 audit): .en variant entries were entirely
  // missing from this list. modelNameEn correctly returned 'tiny.en' etc.
  // elsewhere, but nothing here could match that name, so the lookup
  // silently fell back to the multilingual model regardless. Sizes verified
  // against whisper.cpp's published ggml model list
  // (huggingface.co/ggerganov/whisper.cpp) — .en variants are the same
  // size as their multilingual counterpart at each tier.
  WhisperModel(
    name: 'tiny.en',
    displayName: 'Tiny (English)',
    description: 'Fastest English-only model. Same size as multilingual tiny, tuned for English content.',
    sizeMb: 75.0,
    englishOnly: true,
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
    name: 'base.en',
    displayName: 'Base (English)',
    description: 'Fast English-only model with better accuracy than tiny.en. Perfect for lightweight devices.',
    sizeMb: 142.0,
    englishOnly: true,
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
    name: 'small.en',
    displayName: 'Small (English)',
    description: 'High quality English-only transcription. Balanced daily-driver choice for English creators.',
    sizeMb: 466.0,
    englishOnly: true,
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
    name: 'medium.en',
    displayName: 'Medium (English)',
    description: 'Superb English-only accuracy, demanding on RAM and CPU. Slow extraction unless on high-end hardware.',
    sizeMb: 1530.0,
    englishOnly: true,
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

  // FIX (Issue #7, CapStudio 1.0 audit): previously returned the exact same
  // value as `modelName` for every case, silently defeating the English-only
  // model optimization that import_sheet.dart / transcription_panel.dart
  // both explicitly select on (`isEn ? modelNameEn : modelName`). Verified
  // against whisper.cpp's published model list: tiny/base/small/medium each
  // have a real, smaller/faster .en-suffixed English-only variant; large
  // tiers (including large-v3-turbo) do not — the multilingual large models
  // already perform comparably, so there's no .en build to fall back to.
  String get modelNameEn => switch (this) {
    QualityMode.fast => 'tiny.en',
    QualityMode.standard => 'base.en',
    QualityMode.balanced => 'small.en',
    QualityMode.high => 'medium.en',
    QualityMode.professional => 'large-v3-turbo', // no .en variant exists upstream
  };

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
