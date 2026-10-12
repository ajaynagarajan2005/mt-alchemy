import 'dart:async';

import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/article.dart';
import '../../../state/catalog_store.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';

/// Impact Stories carousel: client quotes with a headline result, from the
/// `impactStories` collection. Advances every 7 seconds unless the visitor
/// prefers reduced motion; dots let people jump to any story.
class TestimonialSection extends StatefulWidget {
  const TestimonialSection({super.key});

  @override
  State<TestimonialSection> createState() => _TestimonialSectionState();
}

class _TestimonialSectionState extends State<TestimonialSection> {
  int _index = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!Motion.reduced(context)) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) => _next());
    }
  }

  void _next() {
    final n = context.read<CatalogStore>().stories.length;
    if (n > 1) setState(() => _index = (_index + 1) % n);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<CatalogStore>().stories;
    if (stories.isEmpty) return const SizedBox.shrink();
    final t = stories[_index % stories.length];

    return Section(
      color: AppColors.grey50,
      child: Reveal(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedQuoteDown,
                    size: 44,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: Space.md),
                  Text('Impact stories', style: AppText.eyebrow),
                ],
              ),
              const SizedBox(height: Space.lg),
              AnimatedSwitcher(
                duration: Motion.slow,
                switchInCurve: Motion.ease,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _Story(key: ValueKey(t.id + t.name), story: t),
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  for (var i = 0; i < stories.length; i++)
                    Semantics(
                      button: true,
                      label: 'Show story ${i + 1}',
                      child: GestureDetector(
                        onTap: () => setState(() => _index = i),
                        child: AnimatedContainer(
                          duration: Motion.medium,
                          margin: const EdgeInsets.only(right: Space.xs),
                          width: i == _index % stories.length ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == _index % stories.length
                                ? AppColors.red
                                : AppColors.grey300,
                            borderRadius: Radii.pillAll,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({super.key, required this.story});
  final Testimonial story;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('“${story.quote}”', style: AppText.h2(context)),
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.lg,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(story.name, style: AppText.label),
                const SizedBox(height: Space.xxs),
                Text(story.role, style: AppText.small),
              ],
            ),
            if (story.metric != null)
              // CONTAINER (decoration): red pill with the measured result.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: Radii.pillAll,
                ),
                child: Text(
                  story.metric!,
                  style: AppText.label.copyWith(color: AppColors.red),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
