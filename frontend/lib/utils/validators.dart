class Validators {
  static String? required(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) {
      return label != null ? '$label is required' : 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final r = required(value, 'Email');
    if (r != null) return r;
    final regex = RegExp(r'^[\w\-.+]+@[\w\-]+\.\w{2,}$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final r = required(value, 'Password');
    if (r != null) return r;
    if (value!.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    final r = required(value, 'Confirm Password');
    if (r != null) return r;
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? amount(String? value, {bool required = true}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'Amount is required';
    }
    if (value != null && value.isNotEmpty) {
      final num? parsed = num.tryParse(value);
      if (parsed == null) return 'Please enter a valid number';
      if (parsed < 0) return 'Amount cannot be negative';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    final r = amount(value);
    if (r != null) return r;
    final num parsed = num.parse(value!);
    if (parsed <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? exactFourDigits(String? value) {
    final r = required(value, 'Last 4 digits');
    if (r != null) return r;
    final regex = RegExp(r'^\d{4}$');
    if (!regex.hasMatch(value!.trim())) return 'Must be exactly 4 digits';
    return null;
  }

  static String? sixDigitCode(String? value) {
    final r = required(value, 'Code');
    if (r != null) return r;
    final regex = RegExp(r'^\d{6}$');
    if (!regex.hasMatch(value!.trim())) return 'Must be exactly 6 digits';
    return null;
  }

  static String? notesOptional(String? value) {
    if (value != null && value.length > 1000) {
      return 'Notes cannot exceed 1000 characters';
    }
    return null;
  }
}
