import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/mock/services.dart';
import '../../data/models/service.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/reveal.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/media/hero_video.dart';
import '../../widgets/layout/section.dart';
import '../about/content_shared.dart';

/// Services overview: four practice areas, each in a different layout.
///
/// SCAFFOLD: AppShell supplies Scaffold + AppBar; this is the page body.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      underNav: true,
      children: [
        const ContentHeader(
          title: 'Four ways we help teams change',
          lead: 'Each starts with your people and your pressures, not a template.',
          // Calm silk-ribbon loop behind the header (left side kept quiet).
          background: LoopVideo(
            asset: 'assets/videos/services_loop.mp4',
            poster: 'assets/images/services_poster.jpg',
          ),
        ),
        _SplitBlock(service: services[0], artLeft: false),
        _GlassBlock(service: services[1]),
        _SplitBlock(service: services[2], artLeft: true),
        _TypeBlock(service: services[3]),
        const ClosingCta(),
      ],
    );
  }
}

/// Title, short line, two outcomes and the link to the detail page.
class _ServiceText extends StatelessWidget {
  const _ServiceText({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(service.title, style: AppText.h2(context)),
        const SizedBox(height: Space.md),
        Text(service.short, style: AppText.lead),
        const SizedBox(height: Space.lg),
        for (final o in service.outcomes.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: AppIcon(
                    HugeIcons.strokeRoundedTick02,
                    size: 18,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(o, style: AppText.body)),
              ],
            ),
          ),
        const SizedBox(height: Space.md),
        ArrowLink(
          label: 'See how it works',
          onTap: () => context.go(Routes.service(service.slug)),
        ),
      ],
    );
  }
}

/// Layout 1 and 3: text beside a framed artwork.
class _SplitBlock extends StatelessWidget {
  const _SplitBlock({required this.service, required this.artLeft});
  final Service service;
  final bool artLeft;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (decoration): clipped rounded frame for the artwork.
    final art = Reveal(
      child: AspectRatio(
        aspectRatio: 5 / 4,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: Radii.cardAll),
          child: InkArt(seed: service.slug),
        ),
      ),
    );
    final text = Reveal(child: _ServiceText(service: service));
    return Section(
      color: artLeft ? AppColors.grey50 : null,
      child: SplitRow(
        flexA: artLeft ? 5 : 6,
        flexB: artLeft ? 6 : 5,
        gap: Space.xxxl,
        a: artLeft ? art : text,
        b: artLeft ? text : art,
      ),
    );
  }
}

/// Layout 2: the copy sits in a glass panel over soft blobs.
class _GlassBlock extends StatelessWidget {
  const _GlassBlock({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return GradientBackdrop(
      blobs: const [
        Blob(alignment: Alignment(0.9, -0.5), size: 600),
        Blob(
          alignment: Alignment(-0.8, 0.8),
          size: 500,
          color: AppColors.grey400,
          opacity: 0.3,
        ),
      ],
      child: Section(
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Reveal(
              child: GlassPanel(
                strong: true,
                padding: EdgeInsets.all(
                  context.isCompact ? Space.lg : Space.xxl,
                ),
                child: _ServiceText(service: service),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Layout 4: type only, set under a hairline rule.
class _TypeBlock extends StatelessWidget {
  const _TypeBlock({required this.service});
  final Service service;

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: Space.xl),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: _ServiceText(service: service),
            ),
          ],
        ),
      ),
    );
  }
}
