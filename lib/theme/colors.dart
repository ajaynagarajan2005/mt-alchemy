import 'package:flutter/widgets.dart';

/// Brand palette: white / grey / red.
/// Red is the single accent. Grey to red is the "transformation" story,
/// so the grey->red gradient is reserved for moments of change.
abstract final class AppColors {
  // Base
  static const white = Color(0xFFFCFCFC);
  static const surface = Color(0xFFFFFFFF);

  // Neutral zinc scale
  static const grey50 = Color(0xFFF7F7F8);
  static const grey100 = Color(0xFFF4F4F5);
  static const grey200 = Color(0xFFE4E4E7);
  static const grey300 = Color(0xFFD4D4D8);
  static const grey400 = Color(0xFFA1A1AA);
  static const grey500 = Color(0xFF71717A);
  static const grey600 = Color(0xFF52525B);
  static const grey700 = Color(0xFF3F3F46);
  static const grey800 = Color(0xFF27272A);
  static const grey900 = Color(0xFF18181B);

  // Accent
  static const red = Color(0xFFC8102E);
  static const redDeep = Color(0xFF9E0C24);
  static const redSoft = Color(0x1FC8102E); // ~12% for blobs and selected chips

  // Semantic
  static const ink = grey900;
  static const inkMuted = grey600; // 7.4:1 on white, AA for body
  static const line = grey200;
  static const success = Color(0xFF1F7A4D);
  static const error = redDeep;

  // Glass
  static const glassFill = Color(0xB3FFFFFF); // 70% white
  static const glassFillStrong = Color(0xD9FFFFFF); // 85% white
  static const glassBorder = Color(0x99FFFFFF);
  static const shadowTint = Color(0x1A18181B); // grey-tinted, never pure black

  /// Grey -> red: used only at moments of change.
  static const transformation = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [grey700, red],
  );
}
