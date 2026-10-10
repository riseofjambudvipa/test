import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../logger/logger_service.dart';

/// Represents a creator or brand identity configuration that can be applied
/// to any video project in 1 click (parity with Submagic and OpusClip Brand Kits).
class BrandKit {
  final String id;
  final String name;
  final String handle;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;
  final String? logoPath;
  final String logoPosition; // 'topRight', 'topLeft', 'bottomRight', 'bottomLeft'
  final double logoOpacity; // 0.1 to 1.0
  final double logoScale; // 0.1 to 1.0
  final String? templateId;
  final DateTime createdAt;

  BrandKit({
    required this.id,
    required this.name,
    this.handle = '',
    this.primaryColor = '#f97316',
    this.secondaryColor = '#06b6d4',
    this.accentColor = '#ec4899',
    this.fontFamily = 'Outfit',
    this.logoPath,
    this.logoPosition = 'topRight',
    this.logoOpacity = 0.9,
    this.logoScale = 0.5,
    this.templateId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BrandKit copyWith({
    String? id,
    String? name,
    String? handle,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? fontFamily,
    String? logoPath,
    String? logoPosition,
    double? logoOpacity,
    double? logoScale,
    String? templateId,
    DateTime? createdAt,
  }) {
    return BrandKit(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      logoPath: logoPath ?? this.logoPath,
      logoPosition: logoPosition ?? this.logoPosition,
      logoOpacity: logoOpacity ?? this.logoOpacity,
      logoScale: logoScale ?? this.logoScale,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'logoPath': logoPath,
      'logoPosition': logoPosition,
      'logoOpacity': logoOpacity,
      'logoScale': logoScale,
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BrandKit.fromJson(Map<String, dynamic> json) {
    return BrandKit(
      id: json['id'] as String? ?? 'kit_${const Uuid().v4()}',
      name: json['name'] as String? ?? 'Untitled Brand Kit',
      handle: json['handle'] as String? ?? '',
      primaryColor: json['primaryColor'] as String? ?? '#f97316',
      secondaryColor: json['secondaryColor'] as String? ?? '#06b6d4',
      accentColor: json['accentColor'] as String? ?? '#ec4899',
      fontFamily: json['fontFamily'] as String? ?? 'Outfit',
      logoPath: json['logoPath'] as String?,
      logoPosition: json['logoPosition'] as String? ?? 'topRight',
      logoOpacity: (json['logoOpacity'] as num?)?.toDouble() ?? 0.9,
      logoScale: (json['logoScale'] as num?)?.toDouble() ?? 0.5,
      templateId: json['templateId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Service managing creator brand kit persistence, defaults, and portable export/import.
class BrandKitService {
  BrandKitService._();
  static final BrandKitService instance = BrandKitService._();

  static const String _prefKey = 'capstudio_brand_kits';

  /// Curated default brand kits representing top content niches.
  static final List<BrandKit> defaultBrandKits = [
    BrandKit(
      id: 'kit_viral_hype',
      name: 'Viral Creator Hype',
      handle: '@viralcreator',
      primaryColor: '#F97316',
      secondaryColor: '#06B6D4',
      accentColor: '#EC4899',
      fontFamily: 'Outfit',
      templateId: 'hormozi',
    ),
    BrandKit(
      id: 'kit_thought_leader',
      name: 'Thought Leader & Podcast',
      handle: '@podcaststudio',
      primaryColor: '#F59E0B',
      secondaryColor: '#38BDF8',
      accentColor: '#E2E8F0',
      fontFamily: 'Montserrat',
      templateId: 'ali_abdaal',
    ),
    BrandKit(
      id: 'kit_silicon_valley',
      name: 'Silicon Valley Tech',
      handle: '@techinsider',
      primaryColor: '#10B981',
      secondaryColor: '#6366F1',
      accentColor: '#F43F5E',
      fontFamily: 'Space Grotesk',
      templateId: 'dev_terminal',
    ),
    BrandKit(
      id: 'kit_cinematic',
      name: 'Cinematic Documentarian',
      handle: '@documentaries',
      primaryColor: '#D4AF37',
      secondaryColor: '#E5E7EB',
      accentColor: '#9CA3AF',
      fontFamily: 'Cinzel',
      templateId: 'documentary',
    ),
    BrandKit(
      id: 'kit_high_energy',
      name: 'Fitness & High Energy',
      handle: '@dailyhustle',
      primaryColor: '#EF4444',
      secondaryColor: '#FACC15',
      accentColor: '#FFFFFF',
      fontFamily: 'Anton',
      templateId: 'beast_mode',
    ),
  ];

  /// Loads all stored brand kits, initializing with default curated kits on first run.
  Future<List<BrandKit>> getBrandKits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        // Initialize with default curated kits
        await saveAllBrandKits(defaultBrandKits);
        return List<BrandKit>.from(defaultBrandKits);
      }

      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final kits = decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => BrandKit.fromJson(item))
            .toList();
        return kits.isNotEmpty ? kits : List<BrandKit>.from(defaultBrandKits);
      }
      return List<BrandKit>.from(defaultBrandKits);
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitService', 'Failed to load brand kits: $e');
      return List<BrandKit>.from(defaultBrandKits);
    }
  }

  /// Saves a brand kit (inserts if new, replaces if existing ID matches).
  Future<void> saveBrandKit(BrandKit kit) async {
    try {
      final kits = await getBrandKits();
      final existingIndex = kits.indexWhere((k) => k.id == kit.id);
      if (existingIndex >= 0) {
        kits[existingIndex] = kit;
      } else {
        kits.insert(0, kit);
      }
      await saveAllBrandKits(kits);
      LoggerService.instance.log(LogLevel.action, 'BrandKitService', 'Saved brand kit: ${kit.name}');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitService', 'Failed to save brand kit: $e');
      rethrow;
    }
  }

  /// Deletes a brand kit by ID.
  Future<void> deleteBrandKit(String id) async {
    try {
      final kits = await getBrandKits();
      kits.removeWhere((k) => k.id == id);
      await saveAllBrandKits(kits);
      LoggerService.instance.log(LogLevel.action, 'BrandKitService', 'Deleted brand kit: $id');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitService', 'Failed to delete brand kit: $e');
      rethrow;
    }
  }

  /// Writes the complete list of brand kits to SharedPreferences.
  Future<void> saveAllBrandKits(List<BrandKit> kits) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = kits.map((k) => k.toJson()).toList();
    await prefs.setString(_prefKey, jsonEncode(jsonList));
  }

  /// Exports a brand kit as a formatted portable JSON string (.capbrand format).
  String exportBrandKitJson(BrandKit kit) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'version': '1.0',
      'type': 'capstudio_brand_kit',
      'brandKit': kit.toJson(),
    });
  }

  /// Imports and parses a brand kit JSON string, generating a fresh ID.
  BrandKit importBrandKitJson(String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid brand kit JSON structure: root is not an object');
      }

      Map<String, dynamic> kitMap;
      if (decoded.containsKey('brandKit') && decoded['brandKit'] is Map<String, dynamic>) {
        kitMap = decoded['brandKit'] as Map<String, dynamic>;
      } else {
        kitMap = decoded;
      }

      final imported = BrandKit.fromJson(kitMap);
      return imported.copyWith(
        id: 'kit_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 6)}',
      );
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitService', 'Failed to import brand kit: $e');
      rethrow;
    }
  }

  /// Resets brand kits back to factory curated presets.
  Future<void> resetToDefaults() async {
    await saveAllBrandKits(defaultBrandKits);
    LoggerService.instance.log(LogLevel.action, 'BrandKitService', 'Reset brand kits to curated defaults.');
  }
}
