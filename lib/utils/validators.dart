/// Pure form validators. Each returns an error message, or null when valid.
/// They plug straight into `TextFormField.validator`.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// [label] reads naturally in "Enter <label>".
  static String? required(String? value, [String label = 'this field']) {
    if (value == null || value.trim().isEmpty) return 'Enter $label.';
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, 'your email address');
    if (missing != null) return missing;
    if (!_email.hasMatch(value!.trim())) {
      return 'Enter a valid email address, like name@example.com.';
    }
    return null;
  }

  /// At least 8 characters with a letter and a number.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!value.contains(RegExp(r'[A-Za-z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? confirm(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Re-enter your password.';
    if (value != original) return 'The passwords do not match.';
    return null;
  }

  static String? minLength(String? value, int min, [String label = 'a value']) {
    final missing = required(value, label);
    if (missing != null) return missing;
    if (value!.trim().length < min) {
      return 'Use at least $min characters.';
    }
    return null;
  }
}

/// Checkout validators (UK postcode, demo card details).
abstract final class CheckoutValidators {
  static final _postcode = RegExp(
    r'^[A-Z]{1,2}[0-9][A-Z0-9]?\s?[0-9][A-Z]{2}$',
    caseSensitive: false,
  );

  static String? postcode(String? value) {
    final missing = Validators.required(value, 'your postcode');
    if (missing != null) return missing;
    if (!_postcode.hasMatch(value!.trim())) {
      return 'Enter a UK postcode, like SW1A 1AA.';
    }
    return null;
  }

  /// True when [digits] (digits only) passes the Luhn checksum.
  static bool luhn(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (alternate) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alternate = !alternate;
    }
    return digits.isNotEmpty && sum % 10 == 0;
  }

  /// 16 digits (spaces allowed) that pass the Luhn check.
  static String? cardNumber(String? value) {
    final missing = Validators.required(value, 'your card number');
    if (missing != null) return missing;
    final digits = value!.replaceAll(' ', '');
    if (!RegExp(r'^[0-9]{16}$').hasMatch(digits)) {
      return 'Enter the 16 digits on your card.';
    }
    if (!luhn(digits)) return 'That card number does not look right.';
    return null;
  }

  /// MM/YY, not in the past. A card is valid to the end of its expiry month.
  static String? expiry(String? value, {DateTime? now}) {
    final missing = Validators.required(value, 'the expiry date');
    if (missing != null) return missing;
    final match = RegExp(r'^([0-9]{2})/([0-9]{2})$').firstMatch(value!.trim());
    if (match == null) return 'Use the format MM/YY.';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'The month must be 01 to 12.';
    final today = now ?? DateTime.now();
    if (year < today.year || (year == today.year && month < today.month)) {
      return 'This card has expired.';
    }
    return null;
  }

  static String? cvc(String? value) {
    final missing = Validators.required(value, 'the 3 digit security code');
    if (missing != null) return missing;
    if (!RegExp(r'^[0-9]{3}$').hasMatch(value!.trim())) {
      return 'The security code is 3 digits.';
    }
    return null;
  }
}
