import 'package:material_ui/material_ui.dart';

import '../state/commerce_store.dart';
import 'paypal_buttons.dart';

/// PayPal's button runs on the web build only.
Widget buildPayPalButtons({
  required PayPalAmount Function() amount,
  required void Function(PayPalPayment payment) onPaid,
  required void Function(String message) onError,
  VoidCallback? onCancel,
  bool Function()? canStart,
}) => const Text('PayPal is available on the website.');
