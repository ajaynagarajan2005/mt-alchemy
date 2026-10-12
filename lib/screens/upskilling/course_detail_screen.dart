import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/services.dart';
import '../../data/models/course.dart';
import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../state/catalog_store.dart';
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
import '../../widgets/common/reviews_section.dart';
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
    final course = context.watch<CatalogStore>().courseById(courseId);
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
        Section(
          child: ReviewsSection(
            targetId: course.id,
            title: 'What learners say',
            canReview: (c) => c.read<LearningStore>().isEnrolled(course.id),
            cannotReviewMessage: 'Enrol on this course to leave a review.',
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
                Padding(
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
        Text('Lessons', style: AppText.h2(context)),
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
      decoration: BoxDecoration(
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
          Text(
            '${module.type.label} · ${module.minutes} min',
            style: AppText.small,
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatefulWidget {
  const _Summary({required this.course});
  final Course course;

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  int _seats = 5;
  bool _busy = false;

  Course get course => widget.course;

  /// Journey A: the course goes into the cart and straight to payment.
  void _buy() {
    final cart = context.read<CartStore>();
    if (!cart.containsCourse(course.id)) cart.addCourse(course);
    context.go(Routes.checkout);
  }

  /// Journey D: an employer buys seats to assign later.
  void _buySeats() {
    context.read<CartStore>().addSeats(course, _seats);
    context.go(Routes.checkout);
  }

  Future<void> _startAssigned(AssignedCourse a) async {
    setState(() => _busy = true);
    final error = await context.read<LearningStore>().startAssigned(a);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go(Routes.learn(course.id));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final learning = context.watch<LearningStore>();
    final enrolled = learning.isEnrolled(course.id);
    final assigned = learning.assignmentFor(course.id);

    final Widget cta;
    if (user == null) {
      cta = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlchemyButton(
            label: 'Buy course',
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
    } else if (user.role == UserRole.employer) {
      final owned = context.watch<AuthStore>().currentOrganisation?.seatsFor(
            course.id,
          ) ??
          0;
      cta = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buy seats for your team', style: AppText.h4),
          const SizedBox(height: Space.xxs),
          Text(
            owned > 0
                ? 'You have $owned unassigned seat${owned == 1 ? '' : 's'}.'
                : 'Each seat lets one employee take this course.',
            style: AppText.small,
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Fewer seats',
                onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                child: Text('$_seats', style: AppText.h3),
              ),
              IconButton.outlined(
                tooltip: 'More seats',
                onPressed: () => setState(() => _seats++),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              Text(gbp.format(course.price * _seats), style: AppText.h4),
            ],
          ),
          const SizedBox(height: Space.md),
          AlchemyButton(label: 'Buy seats', expand: true, onPressed: _buySeats),
        ],
      );
    } else if (user.role.isStaff) {
      cta = AlchemyButton(
        label: 'Edit this course',
        expand: true,
        variant: ButtonVariant.secondary,
        onPressed: () => context.go(Routes.editCourse(course.id)),
      );
    } else if (enrolled) {
      cta = AlchemyButton(
        label: 'Continue learning',
        expand: true,
        onPressed: () => context.go(Routes.learn(course.id)),
      );
    } else if (assigned != null) {
      cta = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your organisation has assigned you this course.',
            style: AppText.small,
          ),
          const SizedBox(height: Space.sm),
          AlchemyButton(
            label: 'Start course',
            expand: true,
            loading: _busy,
            onPressed: () => _startAssigned(assigned),
          ),
        ],
      );
    } else {
      cta = AlchemyButton(label: 'Buy course', expand: true, onPressed: _buy);
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
            '${course.modules.length} lessons, ${course.totalMinutes} minutes in total',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: Space.lg),
          cta,
        ],
      ),
    );
  }
}
