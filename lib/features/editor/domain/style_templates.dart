import '../../../core/database/schemas/project.dart';

enum StyleCategory {
  all,
  trending,
  bold,
  elegant,
  playful,
  effects,
  classic,
  modern,
  premium,
  custom;

  String get displayName {
    switch (this) {
      case StyleCategory.all: return 'All';
      case StyleCategory.trending: return 'Trending';
      case StyleCategory.bold: return 'Bold';
      case StyleCategory.elegant: return 'Elegant';
      case StyleCategory.playful: return 'Playful';
      case StyleCategory.effects: return 'Effects';
      case StyleCategory.classic: return 'Classic';
      case StyleCategory.modern: return 'Modern';
      case StyleCategory.premium: return 'Premium';
      case StyleCategory.custom: return 'Custom';
    }
  }
}

class StyleTemplate {
  final String id;
  final String name;
  final StyleCategory category;
  final String fontFamily;
  final String fontWeight;
  final String textTransform;
  final String color;
  final double fontSize;
  final double top;
  final String mainColor;
  final String secondColor;
  final String thirdColor;
  final String stroke;
  final String animation;
  final String shadow;
  final String? background;
  final bool? highlightBackground;
  final double? letterSpacing;
  final double? lineHeight;

  const StyleTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.fontFamily,
    required this.fontWeight,
    required this.textTransform,
    required this.color,
    required this.fontSize,
    required this.top,
    required this.mainColor,
    required this.secondColor,
    required this.thirdColor,
    required this.stroke,
    required this.animation,
    required this.shadow,
    this.background,
    this.highlightBackground,
    this.letterSpacing,
    this.lineHeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight,
      'textTransform': textTransform,
      'color': color,
      'fontSize': fontSize,
      'top': top,
      'mainColor': mainColor,
      'secondColor': secondColor,
      'thirdColor': thirdColor,
      'stroke': stroke,
      'animation': animation,
      'shadow': shadow,
      'background': background,
      'highlightBackground': highlightBackground,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
    };
  }

  factory StyleTemplate.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String? ?? 'custom';
    final cat = StyleCategory.values.firstWhere(
      (c) => c.name == catName.toLowerCase(),
      orElse: () => StyleCategory.custom,
    );
    return StyleTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom',
      category: cat,
      fontFamily: json['fontFamily'] as String? ?? 'Montserrat',
      fontWeight: json['fontWeight'] as String? ?? '900',
      textTransform: json['textTransform'] as String? ?? 'uppercase',
      color: json['color'] as String? ?? '#ffffff',
      fontSize: (json['fontSize'] is num) ? (json['fontSize'] as num).toDouble() : 42.0,
      top: (json['top'] is num) ? (json['top'] as num).toDouble() : 55.0,
      mainColor: json['mainColor'] as String? ?? '#f97316',
      secondColor: json['secondColor'] as String? ?? '#06b6d4',
      thirdColor: json['thirdColor'] as String? ?? '#22c55e',
      stroke: json['stroke'] as String? ?? 'thick',
      animation: json['animation'] as String? ?? 'pop',
      shadow: json['shadow'] as String? ?? 'none',
      background: json['background'] as String?,
      highlightBackground: json['highlightBackground'] as bool?,
      letterSpacing: (json['letterSpacing'] is num) ? (json['letterSpacing'] as num).toDouble() : null,
      lineHeight: (json['lineHeight'] is num) ? (json['lineHeight'] as num).toDouble() : null,
    );
  }

  ProjectConfigSchema toConfig({String? currentEmojiPack, SubtitleConfigSchema? existingSubs}) {
    final config = ProjectConfigSchema()
      ..name = name
      ..style = (StyleConfigSchema()
        ..fontFamily = fontFamily
        ..fontWeight = fontWeight
        ..textTransform = textTransform
        ..color = color
        ..fontSize = fontSize
        ..top = top
        ..highlightBackground = highlightBackground ?? false
        ..letterSpacing = letterSpacing ?? 0.0
        ..lineHeight = lineHeight ?? 1.2)
      ..highlightStyle = (HighlightStyleSchema()
        ..mainColor = mainColor
        ..secondColor = secondColor
        ..thirdColor = thirdColor)
      ..subs = (existingSubs != null
          ? (SubtitleConfigSchema()
            ..chunkSize = existingSubs.chunkSize
            ..chunkLineMaxLength = existingSubs.chunkLineMaxLength)
          : (SubtitleConfigSchema()
            ..chunkSize = 4
            ..chunkLineMaxLength = 30))
      ..animation = animation
      ..shadow = shadow
      ..stroke = stroke
      ..background = background
      ..emojiPack = currentEmojiPack ?? 'notoColorEmoji';

    return config;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StyleTemplate &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.fontFamily == fontFamily &&
        other.fontWeight == fontWeight &&
        other.textTransform == textTransform &&
        other.color == color &&
        other.fontSize == fontSize &&
        other.top == top &&
        other.mainColor == mainColor &&
        other.secondColor == secondColor &&
        other.thirdColor == thirdColor &&
        other.stroke == stroke &&
        other.animation == animation &&
        other.shadow == shadow &&
        other.background == background &&
        other.highlightBackground == highlightBackground &&
        other.letterSpacing == letterSpacing &&
        other.lineHeight == lineHeight;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        category,
        fontFamily,
        fontWeight,
        textTransform,
        color,
        fontSize,
        top,
        mainColor,
        secondColor,
        thirdColor,
        stroke,
        animation,
        shadow,
        background,
        highlightBackground,
        letterSpacing,
        lineHeight,
      ]);
}

