// Application-wide enumerations for CESA DUES.

/// User roles in the system.
enum UserRole {
  student('student', 'Student'),
  hod('hod', 'Head of Department'),
  financialSecretary('financial_secretary', 'Financial Secretary');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }
}

/// Payment status lifecycle.
enum PaymentStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  successful('successful', 'Successful'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Expired'),
  refunded('refunded', 'Refunded');

  const PaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown payment status: $value'),
    );
  }

  bool get isTerminal =>
      this == successful || this == failed || this == cancelled || this == refunded;
}

/// Student verification status.
enum VerificationStatus {
  unverified('unverified', 'Unverified'),
  pending('pending', 'Pending Verification'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected');

  const VerificationStatus(this.value, this.label);
  final String value;
  final String label;

  static VerificationStatus fromValue(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown verification status: $value'),
    );
  }
}

/// Academic year status.
enum AcademicYearStatus {
  active('active', 'Active'),
  archived('archived', 'Archived');

  const AcademicYearStatus(this.value, this.label);
  final String value;
  final String label;

  static AcademicYearStatus fromValue(String value) {
    return AcademicYearStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown academic year status: $value'),
    );
  }
}

/// Dues status.
enum DuesStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive');

  const DuesStatus(this.value, this.label);
  final String value;
  final String label;

  static DuesStatus fromValue(String value) {
    return DuesStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown dues status: $value'),
    );
  }
}

/// Receipt status.
enum ReceiptStatus {
  valid('valid', 'Valid'),
  revoked('revoked', 'Revoked');

  const ReceiptStatus(this.value, this.label);
  final String value;
  final String label;

  static ReceiptStatus fromValue(String value) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown receipt status: $value'),
    );
  }
}

/// Import status.
enum ImportStatus {
  processing('processing', 'Processing'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed');

  const ImportStatus(this.value, this.label);
  final String value;
  final String label;

  static ImportStatus fromValue(String value) {
    return ImportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown import status: $value'),
    );
  }
}

/// Notification target audience.
enum NotificationTarget {
  all('all', 'All Students'),
  level100('level_100', 'Level 100'),
  level200('level_200', 'Level 200'),
  level300('level_300', 'Level 300'),
  level400('level_400', 'Level 400'),
  unpaid('unpaid', 'Unpaid Students'),
  personal('personal', 'Personal');

  const NotificationTarget(this.value, this.label);
  final String value;
  final String label;

  static NotificationTarget fromValue(String value) {
    return NotificationTarget.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown notification target: $value'),
    );
  }
}

/// Notification type.
enum NotificationType {
  reminder('reminder', 'Reminder'),
  announcement('announcement', 'Announcement'),
  paymentConfirmation('payment_confirmation', 'Payment Confirmation');

  const NotificationType(this.value, this.label);
  final String value;
  final String label;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown notification type: $value'),
    );
  }
}

/// Audit log action types.
enum AuditAction {
  adminLogin('admin_login', 'Admin Login'),
  roleSelected('role_selected', 'Role Selected'),
  studentImport('student_import', 'Student Import'),
  duesCreated('dues_created', 'Dues Created'),
  duesModified('dues_modified', 'Dues Modified'),
  studentModified('student_modified', 'Student Modified'),
  studentVerified('student_verified', 'Student Verified'),
  paymentVerified('payment_verified', 'Payment Verified'),
  receiptGenerated('receipt_generated', 'Receipt Generated'),
  reportGenerated('report_generated', 'Report Generated'),
  notificationSent('notification_sent', 'Notification Sent'),
  academicYearCreated('academic_year_created', 'Academic Year Created'),
  academicYearArchived('academic_year_archived', 'Academic Year Archived');

  const AuditAction(this.value, this.label);
  final String value;
  final String label;

  static AuditAction fromValue(String value) {
    return AuditAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown audit action: $value'),
    );
  }
}
