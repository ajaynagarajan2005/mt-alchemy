import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/mock/courses.dart';
import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/course_card.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// Featured courses as a horizontal, snapping carousel.
class CourseRow extends StatelessWidget {
  const CourseRow({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            child: Text('Learn at your own pace', style: AppText.h2(context)),
          ),
          const SizedBox(height: Space.md),
          Reveal(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'Short online courses built from our live programmes. Start alone, or '
                'enrol your whole team through the employer portal.',
                style: AppText.lead,
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          Reveal(
            child: SizedBox(
              height: 360,
              child: CarouselView(
                itemExtent: compact ? 290 : 340,
                shrinkExtent: compact ? 290 : 340,
                itemSnapping: true,
                enableSplash: false,
                padding: const EdgeInsets.only(right: Space.md),
                backgroundColor: AppColors.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: Radii.cardAll,
                ),
                onTap: (i) => context.go(Routes.course(courses[i].id)),
                children: [for (final c in courses) CourseCard(course: c)],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          AlchemyButton(
            label: 'Browse all courses',
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(Routes.upskilling),
          ),
        ],
      ),
    );
  }
}
