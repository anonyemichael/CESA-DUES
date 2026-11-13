/// Application-wide constants for ACES DUES.
///
/// Every user-facing identity string lives here so the association, department
/// or university wording can be changed in one place. Nothing else in the
/// system (Firestore collections, package ids, Firebase project) depends on
/// these display names.
class AppConstants {
  AppConstants._();

  // ── Identity ────────────────────────────────────────────────────────────
  /// Short product name shown in app bars, titles and notifications.
  static const String appName = 'ACES DUES';

  /// Association acronym (used on receipts, QR passes and badges).
  static const String organizationName = 'ACES';

  /// Full association name.
  static const String associationFullName =
      'Association of Computer Engineering Students';

  /// Year the association was founded (appears on the crest).
  static const String associationFounded = '2021';

  static const String appFullName =
      '$associationFullName (UENR) Dues Management System';

  /// Programme / discipline the association serves.
  static const String departmentName = 'Computer Engineering';
  static const String departmentNameUpper = 'COMPUTER ENGINEERING';

  /// Academic department that owns the BSc Computer Engineering programme.
  static const String departmentFullName =
      'Department of Electrical & Computer Engineering';

  static const String schoolName = 'School of Engineering';
  static const String universityName =
      'University of Energy and Natural Resources';
  static const String universityShort = 'UENR';
  static const String campus = 'Sunyani';
  static const String universityMotto = 'Knowledge, Integrity, Impact';

  /// Default programme written to new roster records.
  static const String programmeName = 'BSc. Computer Engineering';

  /// Placeholder name used when a roster record has no name yet.
  static const String defaultStudentName = 'Computer Engineering Student';

  /// Student e-mail domain used to derive a payer e-mail when none is known.
  static const String studentEmailDomain = 'st.uenr.edu.gh';

  /// One-line institutional footer.
  static const String institutionFooter =
      '$departmentFullName\n$universityName ($universityShort), $campus';

  // ── Receipts ────────────────────────────────────────────────────────────
  /// Prefix for receipt identifiers and payment references, e.g. ACES-2026-1A2B3C4D.
  static const String receiptPrefix = 'ACES';

  /// Older receipts issued before the rebrand still carry this prefix; keep it
  /// recognised by QR scanners and receipt lookups.
  static const List<String> legacyReceiptPrefixes = ['CESA'];

  // Pagination
  static const int defaultPageSize = 20;
  static const int adminPageSize = 50;

  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 15;
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
