import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';

/// Full page message (not found, not enrolled) with one action.
///
/// CONTAINER (card): the message sits in a GlassPanel over the backdrop.
class NoticePage extends StatelessWidget {
  const NoticePage({
    super.key,
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.h2(context)),
                        const SizedBox(height: Space.md),
                        Text(message, style: AppText.bodyMuted),
                        const SizedBox(height: Space.lg),
                        action,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
