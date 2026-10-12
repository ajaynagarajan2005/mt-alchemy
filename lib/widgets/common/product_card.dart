import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'card_image.dart';
import '../../data/models/product.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'alchemy_button.dart';
import 'course_card.dart';
import 'tappable.dart';

/// Currency with pence, for line totals, shipping and order totals.
final gbpExact = NumberFormat.currency(locale: 'en_GB', symbol: '£');

/// Store product tile: artwork, category, name, summary, price, quick add.
///
/// CONTAINER (card): the Container draws the white card surface, hairline
/// border and rounded corners. It lifts a few pixels on hover (not under
/// reduced motion).
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onOpen,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final lift = _hover && !Motion.reduced(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tappable(
        radius: Radii.cardAll,
        onTap: widget.onOpen,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.ease,
          transform: Matrix4.translationValues(0, lift ? -6 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Radii.cardAll,
            border: Border.all(
              color: _hover ? AppColors.grey400 : AppColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: lift ? 32 : 0,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: CardHover(
            hovered: lift,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Photo for ${p.name}',
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CardImage(
                      seed: p.id,
                      src: p.imageUrl ?? bundledImage('product-${p.id}'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.category.label, style: AppText.small),
                        const SizedBox(height: Space.xxs),
                        Text(
                          p.name,
                          style: AppText.h3.copyWith(fontSize: 21),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          p.summary,
                          style: AppText.bodyMuted,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Text(gbp.format(p.price), style: AppText.h4),
                            const Spacer(),
                            Flexible(
                              child: AlchemyButton(
                                label: 'Add to cart',
                                variant: ButtonVariant.secondary,
                                onPressed: widget.onAdd,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
