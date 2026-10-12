import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/backend.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';

/// The five areas of emotional intelligence (after Goleman).
enum EqDomain { selfAwareness, selfRegulation, motivation, empathy, socialSkill }

extension EqDomainX on EqDomain {
  String get label => switch (this) {
    EqDomain.selfAwareness => 'Self-awareness',
    EqDomain.selfRegulation => 'Self-regulation',
    EqDomain.motivation => 'Motivation',
    EqDomain.empathy => 'Empathy',
    EqDomain.socialSkill => 'Social skill',
  };

  /// The course that best builds this area.
  String get courseId => switch (this) {
    EqDomain.selfAwareness => 'ei-foundations',
    EqDomain.selfRegulation => 'sustainable-performance',
    EqDomain.motivation => 'leading-through-change',
    EqDomain.empathy => 'manager-wellbeing-conversations',
    EqDomain.socialSkill => 'team-trust-reset',
  };
}

const _statements = <(EqDomain, String)>[
  (EqDomain.selfAwareness, 'I can name what I am feeling while it is happening.'),
  (EqDomain.selfAwareness, 'I know which situations tend to pull me off balance.'),
  (EqDomain.selfRegulation, 'When I am frustrated, I pause before I respond.'),
  (EqDomain.selfRegulation, 'I recover quickly after a stressful moment at work.'),
  (EqDomain.motivation, 'I stay focused on goals even when progress is slow.'),
  (EqDomain.motivation, 'Setbacks make me curious rather than discouraged.'),
  (EqDomain.empathy, 'I notice when a colleague is having a hard day.'),
  (EqDomain.empathy, 'I can see a disagreement from the other person\'s side.'),
  (EqDomain.socialSkill, 'I can raise a difficult topic without damaging trust.'),
  (EqDomain.socialSkill, 'People come to me to help resolve tensions in the team.'),
];

const _scale = ['Rarely', 'Sometimes', 'Often', 'Usually', 'Almost always'];

/// EQ self-assessment: ten statements, one at a time, then an animated
/// profile with a matched course. Results are saved for signed-in users.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final List<int?> _answers = List.filled(_statements.length, null);
  int _step = 0;
  bool _done = false;

  Map<EqDomain, double> get _scores {
    final totals = <EqDomain, List<int>>{};
    for (var i = 0; i < _statements.length; i++) {
      totals.putIfAbsent(_statements[i].$1, () => []).add(_answers[i] ?? 0);
    }
    // Each answer is 0 to 4; scale each domain to 0 to 1.
    return {
      for (final e in totals.entries)
        e.key: e.value.fold(0, (a, b) => a + b) / (e.value.length * 4),
    };
  }

  void _answer(int value) {
    setState(() => _answers[_step] = value);
    Future.delayed(Motion.fast, () {
      if (!mounted) return;
      if (_step < _statements.length - 1) {
        setState(() => _step++);
      } else {
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _done = true);
    final user = context.read<AuthStore>().currentUser;
    if (user == null) return;
    try {
      await context.read<Backend>().col('assessments').add({
        'userId': user.id,
        'type': 'eq-self-assessment',
        'scores': {for (final e in _scores.entries) e.key.name: e.value},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // The result still shows if saving fails.
    }
  }

  void _restart() => setState(() {
    _answers.fillRange(0, _answers.length, null);
    _step = 0;
    _done = false;
  });

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EQ SELF-ASSESSMENT', style: AppText.eyebrow),
                      const SizedBox(height: Space.xs),
                      Text(
                        _done
                            ? 'Your emotional intelligence profile'
                            : 'How do you show up at work?',
                        style: AppText.h1(context),
                      ),
                      const SizedBox(height: Space.xl),
                      AnimatedSwitcher(
                        duration: Motion.medium,
                        switchInCurve: Motion.ease,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: _done
                            ? _Results(
                                key: const ValueKey('results'),
                                scores: _scores,
                                onRestart: _restart,
                              )
                            : _Question(
                                key: ValueKey(_step),
                                step: _step,
                                selected: _answers[_step],
                                onAnswer: _answer,
                                onBack: _step == 0
                                    ? null
                                    : () => setState(() => _step--),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    super.key,
    required this.step,
    required this.selected,
    required this.onAnswer,
    required this.onBack,
  });

  final int step;
  final int? selected;
  final ValueChanged<int> onAnswer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final (domain, text) = _statements[step];
    return GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${step + 1} of ${_statements.length}  ·  ${domain.label}',
                style: AppText.small,
              ),
              const Spacer(),
              if (onBack != null)
                TextButton(onPressed: onBack, child: const Text('Back')),
            ],
          ),
          const SizedBox(height: Space.xs),
          ClipRRect(
            borderRadius: Radii.pillAll,
            child: LinearProgressIndicator(
              value: (step + 1) / _statements.length,
              minHeight: 6,
              color: AppColors.red,
              backgroundColor: AppColors.grey200,
            ),
          ),
          const SizedBox(height: Space.xl),
          Text(text, style: AppText.h2(context)),
          const SizedBox(height: Space.xl),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (var i = 0; i < _scale.length; i++)
                ChoiceChip(
                  label: Text(_scale[i]),
                  selected: selected == i,
                  selectedColor: AppColors.red,
                  labelStyle: AppText.label.copyWith(
                    color: selected == i ? AppColors.onAccent : AppColors.ink,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: Space.xs,
                  ),
                  onSelected: (_) => onAnswer(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.scores, required this.onRestart});

  final Map<EqDomain, double> scores;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final growth = sorted.first.key;
    final strength = sorted.last.key;
    final course = context.watch<CatalogStore>().courseById(growth.courseId);
    final overall = scores.values.fold(0.0, (a, b) => a + b) / scores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassPanel(
          strong: true,
          padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall ${(overall * 100).round()}%', style: AppText.h3),
              const SizedBox(height: Space.lg),
              for (final d in EqDomain.values) ...[
                _DomainBar(domain: d, value: scores[d] ?? 0),
                const SizedBox(height: Space.md),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        // CONTAINER (decoration): transformation gradient for the result.
        Container(
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
                'Your strength is ${strength.label.toLowerCase()}. '
                'Your growth edge is ${growth.label.toLowerCase()}.',
                style: AppText.h3.copyWith(color: AppColors.onInverse),
              ),
              if (course != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'We recommend ${course.title}: ${course.summary}',
                  style: AppText.body.copyWith(color: AppColors.onInverse),
                ),
                const SizedBox(height: Space.lg),
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.md,
                  children: [
                    AlchemyButton(
                      label: 'View the course',
                      variant: ButtonVariant.inverse,
                      onPressed: () => context.go(Routes.course(course.id)),
                    ),
                    AlchemyButton(
                      label: 'Retake',
                      variant: ButtonVariant.inverse,
                      onPressed: onRestart,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DomainBar extends StatelessWidget {
  const _DomainBar({required this.domain, required this.value});

  final EqDomain domain;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(domain.label, style: AppText.label)),
            Text('${(value * 100).round()}%', style: AppText.small),
          ],
        ),
        const SizedBox(height: Space.xxs),
        // Bars grow in from zero: the profile "fills up" on arrival.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: Motion.reduced(context) ? Duration.zero : Motion.slow * 2,
          curve: Motion.ease,
          builder: (context, v, _) => ClipRRect(
            borderRadius: Radii.pillAll,
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: AppColors.red,
              backgroundColor: AppColors.grey200,
            ),
          ),
        ),
      ],
    );
  }
}
