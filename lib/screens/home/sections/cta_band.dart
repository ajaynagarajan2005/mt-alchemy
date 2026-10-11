import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../router/routes.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// Closing call to action. Shares the dark ground of the footer below it,
/// so together they read as one closing block.
class CtaBand extends StatelessWidget {
  const CtaBand({super.key});

  @override
  Widget build(BuildContext context) {
    return Section(
      color: AppColors.grey900,
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Ready to shift how your team works?',
                style: AppText.h1(context).copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: Space.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Tell us what is happening in your organisation and we will suggest where to start.',
                style: AppText.lead.copyWith(color: AppColors.grey300),
              ),
            ),
            const SizedBox(height: Space.xl),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                AlchemyButton(
                  label: 'Book a call',
                  onPressed: () => context.go(Routes.contact),
                ),
                AlchemyButton(
                  label: 'Register your organisation',
                  variant: ButtonVariant.inverse,
                  onPressed: () =>
                      context.go('${Routes.register}?type=organisation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
