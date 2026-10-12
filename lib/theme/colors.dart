import 'package:flutter/widgets.dart';

/// One complete set of colour tokens. [AppColors] reads from the active one.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.white,
    required this.surface,
    required this.grey50,
    required this.grey100,
    required this.grey200,
    required this.grey300,
    required this.grey400,
    required this.grey500,
    required this.grey600,
    required this.grey700,
    required this.grey800,
    required this.grey900,
    required this.red,
    required this.redDeep,
    required this.redSoft,
    required this.accentFill,
    required this.accentHover,
    required this.onAccent,
    required this.success,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassHighlightStrong,
    required this.shadowTint,
    required this.inverseSurface,
    required this.onInverse,
    required this.inverseMuted,
    required this.inverseFaint,
    required this.inverseLine,
    required this.inverseOutline,
  });

  final Brightness brightness;
  final Color white,
      surface,
      grey50,
      grey100,
      grey200,
      grey300,
      grey400,
      grey500,
      grey600,
      grey700,
      grey800,
      grey900;
  final Color red, redDeep, redSoft, accentFill, accentHover, onAccent, success;
  final Color glassFill,
      glassFillStrong,
      glassBorder,
      glassHighlight,
      glassHighlightStrong,
      shadowTint;
  final Color inverseSurface,
      onInverse,
      inverseMuted,
      inverseFaint,
      inverseLine,
      inverseOutline;

  static const light = AppPalette(
    brightness: Brightness.light,
    white: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    grey50: Color(0xFFF7F7F8),
    grey100: Color(0xFFF4F4F5),
    grey200: Color(0xFFE4E4E7),
    grey300: Color(0xFFD4D4D8),
    grey400: Color(0xFFA1A1AA),
    grey500: Color(0xFF71717A),
    grey600: Color(0xFF52525B),
    grey700: Color(0xFF3F3F46),
    grey800: Color(0xFF27272A),
    grey900: Color(0xFF18181B),
    red: Color(0xFFC8102E),
    redDeep: Color(0xFF9E0C24),
    redSoft: Color(0x1FC8102E),
    accentFill: Color(0xFFC8102E),
    accentHover: Color(0xFF9E0C24),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1F7A4D),
    glassFill: Color(0xB3FFFFFF),
    glassFillStrong: Color(0xD9FFFFFF),
    glassBorder: Color(0x99FFFFFF),
    glassHighlight: Color(0xD9FFFFFF),
    glassHighlightStrong: Color(0xF2FFFFFF),
    shadowTint: Color(0x1A18181B),
    inverseSurface: Color(0xFF18181B),
    onInverse: Color(0xFFFCFCFC),
    inverseMuted: Color(0xFFD4D4D8),
    inverseFaint: Color(0xFFA1A1AA),
    inverseLine: Color(0xFF3F3F46),
    inverseOutline: Color(0xFF71717A),
  );

  /// Calm charcoal, never pure black. Text red is lifted to #EE4A63 so it
  /// keeps 4.5:1 on the dark surfaces; filled buttons keep #C8102E with white.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    white: Color(0xFF141416),
    surface: Color(0xFF1C1C1F),
    grey50: Color(0xFF1F1F23),
    grey100: Color(0xFF26262B),
    grey200: Color(0xFF2E2E34),
    grey300: Color(0xFF3A3A41),
    grey400: Color(0xFF5A5A63),
    grey500: Color(0xFF8A8A94),
    grey600: Color(0xFFB4B4BD),
    grey700: Color(0xFFD4D4D8),
    grey800: Color(0xFFE4E4E7),
    grey900: Color(0xFFF4F4F5),
    red: Color(0xFFEE4A63),
    redDeep: Color(0xFFFF8396),
    redSoft: Color(0x33EE4A63),
    accentFill: Color(0xFFC8102E),
    accentHover: Color(0xFF9E0C24),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF4CC38A),
    glassFill: Color(0x9E1C1C1F),
    glassFillStrong: Color(0xD11C1C1F),
    glassBorder: Color(0x1AFFFFFF),
    glassHighlight: Color(0x1FFFFFFF),
    glassHighlightStrong: Color(0x29FFFFFF),
    shadowTint: Color(0x73000000),
    inverseSurface: Color(0xFF0E0E10),
    onInverse: Color(0xFFFCFCFC),
    inverseMuted: Color(0xFFD4D4D8),
    inverseFaint: Color(0xFFA1A1AA),
    inverseLine: Color(0xFF3F3F46),
    inverseOutline: Color(0xFF71717A),
  );
}

/// Brand palette: white / grey / red, switchable between light and dark.
/// Red is the single accent. Grey to red is the "transformation" story,
/// so the grey->red gradient is reserved for moments of change.
///
/// Every token is a getter on the active [AppPalette]; call
/// [AppColors.apply] before building (app.dart does) and rebuild the tree.
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;

  static void apply(Brightness b) =>
      _p = b == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static Brightness get brightness => _p.brightness;
  static bool get isDark => _p.brightness == Brightness.dark;

  // Base
  static Color get white => _p.white;
  static Color get surface => _p.surface;

  // Neutral zinc scale
  static Color get grey50 => _p.grey50;
  static Color get grey100 => _p.grey100;
  static Color get grey200 => _p.grey200;
  static Color get grey300 => _p.grey300;
  static Color get grey400 => _p.grey400;
  static Color get grey500 => _p.grey500;
  static Color get grey600 => _p.grey600;
  static Color get grey700 => _p.grey700;
  static Color get grey800 => _p.grey800;
  static Color get grey900 => _p.grey900;

  // Accent. [red] is for text, icons and strokes; [accentFill] backs filled
  // buttons whose label is [onAccent].
  static Color get red => _p.red;
  static Color get redDeep => _p.redDeep;
  static Color get redSoft => _p.redSoft;
  static Color get accentFill => _p.accentFill;
  static Color get accentHover => _p.accentHover;
  static Color get onAccent => _p.onAccent;

  // Semantic
  static Color get ink => _p.grey900;
  static Color get inkMuted => _p.grey600; // 7.4:1 on white, AA for body
  static Color get line => _p.grey200;
  static Color get success => _p.success;
  static Color get error => _p.redDeep;

  // Glass
  static Color get glassFill => _p.glassFill;
  static Color get glassFillStrong => _p.glassFillStrong;
  static Color get glassBorder => _p.glassBorder;
  static Color get glassHighlight => _p.glassHighlight;
  static Color get glassHighlightStrong => _p.glassHighlightStrong;
  static Color get shadowTint => _p.shadowTint;

  // Surfaces that stay dark in both modes (footer, CTA band, snackbars).
  static Color get inverseSurface => _p.inverseSurface;
  static Color get onInverse => _p.onInverse;
  static Color get inverseMuted => _p.inverseMuted;
  static Color get inverseFaint => _p.inverseFaint;
  static Color get inverseLine => _p.inverseLine;
  static Color get inverseOutline => _p.inverseOutline;

  /// Grey -> red: used only at moments of change. Same in both modes, white
  /// text sits on it.
  static LinearGradient get transformation => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_p.inverseLine, _p.accentFill],
  );
}
