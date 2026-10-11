import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/mock/articles.dart';
import '../../data/mock/courses.dart';
import '../../data/mock/services.dart';
import '../../data/models/course.dart';
import '../../data/models/service.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/course_card.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../about/content_shared.dart';
import '../../widgets/common/tappable.dart';

/// One service: summary, outcomes, formats, related courses, a quote.
///
/// SCAFFOLD: AppShell supplies Scaffold + AppBar; this is the page body.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final service = serviceBySlug(slug);
    if (service == null) {
      return const NotFoundView(
        title: 'We could not find that service',
        backLabel: 'All services',
        backTo: Routes.services,
      );
    }
    final index = services.indexOf(service);
    final related = [
      for (final c in courses)
        if (c.serviceSlug == service.slug) c,
    ];
    return PageScroll(
      underNav: true,
      children: [
        _Hero(service: service),
        if (related.isNotEmpty) _RelatedCourses(courses: related),
        _Quote(index: index),
        _OtherServices(current: service),
        const ClosingCta(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: staggerIn(context, [
        ArrowLink(
          label: 'All services',
          color: AppColors.inkMuted,
          onTap: () => context.go(Routes.services),
        ),
        const SizedBox(height: Space.xl),
        Text(service.title, style: AppText.h1(context)),
        const SizedBox(height: Space.lg),
        Text(service.summary, style: AppText.lead),
        const SizedBox(height: Space.xl),
        // Formats as pill chips.
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [for (final f in service.formats) _Pill(label: f)],
        ),
      ]),
    );

    final outcomes = GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What changes', style: AppText.h3),
          const SizedBox(height: Space.md),
          for (final o in service.outcomes)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: AppIcon(
                      HugeIcons.strokeRoundedTick02,
                      size: 18,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(o, style: AppText.body)),
                ],
              ),
            ),
        ],
      ),
    );

    return GradientBackdrop(
      child: Padding(
        padding: EdgeInsets.only(top: pageHeaderTop(context)),
        child: Section(
          top: false,
          child: SplitRow(
            flexA: 6,
            flexB: 5,
            gap: Space.xxxl,
            stackBelow: 900,
            crossAxisAlignment: CrossAxisAlignment.start,
            a: left,
            b: Reveal(delay: Motion.slow, child: outcomes),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (decoration): pill-shaped chip with a hairline border.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.pillAll,
        border: Border.all(color: AppColors.grey300),
      ),
      child: Text(label, style: AppText.label),
    );
  }
}

class _RelatedCourses extends StatelessWidget {
  const _RelatedCourses({required this.courses});
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Section(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Learn it online', style: AppText.h2(context))),
          const SizedBox(height: Space.sm),
          Reveal(
            child: Text(
              'Self-paced courses that pair with this work.',
              style: AppText.lead,
            ),
          ),
          const SizedBox(height: Space.xl),
          LayoutBuilder(
            builder: (context, c) {
              final w = compact ? c.maxWidth : 340.0;
              return Wrap(
                spacing: Space.md,
                runSpacing: Space.md,
                children: [
                  for (var i = 0; i < courses.length; i++)
                    Reveal(
                      delay: Motion.stagger * i,
                      child: SizedBox(
                        width: w,
                        height: 360,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Tappable(
                            radius: Radii.cardAll,
                            onTap: () =>
                                context.go(Routes.course(courses[i].id)),
                            child: CourseCard(course: courses[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = testimonials[index % testimonials.length];
    return Section(
      child: Reveal(
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('“${t.quote}”', style: AppText.h2(context)),
                const SizedBox(height: Space.lg),
                Text(t.name, style: AppText.label),
                const SizedBox(height: Space.xxs),
                Text(t.role, style: AppText.small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtherServices extends StatelessWidget {
  const _OtherServices({required this.current});
  final Service current;

  @override
  Widget build(BuildContext context) {
    final others = [
      for (final s in services)
        if (s.slug != current.slug) s,
    ];
    return Section(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Other services', style: AppText.h3)),
          const SizedBox(height: Space.md),
          for (final s in others) ...[const Divider(), _OtherRow(service: s)],
          const Divider(),
        ],
      ),
    );
  }
}

class _OtherRow extends StatefulWidget {
  const _OtherRow({required this.service});
  final Service service;

  @override
  State<_OtherRow> createState() => _OtherRowState();
}

class _OtherRowState extends State<_OtherRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? AppColors.red : AppColors.ink;
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Tappable(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(Routes.service(widget.service.slug)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.service.title,
                    style: AppText.h3.copyWith(color: color),
                  ),
                ),
                AppIcon(HugeIcons.strokeRoundedArrowUpRight01, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
