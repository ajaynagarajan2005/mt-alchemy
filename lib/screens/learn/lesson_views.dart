import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/course.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/glass_panel.dart';

/// Opens a workbook or download. Relative paths resolve against the site,
/// so `/downloads/x.pdf` works on localhost and on Firebase Hosting.
Future<void> openDocument(String url) async {
  final uri = url.startsWith('http') ? Uri.parse(url) : Uri.base.resolve(url);
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

/// A PDF lesson: a document card with open and download actions.
class PdfLessonView extends StatelessWidget {
  const PdfLessonView({super.key, required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final url = module.mediaUrl;
    // CONTAINER (card): glass panel framing the workbook.
    return GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.smallAll,
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowTint,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(height: 14, color: AppColors.red),
                const Spacer(),
                AppIcon(
                  HugeIcons.strokeRoundedPdf01,
                  size: 30,
                  color: AppColors.red,
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lesson workbook', style: AppText.h4),
                const SizedBox(height: Space.xxs),
                Text(
                  'Read along, then use the reflection prompts to apply the '
                  'idea to your own week.',
                  style: AppText.small,
                ),
                const SizedBox(height: Space.md),
                AlchemyButton(
                  label: 'Open workbook (PDF)',
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  variant: ButtonVariant.secondary,
                  onPressed: url == null ? null : () => openDocument(url),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiz lesson: one choice per question, scored on submit. Passing
/// ([CourseModule.passMark]) completes the lesson.
class QuizLessonView extends StatefulWidget {
  const QuizLessonView({
    super.key,
    required this.module,
    required this.onSubmitted,
    this.bestScore,
  });

  final CourseModule module;
  final Future<String?> Function(double score) onSubmitted;
  final double? bestScore;

  @override
  State<QuizLessonView> createState() => _QuizLessonViewState();
}

class _QuizLessonViewState extends State<QuizLessonView> {
  late List<int?> _answers = List.filled(widget.module.quiz.length, null);
  double? _score;
  bool _busy = false;

  List<QuizQuestion> get _questions => widget.module.quiz;
  bool get _allAnswered => !_answers.contains(null);

  Future<void> _submit() async {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].answer) correct++;
    }
    final score = _questions.isEmpty ? 1.0 : correct / _questions.length;
    setState(() {
      _score = score;
      _busy = true;
    });
    final error = await widget.onSubmitted(score);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _retry() => setState(() {
    _answers = List.filled(_questions.length, null);
    _score = null;
  });

  @override
  Widget build(BuildContext context) {
    final best = widget.bestScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.module.body, style: AppText.bodyMuted),
        if (best != null && _score == null) ...[
          const SizedBox(height: Space.xs),
          Text(
            'Your best score so far: ${(best * 100).round()}%',
            style: AppText.label.copyWith(color: AppColors.red),
          ),
        ],
        const SizedBox(height: Space.lg),
        for (var q = 0; q < _questions.length; q++) ...[
          _QuestionCard(
            number: q + 1,
            question: _questions[q],
            selected: _answers[q],
            revealed: _score != null,
            onSelect: _score != null
                ? null
                : (i) => setState(() => _answers[q] = i),
          ),
          const SizedBox(height: Space.md),
        ],
        AnimatedSwitcher(
          duration: Motion.medium,
          child: _score == null
              ? AlchemyButton(
                  key: const ValueKey('submit'),
                  label: 'Submit answers',
                  loading: _busy,
                  onPressed: _allAnswered ? _submit : null,
                )
              : _Result(
                  key: const ValueKey('result'),
                  score: _score!,
                  onRetry: _retry,
                ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.selected,
    required this.revealed,
    required this.onSelect,
  });

  final int number;
  final QuizQuestion question;
  final int? selected;
  final bool revealed;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (card): one bordered surface per question.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question $number', style: AppText.eyebrow),
          const SizedBox(height: Space.xs),
          Text(question.prompt, style: AppText.h4),
          const SizedBox(height: Space.sm),
          RadioGroup<int>(
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onSelect?.call(v);
            },
            child: Column(
              children: [
                for (var i = 0; i < question.options.length; i++)
                  _Option(
                    index: i,
                    label: question.options[i],
                    enabled: onSelect != null,
                    state: !revealed
                        ? null
                        : i == question.answer
                        ? true
                        : i == selected
                        ? false
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.index,
    required this.label,
    required this.enabled,
    required this.state,
  });

  final int index;
  final String label;
  final bool enabled;

  /// After submit: true = correct answer, false = wrong pick, null = neutral.
  final bool? state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      true => AppColors.success,
      false => AppColors.red,
      null => AppColors.ink,
    };
    return RadioListTile<int>(
      value: index,
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.red,
      title: Text(label, style: AppText.body.copyWith(color: color)),
      secondary: state == null
          ? null
          : AppIcon(
              state!
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedCancelCircle,
              size: 20,
              color: color,
            ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({super.key, required this.score, required this.onRetry});

  final double score;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final passed = score >= CourseModule.passMark;
    final pct = (score * 100).round();
    // CONTAINER (decoration): the transformation gradient on a pass.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        gradient: passed ? AppColors.transformation : null,
        color: passed ? null : AppColors.redSoft,
        borderRadius: Radii.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            passed ? 'You passed with $pct%' : 'You scored $pct%',
            style: AppText.h3.copyWith(
              color: passed ? AppColors.onInverse : AppColors.ink,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            passed
                ? 'Lesson complete. Well done.'
                : 'You need ${(CourseModule.passMark * 100).round()}% to pass. '
                      'Review the answers above and try again.',
            style: AppText.body.copyWith(
              color: passed ? AppColors.onInverse : AppColors.ink,
            ),
          ),
          if (!passed) ...[
            const SizedBox(height: Space.md),
            AlchemyButton(
              label: 'Try again',
              variant: ButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
