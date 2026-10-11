import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/learning_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import 'portal_widgets.dart';

/// Individual learner dashboard: courses in progress and completed.
class IndividualScreen extends StatelessWidget {
  const IndividualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final learning = context.watch<LearningStore>();
    if (user == null) return const SizedBox.shrink();

    final all = learning.enrolmentsFor(user.id);
    final active = all.where((e) => !e.isComplete).toList();
    final done = all.where((e) => e.isComplete).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Hello, ${user.firstName}',
          subtitle: 'Pick up where you left off.',
        ),
        if (all.isEmpty)
          EmptyState(
            title: 'You have not enrolled yet',
            message: 'Browse the learning catalogue and enrol in a course to see it here.',
            actionLabel: 'Browse courses',
            onAction: () => context.go(Routes.upskilling),
          )
        else ...[
          Text('In progress', style: AppText.h3),
          const SizedBox(height: Space.md),
          if (active.isEmpty)
            Text('Nothing in progress right now.', style: AppText.bodyMuted)
          else
            for (var i = 0; i < active.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _EnrolmentCard(enrolment: active[i], primary: i == 0),
              ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            Text('Completed', style: AppText.h3),
            const SizedBox(height: Space.md),
            for (final e in done)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _EnrolmentCard(enrolment: e, primary: false),
              ),
          ],
          const SizedBox(height: Space.lg),
          ArrowLink(
            label: 'Browse more courses',
            onTap: () => context.go(Routes.upskilling),
          ),
        ],
      ],
    );
  }
}

class _EnrolmentCard extends StatelessWidget {
  const _EnrolmentCard({required this.enrolment, required this.primary});

  final Enrolment enrolment;

  /// Only the first card in the view carries the red primary button.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final course = enrolment.course;
    final done = enrolment.completedModuleIds.length;
    final status = enrolment.isComplete
        ? ProgressStatus.complete
        : done == 0
        ? ProgressStatus.notStarted
        : ProgressStatus.inProgress;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(course.title, style: AppText.h4)),
            const SizedBox(width: Space.sm),
            StatusChip(status: status),
          ],
        ),
        const SizedBox(height: Space.xxs),
        Text(
          '${course.level.label}  |  $done of ${course.modules.length} modules',
          style: AppText.small,
        ),
        const SizedBox(height: Space.sm),
        ProgressBar(value: enrolment.progress, complete: enrolment.isComplete),
      ],
    );

    final button = AlchemyButton(
      label: enrolment.isComplete ? 'Review' : 'Continue',
      variant: primary && !enrolment.isComplete
          ? ButtonVariant.primary
          : ButtonVariant.secondary,
      expand: context.isCompact,
      onPressed: () => context.go(Routes.learn(course.id)),
    );

    return PortalCard(
      padding: const EdgeInsets.all(Space.lg),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: Space.md),
                button,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: Space.lg),
                button,
              ],
            ),
    );
  }
}