const List<StyleCategory> templateCategories = StyleCategory.values;

const List<StyleTemplate> allTemplates = [
  // TRENDING
  StyleTemplate(
    id: 'hormozi_classic',
    name: 'Hormozi Classic',
    category: StyleCategory.trending,
    fontFamily: 'Montserrat',
    fontWeight: '900',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 42.0,
    top: 75.0,
    mainColor: '#22c55e',
    secondColor: '#eab308',
    thirdColor: '#f97316',
    stroke: 'thick',
    animation: 'pop',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'mrbeast_impact',
    name: 'MrBeast Big Impact',
    category: StyleCategory.trending,
    fontFamily: 'Anton',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#facc15',
    fontSize: 48.0,
    top: 78.0,
    mainColor: '#ffffff',
    secondColor: '#06b6d4',
    thirdColor: '#ef4444',
    stroke: 'thick',
    animation: 'bounce',
    shadow: '3d',
  ),
  StyleTemplate(
    id: 'tiktok_pop',
    name: 'TikTok Vibrant',
    category: StyleCategory.trending,
    fontFamily: 'Poppins',
    fontWeight: '800',
    textTransform: 'none',
    color: '#ffffff',
    fontSize: 38.0,
    top: 60.0,
    mainColor: '#ff007f',
    secondColor: '#00f0ff',
    thirdColor: '#ffe600',
    stroke: 'thin',
    animation: 'pop',
    shadow: 'soft',
  ),

  // BOLD
  StyleTemplate(
    id: 'bebas_power',
    name: 'Bebas High Impact',
    category: StyleCategory.bold,
    fontFamily: 'Bebas Neue',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 52.0,
    top: 72.0,
    mainColor: '#ef4444',
    secondColor: '#f97316',
    thirdColor: '#eab308',
    stroke: 'thick',
    animation: 'pop',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'comic_slam',
    name: 'Comic Slam',
    category: StyleCategory.bold,
    fontFamily: 'Bangers',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 48.0,
    top: 70.0,
    mainColor: '#06b6d4',
    secondColor: '#8b5cf6',
    thirdColor: '#ec4899',
    stroke: 'thick',
    animation: 'bounce',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'heavy_boxer',
    name: 'Heavy Boxer',
    category: StyleCategory.bold,
    fontFamily: 'Oswald',
    fontWeight: '700',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 46.0,
    top: 74.0,
    mainColor: '#f97316',
    secondColor: '#ef4444',
    thirdColor: '#eab308',
    stroke: 'thick',
    animation: 'pop',
    shadow: '3d',
  ),

  // ELEGANT
  StyleTemplate(
    id: 'editorial_dm_serif',
    name: 'Editorial Serif',
    category: StyleCategory.elegant,
    fontFamily: 'DM Serif Display',
    fontWeight: '400',
    textTransform: 'none',
    color: '#fffdf5',
    fontSize: 36.0,
    top: 78.0,
    mainColor: '#d4af37',
    secondColor: '#38bdf8',
    thirdColor: '#10b981',
    stroke: 'none',
    animation: 'wordReveal',
    shadow: 'soft',
  ),
  StyleTemplate(
    id: 'luxury_vogue',
    name: 'Luxury Vogue',
    category: StyleCategory.elegant,
    fontFamily: 'Playfair Display',
    fontWeight: '600',
    textTransform: 'uppercase',
    color: '#f8fafc',
    fontSize: 36.0,
    top: 75.0,
    mainColor: '#c026d3',
    secondColor: '#0ea5e9',
    thirdColor: '#10b981',
    stroke: 'none',
    animation: 'wordReveal',
    shadow: 'soft',
  ),
  StyleTemplate(
    id: 'warm_fraunces',
    name: 'Warm Editorial',
    category: StyleCategory.elegant,
    fontFamily: 'Fraunces',
    fontWeight: '600',
    textTransform: 'none',
    color: '#fef3c7',
    fontSize: 34.0,
    top: 78.0,
    mainColor: '#f59e0b',
    secondColor: '#0ea5e9',
    thirdColor: '#10b981',
    stroke: 'none',
    animation: 'wordReveal',
    shadow: 'soft',
  ),

  // PLAYFUL
  StyleTemplate(
    id: 'bouncy_bubble',
    name: 'Bouncy Bubble',
    category: StyleCategory.playful,
    fontFamily: 'Comic Neue',
    fontWeight: '700',
    textTransform: 'none',
    color: '#ffffff',
    fontSize: 42.0,
    top: 65.0,
    mainColor: '#ec4899',
    secondColor: '#06b6d4',
    thirdColor: '#eab308',
    stroke: 'thin',
    animation: 'bounce',
    shadow: 'soft',
  ),
  StyleTemplate(
    id: 'handwritten_note',
    name: 'Handwritten Vibe',
    category: StyleCategory.playful,
    fontFamily: 'Caveat',
    fontWeight: '700',
    textTransform: 'none',
    color: '#fef08a',
    fontSize: 44.0,
    top: 70.0,
    mainColor: '#ffffff',
    secondColor: '#f472b6',
    thirdColor: '#38bdf8',
    stroke: 'none',
    animation: 'bounce',
    shadow: 'soft',
  ),
  StyleTemplate(
    id: 'retro_arcade',
    name: 'Retro 8-Bit Arcade',
    category: StyleCategory.playful,
    fontFamily: 'Press Start 2P',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#39ff14',
    fontSize: 26.0,
    top: 68.0,
    mainColor: '#ff1493',
    secondColor: '#00ffff',
    thirdColor: '#ffff00',
    stroke: 'thick',
    animation: 'pop',
    shadow: 'hard',
  ),

  // EFFECTS
  StyleTemplate(
    id: 'cyberpunk_glitch',
    name: 'Cyberpunk Glitch',
    category: StyleCategory.effects,
    fontFamily: 'Rubik Glitch',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#00f0ff',
    fontSize: 42.0,
    top: 72.0,
    mainColor: '#ff007f',
    secondColor: '#ffe600',
    thirdColor: '#00f0ff',
    stroke: 'thick',
    animation: 'pop',
    shadow: '3d',
    background: 'box',
  ),
  StyleTemplate(
    id: 'glow',
    name: 'Glowing Aura',
    category: StyleCategory.effects,
    fontFamily: 'Orbitron',
    fontWeight: '700',
    textTransform: 'uppercase',
    color: '#38bdf8',
    fontSize: 38.0,
    top: 65.0,
    mainColor: '#ffffff',
    secondColor: '#818cf8',
    thirdColor: '#c084fc',
    stroke: 'thin',
    animation: 'glowPulse',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'synthwave_80s',
    name: 'Synthwave 80s',
    category: StyleCategory.effects,
    fontFamily: 'Righteous',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#f43f5e',
    fontSize: 44.0,
    top: 72.0,
    mainColor: '#38bdf8',
    secondColor: '#facc15',
    thirdColor: '#a855f7',
    stroke: 'thick',
    animation: 'bounce',
    shadow: '3d',
  ),

  // CLASSIC
  StyleTemplate(
    id: 'standard_yellow_bottom',
    name: 'Standard Yellow Subtitle',
    category: StyleCategory.classic,
    fontFamily: 'Montserrat',
    fontWeight: '700',
    textTransform: 'none',
    color: '#fde047',
    fontSize: 34.0,
    top: 84.0,
    mainColor: '#ffffff',
    secondColor: '#facc15',
    thirdColor: '#fb923c',
    stroke: 'thick',
    animation: 'none',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'clean_white_pill',
    name: 'Clean White Pill',
    category: StyleCategory.classic,
    fontFamily: 'Outfit',
    fontWeight: '600',
    textTransform: 'none',
    color: '#ffffff',
    fontSize: 32.0,
    top: 82.0,
    mainColor: '#38bdf8',
    secondColor: '#4ade80',
    thirdColor: '#facc15',
    stroke: 'none',
    animation: 'none',
    shadow: 'none',
    background: 'pill',
  ),

  // MODERN
  StyleTemplate(
    id: 'glass_capsule',
    name: 'Glass Capsule',
    category: StyleCategory.modern,
    fontFamily: 'Space Grotesk',
    fontWeight: '700',
    textTransform: 'none',
    color: '#ffffff',
    fontSize: 34.0,
    top: 76.0,
    mainColor: '#facc15',
    secondColor: '#38bdf8',
    thirdColor: '#4ade80',
    stroke: 'none',
    animation: 'wordReveal',
    shadow: 'soft',
    background: 'pill',
  ),
  StyleTemplate(
    id: 'urbanist_clean',
    name: 'Urbanist Clean',
    category: StyleCategory.modern,
    fontFamily: 'Urbanist',
    fontWeight: '700',
    textTransform: 'none',
    color: '#f8fafc',
    fontSize: 36.0,
    top: 78.0,
    mainColor: '#22c55e',
    secondColor: '#38bdf8',
    thirdColor: '#f59e0b',
    stroke: 'thin',
    animation: 'wordReveal',
    shadow: 'soft',
  ),

  // PREMIUM
  StyleTemplate(
    id: 'obsidian_gold',
    name: 'Obsidian Gold',
    category: StyleCategory.premium,
    fontFamily: 'DM Serif Display',
    fontWeight: '400',
    textTransform: 'uppercase',
    color: '#fbbf24',
    fontSize: 38.0,
    top: 72.0,
    mainColor: '#ffffff',
    secondColor: '#f59e0b',
    thirdColor: '#d97706',
    stroke: 'thin',
    animation: 'wordReveal',
    shadow: 'hard',
    letterSpacing: 2.0,
  ),
  StyleTemplate(
    id: 'diamond_cyan',
    name: 'Diamond Cyan',
    category: StyleCategory.premium,
    fontFamily: 'Exo 2',
    fontWeight: '700',
    textTransform: 'uppercase',
    color: '#67e8f9',
    fontSize: 36.0,
    top: 74.0,
    mainColor: '#ffffff',
    secondColor: '#22d3ee',
    thirdColor: '#06b6d4',
    stroke: 'none',
    animation: 'glowPulse',
    shadow: 'soft',
  ),

  // CUSTOM STARTERS
  StyleTemplate(
    id: 'starter_custom_1',
    name: 'Starter Custom 1',
    category: StyleCategory.custom,
    fontFamily: 'Montserrat',
    fontWeight: '900',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 42.0,
    top: 75.0,
    mainColor: '#f97316',
    secondColor: '#06b6d4',
    thirdColor: '#22c55e',
    stroke: 'thick',
    animation: 'pop',
    shadow: 'hard',
  ),
  StyleTemplate(
    id: 'starter_custom_2',
    name: 'Starter Custom 2',
    category: StyleCategory.custom,
    fontFamily: 'Poppins',
    fontWeight: '600',
    textTransform: 'none',
    color: '#ffffff',
    fontSize: 36.0,
    top: 80.0,
    mainColor: '#eab308',
    secondColor: '#3b82f6',
    thirdColor: '#ec4899',
    stroke: 'none',
    animation: 'none',
    shadow: 'soft',
  ),
];

/// Converts a [StyleTemplate] into a fully populated [ProjectConfigSchema]
/// suitable for initialising a new project or applying a style preset.
ProjectConfigSchema templateToConfig(StyleTemplate template, {String? currentEmojiPack, SubtitleConfigSchema? existingSubs}) {
  return template.toConfig(currentEmojiPack: currentEmojiPack, existingSubs: existingSubs);
}
