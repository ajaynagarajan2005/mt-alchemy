import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'radii.dart';
import 'spacing.dart';
import 'typography.dart';

/// Light and dark themes. Material widgets are restyled from the tokens so nothing
/// ships in the stock Material look.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  /// Same structure, built from the dark palette (call after AppColors.apply).
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.red,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.accentFill,
          onPrimary: AppColors.onAccent,
          secondary: AppColors.grey800,
          onSecondary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.ink,
          error: AppColors.error,
          outline: AppColors.grey300,
          outlineVariant: AppColors.line,
        );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final inputBorder = OutlineInputBorder(
      borderRadius: Radii.inputAll,
      borderSide: BorderSide(color: AppColors.grey300),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.white,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.fieldInset,
          vertical: 14,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.grey500),
        errorStyle: AppText.small.copyWith(color: AppColors.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: AppColors.red, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.red,
        selectionColor: AppColors.redSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: AppText.body.copyWith(color: AppColors.onInverse),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.inputAll),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: StadiumBorder(side: BorderSide(color: AppColors.grey300)),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.redSoft,
        labelStyle: AppText.label,
        showCheckmark: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.red,
        linearTrackColor: AppColors.grey200,
      ),
      focusColor: AppColors.redSoft,
      hoverColor: AppColors.grey100,
      splashFactory: NoSplash.splashFactory,
    );
  }
}
