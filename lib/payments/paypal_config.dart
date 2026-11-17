/// PayPal settings, fixed when the app is built.
///
/// Get the Client ID from developer.paypal.com > Apps & Credentials. It is a
/// public identifier (it is sent to every visitor's browser), so it is safe in
/// the build. Never put the PayPal *Secret* in the app.
///
///   `flutter build web --dart-define=PAYPAL_CLIENT_ID=YOUR_CLIENT_ID`
///
/// With no Client ID the checkout falls back to the demo card form only.
abstract final class PayPalConfig {
  static const clientId = String.fromEnvironment('PAYPAL_CLIENT_ID');

  /// `sandbox` (test money, the default) or `live` (real money). It must
  /// match the kind of Client ID above; it is recorded on each payment.
  static const environment = String.fromEnvironment(
    'PAYPAL_ENV',
    defaultValue: 'sandbox',
  );

  static const currency = 'GBP';

  static bool get enabled => clientId.isNotEmpty;
  static bool get isSandbox => environment != 'live';
}
