import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/motion.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/ink_art.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/content_frame.dart';

/// Full-bleed hero. The media layer zooms and fades as the page scrolls,
/// pulling the visitor "through" it into Services.
///
/// The media is the seeded [InkArt] still for now; phase 7 swaps in the
/// looping muted hero video with this still as its poster.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.scroll, required this.height});

  final ScrollController scroll;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final compact = context.isCompact;

    final media = const InkArt(seed: 'mt-alchemy-hero', intensity: 1);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: reduced
                ? media
                : AnimatedBuilder(
                    animation: scroll,
                    child: media,
                    builder: (context, child) {
                      final offset = scroll.hasClients ? scroll.offset : 0.0;
                      final t = (offset / (height * 0.9)).clamp(0.0, 1.0);
                      // Zoom-through: the ink grows towards the viewer and dissolves.
                      return Opacity(
                        opacity: 1 - t * 0.85,
                        child: Transform.scale(
                          scale: 1 + t * 0.18,
                          child: child,
                        ),
                      );
                    },
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: compact ? Space.lg : Space.xxxl,
            child: ContentFrame(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  // Wide enough for a 2-line headline at the expanded display size.
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: GlassPanel(
                    strong: true,
                    padding: EdgeInsets.all(compact ? Space.lg : Space.xxl),
                    child: const _HeroCopy(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final display = AppText.display(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: staggerIn(context, [
        Text('PEOPLE DEVELOPMENT CONSULTANCY', style: AppText.eyebrow),
        Padding(
          padding: const EdgeInsets.only(top: Space.md, bottom: Space.xxs),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'We shift mindsets, behaviours, and '),
                TextSpan(
                  text: 'team culture.',
                  style: display.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: display,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Emotional intelligence, leadership and well-being programmes that change '
              'how people work together, long after the workshop ends.',
              style: AppText.lead,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xl),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              AlchemyButton(
                label: 'Book a call',
                onPressed: () => context.go(Routes.contact),
              ),
              AlchemyButton(
                label: 'Explore learning',
                variant: ButtonVariant.secondary,
                onPressed: () => context.go(Routes.upskilling),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Scales its child from 0.92 to 1 while the hero scrolls away, so the
/// next section appears to arrive from behind the hero.
class ZoomThrough extends StatelessWidget {
  const ZoomThrough({
    super.key,
    required this.scroll,
    required this.distance,
    required this.child,
  });

  final ScrollController scroll;

  /// Scroll distance over which the zoom completes.
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    return AnimatedBuilder(
      animation: scroll,
      child: child,
      builder: (context, child) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final t = Motion.ease.transform((offset / distance).clamp(0.0, 1.0));
        return Transform.scale(
          scale: 0.92 + 0.08 * t,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }
}
