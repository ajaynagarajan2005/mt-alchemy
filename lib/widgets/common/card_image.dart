import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/motion.dart';
import 'ink_art.dart';

/// Bundled photography for cards, keyed by kind and id.
/// Files live in assets/images/cards (free-licence Unsplash photos, WebP).
const _bundled = {
  'course-ei-foundations',
  'course-first-time-manager',
  'course-leading-through-change',
  'course-team-trust-reset',
  'course-sustainable-performance',
  'course-manager-wellbeing-conversations',
  'course-ei-in-practice',
  'course-emotionally-intelligent-leader',
  'course-leadership-essentials',
  'course-team-foundations',
  'course-high-performing-teams',
  'course-wellbeing-strategy-for-leaders',
  'product-feedback-conversation-cards',
  'product-ei-self-coaching-toolkit',
  'product-team-charter-workshop-kit',
  'product-leading-with-care-book',
  'product-wellbeing-check-in-deck',
  'product-manager-one-to-one-planner',
  'service-emotional-intelligence',
  'service-leadership-development',
  'service-team-engagement',
  'service-workplace-wellbeing',
  'article-why-team-away-days-fade',
  'article-feedback-is-a-skill',
  'article-wellbeing-starts-with-workload',
  'article-naming-emotions-at-work',
  'about-studio',
  'about-team',
  'portal-learning',
  'contact-community',
};

/// `asset:` path for a bundled card image, or null when none exists.
String? bundledImage(String key) =>
    _bundled.contains(key) ? 'asset:assets/images/cards/$key.webp' : null;

/// Lets a card tell its image that the pointer is over it.
class CardHover extends InheritedWidget {
  const CardHover({super.key, required this.hovered, required super.child});

  final bool hovered;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardHover>()?.hovered ?? false;

  @override
  bool updateShouldNotify(CardHover old) => old.hovered != hovered;
}

/// A card photo that slowly zooms when its card is hovered.
///
/// [src] is an `asset:` path or an http(s) URL; when it is null or fails to
/// load, the seeded red ink artwork is shown instead, so a card is never blank.
class CardImage extends StatelessWidget {
  const CardImage({
    super.key,
    required this.seed,
    this.src,
    this.fit = BoxFit.cover,
    this.tint = true,
  });

  /// Used for the fallback artwork.
  final String seed;
  final String? src;
  final BoxFit fit;

  /// A soft red-to-clear wash at the bottom ties photos to the brand.
  final bool tint;

  @override
  Widget build(BuildContext context) {
    final hovered = CardHover.of(context);
    final fallback = InkArt(seed: seed, intensity: 0.9);
    final url = src;
    Widget image;
    if (url == null || url.isEmpty) {
      image = fallback;
    } else if (url.startsWith('data:')) {
      // An uploaded photo stored in the document itself.
      final bytes = UriData.parse(url).contentAsBytes();
      image = Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (url.startsWith('asset:')) {
      image = Image.asset(
        url.substring(6),
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      image = Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedScale(
          scale: hovered && !Motion.reduced(context) ? 1.06 : 1,
          duration: Motion.slow,
          curve: Motion.ease,
          child: image,
        ),
        if (tint && url != null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.red.withValues(alpha: hovered ? 0.18 : 0.08),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps any card with the shared motion: it lifts, gains a soft red-tinted
/// shadow and zooms its [CardImage] on hover; presses scale it down slightly.
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final lift = _hovered && !reduced ? -6.0 : 0.0;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      // Listener (not a tap recogniser) tracks presses, so a parent's
      // onTap still wins the gesture when this card has no onTap of its own.
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.ease,
            transform: Matrix4.translationValues(0, lift, 0)
              ..scaleByDouble(_pressed ? 0.985 : 1, _pressed ? 0.985 : 1, 1, 1),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.red.withValues(
                    alpha: _hovered && !reduced ? 0.14 : 0,
                  ),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: CardHover(hovered: _hovered, child: widget.child),
          ),
        ),
      ),
    );
  }
}
