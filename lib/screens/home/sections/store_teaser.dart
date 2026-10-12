import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../state/catalog_store.dart';

import '../../../router/routes.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/course_card.dart' show gbp;
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/ink_art.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';
import '../../../widgets/common/tappable.dart';

/// Split layout: product visual on one side, copy and CTA on the other.
/// Stacks visual-first below 1024px.
class StoreTeaser extends StatelessWidget {
  const StoreTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = context.watch<CatalogStore>().products.first;

    final visual = ClipRRect(
      borderRadius: Radii.cardAll,
      child: SizedBox(
        height: context.isCompact ? 300 : 420,
        child: Stack(
          children: [
            const Positioned.fill(
              child: InkArt(seed: 'store-teaser', intensity: 1),
            ),
            // Real product data from the catalogue, previewed as a glass tag.
            Positioned(
              left: Space.lg,
              bottom: Space.lg,
              child: Tappable(
                onTap: () => context.go(Routes.product(featured.id)),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GlassPanel(
                    strong: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(featured.name, style: AppText.label),
                        const SizedBox(height: 2),
                        Text(
                          gbp.format(featured.price),
                          style: AppText.small.copyWith(color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tools that keep the work going', style: AppText.h2(context)),
        const SizedBox(height: Space.md),
        Text(
          'Card decks, workbooks and workshop kits drawn from our programmes, so teams '
          'keep practising between sessions.',
          style: AppText.lead,
        ),
        const SizedBox(height: Space.xl),
        AlchemyButton(
          label: 'Visit the store',
          variant: ButtonVariant.secondary,
          onPressed: () => context.go(Routes.store),
        ),
      ],
    );

    return Section(
      child: Reveal(
        child: context.isExpanded
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: visual),
                  const SizedBox(width: Space.xxxl),
                  Expanded(flex: 5, child: copy),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visual,
                  const SizedBox(height: Space.xl),
                  copy,
                ],
              ),
      ),
    );
  }
}
