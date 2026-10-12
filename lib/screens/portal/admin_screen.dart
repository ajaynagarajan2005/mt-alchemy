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

    return StreamBuilder<Map<String, int>>(
      stream: context.read<AdminStore>().learnersPerCourse(),
      builder: (context, snap) {
        final learners = snap.data ?? const <String, int>{};
        final total = learners.values.fold(0, (a, b) => a + b);
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
              expandedColumns: 3,
              mediumColumns: 3,
              compactColumns: 3,
              children: [
                StatTile(value: '${courses.length}', label: 'Courses'),
                StatTile(
                  value: '${courses.where((c) => c.published).length}',
                  label: 'Published',
                ),
                StatTile(value: '$total', label: 'Learners'),
              ],
            ),
            const SizedBox(height: Space.xl),
            Text('Course catalogue', style: AppText.h3),
            const SizedBox(height: Space.md),
            for (final c in courses)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _CourseRow(course: c, learners: learners[c.id] ?? 0),
              ),
          ],
        );
      },
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.learners});

  final Course course;
  final int learners;

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
          '${gbp.format(course.price)}  |  $learners learners',
          style: AppText.small,
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          icon: AppIcon(HugeIcons.strokeRoundedEdit02, size: 20, color: AppColors.ink),
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
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      child: context.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: Space.xs), actions],
            )
          : Row(children: [Expanded(child: info), actions]),
    );
  }
}
