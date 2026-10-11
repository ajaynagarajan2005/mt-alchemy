import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/mock/articles.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// A single, large quote. Sample content for the prototype.
class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = testimonials.first;
    return Section(
      color: AppColors.grey50,
      child: Reveal(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                HugeIcons.strokeRoundedQuoteDown,
                size: 44,
                color: AppColors.red,
              ),
              const SizedBox(height: Space.lg),
              Text('“${t.quote}”', style: AppText.h2(context)),
              const SizedBox(height: Space.xl),
              Text(t.name, style: AppText.label),
              const SizedBox(height: Space.xxs),
              Text(t.role, style: AppText.small),
            ],
          ),
        ),
      ),
    );
  }
}
