import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/mock/services.dart';
import '../../../data/models/service.dart';
import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/gradient_backdrop.dart';
import '../../../widgets/common/ink_art.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/common/tilt_card.dart';
import '../../../widgets/layout/section.dart';

const _icons = <String, AppIconData>{
  'emotional-intelligence': HugeIcons.strokeRoundedBrain,
  'leadership-development': HugeIcons.strokeRoundedCompass01,
  'team-engagement': HugeIcons.strokeRoundedUserGroup,
  'workplace-wellbeing': HugeIcons.strokeRoundedPlant02,
};

enum _Fill { art, glass, gradient }

/// Four practice areas as an asymmetric bento: exactly four cells.
/// Desktop: 7/5 then 5/7. Tablet: two equal columns. Phone: one column.
class ServicesBento extends StatelessWidget {
  const ServicesBento({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;
    final cells = [
      _Cell(service: services[0], fill: _Fill.art),
      _Cell(service: services[1], fill: _Fill.glass),
      _Cell(service: services[2], fill: _Fill.glass),
      _Cell(service: services[3], fill: _Fill.gradient),
    ];

    Widget grid;
    switch (size) {
      case ScreenSize.expanded:
        grid = Column(
          children: [
            _row(cells[0], 7, cells[1], 5, 360),
            const SizedBox(height: Space.lg),
            _row(cells[2], 5, cells[3], 7, 320),
          ],
        );
      case ScreenSize.medium:
        grid = Column(
          children: [
            _row(cells[0], 1, cells[1], 1, 340),
            const SizedBox(height: Space.md),
            _row(cells[2], 1, cells[3], 1, 340),
          ],
        );
      case ScreenSize.compact:
        grid = Column(
          children: [
            for (final c in cells) ...[
              SizedBox(height: 300, child: c),
              if (c != cells.last) const SizedBox(height: Space.md),
            ],
          ],
        );
    }

    return GradientBackdrop(
      blobs: const [
        Blob(alignment: Alignment(-0.9, 0.1), size: 620, opacity: 0.18),
        Blob(
          alignment: Alignment(1.0, -0.4),
          size: 560,
          color: AppColors.grey400,
          opacity: 0.4,
        ),
        Blob(alignment: Alignment(0.5, 1.0), size: 480, opacity: 0.14),
      ],
      child: Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Reveal(
              child: Text(
                'Four ways we work with your people',
                style: AppText.h2(context),
              ),
            ),
            const SizedBox(height: Space.md),
            Reveal(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  'Every programme is shaped around your culture and measured by what '
                  'changes back at work, not by how the day felt.',
                  style: AppText.lead,
                ),
              ),
            ),
            const SizedBox(height: Space.xxl),
            grid,
          ],
        ),
      ),
    );
  }

  Widget _row(Widget a, int flexA, Widget b, int flexB, double height) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: flexA, child: a),
          const SizedBox(width: Space.lg),
          Expanded(flex: flexB, child: b),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.service, required this.fill});

  final Service service;
  final _Fill fill;

  @override
  Widget build(BuildContext context) {
    void open() => context.go(Routes.service(service.slug));
    final onDark = fill == _Fill.gradient;
    final fg = onDark ? AppColors.white : AppColors.ink;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(service.title, style: AppText.h3.copyWith(color: fg)),
        const SizedBox(height: Space.xs),
        Text(
          service.short,
          style: AppText.body.copyWith(
            color: onDark ? AppColors.grey200 : AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: Space.md),
        ArrowLink(
          label: 'Explore',
          onTap: open,
          color: fg,
          hoverColor: onDark ? AppColors.white : AppColors.red,
        ),
      ],
    );

    final icon = AppIcon(
      _icons[service.slug]!,
      size: 32,
      color: onDark ? AppColors.white : AppColors.red,
    );

    final Widget body = switch (fill) {
      // Artwork fill with a glass caption floating over it.
      _Fill.art => ClipRRect(
        borderRadius: Radii.cardAll,
        child: Stack(
          children: [
            const Positioned.fill(
              child: InkArt(seed: 'service-ei', intensity: 1.1),
            ),
            Positioned(left: Space.lg, top: Space.lg, child: icon),
            Positioned(
              left: Space.md,
              right: Space.md,
              bottom: Space.md,
              child: GlassPanel(strong: true, shadow: false, child: copy),
            ),
          ],
        ),
      ),
      _Fill.glass => GlassPanel(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [icon, const Spacer(), copy],
        ),
      ),
      // Grey to red: the "transformation" gradient, used once on this page.
      _Fill.gradient => Container(
        padding: const EdgeInsets.all(Space.xl),
        decoration: const BoxDecoration(
          gradient: AppColors.transformation,
          borderRadius: Radii.cardAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [icon, const Spacer(), copy],
        ),
      ),
    };

    return Reveal(
      child: Semantics(
        container: true,
        label: service.title,
        child: TiltCard(onTap: open, child: body),
      ),
    );
  }
}
