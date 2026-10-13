import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/course_thumb.dart';
import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../state/learning_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import 'portal_widgets.dart';

/// Individual learner dashboard (Journey A "Course Dashboard"): stats,
/// courses assigned by an employer, courses in progress and completed.
class IndividualScreen extends StatelessWidget {
  const IndividualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final org = context.watch<AuthStore>().currentOrganisation;
    final learning = context.watch<LearningStore>();
    final catalog = context.watch<CatalogStore>();
    if (user == null) return const SizedBox.shrink();

    final all = [
      for (final e in learning.enrolments)
        if (catalog.courseById(e.courseId) != null)
          (e, catalog.courseById(e.courseId)!),
    ];
    final active = all.where((p) => !p.$1.isCompleteIn(p.$2)).toList();
    final done = all.where((p) => p.$1.isCompleteIn(p.$2)).toList();
    final waiting = [
      for (final a in learning.assigned)
        if (!learning.isEnrolled(a.courseId) &&
            catalog.courseById(a.courseId) != null)
          (a, catalog.courseById(a.courseId)!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Hello, ${user.firstName}',
          subtitle: org != null
              ? 'Learning with ${org.name}. Pick up where you left off.'
              : 'Pick up where you left off.',
        ),
        PortalGrid(
          expandedColumns: 3,
          mediumColumns: 3,
          compactColumns: 3,
          children: [
            StatTile(value: '${all.length}', label: 'Enrolled'),
            StatTile(value: '${done.length}', label: 'Completed'),
            StatTile(
              value: '${learning.certificates.length}',
              label: 'Certificates',
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        if (waiting.isNotEmpty) ...[
          Text('Assigned to you', style: AppText.h3),
          const SizedBox(height: Space.md),
          for (final (a, course) in waiting)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: _AssignedCard(assignment: a, course: course),
            ),
          const SizedBox(height: Space.lg),
        ],
        if (all.isEmpty && waiting.isEmpty)
          EmptyState(
            title: 'You have not enrolled yet',
            message: 'Open the course catalogue to pick a course from your learning pathway.',
            actionLabel: 'Open the course catalogue',
            onAction: () => context.go(Routes.myCourses),
          )
        else if (all.isNotEmpty) ...[
          Text('In progress', style: AppText.h3),
          const SizedBox(height: Space.md),
          if (active.isEmpty)
            Text('Nothing in progress right now.', style: AppText.bodyMuted)
          else
            for (var i = 0; i < active.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _EnrolmentCard(
                  enrolment: active[i].$1,
                  course: active[i].$2,
                  primary: i == 0,
                ),
              ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            Text('Completed', style: AppText.h3),
            const SizedBox(height: Space.md),
            for (final (e, course) in done)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _EnrolmentCard(
                  enrolment: e,
                  course: course,
                  primary: false,
                  certificateCode: learning.certificateFor(course.id)?.code,
                ),
              ),
          ],
        ],
        const SizedBox(height: Space.xl),
        const _AssessmentPrompt(),
        const SizedBox(height: Space.lg),
        ArrowLink(
          label: 'Add a course',
          onTap: () => context.go(Routes.myCourses),
        ),
      ],
    );
  }
}

class _AssignedCard extends StatefulWidget {
  const _AssignedCard({required this.assignment, required this.course});

  final AssignedCourse assignment;
  final Course course;

  @override
  State<_AssignedCard> createState() => _AssignedCardState();
}

class _AssignedCardState extends State<_AssignedCard> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final error = await context.read<LearningStore>().startAssigned(
      widget.assignment,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go(Routes.learn(widget.course.id));
  }

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      child: Row(
        children: [
          CourseThumb(courseId: widget.course.id, width: 88, height: 66),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.course.title, style: AppText.h4),
                Text(
                  '${widget.course.modules.length} lessons · assigned by your organisation',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          AlchemyButton(label: 'Start', loading: _busy, onPressed: _start),
        ],
      ),
    );
  }
}

class _EnrolmentCard extends StatelessWidget {
  const _EnrolmentCard({
    required this.enrolment,
    required this.course,
    required this.primary,
    this.certificateCode,
  });

  final Enrolment enrolment;
  final Course course;

  /// Only the first card in the view carries the red primary button.
  final bool primary;
  final String? certificateCode;

  @override
  Widget build(BuildContext context) {
    final complete = enrolment.isCompleteIn(course);
    final done = course.modules
        .where((m) => enrolment.completedModuleIds.contains(m.id))
        .length;
    final status = complete
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
          '${course.level.label}  |  $done of ${course.modules.length} lessons  |  '
          '${(enrolment.progressIn(course) * 100).round()}%',
          style: AppText.small,
        ),
        const SizedBox(height: Space.sm),
        ProgressBar(value: enrolment.progressIn(course), complete: complete),
      ],
    );

    final buttons = Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        if (certificateCode != null)
          AlchemyButton(
            label: 'Certificate',
            icon: HugeIcons.strokeRoundedAward01,
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(Routes.certificate(certificateCode!)),
          ),
        AlchemyButton(
          label: complete ? 'Review' : 'Continue',
          variant: primary && !complete
              ? ButtonVariant.primary
              : ButtonVariant.secondary,
          onPressed: () => context.go(Routes.learn(course.id)),
        ),
      ],
    );

    return PortalCard(
      padding: const EdgeInsets.all(Space.lg),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourseThumb.banner(
                  courseId: course.id,
                  height: 120,
                  radius: Radii.smallAll,
                ),
                const SizedBox(height: Space.md),
                info,
                const SizedBox(height: Space.md),
                buttons,
              ],
            )
          : Row(
              children: [
                CourseThumb(courseId: course.id, width: 120, height: 84),
                const SizedBox(width: Space.lg),
                Expanded(child: info),
                const SizedBox(width: Space.lg),
                buttons,
              ],
            ),
    );
  }
}

class _AssessmentPrompt extends StatelessWidget {
  const _AssessmentPrompt();

  @override
  Widget build(BuildContext context) {
    // CONTAINER (decoration): soft red card inviting the EQ self-assessment.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: Radii.cardAll,
      ),
      child: Wrap(
        spacing: Space.lg,
        runSpacing: Space.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How emotionally intelligent are you today?',
                  style: AppText.h4,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Take the five-minute EQ self-assessment and get a course '
                  'recommendation matched to your results.',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          AlchemyButton(
            label: 'Take the assessment',
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(Routes.assessment),
          ),
        ],
      ),
    );
  }
}
