import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'schediel_theme.dart';

enum ThemeTexture {
  none('None'),
  paper('Paper'),
  dots('Dots'),
  grid('Grid'),
  stripes('Stripes'),
  carbon('Carbon'),
  graphite('Graphite'),
  flow('Flow'),
  topo('Topo'),
  mesh('Mesh'),
  gradient('Gradient');

  const ThemeTexture(this.label);
  final String label;
}

@immutable
class ThemeCustomization {
  const ThemeCustomization({
    this.mainHue,
    this.mainTone,
    this.backgroundHue,
    this.backgroundTone,
    this.texture = ThemeTexture.none,
  });
  final double? mainHue, mainTone, backgroundHue, backgroundTone;
  final ThemeTexture texture;
  bool get hasColors => mainHue != null || mainTone != null || backgroundHue != null || backgroundTone != null;

  ThemeCustomization copyWith({
    double? mainHue,
    double? mainTone,
    double? backgroundHue,
    double? backgroundTone,
    ThemeTexture? texture,
  }) => ThemeCustomization(
    mainHue: mainHue ?? this.mainHue,
    mainTone: mainTone ?? this.mainTone,
    backgroundHue: backgroundHue ?? this.backgroundHue,
    backgroundTone: backgroundTone ?? this.backgroundTone,
    texture: texture ?? this.texture,
  );

  static double? number(Object? value, double max) => value is num && value.isFinite ? value.clamp(0, max).toDouble() : null;
  factory ThemeCustomization.fromJson(Map<Object?, Object?> json) => ThemeCustomization(
    mainHue: number(json['mainHue'], 359),
    mainTone: number(json['mainTone'], 100),
    backgroundHue: number(json['backgroundHue'], 359),
    backgroundTone: number(json['backgroundTone'], 100),
    texture: ThemeTexture.values.firstWhere((v) => v.name == json['texture'], orElse: () => ThemeTexture.none),
  );
  Map<String, Object> toJson() => {
    'mainHue': ?number(mainHue, 359),
    'mainTone': ?number(mainTone, 100),
    'backgroundHue': ?number(backgroundHue, 359),
    'backgroundTone': ?number(backgroundTone, 100),
    'texture': texture.name,
  };
  @override
  bool operator ==(Object other) =>
      other is ThemeCustomization &&
      other.mainHue == mainHue &&
      other.mainTone == mainTone &&
      other.backgroundHue == backgroundHue &&
      other.backgroundTone == backgroundTone &&
      other.texture == texture;
  @override
  int get hashCode => Object.hash(mainHue, mainTone, backgroundHue, backgroundTone, texture);
}

Map<ThemeId, ThemeCustomization> decodeThemeCustomizations(String source) {
  try {
    final json = jsonDecode(source);
    if (json is! Map) return const {};
    return Map.unmodifiable({
      for (final id in ThemeId.values)
        if (json[id.name] case final Map value) id: ThemeCustomization.fromJson(value),
    });
  } on FormatException {
    return const {};
  }
}

String encodeThemeCustomizations(Map<ThemeId, ThemeCustomization> values) =>
    jsonEncode({for (final entry in values.entries) entry.key.name: entry.value.toJson()});
