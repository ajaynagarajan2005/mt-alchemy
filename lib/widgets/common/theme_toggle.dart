import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/theme_controller.dart';
import '../../theme/colors.dart';
import 'app_icon.dart';

/// Icon button that flips the whole page between light and dark.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      // Read the live brightness at press time, not the one captured when
      // this button was built, so repeated taps always flip.
      onPressed: () {
        final theme = context.read<ThemeController>();
        theme.toggle(theme.effective(MediaQuery.platformBrightnessOf(context)));
      },
      icon: AppIcon(
        dark ? HugeIcons.strokeRoundedSun01 : HugeIcons.strokeRoundedMoon02,
        size: 22,
        color: AppColors.ink,
      ),
    );
  }
}
