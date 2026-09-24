import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// Digital receipt for a successful payment.
class Receipt extends Equatable {
  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
    required this.duesId,
    required this.duesName,
    required this.academicYear,
    required this.amount,
    this.currency = 'GHS',
    required this.paymentId,
    required this.paymentDate,
    this.transactionReference,
    this.qrToken,
    this.status = ReceiptStatus.valid,
    this.issuedAt,
    this.revokedAt,
    this.revokedReason,
  });

  final String id;
  final String receiptNumber; // e.g. CESA-2026-000123
  final String studentId;
  final String studentName;
  final int studentLevel;
  final String duesId;
  final String duesName;
  final String academicYear;
  final int amount; // pesewas
  final String currency;
  final String paymentId;
  final DateTime paymentDate;
  final String? transactionReference;
  final String? qrToken;
  final ReceiptStatus status;
  final DateTime? issuedAt;
  final DateTime? revokedAt;
  final String? revokedReason;

  double get amountInCedis => amount / 100;
  bool get isValid => status == ReceiptStatus.valid;

  factory Receipt.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Receipt(
      id: doc.id,
      receiptNumber: data['receiptNumber'] as String,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      studentLevel: data['studentLevel'] as int,
      duesId: data['duesId'] as String,
      duesName: data['duesName'] as String,
      academicYear: data['academicYear'] as String,
      amount: data['amount'] as int,
      currency: data['currency'] as String? ?? 'GHS',
      paymentId: data['paymentId'] as String,
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      transactionReference: data['transactionReference'] as String?,
      qrToken: data['qrToken'] as String?,
      status: ReceiptStatus.fromValue(data['status'] as String? ?? 'valid'),
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate(),
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedReason: data['revokedReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receiptNumber': receiptNumber,
      'studentId': studentId,
      'studentName': studentName,
      'studentLevel': studentLevel,
      'duesId': duesId,
      'duesName': duesName,
      'academicYear': academicYear,
      'amount': amount,
      'currency': currency,
      'paymentId': paymentId,
      'paymentDate': Timestamp.fromDate(paymentDate),
      if (transactionReference != null)
        'transactionReference': transactionReference,
      if (qrToken != null) 'qrToken': qrToken,
      'status': status.value,
      'issuedAt': issuedAt != null
          ? Timestamp.fromDate(issuedAt!)
          : FieldValue.serverTimestamp(),
      if (revokedAt != null) 'revokedAt': Timestamp.fromDate(revokedAt!),
      if (revokedReason != null) 'revokedReason': revokedReason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        receiptNumber,
        studentId,
        paymentId,
        amount,
        status,
      ];
}
