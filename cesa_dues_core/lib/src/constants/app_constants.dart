/// Application-wide constants for CESA DUES.
class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'CESA DUES';
  static const String appFullName =
      "Civil Engineering Students' Association Dues Management System";
  static const String organizationName = 'CESA';
  static const String departmentName = 'Civil Engineering';

  // Receipt format
  static const String receiptPrefix = 'CESA';

  // Pagination
  static const int defaultPageSize = 20;
  static const int adminPageSize = 50;

  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  static const int otpMaxAttempts = 5;
  static const int otpResendCooldownSeconds = 60;

  // Images
  static const int maxImageWidth = 1024;
  static const int imageQuality = 70;
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB

  // Currency
  static const String currencyCode = 'GHS';
  static const String currencySymbol = 'GH₵';

  // Academic levels
  static const List<int> academicLevels = [100, 200, 300, 400];

  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);
}
