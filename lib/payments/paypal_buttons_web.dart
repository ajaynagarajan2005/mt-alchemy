import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import '../state/commerce_store.dart';
import 'paypal_buttons.dart';
import 'paypal_config.dart';

Widget buildPayPalButtons({
  required PayPalAmount Function() amount,
  required void Function(PayPalPayment payment) onPaid,
  required void Function(String message) onError,
  VoidCallback? onCancel,
  bool Function()? canStart,
}) => _PayPalButtons(
  amount: amount,
  onPaid: onPaid,
  onError: onError,
  onCancel: onCancel,
  canStart: canStart,
);

Future<JSObject>? _sdk;

/// Loads https://www.paypal.com/sdk/js once and returns `window.paypal`.
Future<JSObject> _loadSdk() => _sdk ??= () async {
  final existing = web.window.getProperty<JSObject?>('paypal'.toJS);
  if (existing != null) return existing;
  final done = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src =
        'https://www.paypal.com/sdk/js'
        '?client-id=${Uri.encodeQueryComponent(PayPalConfig.clientId)}'
        '&currency=${PayPalConfig.currency}&intent=capture'
        '&components=buttons&disable-funding=paylater,credit'
    ..async = true;
  script.onload = ((web.Event _) => done.complete()).toJS;
  script.onerror = ((web.Event _) => done.completeError(
    'PayPal could not be loaded. Check your connection and try again.',
  )).toJS;
  web.document.head!.append(script);
  await done.future;
  final paypal = web.window.getProperty<JSObject?>('paypal'.toJS);
  if (paypal == null) throw 'PayPal could not be loaded.';
  return paypal;
}();

String _money(double v) => v.toStringAsFixed(2);

class _PayPalButtons extends StatefulWidget {
  const _PayPalButtons({
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
  final bool Function()? canStart;

  @override
  State<_PayPalButtons> createState() => _PayPalButtonsState();
}

class _PayPalButtonsState extends State<_PayPalButtons> {
  String? _loadError;
  bool _ready = false;

  // PayPal renders a 45-55px button; its pop-up handles everything else.
  static const _height = 56.0;

  Future<void> _render(web.HTMLElement host) async {
    host.style
      ..width = '100%'
      ..height = '${_height}px';
    try {
      final paypal = await _loadSdk();
      // PayPal can only render into an element that is in the page.
      for (var i = 0; i < 100 && !host.isConnected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      final funding = paypal.getProperty<JSObject>('FUNDING'.toJS);
      final options = JSObject()
        ..setProperty('fundingSource'.toJS, funding.getProperty('PAYPAL'.toJS))
        ..setProperty(
          'style'.toJS,
          {
            'layout': 'horizontal',
            'color': 'gold',
            'shape': 'pill',
            'label': 'pay',
            'height': 48,
            'tagline': false,
          }.jsify(),
        )
        ..setProperty('onClick'.toJS, _onClick.toJS)
        ..setProperty('createOrder'.toJS, _createOrder.toJS)
        ..setProperty('onApprove'.toJS, _onApprove.toJS)
        ..setProperty('onCancel'.toJS, _onCancel.toJS)
        ..setProperty('onError'.toJS, _onSdkError.toJS);
      final buttons = paypal.callMethod<JSObject>('Buttons'.toJS, options);
      await buttons.callMethod<JSPromise<JSAny?>>('render'.toJS, host).toDart;
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  JSAny? _onClick(JSAny? data, JSObject actions) {
    final ok = widget.canStart?.call() ?? true;
    return actions.callMethod<JSAny?>((ok ? 'resolve' : 'reject').toJS);
  }

  /// Creates the PayPal order for the current cart total, in GBP.
  JSPromise<JSAny?> _createOrder(JSAny? data, JSObject actions) {
    final a = widget.amount();
    final order = {
      'intent': 'CAPTURE',
      'purchase_units': [
        {
          'description': a.description.length > 127
              ? a.description.substring(0, 127)
              : a.description,
          'amount': {
            'currency_code': PayPalConfig.currency,
            'value': _money(a.total),
            'breakdown': {
              'item_total': {
                'currency_code': PayPalConfig.currency,
                'value': _money(a.subtotal),
              },
              'shipping': {
                'currency_code': PayPalConfig.currency,
                'value': _money(a.shipping),
              },
            },
          },
        },
      ],
      'application_context': {'shipping_preference': 'NO_SHIPPING'},
    }.jsify();
    final orderApi = actions.getProperty<JSObject>('order'.toJS);
    return orderApi.callMethod<JSPromise<JSAny?>>('create'.toJS, order);
  }

  /// The buyer approved in PayPal: capture the money, then hand the result on.
  JSPromise<JSAny?> _onApprove(JSObject data, JSObject actions) {
    Future<JSAny?> run() async {
      try {
        final orderApi = actions.getProperty<JSObject>('order'.toJS);
        final details = await orderApi
            .callMethod<JSPromise<JSObject>>('capture'.toJS)
            .toDart;
        final orderId =
            (details.getProperty<JSString?>('id'.toJS) ??
                    data.getProperty<JSString?>('orderID'.toJS))
                ?.toDart ??
            '';
        var status =
            details.getProperty<JSString?>('status'.toJS)?.toDart ?? '';
        var captureId = '';
        final units = details.getProperty<JSArray<JSObject>?>(
          'purchase_units'.toJS,
        );
        if (units != null && units.length > 0) {
          final payments = units[0].getProperty<JSObject?>('payments'.toJS);
          final captures = payments?.getProperty<JSArray<JSObject>?>(
            'captures'.toJS,
          );
          if (captures != null && captures.length > 0) {
            captureId =
                captures[0].getProperty<JSString?>('id'.toJS)?.toDart ?? '';
            status =
                captures[0].getProperty<JSString?>('status'.toJS)?.toDart ??
                status;
          }
        }
        final payer = details.getProperty<JSObject?>('payer'.toJS);
        final email = payer
            ?.getProperty<JSString?>('email_address'.toJS)
            ?.toDart;
        widget.onPaid(
          PayPalPayment(
            orderId: orderId,
            captureId: captureId.isEmpty ? orderId : captureId,
            status: status,
            payerEmail: email,
            environment: PayPalConfig.isSandbox ? 'sandbox' : 'live',
          ),
        );
      } catch (e) {
        widget.onError(
          'PayPal could not complete the payment. You have not been '
          'charged; please try again.',
        );
      }
      return null;
    }

    return run().toJS;
  }

  void _onCancel(JSAny? data) => widget.onCancel?.call();

  void _onSdkError(JSAny? err) => widget.onError(
    'Something went wrong with PayPal. You have not been charged; '
    'please try again.',
  );

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Text(_loadError!, style: TextStyle(color: Colors.red.shade700));
    }
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          HtmlElementView.fromTagName(
            tagName: 'div',
            onElementCreated: (e) => _render(e as web.HTMLElement),
          ),
          if (!_ready)
            const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
