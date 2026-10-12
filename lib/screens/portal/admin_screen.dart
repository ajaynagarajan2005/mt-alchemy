import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/admin_store.dart';
import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/course_card.dart' show gbp;
import 'portal_widgets.dart';

/// Trainer portal (and super admin "Courses"): the course catalogue with
/// create, edit, publish and delete (CRUD for Courses).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, this.showWelcome = true});

  final bool showWelcome;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final user = context.watch<AuthStore>().currentUser;
    final courses = catalog.allCourses;

    return StreamBuilder<Map<String, CourseStats>>(
      stream: context.read<AdminStore>().courseStats(
        (id) => catalog.courseById(id)?.price ?? 0,
      ),
      builder: (context, snap) {
        final stats = snap.data ?? const <String, CourseStats>{};
        final total = stats.values.fold(0, (a, b) => a + b.enrolled);
        final revenue = stats.values.fold(0.0, (a, b) => a + b.revenue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PortalHeader(
              title: showWelcome
                  ? 'Welcome, ${user?.firstName ?? ''}'
                  : 'Courses',
              subtitle:
                  'Create courses, add video, PDF and quiz lessons, and '
                  'publish them to the learning library.',
              trailing: AlchemyButton(
                label: 'New course',
                icon: HugeIcons.strokeRoundedAdd01,
                onPressed: () => context.go(Routes.editCourse('new')),
              ),
            ),
            PortalGrid(
              expandedColumns: 4,
              mediumColumns: 2,
              compactColumns: 2,
              children: [
                StatTile(value: '${courses.length}', label: 'Courses'),
                StatTile(
                  value: '${courses.where((c) => c.published).length}',
                  label: 'Published',
                ),
                StatTile(value: '$total', label: 'Enrolments'),
                StatTile(value: gbp.format(revenue), label: 'Received'),
              ],
            ),
            const SizedBox(height: Space.xl),
            Text('Course catalogue', style: AppText.h3),
            const SizedBox(height: Space.md),
            for (final c in courses)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _CourseRow(
                  course: c,
                  stats: stats[c.id] ?? const CourseStats(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.stats});

  final Course course;
  final CourseStats stats;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${course.title}?', style: AppText.h3),
        content: Text(
          'Learners already enrolled keep their records, but the course will '
          'disappear from the library. This cannot be undone.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<CatalogStore>().deleteCourse(course.id);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? '${course.title} deleted.')),
    );
  }

  Future<void> _togglePublished(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<CatalogStore>().saveCourse(
      course.copyWith(published: !course.published),
    );
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final types = {for (final m in course.modules) m.type};
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(course.title, style: AppText.h4)),
            const SizedBox(width: Space.sm),
            // CONTAINER (decoration): publish state pill.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: course.published ? AppColors.redSoft : AppColors.grey100,
                borderRadius: Radii.pillAll,
              ),
              child: Text(
                course.published ? 'Published' : 'Draft',
                style: AppText.small.copyWith(
                  color: course.published ? AppColors.red : AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xxs),
        Text(
          '${course.level.label}  |  ${course.modules.length} lessons '
          '(${types.map((t) => t.label).join(', ')})  |  '
          '${gbp.format(course.price)}',
          style: AppText.small,
        ),
        const SizedBox(height: Space.xs),
        // Enrolment, payment and revenue at a glance; Students opens the list.
        Wrap(
          spacing: Space.md,
          runSpacing: 2,
          children: [
            _Fact('${stats.enrolled} enrolled'),
            _Fact('${stats.paid} paid ${gbp.format(stats.revenue)}'),
            if (stats.assigned > 0) _Fact('${stats.assigned} via employers'),
            if (stats.granted > 0) _Fact('${stats.granted} free access'),
          ],
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => context.go(Routes.courseStudents(course.id)),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('Students'),
        ),
        IconButton(
          tooltip: 'Open ${course.title} free',
          onPressed: () => context.go(Routes.learn(course.id)),
          icon: AppIcon(
            HugeIcons.strokeRoundedPlayCircle,
            size: 22,
            color: AppColors.ink,
          ),
        ),
        Tooltip(
          message: course.published ? 'Unpublish' : 'Publish',
          child: Switch(
            value: course.published,
            activeThumbColor: AppColors.red,
            onChanged: (_) => _togglePublished(context),
          ),
        ),
        IconButton(
          tooltip: 'Edit ${course.title}',
          onPressed: () => context.go(Routes.editCourse(course.id)),
          icon: AppIcon(
            HugeIcons.strokeRoundedEdit02,
            size: 20,
            color: AppColors.ink,
          ),
        ),
        IconButton(
          tooltip: 'Delete ${course.title}',
          onPressed: () => _delete(context),
          icon: AppIcon(
            HugeIcons.strokeRoundedDelete02,
            size: 20,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
    return PortalCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: Space.xs),
                actions,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                actions,
              ],
            ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.small.copyWith(color: AppColors.ink));
}
