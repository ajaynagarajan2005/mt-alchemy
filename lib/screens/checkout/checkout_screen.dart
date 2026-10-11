import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/glass_panel.dart';
import '../../widgets/common/ink_art.dart';
import '../../widgets/common/labeled_field.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/reveal.dart';
import '../cart/order_totals.dart';
import '../store/shop_widgets.dart';

/// Checkout: delivery details and a demo payment form beside the order summary.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // FORM: one Form key validates every field below on "Place order".
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _cardName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();

  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthStore>().currentUser;
    if (user != null) {
      _name.text = user.name;
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _address1,
      _address2,
      _city,
      _postcode,
      _cardName,
      _cardNumber,
      _expiry,
      _cvc,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    // Clear any stale "Added to cart" message before the confirmation.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.read<CartStore>().placeOrder(email: _email.text.trim());
    context.go(Routes.checkoutSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    if (cart.isEmpty && !_placing) {
      return const ShopPage(
        child: ShopMessage(
          title: 'Nothing to check out',
          message: 'Your cart is empty. Add something from the store first.',
          actionLabel: 'Visit the store',
          route: Routes.store,
        ),
      );
    }

    final split = context.isExpanded;
    final form = _form(context);
    final summary = _summary(context, cart);

    return ShopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: Text('Checkout', style: AppText.h1(context))),
          const SizedBox(height: Space.xl),
          if (split)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: form),
                const SizedBox(width: Space.xxl),
                Expanded(flex: 4, child: summary),
              ],
            )
          else ...[
            form,
            const SizedBox(height: Space.xl),
            summary,
          ],
        ],
      ),
    );
  }

  /// Two fields side by side from medium up, stacked on compact.
  Widget _pair(BuildContext context, Widget a, Widget b) {
    if (context.isCompact) {
      return Column(
        children: [
          a,
          const SizedBox(height: Space.md),
          b,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: Space.md),
        Expanded(child: b),
      ],
    );
  }

  Widget _form(BuildContext context) {
    const gap = SizedBox(height: Space.md);
    // CONTAINER (decoration): the whole form sits in a strong GlassPanel.
    return GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery details', style: AppText.h3),
            const SizedBox(height: Space.lg),
            _pair(
              context,
              LabeledField(
                label: 'Full name',
                controller: _name,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'your full name'),
              ),
              LabeledField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
            ),
            gap,
            LabeledField(
              label: 'Address line 1',
              controller: _address1,
              autofillHints: const [AutofillHints.streetAddressLine1],
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'your address'),
            ),
            gap,
            LabeledField(
              label: 'Address line 2 (optional)',
              controller: _address2,
              autofillHints: const [AutofillHints.streetAddressLine2],
              textInputAction: TextInputAction.next,
            ),
            gap,
            _pair(
              context,
              LabeledField(
                label: 'Town or city',
                controller: _city,
                autofillHints: const [AutofillHints.addressCity],
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'your town or city'),
              ),
              LabeledField(
                label: 'Postcode',
                controller: _postcode,
                autofillHints: const [AutofillHints.postalCode],
                textInputAction: TextInputAction.next,
                validator: CheckoutValidators.postcode,
              ),
            ),
            const SizedBox(height: Space.xl),
            Text('Payment', style: AppText.h3),
            const SizedBox(height: Space.xs),
            // Demo notice: no real card data is processed anywhere.
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: AppColors.redSoft,
                borderRadius: Radii.inputAll,
              ),
              child: Text(
                'Demo payment. No real payment is taken. Use any valid test '
                'card number, such as 4242 4242 4242 4242.',
                style: AppText.small.copyWith(color: AppColors.ink),
              ),
            ),
            const SizedBox(height: Space.md),
            LabeledField(
              label: 'Name on card',
              controller: _cardName,
              autofillHints: const [AutofillHints.creditCardName],
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'the name on the card'),
            ),
            gap,
            LabeledField(
              label: 'Card number',
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardNumber],
              textInputAction: TextInputAction.next,
              inputFormatters: [_GroupFormatter.card],
              validator: CheckoutValidators.cardNumber,
            ),
            gap,
            _pair(
              context,
              LabeledField(
                label: 'Expiry (MM/YY)',
                controller: _expiry,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardExpirationDate],
                textInputAction: TextInputAction.next,
                inputFormatters: [_GroupFormatter.expiry],
                validator: CheckoutValidators.expiry,
              ),
              LabeledField(
                label: 'CVC',
                controller: _cvc,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardSecurityCode],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _placeOrder(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: CheckoutValidators.cvc,
              ),
            ),
            const SizedBox(height: Space.xl),
            AlchemyButton(
              label: 'Place order',
              expand: context.isCompact,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, CartStore cart) {
    // CONTAINER (card): bordered surface listing what is being bought.
    return Container(
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your order', style: AppText.h3),
          const SizedBox(height: Space.md),
          for (final i in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: Radii.smallAll,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: InkArt(seed: i.product.id, intensity: 0.9),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      '${i.product.name} x ${i.quantity}',
                      style: AppText.body,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Text(gbpExact.format(i.lineTotal), style: AppText.label),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          OrderTotals(
            subtotal: cart.subtotal,
            shipping: cart.shipping,
            total: cart.total,
          ),
        ],
      ),
    );
  }
}

/// Keeps digits only and re-inserts separators as the user types.
class _GroupFormatter extends TextInputFormatter {
  const _GroupFormatter(this.group, this.separator, this.maxDigits);

  /// Card number: groups of 4 separated by spaces, 16 digits.
  static const card = _GroupFormatter(4, ' ', 16);

  /// Expiry: MM/YY.
  static const expiry = _GroupFormatter(2, '/', 4);

  final int group;
  final String separator;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % group == 0) buffer.write(separator);
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
