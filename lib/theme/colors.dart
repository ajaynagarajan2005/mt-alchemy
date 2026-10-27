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
    required this.purple,
    required this.purpleSoft,
    required this.yellow,
    required this.yellowSoft,
    required this.onYellow,
    required this.danger,
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
  final Color purple, purpleSoft, yellow, yellowSoft, onYellow, danger;
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
    grey50: Color(0xFFF6F7FB),
    grey100: Color(0xFFEEF0F8),
    grey200: Color(0xFFDFE2F0),
    grey300: Color(0xFFC7CBE0),
    grey400: Color(0xFF9499B8),
    grey500: Color(0xFF6B7094),
    grey600: Color(0xFF4A4F73),
    grey700: Color(0xFF353A5C),
    grey800: Color(0xFF232848),
    grey900: Color(0xFF141836),
    red: Color(0xFF1B2A78),
    redDeep: Color(0xFF111C55),
    redSoft: Color(0x1F1B2A78),
    accentFill: Color(0xFF1B2A78),
    accentHover: Color(0xFF111C55),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1F7A4D),
    purple: Color(0xFF2F5BD8),
    purpleSoft: Color(0x1F2F5BD8),
    yellow: Color(0xFFFFD95A),
    yellowSoft: Color(0xFFFFF4CC),
    onYellow: Color(0xFF141836),
    danger: Color(0xFFC62839),
    glassFill: Color(0xB3FFFFFF),
    glassFillStrong: Color(0xD9FFFFFF),
    glassBorder: Color(0x99FFFFFF),
    glassHighlight: Color(0xD9FFFFFF),
    glassHighlightStrong: Color(0xF2FFFFFF),
    shadowTint: Color(0x1A141836),
    inverseSurface: Color(0xFF0F1440),
    onInverse: Color(0xFFFAFBFF),
    inverseMuted: Color(0xFFCDD1EA),
    inverseFaint: Color(0xFF9AA0C8),
    inverseLine: Color(0xFF2E3566),
    inverseOutline: Color(0xFF5A6199),
  );

  /// Deep navy, never pure black. Text blue is lifted to #9DB0FF so it keeps
  /// 4.5:1 on the dark surfaces; filled buttons use #3347C4 with white.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    white: Color(0xFF0C1030),
    surface: Color(0xFF141945),
    grey50: Color(0xFF171C4C),
    grey100: Color(0xFF1D2358),
    grey200: Color(0xFF272E69),
    grey300: Color(0xFF343C7E),
    grey400: Color(0xFF5B64A8),
    grey500: Color(0xFF8D95CC),
    grey600: Color(0xFFB5BBE6),
    grey700: Color(0xFFD2D6F2),
    grey800: Color(0xFFE4E7F8),
    grey900: Color(0xFFF3F4FD),
    red: Color(0xFF9DB0FF),
    redDeep: Color(0xFFC3CEFF),
    redSoft: Color(0x339DB0FF),
    accentFill: Color(0xFF3347C4),
    accentHover: Color(0xFF2536A0),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF4CC38A),
    purple: Color(0xFF8FB0FF),
    purpleSoft: Color(0x338FB0FF),
    yellow: Color(0xFFFFD95A),
    yellowSoft: Color(0x33FFD95A),
    onYellow: Color(0xFF141836),
    danger: Color(0xFFFF7A8A),
    glassFill: Color(0x9E141945),
    glassFillStrong: Color(0xD1141945),
    glassBorder: Color(0x1AFFFFFF),
    glassHighlight: Color(0x1FFFFFFF),
    glassHighlightStrong: Color(0x29FFFFFF),
    shadowTint: Color(0x73000000),
    inverseSurface: Color(0xFF070A24),
    onInverse: Color(0xFFFAFBFF),
    inverseMuted: Color(0xFFCDD1EA),
    inverseFaint: Color(0xFF9AA0C8),
    inverseLine: Color(0xFF2E3566),
    inverseOutline: Color(0xFF5A6199),
  );
}

/// Brand palette: blue, white and yellow, switchable between light and dark.
/// Deep blue is the primary accent (the token is still called `red` from the
/// first design; read it as "accent"). `purple` is a bright blue, kept under
/// its old name: it marks labels and the second end of the "transformation"
/// gradient. Yellow is for highlights, badges and charts; `error` is a true red.
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

  // Secondary and highlight colours from the brief: purple and soft yellow.
  static Color get purple => _p.purple;
  static Color get purpleSoft => _p.purpleSoft;
  static Color get yellow => _p.yellow;
  static Color get yellowSoft => _p.yellowSoft;
  static Color get onYellow => _p.onYellow;

  // Semantic
  static Color get ink => _p.grey900;
  static Color get inkMuted => _p.grey600; // 7.4:1 on white, AA for body
  static Color get line => _p.grey200;
  static Color get success => _p.success;
  static Color get error => _p.danger;

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

  /// Deep blue -> bright blue: used only at moments of change. Same in both
  /// modes, white text sits on it.
  static LinearGradient get transformation => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_p.accentFill, const Color(0xFF2F5BD8)],
  );
}
