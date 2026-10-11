import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/courses.dart';
import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/learning_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../upskilling/filter_pill.dart';
import '../upskilling/notice_page.dart';
import '../../widgets/common/tappable.dart';

/// Course player. The route redirect already requires sign-in.
///
/// SCAFFOLD note: lives inside the AppShell Scaffold (AppBar nav).
/// CONTAINER (grouping): module list, lesson column and completion panel are
/// Containers/GlassPanels over the GradientBackdrop.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _index = 0;
  bool _positioned = false;

  @override
  Widget build(BuildContext context) {
    final course = courseById(widget.courseId);
    final user = context.watch<AuthStore>().currentUser;
    final learning = context.watch<LearningStore>();
    final enrolment = (course == null || user == null)
        ? null
        : learning.enrolment(user.id, course.id);

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
    if (enrolment == null || user == null) {
      return NoticePage(
        title: 'You are not enrolled yet',
        message: 'Enrol in ${course.title} to open its lessons.',
        action: AlchemyButton(
          label: 'View the course',
          onPressed: () => context.go(Routes.course(course.id)),
        ),
      );
    }

    // Start on the first unfinished module the first time the page opens.
    if (!_positioned) {
      _positioned = true;
      final firstOpen = course.modules.indexWhere(
        (m) => !enrolment.completedModuleIds.contains(m.id),
      );
      _index = firstOpen < 0 ? 0 : firstOpen;
    }

    final module = course.modules[_index];
    final done = enrolment.completedModuleIds;

    void select(int i) => setState(() => _index = i);

    final lesson = _Lesson(
      course: course,
      module: module,
      index: _index,
      complete: done.contains(module.id),
      onToggle: (v) =>
          learning.setModuleComplete(user.id, course.id, module.id, v),
      onPrevious: _index > 0 ? () => select(_index - 1) : null,
      onNext: _index < course.modules.length - 1
          ? () => select(_index + 1)
          : null,
    );

    final progress = _Progress(enrolment: enrolment, course: course);
    final expanded = context.isExpanded;

    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArrowLink(
                    label: course.title,
                    onTap: () => context.go(Routes.course(course.id)),
                  ),
                  const SizedBox(height: Space.lg),
                  progress,
                  const SizedBox(height: Space.xl),
                  if (enrolment.isComplete) ...[
                    _CompletionPanel(course: course),
                    const SizedBox(height: Space.xl),
                  ],
                  expanded
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 340,
                              child: _ModuleList(
                                course: course,
                                done: done,
                                current: _index,
                                onSelect: select,
                              ),
                            ),
                            const SizedBox(width: Space.xxl),
                            Expanded(child: lesson),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Compact and medium: horizontal chips instead of a side list.
                            _ModuleChips(
                              course: course,
                              done: done,
                              current: _index,
                              onSelect: select,
                            ),
                            const SizedBox(height: Space.xl),
                            lesson,
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.enrolment, required this.course});
  final Enrolment enrolment;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final count = enrolment.completedModuleIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count of ${course.modules.length} modules complete',
          style: AppText.label,
        ),
        const SizedBox(height: Space.xs),
        ClipRRect(
          borderRadius: Radii.pillAll,
          child: LinearProgressIndicator(
            value: enrolment.progress,
            minHeight: 8,
            color: AppColors.red,
            backgroundColor: AppColors.grey200,
          ),
        ),
      ],
    );
  }
}

class _ModuleList extends StatelessWidget {
  const _ModuleList({
    required this.course,
    required this.done,
    required this.current,
    required this.onSelect,
  });

  final Course course;
  final Set<String> done;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (card): glass panel holds the module navigation.
    return GlassPanel(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: Text('Modules', style: AppText.h4),
          ),
          for (var i = 0; i < course.modules.length; i++)
            _ModuleTile(
              module: course.modules[i],
              number: i + 1,
              selected: i == current,
              complete: done.contains(course.modules[i].id),
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.number,
    required this.selected,
    required this.complete,
    required this.onTap,
  });

  final CourseModule module;
  final int number;
  final bool selected;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tappable(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // CONTAINER (decoration): tinted row marks the current module.
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: selected ? AppColors.redSoft : Colors.transparent,
              borderRadius: Radii.inputAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: complete
                      ? AppIcon(
                          HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 20,
                          color: AppColors.success,
                        )
                      : Text('$number', style: AppText.label),
                ),
                const SizedBox(width: Space.xs),
                Expanded(child: Text(module.title, style: AppText.body)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleChips extends StatelessWidget {
  const _ModuleChips({
    required this.course,
    required this.done,
    required this.current,
    required this.onSelect,
  });

  final Course course;
  final Set<String> done;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < course.modules.length; i++) ...[
            FilterPill(
              label:
                  '${i + 1}${done.contains(course.modules[i].id) ? ' done' : ''}',
              selected: i == current,
              onTap: () => onSelect(i),
            ),
            const SizedBox(width: Space.xs),
          ],
        ],
      ),
    );
  }
}

class _Lesson extends StatelessWidget {
  const _Lesson({
    required this.course,
    required this.module,
    required this.index,
    required this.complete,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
  });

  final Course course;
  final CourseModule module;
  final int index;
  final bool complete;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Module ${index + 1} of ${course.modules.length}',
          style: AppText.eyebrow,
        ),
        const SizedBox(height: Space.xs),
        Text(module.title, style: AppText.h2(context)),
        const SizedBox(height: Space.xs),
        Text('${module.minutes} minutes', style: AppText.small),
        const SizedBox(height: Space.lg),
        // CONTAINER (decoration): PLACEHOLDER for the lesson video. A real
        // player replaces this InkArt panel once lesson media exists.
        Container(
          height: compact ? 200 : 340,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: Radii.cardAll),
          child: Stack(
            fit: StackFit.expand,
            children: [
              InkArt(seed: module.id),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.glassFillStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon(
                      HugeIcons.strokeRoundedPlay,
                      size: 28,
                      color: AppColors.red,
                      semanticLabel: 'Lesson video placeholder',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(module.body, style: AppText.body.copyWith(height: 1.7)),
        ),
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AlchemyButton(
              label: complete ? 'Marked as complete' : 'Mark as complete',
              icon: complete ? HugeIcons.strokeRoundedCheckmarkCircle02 : null,
              onPressed: () => onToggle(!complete),
            ),
            AlchemyButton(
              label: 'Previous',
              variant: ButtonVariant.secondary,
              onPressed: onPrevious,
            ),
            AlchemyButton(
              label: 'Next',
              variant: ButtonVariant.secondary,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (decoration): the transformation gradient marks the moment of change.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      decoration: BoxDecoration(
        gradient: AppColors.transformation,
        borderRadius: Radii.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course complete',
            style: AppText.h2(context).copyWith(color: AppColors.onInverse),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'You have finished ${course.title}. Take the next step when you are ready.',
            style: AppText.body.copyWith(color: AppColors.onInverse),
          ),
          const SizedBox(height: Space.md),
          ArrowLink(
            label: 'Browse more courses',
            color: AppColors.onInverse,
            hoverColor: AppColors.inverseMuted,
            onTap: () => context.go(Routes.upskilling),
          ),
        ],
      ),
    );
  }
}
