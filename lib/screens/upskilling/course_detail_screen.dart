import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/courses.dart';
import '../../data/mock/services.dart';
import '../../data/models/course.dart';
import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/learning_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/course_card.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import 'notice_page.dart';

/// Course detail: hero, outcomes, modules and an enrol summary.
///
/// SCAFFOLD note: lives inside the AppShell Scaffold (AppBar nav).
/// CONTAINER (decoration): InkArt hero is clipped by a rounded Container;
/// the enrol summary is a GlassPanel; module rows are Containers with a
/// hairline divider.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final course = courseById(courseId);
    if (course == null) {
      return NoticePage(
        title: 'We could not find that course',
        message: 'It may have moved or the link may be wrong.',
        action: AlchemyButton(
          label: 'Browse all courses',
          onPressed: () => context.go(Routes.upskilling),
        ),
      );
    }

    final expanded = context.isExpanded;
    final main = _Main(course: course);
    final summary = _Summary(course: course);

    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: expanded
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: main),
                        const SizedBox(width: Space.xxl),
                        // Sticky-ish: the summary sits at the top of its own column.
                        Expanded(flex: 4, child: Reveal(child: summary)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        main,
                        const SizedBox(height: Space.xl),
                        // Medium fallback: summary caps its width; compact: full width.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: summary,
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

class _Main extends StatelessWidget {
  const _Main({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final service = services
        .where((s) => s.slug == course.serviceSlug)
        .firstOrNull;
    final compact = context.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArrowLink(
          label: 'All courses',
          onTap: () => context.go(Routes.upskilling),
        ),
        const SizedBox(height: Space.lg),
        // CONTAINER (decoration): rounded clip for the artwork hero.
        Container(
          height: compact ? 180 : 280,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: Radii.cardAll),
          child: InkArt(seed: course.id),
        ),
        const SizedBox(height: Space.lg),
        if (service != null) Text(service.title, style: AppText.eyebrow),
        const SizedBox(height: Space.xs),
        Text(course.title, style: AppText.h1(context)),
        const SizedBox(height: Space.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(course.summary, style: AppText.lead),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.lg,
          runSpacing: Space.xs,
          children: [
            _Fact(label: 'Level', value: course.level.label),
            _Fact(label: 'Trainer', value: course.trainer),
            _Fact(label: 'Duration', value: '${course.totalMinutes} min'),
            _Fact(label: 'Price', value: gbp.format(course.price)),
          ],
        ),
        SizedBox(height: compact ? Space.xl : Space.xxl),
        Text('What you will learn', style: AppText.h2(context)),
        const SizedBox(height: Space.md),
        for (final o in course.outcomes)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: AppIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 20,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(o, style: AppText.body)),
              ],
            ),
          ),
        SizedBox(height: compact ? Space.xl : Space.xxl),
        Text('Modules', style: AppText.h2(context)),
        const SizedBox(height: Space.md),
        for (var i = 0; i < course.modules.length; i++)
          _ModuleRow(index: i + 1, module: course.modules[i]),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppText.small),
      const SizedBox(height: 2),
      Text(value, style: AppText.h4),
    ],
  );
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.index, required this.module});
  final int index;
  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (grouping): one module row with a hairline divider beneath.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AppText.h3.copyWith(color: AppColors.grey400),
            ),
          ),
          Expanded(child: Text(module.title, style: AppText.body)),
          const SizedBox(width: Space.md),
          Text('${module.minutes} min', style: AppText.small),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.course});
  final Course course;

  void _enrol(BuildContext context, AppUser user) {
    context.read<LearningStore>().enrol(user.id, course.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are enrolled in ${course.title}')),
    );
    context.go(Routes.learn(course.id));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final learning = context.watch<LearningStore>();
    final enrolled = user != null && learning.isEnrolled(user.id, course.id);

    final Widget cta;
    if (user == null) {
      cta = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlchemyButton(
            label: 'Enrol',
            expand: true,
            onPressed: () => context.go(
              Uri(
                path: Routes.login,
                queryParameters: {'from': Routes.course(course.id)},
              ).toString(),
            ),
          ),
          const SizedBox(height: Space.md),
          Text('New here?', style: AppText.small),
          const SizedBox(height: Space.xxs),
          ArrowLink(
            label: 'Create an account',
            onTap: () => context.go(Routes.register),
          ),
        ],
      );
    } else if (user.role != UserRole.individual) {
      cta = Text(
        'Courses are assigned through the employer portal, so you do not '
        'enrol yourself here.',
        style: AppText.bodyMuted,
      );
    } else if (enrolled) {
      cta = AlchemyButton(
        label: 'Continue learning',
        expand: true,
        onPressed: () => context.go(Routes.learn(course.id)),
      );
    } else {
      cta = AlchemyButton(
        label: 'Enrol',
        expand: true,
        onPressed: () => _enrol(context, user),
      );
    }

    // CONTAINER (card): the one glass panel in view holds the price and CTA.
    return GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gbp.format(course.price), style: AppText.h2(context)),
          const SizedBox(height: Space.xs),
          Text(
            '${course.modules.length} modules, ${course.totalMinutes} minutes in total',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: Space.lg),
          cta,
        ],
      ),
    );
  }
}
