import 'package:material_ui/material_ui.dart';

import '../state/commerce_store.dart';
import 'paypal_buttons_stub.dart'
    if (dart.library.js_interop) 'paypal_buttons_web.dart'
    as impl;

/// What PayPal is asked to charge.
class PayPalAmount {
  const PayPalAmount({
    required this.subtotal,
    required this.shipping,
    required this.description,
  });
  final double subtotal;
  final double shipping;
  final String description;
  double get total => subtotal + shipping;
}

/// PayPal's own checkout button. Tapping it opens PayPal (a pop-up on
/// desktop), where the buyer logs in and approves; the payment is then
/// captured and [onPaid] receives the result.
class PayPalButtons extends StatelessWidget {
  const PayPalButtons({
    super.key,
    required this.amount,
    required this.onPaid,
    required this.onError,
    this.onCancel,
    this.canStart,
  });

  final PayPalAmount Function() amount;
  final void Function(PayPalPayment payment) onPaid;
  final void Function(String message) onError;
  final VoidCallback? onCancel;

  /// Called when the button is tapped, before PayPal opens; return false to
  /// stop (for example, when the delivery address is not filled in).
  final bool Function()? canStart;

  @override
  Widget build(BuildContext context) => impl.buildPayPalButtons(
    amount: amount,
    onPaid: onPaid,
    onError: onError,
    onCancel: onCancel,
    canStart: canStart,
  );
}
