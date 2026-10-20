import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/theme_controller.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Menu button that makes all text larger. The choice is saved.
class TextSizeButton extends StatelessWidget {
  const TextSizeButton({super.key});

  static const _labels = ['Normal', 'Large', 'Extra large'];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return PopupMenuButton<double>(
      tooltip: 'Text size',
      initialValue: theme.textScale,
      color: AppColors.surface,
      onSelected: theme.setTextScale,
      icon: Icon(Icons.text_fields, size: 22, color: AppColors.ink),
      itemBuilder: (_) => [
        for (var i = 0; i < ThemeController.textScales.length; i++)
          CheckedPopupMenuItem(
            value: ThemeController.textScales[i],
            checked: ThemeController.textScales[i] == theme.textScale,
            child: Text(
              '${_labels[i]} text',
              style: AppText.body.copyWith(
                fontSize: 14.0 * ThemeController.textScales[i],
              ),
            ),
          ),
      ],
    );
  }
}
