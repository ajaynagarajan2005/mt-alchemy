import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/common/glass_panel.dart';
import '../widgets/common/gradient_backdrop.dart';
import '../widgets/layout/app_shell.dart';
import '../widgets/layout/section.dart';

/// Temporary page used while each screen is built phase by phase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      // The backdrop runs behind the glass nav so the bar has colour to blur.
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h1(context)),
                  const SizedBox(height: Space.lg),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: GlassPanel(
                      child: Text(
                        note ??
                            'This screen is planned for a later build phase.',
                        style: AppText.bodyMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
