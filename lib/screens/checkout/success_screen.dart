import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/cart_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/reveal.dart';
import '../store/shop_widgets.dart';

/// Order confirmation. The grey to red gradient marks the moment of change.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<CartStore>().lastOrder;

    if (order == null) {
      return const ShopPage(
        child: ShopMessage(
          title: 'No recent order',
          message: 'There is no order to show right now. The store is a good place to start.',
          actionLabel: 'Visit the store',
          route: Routes.store,
        ),
      );
    }

    final compact = context.isCompact;
    final white = AppText.body.copyWith(color: Colors.white);

    return ShopPage(
      child: Reveal(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            // CONTAINER (decoration): gradient panel for the moment of change.
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? Space.lg : Space.xxl),
              decoration: const BoxDecoration(
                gradient: AppColors.transformation,
                borderRadius: Radii.cardAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Thank you. Your order is confirmed.',
                    style: AppText.h1(context).copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'Order number',
                    style: white.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SelectableText(
                    order.number,
                    style: AppText.h2(context).copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'A confirmation would be sent to ${order.email}. '
                    'This is a demo, so no payment was taken.',
                    style: white,
                  ),
                  const SizedBox(height: Space.lg),
                  const Divider(height: 1, color: Colors.white38),
                  const SizedBox(height: Space.md),
                  for (final i in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i.product.name} x ${i.quantity}',
                              style: white,
                            ),
                          ),
                          Text(
                            gbpExact.format(i.lineTotal),
                            style: white.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.shipping == 0 ? 'Shipping (free)' : 'Shipping',
                          style: white,
                        ),
                      ),
                      Text(gbpExact.format(order.shipping), style: white),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: white.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        gbpExact.format(order.total),
                        style: white.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.md,
                    children: [
                      // The single primary action; the other is inverse.
                      _OnGradientButton(
                        label: 'Keep shopping',
                        onPressed: () => context.go(Routes.store),
                      ),
                      AlchemyButton(
                        label: 'Browse learning',
                        variant: ButtonVariant.inverse,
                        onPressed: () => context.go(Routes.upskilling),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White pill so the primary action stays legible on the gradient.
class _OnGradientButton extends StatelessWidget {
  const _OnGradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: Radii.pillAll),
        textStyle: AppText.button,
      ),
      child: Text(label),
    );
  }
}
