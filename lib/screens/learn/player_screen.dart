import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/catalog_store.dart';
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
import '../../widgets/media/brand_video_player.dart';
import 'lesson_views.dart';
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
    final course = context.watch<CatalogStore>().courseById(widget.courseId);
    final learning = context.watch<LearningStore>();
    final enrolment = course == null ? null : learning.enrolment(course.id);

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
    if (enrolment == null && !learning.loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.section),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (enrolment == null) {
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
      onToggle: (v) => learning.setModuleComplete(course, module.id, v),
      onQuizSubmitted: (score) => learning.submitQuiz(course, module.id, score),
      bestScore: enrolment.quizScores[module.id],
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
                  if (enrolment.isCompleteIn(course)) ...[
                    _CompletionPanel(
                      course: course,
                      certificate: learning.certificateFor(course.id),
                    ),
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
    final count = course.modules
        .where((m) => enrolment.completedModuleIds.contains(m.id))
        .length;
    final pct = (enrolment.progressIn(course) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$count of ${course.modules.length} lessons complete',
                style: AppText.label,
              ),
            ),
            Text('$pct%', style: AppText.h4.copyWith(color: AppColors.red)),
          ],
        ),
        const SizedBox(height: Space.xs),
        ClipRRect(
          borderRadius: Radii.pillAll,
          child: LinearProgressIndicator(
            value: enrolment.progressIn(course),
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
            child: Text('Lessons', style: AppText.h4),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: AppText.body),
                      Text(
                        '${module.type.label} · ${module.minutes} min',
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),
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
    required this.onQuizSubmitted,
    required this.onPrevious,
    required this.onNext,
    this.bestScore,
  });

  final Course course;
  final CourseModule module;
  final int index;
  final bool complete;
  final ValueChanged<bool> onToggle;
  final Future<String?> Function(double score) onQuizSubmitted;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final double? bestScore;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final isQuiz = module.type == LessonType.quiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lesson ${index + 1} of ${course.modules.length} · ${module.type.label}',
          style: AppText.eyebrow,
        ),
        const SizedBox(height: Space.xs),
        Text(module.title, style: AppText.h2(context)),
        const SizedBox(height: Space.xs),
        Text('${module.minutes} minutes', style: AppText.small),
        const SizedBox(height: Space.lg),
        // Modular player: each lesson type renders its own view.
        switch (module.type) {
          LessonType.video => _videoView(module),
          LessonType.pdf => PdfLessonView(module: module),
          LessonType.quiz => QuizLessonView(
            key: ValueKey(module.id),
            module: module,
            bestScore: bestScore,
            onSubmitted: onQuizSubmitted,
          ),
          // CONTAINER (decoration): artwork header for reading lessons.
          LessonType.text => Container(
            height: compact ? 160 : 240,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(borderRadius: Radii.cardAll),
            child: InkArt(seed: module.id),
          ),
        },
        if (!isQuiz) ...[
          const SizedBox(height: Space.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(module.body, style: AppText.body.copyWith(height: 1.7)),
          ),
        ],
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AlchemyButton(
              label: 'Previous',
              variant: ButtonVariant.secondary,
              onPressed: onPrevious,
            ),
            // Quizzes complete themselves when passed.
            if (!isQuiz)
              AlchemyButton(
                label: complete ? 'Marked as complete' : 'Mark as complete',
                icon: complete
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : null,
                onPressed: () => onToggle(!complete),
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

  Widget _videoView(CourseModule module) {
    final url = module.mediaUrl ?? 'asset:assets/videos/brand_intro.mp4';
    return BrandVideoPlayer(
      key: ValueKey(module.id),
      asset: url.startsWith('asset:') ? url.substring(6) : url,
      poster: 'assets/images/brand_intro_poster.jpg',
      muted: false,
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({required this.course, this.certificate});
  final Course course;
  final Certificate? certificate;

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
            'You have finished ${course.title}. Your certificate is ready.',
            style: AppText.body.copyWith(color: AppColors.onInverse),
          ),
          const SizedBox(height: Space.md),
          if (certificate != null) ...[
            ArrowLink(
              label: 'View your certificate',
              color: AppColors.onInverse,
              hoverColor: AppColors.inverseMuted,
              onTap: () => context.go(Routes.certificate(certificate!.code)),
            ),
            const SizedBox(height: Space.xs),
          ],
          ArrowLink(
            label: 'Choose your next course',
            color: AppColors.onInverse,
            hoverColor: AppColors.inverseMuted,
            onTap: () => context.go(Routes.myCourses),
          ),
        ],
      ),
    );
  }
}
