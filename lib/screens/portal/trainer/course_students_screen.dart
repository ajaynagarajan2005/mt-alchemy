import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/people.dart';
import '../../../router/routes.dart';
import '../../../state/admin_store.dart';
import '../../../state/auth_store.dart';
import '../../../state/catalog_store.dart';
import '../../../state/learning_store.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/product_card.dart' show gbpExact;
import '../portal_widgets.dart';

/// Who is on a course: how many students, who paid and how much, and manual
/// access. Staff can add anyone free of charge, or remove people.
class CourseStudentsScreen extends StatefulWidget {
  const CourseStudentsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseStudentsScreen> createState() => _CourseStudentsScreenState();
}

class _CourseStudentsScreenState extends State<CourseStudentsScreen> {
  // FORM: search box for finding a learner to add.
  final _search = TextEditingController();
  List<AppUser> _results = const [];
  bool _searching = false;
  bool _searched = false;
  String? _adding;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    setState(() => _searching = true);
    final found = await context.read<AdminStore>().findLearners(_search.text);
    if (!mounted) return;
    setState(() {
      _results = found;
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _grant(AppUser learner) async {
    final course = context.read<CatalogStore>().courseById(widget.courseId);
    if (course == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = learner.id);
    final error = await context.read<AdminStore>().grantAccess(learner, course);
    if (!mounted) return;
    setState(() => _adding = null);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? '${learner.name} now has free access to ${course.title}.',
        ),
      ),
    );
  }

  Future<void> _remove(Enrolment e, String courseTitle) async {
    final who = e.userName ?? e.userEmail ?? 'this person';
    final paid = e.accessType == 'purchase';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove $who?', style: AppText.h3),
        content: Text(
          paid
              ? 'They paid for this course. Removing them deletes their '
                    'progress and takes away their access, but does not refund '
                    'the payment.'
              : 'They lose access to $courseTitle and their progress is deleted.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminStore>().removeAccess(e);
    messenger.showSnackBar(SnackBar(content: Text(error ?? '$who removed.')));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final course = catalog.courseById(widget.courseId);
    final me = context.watch<AuthStore>().currentUser;
    final back = me?.role == UserRole.superAdmin
        ? Routes.superCourses
        : Routes.admin;
    if (course == null) {
      return const EmptyState(
        title: 'Course not found',
        message: 'It may have been deleted.',
      );
    }
    final admin = context.read<AdminStore>();

    return StreamBuilder<List<Enrolment>>(
      stream: admin.enrolmentsFor(course.id),
      builder: (context, snap) {
        final list = snap.data ?? const <Enrolment>[];
        final enrolledIds = {for (final e in list) e.userId};
        var stats = const CourseStats();
        for (final e in list) {
          stats = stats.add(e, (_) => course.price);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArrowLink(label: 'All courses', onTap: () => context.go(back)),
            const SizedBox(height: Space.md),
            PortalHeader(
              title: course.title,
              subtitle:
                  'Students, payments and access. List price ${gbpExact.format(course.price)}.',
              trailing: Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  AlchemyButton(
                    label: 'Open course free',
                    icon: HugeIcons.strokeRoundedPlayCircle,
                    onPressed: () => context.go(Routes.learn(course.id)),
                  ),
                  AlchemyButton(
                    label: 'Edit',
                    variant: ButtonVariant.secondary,
                    onPressed: () => context.go(Routes.editCourse(course.id)),
                  ),
                ],
              ),
            ),
            PortalGrid(
              expandedColumns: 5,
              mediumColumns: 3,
              compactColumns: 2,
              children: [
                StatTile(value: '${stats.enrolled}', label: 'Enrolled'),
                StatTile(value: '${stats.paid}', label: 'Paid themselves'),
                StatTile(value: '${stats.assigned}', label: 'Employer seats'),
                StatTile(value: '${stats.granted}', label: 'Free access'),
                StatTile(
                  value: gbpExact.format(stats.revenue),
                  label: 'Received',
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            Text('Add someone for free', style: AppText.h3),
            const SizedBox(height: Space.xs),
            Text(
              'Search by name or email. They get access straight away without paying, and are notified.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: Space.md),
            PortalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _find(),
                          decoration: const InputDecoration(
                            hintText:
                                'Name or email (leave blank to list learners)',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      AlchemyButton(
                        label: 'Search',
                        variant: ButtonVariant.secondary,
                        loading: _searching,
                        onPressed: _find,
                      ),
                    ],
                  ),
                  if (_searched && _results.isEmpty) ...[
                    const SizedBox(height: Space.md),
                    Text(
                      'No learner matches. They need to register first.',
                      style: AppText.small,
                    ),
                  ],
                  for (final u in _results)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: AppText.label),
                                Text(u.email, style: AppText.small),
                              ],
                            ),
                          ),
                          if (enrolledIds.contains(u.id))
                            Text('Already enrolled', style: AppText.small)
                          else
                            AlchemyButton(
                              label: 'Give free access',
                              loading: _adding == u.id,
                              onPressed: () => _grant(u),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Text('Students (${list.length})', style: AppText.h3),
            const SizedBox(height: Space.md),
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              const EmptyState(
                title: 'No students yet',
                message: 'Add someone above, or they can buy the course from the catalogue.',
              )
            else
              for (final e in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: _StudentRow(
                    enrolment: e,
                    listPrice: course.price,
                    lessons: course.modules.length,
                    progress: e.progressIn(course),
                    onRemove: () => _remove(e, course.title),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.enrolment,
    required this.listPrice,
    required this.lessons,
    required this.progress,
    required this.onRemove,
  });

  final Enrolment enrolment;
  final double listPrice;
  final int lessons;
  final double progress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final e = enrolment;
    final type = e.accessType;
    final (label, color, bg) = switch (type) {
      'purchase' => (
        'Paid ${gbpExact.format(e.amountPaid ?? listPrice)}',
        AppColors.success,
        AppColors.success.withValues(alpha: 0.12),
      ),
      'assignment' => ('Employer seat', AppColors.grey700, AppColors.grey100),
      _ => ('Free access', AppColors.red, AppColors.redSoft),
    };
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                e.userName ?? e.userEmail ?? 'Learner',
                style: AppText.h4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.sm),
            // CONTAINER (decoration): access type pill.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: bg, borderRadius: Radii.pillAll),
              child: Text(label, style: AppText.small.copyWith(color: color)),
            ),
          ],
        ),
        Text(
          '${e.userEmail ?? ''}  |  joined ${formatDate(e.enrolledAt)}',
          style: AppText.small,
        ),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            Expanded(
              child: ProgressBar(value: progress, complete: progress >= 1),
            ),
            const SizedBox(width: Space.sm),
            Text('${(progress * 100).round()}%', style: AppText.small),
          ],
        ),
      ],
    );
    final remove = IconButton(
      tooltip: 'Remove from course',
      onPressed: onRemove,
      icon: AppIcon(
        HugeIcons.strokeRoundedDelete02,
        size: 20,
        color: AppColors.grey600,
      ),
    );
    return PortalCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Expanded(child: info),
          const SizedBox(width: Space.sm),
          remove,
        ],
      ),
    );
  }
}
