import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/mock/products.dart';
import '../../data/models/product.dart';
import '../../router/routes.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/course_card.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/reveal.dart';
import 'shop_widgets.dart';
import 'store_screen.dart' show addToCartWithFeedback;

/// Product detail: artwork, price, description, details and add to cart.
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _quantity = 1;

  @override
  void didUpdateWidget(ProductScreen old) {
    super.didUpdateWidget(old);
    if (old.productId != widget.productId) _quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    final product = productById(widget.productId);
    if (product == null) {
      return const ShopPage(
        child: ShopMessage(
          title: 'We could not find that product',
          message:
              'It may have been removed. The rest of the store is still here.',
          actionLabel: 'Visit the store',
          route: Routes.store,
        ),
      );
    }

    final split = context.isExpanded;
    final visual = ClipRRect(
      borderRadius: Radii.cardAll,
      child: AspectRatio(
        aspectRatio: split ? 1 : (context.isCompact ? 1.1 : 1.6),
        child: Semantics(
          label: 'Artwork for ${product.name}',
          child: InkArt(seed: product.id),
        ),
      ),
    );
    final info = _Info(
      product: product,
      quantity: _quantity,
      onQuantity: (q) => setState(() => _quantity = q),
    );

    final others = [
      for (final p in products)
        if (p.id != product.id) p,
    ].take(3).toList();
    final columns = switch (context.screenSize) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
    };

    return ShopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            child: split
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: visual),
                      const SizedBox(width: Space.xxl),
                      Expanded(flex: 6, child: info),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      visual,
                      const SizedBox(height: Space.xl),
                      info,
                    ],
                  ),
          ),
          const SizedBox(height: Space.xxl),
          Text('You might also like', style: AppText.h2(context)),
          const SizedBox(height: Space.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: Space.lg,
              crossAxisSpacing: Space.lg,
              mainAxisExtent: 440,
            ),
            // Medium shows two so the grid has no orphan card.
            itemCount: columns == 2 ? 2 : others.length,
            itemBuilder: (context, i) {
              final p = others[i];
              return ProductCard(
                product: p,
                onOpen: () => context.go(Routes.product(p.id)),
                onAdd: () => addToCartWithFeedback(context, p),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.product,
    required this.quantity,
    required this.onQuantity,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.category.label, style: AppText.eyebrow),
        const SizedBox(height: Space.sm),
        Text(product.name, style: AppText.h1(context)),
        const SizedBox(height: Space.md),
        Text(gbp.format(product.price), style: AppText.h3),
        const SizedBox(height: Space.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(product.description, style: AppText.lead),
        ),
        const SizedBox(height: Space.lg),
        // CONTAINER (grouping): the details list sits in a bordered card.
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Radii.cardAll,
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is included', style: AppText.h4),
              const SizedBox(height: Space.sm),
              for (final d in product.details)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: AppIcon(
                          HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 18,
                          color: AppColors.red,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(d, style: AppText.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            QuantityStepper(
              value: quantity,
              onChanged: onQuantity,
              itemName: product.name,
            ),
            AlchemyButton(
              label: 'Add to cart',
              icon: HugeIcons.strokeRoundedShoppingCart01,
              onPressed: () =>
                  addToCartWithFeedback(context, product, quantity: quantity),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        ArrowLink(
          label: 'Keep browsing the store',
          onTap: () => context.go(Routes.store),
        ),
      ],
    );
  }
}
