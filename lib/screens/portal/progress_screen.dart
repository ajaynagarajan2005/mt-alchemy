import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/course_thumb.dart';
import '../../state/catalog_store.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/labeled_field.dart';
import 'portal_widgets.dart';

/// Employer: progress per assignment, filterable by course.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _all = '';
  String _filter = _all;

  @override
  Widget build(BuildContext context) {
    final org = context.watch<AuthStore>().currentOrganisation;
    final store = context.watch<OrgStore>();
    if (org == null) return const SizedBox.shrink();

    final all = store.assignments(org.id);
    if (all.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortalHeader(title: 'Progress'),
          EmptyState(
            title: 'Nothing to track yet',
            message: 'Assign a course to your team and their progress will appear here.',
            actionLabel: 'Assign a course',
            onAction: () => context.go(Routes.employerAssign),
          ),
        ],
      );
    }

    final summaries = store.courseSummaries(org.id);
    final rows = all.where((a) => _filter == _all || a.courseId == _filter);
    final list = rows.toList()
      ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Progress',
          subtitle: 'See how each person is getting on.',
        ),
        PortalGrid(
          compactColumns: 1,
          mediumColumns: 2,
          expandedColumns: 3,
          children: [
            for (final s in summaries)
              PortalCard(
                padding: EdgeInsets.zero,
                // CONTAINER (card): photo banner above the course totals.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CourseThumb.banner(
                      courseId: s.courseId,
                      height: 100,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context
                                    .read<CatalogStore>()
                                    .courseById(s.courseId)
                                    ?.title ??
                                s.courseId,
                            style: AppText.label,
                          ),
                          const SizedBox(height: Space.xxs),
                          Text(
                            '${s.completed} of ${s.assigned} complete  |  ${(s.averageProgress * 100).round()}% average',
                            style: AppText.small,
                          ),
                          const SizedBox(height: Space.sm),
                          ProgressBar(
                            value: s.averageProgress,
                            complete: s.completed == s.assigned,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        SizedBox(
          width: context.isCompact ? double.infinity : 360,
          child: LabeledDropdown<String>(
            label: 'Filter by course',
            value: _filter,
            items: [
              const DropdownMenuItem(value: _all, child: Text('All courses')),
              for (final s in summaries)
                DropdownMenuItem(
                  value: s.courseId,
                  child: Text(
                    context
                            .read<CatalogStore>()
                            .courseById(s.courseId)
                            ?.title ??
                        s.courseId,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _filter = v ?? _all),
          ),
        ),
        const SizedBox(height: Space.lg),
        PortalCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!context.isCompact) ...[
                _Row(
                  employee: 'Employee',
                  course: 'Course',
                  date: 'Assigned',
                  bar: Text('Progress', style: AppText.small),
                  status: Text('Status', style: AppText.small),
                  header: true,
                ),
                const Divider(),
              ],
              for (var i = 0; i < list.length; i++) ...[
                _Row(
                  courseId: list[i].courseId,
                  employee:
                      store.employeeById(org.id, list[i].employeeId)?.name ??
                      '',
                  course:
                      context
                          .read<CatalogStore>()
                          .courseById(list[i].courseId)
                          ?.title ??
                      '',
                  date: formatDate(list[i].assignedAt),
                  bar: Row(
                    children: [
                      Expanded(
                        child: ProgressBar(
                          value: list[i].progress,
                          complete: list[i].status == ProgressStatus.complete,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(list[i].progress * 100).round()}%',
                          style: AppText.small,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  status: StatusChip(status: list[i].status),
                ),
                if (i < list.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.employee,
    required this.course,
    required this.date,
    required this.bar,
    required this.status,
    this.header = false,
    this.courseId,
  });

  final String? courseId;
  final String employee;
  final String course;
  final String date;
  final Widget bar;
  final Widget status;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final strong = header ? AppText.small : AppText.label;
    final plain = header ? AppText.small : AppText.body;

    if (context.isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(employee, style: strong)),
                status,
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (courseId != null) ...[
                  CourseThumb(courseId: courseId!, width: 44, height: 44),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(
                  child: Text('$course  |  $date', style: AppText.small),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            bar,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(employee, style: strong)),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (courseId != null) ...[
                  CourseThumb(courseId: courseId!, width: 48, height: 48),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(child: Text(course, style: plain)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(date, style: plain)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: Space.md),
              child: bar,
            ),
          ),
          SizedBox(
            width: 110,
            child: Align(alignment: Alignment.centerLeft, child: status),
          ),
        ],
      ),
    );
  }
}
