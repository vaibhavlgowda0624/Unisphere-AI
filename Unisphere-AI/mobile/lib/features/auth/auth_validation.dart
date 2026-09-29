class AuthValidation {
  static String? required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  static String? email(String? value, String allowedDomain) {
    final address = value?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      return 'Enter a valid email address';
    }
    if (allowedDomain.isNotEmpty &&
        !address.endsWith('@${allowedDomain.toLowerCase()}')) {
      return 'Use your $allowedDomain email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String password, String? confirmation) =>
      password == confirmation ? null : 'Passwords do not match';
}
