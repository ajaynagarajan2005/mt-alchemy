import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/cart_item.dart';
import '../../router/routes.dart';
import '../../state/cart_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/reveal.dart';
import '../store/shop_widgets.dart';
import 'order_totals.dart';

/// Cart: line items on the left, order summary on the right (stacked on
/// compact and medium).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    if (cart.isEmpty) {
      return const ShopPage(
        child: ShopMessage(
          title: 'Your cart is empty',
          message: 'Nothing here yet. Browse the store for cards, toolkits and books.',
          actionLabel: 'Visit the store',
          route: Routes.store,
        ),
      );
    }

    final split = context.isExpanded;
    final items = _Items(items: cart.items);
    final summary = GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order summary', style: AppText.h3),
          const SizedBox(height: Space.lg),
          OrderTotals(
            subtotal: cart.subtotal,
            shipping: cart.shipping,
            total: cart.total,
          ),
          const SizedBox(height: Space.lg),
          AlchemyButton(
            label: 'Checkout',
            expand: true,
            onPressed: () => context.go(Routes.checkout),
          ),
        ],
      ),
    );

    return ShopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Your cart', style: AppText.h1(context))),
          const SizedBox(height: Space.xl),
          if (split)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: items),
                const SizedBox(width: Space.xxl),
                Expanded(flex: 4, child: summary),
              ],
            )
          else ...[
            items,
            const SizedBox(height: Space.xl),
            summary,
          ],
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (card): one bordered surface groups all the line items.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _Line(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();
    final p = item.product;
    final size = context.isCompact ? 72.0 : 104.0;

    return Padding(
      padding: EdgeInsets.all(context.isCompact ? Space.md : Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: Radii.smallAll,
            child: SizedBox(
              width: size,
              height: size,
              child: InkArt(seed: p.id, intensity: 0.9),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppText.h4),
                const SizedBox(height: 2),
                Text('${gbpExact.format(p.price)} each', style: AppText.small),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    QuantityStepper(
                      value: item.quantity,
                      itemName: p.name,
                      onChanged: (q) => cart.setQuantity(p.id, q),
                    ),
                    IconButton(
                      tooltip: 'Remove ${p.name} from cart',
                      onPressed: () => cart.remove(p.id),
                      icon: const AppIcon(
                        HugeIcons.strokeRoundedDelete02,
                        size: 20,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(gbpExact.format(item.lineTotal), style: AppText.h4),
        ],
      ),
    );
  }
}
