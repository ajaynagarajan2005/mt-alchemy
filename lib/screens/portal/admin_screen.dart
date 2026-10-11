import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/courses.dart';
import '../../data/models/course.dart';
import '../../data/mock/demo_accounts.dart';
import '../../state/auth_store.dart';
import '../../state/learning_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/course_card.dart' show gbp;
import 'portal_widgets.dart';

/// Trainer / admin: read-only view of the catalogue and organisations.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningStore>();
    final org = context.watch<OrgStore>();
    final user = context.watch<AuthStore>().currentUser;

    // Learners per course: individual enrolments plus employer assignments
    // for the demo organisation.
    int learners(String courseId) {
      final individuals = demoUsers
          .where((u) => learning.isEnrolled(u.id, courseId))
          .length;
      final assigned = org
          .assignments(demoOrganisation.id)
          .where((a) => a.courseId == courseId)
          .length;
      return individuals + assigned;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Welcome, ${user?.firstName ?? ''}',
          subtitle: 'A read-only view of the catalogue and the organisations you support.',
        ),
        Text('Course catalogue', style: AppText.h3),
        const SizedBox(height: Space.md),
        PortalCard(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!context.isCompact) ...[
                const _CourseRow(
                  title: 'Course',
                  level: 'Level',
                  modules: 'Modules',
                  price: 'Price',
                  learners: 'Learners',
                  header: true,
                ),
                const Divider(),
              ],
              for (var i = 0; i < courses.length; i++) ...[
                _CourseRow(
                  title: courses[i].title,
                  level: courses[i].level.label,
                  modules: '${courses[i].modules.length}',
                  price: gbp.format(courses[i].price),
                  learners: '${learners(courses[i].id)}',
                ),
                if (i < courses.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Text('Organisations', style: AppText.h3),
        const SizedBox(height: Space.md),
        PortalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(demoOrganisation.name, style: AppText.h4),
              const SizedBox(height: Space.xxs),
              Text(
                '${demoOrganisation.sector}  |  ${demoOrganisation.size}',
                style: AppText.small,
              ),
              const SizedBox(height: Space.sm),
              Text(
                '${org.employeeCount(demoOrganisation.id)} employees  |  ${org.assignments(demoOrganisation.id).length} course assignments',
                style: AppText.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.title,
    required this.level,
    required this.modules,
    required this.price,
    required this.learners,
    this.header = false,
  });

  final String title;
  final String level;
  final String modules;
  final String price;
  final String learners;
  final bool header;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.label),
            const SizedBox(height: 2),
            Text(
              '$level  |  $modules modules  |  $price  |  $learners ${learners == '1' ? 'learner' : 'learners'}',
              style: AppText.small,
            ),
          ],
        ),
      );
    }
    final strong = header ? AppText.small : AppText.label;
    final plain = header ? AppText.small : AppText.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(title, style: strong)),
          Expanded(flex: 2, child: Text(level, style: plain)),
          Expanded(flex: 2, child: Text(modules, style: plain)),
          Expanded(flex: 2, child: Text(price, style: plain)),
          Expanded(flex: 2, child: Text(learners, style: plain)),
        ],
      ),
    );
  }
}
