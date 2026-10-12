import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/product_card.dart' show gbpExact;
import '../../state/cart_store.dart';

/// Subtotal, shipping and total rows, plus the free-shipping nudge.
class OrderTotals extends StatelessWidget {
  const OrderTotals({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.total,
    this.showNudge = true,
    this.physicalSubtotal,
  });

  final double subtotal;
  final double shipping;
  final double total;
  final bool showNudge;

  /// Spend on shipped goods; null means everything ships. Zero hides the
  /// shipping row because digital items and courses never ship.
  final double? physicalSubtotal;

  @override
  Widget build(BuildContext context) {
    final shipped = physicalSubtotal ?? subtotal;
    final remaining = CartStore.freeShippingFrom - shipped;
    final ships = shipped > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Subtotal', gbpExact.format(subtotal)),
        if (ships) ...[
          const SizedBox(height: Space.xs),
          _Row('Shipping', shipping == 0 ? 'Free' : gbpExact.format(shipping)),
        ],
        if (showNudge && ships) ...[
          const SizedBox(height: Space.xs),
          Text(
            remaining > 0
                ? 'Add ${gbpExact.format(remaining)} more for free shipping. '
                      'Free over £${CartStore.freeShippingFrom.toStringAsFixed(0)}.'
                : 'Your order qualifies for free shipping.',
            style: AppText.small,
          ),
        ],
        Padding(
          padding: EdgeInsets.symmetric(vertical: Space.md),
          child: Divider(height: 1, color: AppColors.line),
        ),
        _Row('Total', gbpExact.format(total), strong: true),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? AppText.h4 : AppText.body;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
