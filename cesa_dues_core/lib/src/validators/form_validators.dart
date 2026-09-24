/// Form validation functions shared between Student App and Admin Portal.
class FormValidators {
  FormValidators._();

  /// Validate email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate student index number format.
  /// Expected: letters followed by digits, e.g. CE2024001
  static String? indexNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Index number is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length < 5) {
      return 'Index number is too short';
    }
    // Allow alphanumeric format common in Ghanaian universities
    final indexRegex = RegExp(r'^[A-Z]{2,4}\d{4,}$');
    if (!indexRegex.hasMatch(trimmed)) {
      return 'Enter a valid index number (e.g. CE2024001)';
    }
    return null;
  }

  /// Validate required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate full name.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Name is too short';
    }
    return null;
  }

  /// Validate phone number (Ghana format).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    // Ghana: +233XXXXXXXXX or 0XXXXXXXXX
    final ghanaRegex = RegExp(r'^(\+233|0)\d{9}$');
    if (!ghanaRegex.hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validate monetary amount (in cedis).
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  /// Validate password (for student accounts).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate OTP code.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification code is required';
    }
    if (value.trim().length != 6) {
      return 'Enter the 6-digit code';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Code must be 6 digits';
    }
    return null;
  }

  /// Validate academic year format (e.g. 2026/2027).
  static String? academicYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Academic year is required';
    }
    final regex = RegExp(r'^\d{4}/\d{4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format: YYYY/YYYY (e.g. 2026/2027)';
    }
    final parts = value.trim().split('/');
    final start = int.parse(parts[0]);
    final end = int.parse(parts[1]);
    if (end != start + 1) {
      return 'End year must be start year + 1';
    }
    return null;
  }
}
