/// Firestore collection and document paths.
class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String config = 'config';
  static const String academicYears = 'academicYears';
  static const String students = 'students';
  static const String studentAccounts = 'studentAccounts';
  static const String dues = 'dues';
  static const String payments = 'payments';
  static const String receipts = 'receipts';
  static const String imports = 'imports';
  static const String notifications = 'notifications';
  static const String auditLogs = 'auditLogs';
  static const String aggregates = 'aggregates';
  static const String otpSessions = 'otpSessions';

  // Singleton config documents
  static const String appSettings = '$config/appSettings';
  static const String receiptCounter = '$config/receiptCounter';

  // Dynamic paths
  static String student(String indexNumber) => '$students/$indexNumber';
  static String studentAccount(String uid) => '$studentAccounts/$uid';
  static String payment(String paymentId) => '$payments/$paymentId';
  static String receipt(String receiptId) => '$receipts/$receiptId';
  static String duesDoc(String duesId) => '$dues/$duesId';
  static String importDoc(String importId) => '$imports/$importId';
  static String auditLog(String logId) => '$auditLogs/$logId';
  static String aggregate(String academicYear) =>
      '$aggregates/payments_${academicYear.replaceAll('/', '_')}';
}
