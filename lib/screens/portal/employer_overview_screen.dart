import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_store.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/org_store.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import 'portal_widgets.dart';

/// Employer dashboard: headline numbers, quick actions, recent assignments.
class EmployerOverviewScreen extends StatelessWidget {
  const EmployerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final org = auth.currentOrganisation;
    final store = context.watch<OrgStore>();
    if (org == null) return const SizedBox.shrink();

    final employees = store.employees(org.id);
    final assignments = store.assignments(org.id);
    final recent = [...assignments]
      ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    final avg = (store.averageProgress(org.id) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Welcome, ${auth.currentUser!.firstName}',
          subtitle: '${org.name}  |  ${org.sector}',
        ),
        PortalGrid(
          children: [
            StatTile(value: '${employees.length}', label: 'Employees'),
            StatTile(value: '${assignments.length}', label: 'Courses assigned'),
            StatTile(value: '$avg%', label: 'Average progress'),
            StatTile(
              value: '${store.completedCount(org.id)}',
              label: 'Completed',
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text('Quick actions', style: AppText.h3),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            AlchemyButton(
              label: 'Add employees',
              onPressed: () => context.go(Routes.employerEmployees),
            ),
            AlchemyButton(
              label: 'Assign a course',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(Routes.employerAssign),
            ),
            AlchemyButton(
              label: 'Buy course seats',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(Routes.employerCourses),
            ),
            AlchemyButton(
              label: 'View analytics',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(Routes.employerReports),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text('Recent assignments', style: AppText.h3),
        const SizedBox(height: Space.md),
        if (recent.isEmpty)
          EmptyState(
            title: 'No courses assigned yet',
            message: 'Add your people, then assign them a course to start tracking progress.',
            actionLabel: 'Assign a course',
            secondary: true,
            onAction: () => context.go(Routes.employerAssign),
          )
        else
          PortalCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.xs,
            ),
            child: Column(
              children: [
                for (final a in recent.take(5)) ...[
                  _RecentRow(
                    name: store.employeeById(org.id, a.employeeId)?.name ?? '',
                    course:
                        context
                            .read<CatalogStore>()
                            .courseById(a.courseId)
                            ?.title ??
                        a.courseId,
                    date: formatDate(a.assignedAt),
                    status: a.status,
                  ),
                  if (a != recent.take(5).last) const Divider(),
                ],
              ],
            ),
          ),
        const SizedBox(height: Space.md),
        ArrowLink(
          label: 'See all progress',
          onTap: () => context.go(Routes.employerProgress),
        ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.name,
    required this.course,
    required this.date,
    required this.status,
  });

  final String name;
  final String course;
  final String date;
  final ProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppText.label),
        const SizedBox(height: 2),
        Text('$course  |  $date', style: AppText.small),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Expanded(child: text),
          const SizedBox(width: Space.sm),
          StatusChip(status: status),
        ],
      ),
    );
  }
}
