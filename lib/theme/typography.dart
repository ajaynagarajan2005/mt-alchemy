import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'breakpoints.dart';
import 'colors.dart';

/// Fraunces for headlines (named in the brand brief), Manrope for body and UI.
/// Emphasis inside a headline uses Fraunces italic, never another family.
abstract final class AppText {
  static TextStyle _serif(
    double size, {
    double height = 1.1,
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.fraunces(
    fontSize: size,
    height: height,
    fontWeight: w,
    letterSpacing: -0.02 * size,
    color: AppColors.ink,
  );

  static TextStyle _sans(
    double size, {
    double height = 1.55,
    FontWeight w = FontWeight.w400,
    Color color = AppColors.ink,
  }) => GoogleFonts.manrope(
    fontSize: size,
    height: height,
    fontWeight: w,
    color: color,
  );

  /// Hero headline. Scales with breakpoint so it stays within 2 lines.
  static TextStyle display(BuildContext context) =>
      switch (context.screenSize) {
        ScreenSize.compact => _serif(40, height: 1.1),
        ScreenSize.medium => _serif(56, height: 1.08),
        ScreenSize.expanded => _serif(72, height: 1.05),
      };

  static TextStyle h1(BuildContext context) => switch (context.screenSize) {
    ScreenSize.compact => _serif(34),
    ScreenSize.medium => _serif(44),
    ScreenSize.expanded => _serif(52),
  };

  static TextStyle h2(BuildContext context) => switch (context.screenSize) {
    ScreenSize.compact => _serif(28, height: 1.15),
    ScreenSize.medium => _serif(34, height: 1.15),
    ScreenSize.expanded => _serif(40, height: 1.12),
  };

  static TextStyle get h3 => _serif(24, height: 1.2, w: FontWeight.w500);
  static TextStyle get h4 => _sans(18, height: 1.35, w: FontWeight.w700);

  static TextStyle get lead =>
      _sans(19, height: 1.55, color: AppColors.inkMuted);
  static TextStyle get body => _sans(16);
  static TextStyle get bodyMuted => _sans(16, color: AppColors.inkMuted);
  static TextStyle get small =>
      _sans(14, height: 1.45, color: AppColors.inkMuted);
  static TextStyle get label => _sans(14, height: 1.2, w: FontWeight.w600);
  static TextStyle get button => _sans(15, height: 1.2, w: FontWeight.w700);
  static TextStyle get nav => _sans(15, height: 1.2, w: FontWeight.w600);

  /// Small uppercase label. Rationed: at most one per three sections.
  static TextStyle get eyebrow => _sans(
    12,
    height: 1.2,
    w: FontWeight.w700,
    color: AppColors.red,
  ).copyWith(letterSpacing: 1.6);

  /// Brand wordmark.
  static TextStyle get wordmark => _serif(24, height: 1, w: FontWeight.w500);
}
