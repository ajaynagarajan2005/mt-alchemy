import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/eligibility.dart';
import '../../data/mock/services.dart';
import '../../data/models/course.dart';
import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../state/catalog_store.dart';
import '../../state/learning_store.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/card_image.dart';
import '../../widgets/common/course_card.dart' show gbp;
import '../../widgets/common/reveal.dart';
import 'portal_widgets.dart';

/// "Add a course" inside the portal.
///
/// Learners see the courses their pathway allows (career stage x interest
/// areas) and can buy any of them; the rest are listed as locked with the
/// reason. Employers see every course and buy seats for their team.
class CourseCatalogueScreen extends StatefulWidget {
  const CourseCatalogueScreen({super.key});

  @override
  State<CourseCatalogueScreen> createState() => _CourseCatalogueScreenState();
}

class _CourseCatalogueScreenState extends State<CourseCatalogueScreen> {
  bool _showLocked = false;
  String? _area;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final catalog = context.watch<CatalogStore>();
    if (user == null) return const SizedBox.shrink();
    final employer = user.role == UserRole.employer;

    final all = catalog.courses
        .where((c) => _area == null || c.serviceSlug == _area)
        .toList();
    final open = employer ? all : all.where(user.canEnrol).toList();
    final locked = employer
        ? <Course>[]
        : all.where((c) => !user.canEnrol(c)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: employer ? 'Buy courses for your team' : 'Course catalogue',
          subtitle: employer
              ? 'Each seat lets one employee take a course. Buy seats, then assign them.'
              : 'Courses in your learning pathway. Pick any of them to start.',
        ),
        if (!employer) _PathwayBanner(user: user),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            ChoiceChip(
              label: const Text('All areas'),
              selected: _area == null,
              selectedColor: AppColors.redSoft,
              onSelected: (_) => setState(() => _area = null),
            ),
            for (final s in services)
              if (employer ||
                  user.interests.isEmpty ||
                  user.interests.contains(s.slug))
                ChoiceChip(
                  label: Text(s.title),
                  selected: _area == s.slug,
                  selectedColor: AppColors.redSoft,
                  onSelected: (_) => setState(() => _area = s.slug),
                ),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (open.isEmpty)
          const EmptyState(
            title: 'No courses here yet',
            message:
                'No course matches this area for your career stage. Try another '
                'area, or widen your interests in your profile.',
          )
        else
          PortalGrid(
            compactColumns: 1,
            mediumColumns: 2,
            expandedColumns: 3,
            children: [
              for (var i = 0; i < open.length; i++)
                Reveal(
                  delay: Duration(milliseconds: 60 * (i % 6)),
                  child: _CatalogueCard(course: open[i], employer: employer),
                ),
            ],
          ),
        if (locked.isNotEmpty) ...[
          const SizedBox(height: Space.xl),
          TextButton.icon(
            onPressed: () => setState(() => _showLocked = !_showLocked),
            icon: Icon(_showLocked ? Icons.expand_less : Icons.expand_more),
            label: Text(
              '${locked.length} course${locked.length == 1 ? ' is' : 's are'} '
              'outside your pathway',
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          ),
          if (_showLocked) ...[
            const SizedBox(height: Space.md),
            PortalGrid(
              compactColumns: 1,
              mediumColumns: 2,
              expandedColumns: 3,
              children: [
                for (final c in locked)
                  _CatalogueCard(
                    course: c,
                    employer: false,
                    lockedReason: eligibilityMessage(
                      user.eligibilityFor(c),
                      user,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _PathwayBanner extends StatelessWidget {
  const _PathwayBanner({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final areas = [
      for (final s in services)
        if (user.interests.contains(s.slug)) s.title,
    ];
    // CONTAINER (decoration): soft red pathway summary.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: Radii.cardAll,
      ),
      child: Wrap(
        spacing: Space.lg,
        runSpacing: Space.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppIcon(
            HugeIcons.strokeRoundedRoute01,
            size: 28,
            color: AppColors.red,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.stage == null
                      ? 'Set your learning pathway'
                      : 'Your pathway: ${user.stage!.label}',
                  style: AppText.h4,
                ),
                const SizedBox(height: 2),
                Text(
                  user.stage == null
                      ? 'Choose your career stage and interests to see the courses meant for you.'
                      : '${user.stage!.blurb} in ${areas.isEmpty ? 'every area' : areas.join(', ')}.',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(Routes.myProfile),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Edit pathway'),
          ),
        ],
      ),
    );
  }
}

class _CatalogueCard extends StatefulWidget {
  const _CatalogueCard({
    required this.course,
    required this.employer,
    this.lockedReason,
  });

  final Course course;
  final bool employer;
  final String? lockedReason;

  @override
  State<_CatalogueCard> createState() => _CatalogueCardState();
}

class _CatalogueCardState extends State<_CatalogueCard> {
  int _seats = 5;

  Course get course => widget.course;

  void _buy() {
    final cart = context.read<CartStore>();
    if (widget.employer) {
      cart.addSeats(course, _seats);
    } else if (!cart.containsCourse(course.id)) {
      cart.addCourse(course);
    }
    context.go(Routes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningStore>();
    final enrolled = learning.isEnrolled(course.id);
    final locked = widget.lockedReason != null;
    final seatsOwned =
        context.watch<AuthStore>().currentOrganisation?.seatsFor(course.id) ??
        0;

    final Widget action;
    if (locked) {
      action = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.grey600),
          const SizedBox(width: Space.xs),
          Expanded(child: Text(widget.lockedReason!, style: AppText.small)),
        ],
      );
    } else if (widget.employer) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seatsOwned > 0)
            Text('$seatsOwned unassigned seats', style: AppText.small),
          Row(
            children: [
              IconButton(
                tooltip: 'Fewer seats',
                onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_seats seats', style: AppText.label),
              IconButton(
                tooltip: 'More seats',
                onPressed: () => setState(() => _seats++),
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              AlchemyButton(
                label: 'Buy ${gbp.format(course.price * _seats)}',
                onPressed: _buy,
              ),
            ],
          ),
        ],
      );
    } else if (enrolled) {
      action = AlchemyButton(
        label: 'Continue learning',
        variant: ButtonVariant.secondary,
        expand: true,
        onPressed: () => context.go(Routes.learn(course.id)),
      );
    } else {
      action = Row(
        children: [
          Expanded(
            child: AlchemyButton(
              label: 'Buy ${gbp.format(course.price)}',
              onPressed: _buy,
            ),
          ),
          const SizedBox(width: Space.xs),
          TextButton(
            onPressed: () => context.go(Routes.course(course.id)),
            child: const Text('Details'),
          ),
        ],
      );
    }

    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: AnimatedCard(
        onTap: locked ? null : () => context.go(Routes.course(course.id)),
        // CONTAINER (card): photo, level, title and the buy action.
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Radii.cardAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CardImage(
                  seed: course.id,
                  src: course.imageUrl ?? bundledImage('course-${course.id}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.level.label}  ·  ${course.modules.length} lessons  ·  ${course.totalMinutes} min',
                      style: AppText.small,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(course.title, style: AppText.h4, maxLines: 2),
                    const SizedBox(height: Space.xxs),
                    Text(
                      course.summary,
                      style: AppText.small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.md),
                    action,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
