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

  ProjectConfigSchema toConfig({String? currentEmojiPack}) {
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
      ..subs = (SubtitleConfigSchema()
        ..chunkSize = 4
        ..chunkLineMaxLength = 30)
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
  StyleTemplate(
    id: 'glow',
    name: 'GLOW',
    category: StyleCategory.effects,
    fontFamily: 'Outfit',
    fontWeight: '900',
    textTransform: 'uppercase',
    color: '#ffffff',
    fontSize: 38,
    top: 65,
    mainColor: '#8B5CF6', // Violet
    secondColor: '#EC4899', // Hot Pink
    thirdColor: '#06B6D4', // Cyan
    stroke: 'thick',
    animation: 'glowPulse',
    shadow: 'soft',
    background: null,
  ),
];

/// Converts a [StyleTemplate] into a fully populated [ProjectConfigSchema]
/// suitable for initialising a new project or applying a style preset.
ProjectConfigSchema templateToConfig(StyleTemplate template, {String? currentEmojiPack}) {
  return template.toConfig(currentEmojiPack: currentEmojiPack);
}
