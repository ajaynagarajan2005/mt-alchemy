import 'package:material_ui/material_ui.dart';

import '../../data/eligibility.dart';
import '../../data/mock/services.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Career stage and interest areas: the learner's pathway. Both are
/// required form fields, used at registration and on the profile page.
class PathwayFields extends StatelessWidget {
  const PathwayFields({
    super.key,
    required this.stage,
    required this.interests,
    required this.onStage,
    required this.onInterest,
  });

  final CareerStage? stage;
  final Set<String> interests;
  final ValueChanged<CareerStage> onStage;
  final void Function(String slug, bool selected) onInterest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormField<CareerStage>(
          validator: (_) => stage == null ? 'Choose your career stage.' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Career stage', style: AppText.label),
              const SizedBox(height: Space.xxs),
              Text(
                'This decides which course levels you can enrol on.',
                style: AppText.small,
              ),
              const SizedBox(height: Space.sm),
              LayoutBuilder(
                builder: (context, c) {
                  final two = c.maxWidth > 420;
                  final w = two ? (c.maxWidth - Space.sm) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final s in CareerStage.values)
                        SizedBox(
                          width: w,
                          child: _StageTile(
                            stage: s,
                            selected: stage == s,
                            onTap: () {
                              onStage(s);
                              field.didChange(s);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (field.hasError) ...[
                const SizedBox(height: Space.xs),
                Text(
                  field.errorText!,
                  style: AppText.small.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        FormField<Set<String>>(
          validator: (_) =>
              interests.isEmpty ? 'Choose at least one interest area.' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interest areas', style: AppText.label),
              const SizedBox(height: Space.xxs),
              Text(
                'You will see courses in these practice areas.',
                style: AppText.small,
              ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final s in services)
                    FilterChip(
                      label: Text(s.title),
                      selected: interests.contains(s.slug),
                      selectedColor: AppColors.redSoft,
                      checkmarkColor: AppColors.red,
                      onSelected: (on) {
                        onInterest(s.slug, on);
                        field.didChange(interests);
                      },
                    ),
                ],
              ),
              if (field.hasError) ...[
                const SizedBox(height: Space.xs),
                Text(
                  field.errorText!,
                  style: AppText.small.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final CareerStage stage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: stage.label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          // CONTAINER (decoration): selectable tile, red border when chosen.
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.redSoft : AppColors.surface,
              borderRadius: Radii.inputAll,
              border: Border.all(
                color: selected ? AppColors.red : AppColors.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.label, style: AppText.label),
                const SizedBox(height: 2),
                Text(stage.blurb, style: AppText.small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
