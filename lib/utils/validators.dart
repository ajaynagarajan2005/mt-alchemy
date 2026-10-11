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
