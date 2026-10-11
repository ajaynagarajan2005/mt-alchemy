import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

/// Light theme. Material widgets are restyled from the tokens so nothing
/// ships in the stock Material look.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.red,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.red,
          onPrimary: AppColors.surface,
          secondary: AppColors.grey800,
          onSecondary: AppColors.surface,
          surface: AppColors.white,
          onSurface: AppColors.ink,
          error: AppColors.error,
          outline: AppColors.grey300,
          outlineVariant: AppColors.line,
        );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final inputBorder = OutlineInputBorder(
      borderRadius: Radii.inputAll,
      borderSide: const BorderSide(color: AppColors.grey300),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.white,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.grey500),
        errorStyle: AppText.small.copyWith(color: AppColors.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.red,
        selectionColor: AppColors.redSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey900,
        contentTextStyle: AppText.body.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.inputAll),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(side: BorderSide(color: AppColors.grey300)),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.redSoft,
        labelStyle: AppText.label,
        showCheckmark: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.red,
        linearTrackColor: AppColors.grey200,
      ),
      focusColor: AppColors.redSoft,
      hoverColor: AppColors.grey100,
      splashFactory: NoSplash.splashFactory,
    );
  }
}
