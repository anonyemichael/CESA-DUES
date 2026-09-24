import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

/// A payment transaction for departmental dues.
class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
    required this.duesId,
    required this.duesName,
    required this.academicYear,
    required this.amount,
    this.currency = 'GHS',
    this.status = PaymentStatus.pending,
    this.paymentMethod,
    this.gatewayProvider = 'paystack',
    this.gatewayReference,
    this.gatewayTransactionId,
    this.receiptId,
    this.idempotencyKey,
    this.initiatedAt,
    this.confirmedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final int studentLevel;
  final String duesId;
  final String duesName;
  final String academicYear;
  final int amount; // pesewas
  final String currency;
  final PaymentStatus status;
  final String? paymentMethod;
  final String gatewayProvider;
  final String? gatewayReference;
  final String? gatewayTransactionId;
  final String? receiptId;
  final String? idempotencyKey;
  final DateTime? initiatedAt;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get amountInCedis => amount / 100;

  bool get isSuccessful => status == PaymentStatus.successful;
  bool get isPending =>
      status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isTerminal => status.isTerminal;

  Payment copyWith({
    String? id,
    String? studentId,
    String? studentName,
    int? studentLevel,
    String? duesId,
    String? duesName,
    String? academicYear,
    int? amount,
    String? currency,
    PaymentStatus? status,
    String? paymentMethod,
    String? gatewayProvider,
    String? gatewayReference,
    String? gatewayTransactionId,
    String? receiptId,
    String? idempotencyKey,
    DateTime? initiatedAt,
    DateTime? confirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentLevel: studentLevel ?? this.studentLevel,
      duesId: duesId ?? this.duesId,
      duesName: duesName ?? this.duesName,
      academicYear: academicYear ?? this.academicYear,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gatewayProvider: gatewayProvider ?? this.gatewayProvider,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      receiptId: receiptId ?? this.receiptId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Payment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Payment(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      studentName: (data['studentName'] as String?) ?? 'Student',
      studentLevel: (data['studentLevel'] as num?)?.toInt() ?? 100,
      duesId: (data['duesId'] as String?) ?? '',
      duesName: (data['duesName'] as String?) ?? 'CESA Dues',
      academicYear: (data['academicYear'] as String?) ?? '2025/2026',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] as String?) ?? 'GHS',
      status: PaymentStatus.fromValue(data['status'] as String? ?? 'pending'),
      paymentMethod: data['paymentMethod'] as String?,
      gatewayProvider: (data['gatewayProvider'] as String?) ?? 'paystack',
      gatewayReference: data['gatewayReference'] as String?,
      gatewayTransactionId: data['gatewayTransactionId'] as String?,
      receiptId: data['receiptId'] as String?,
      idempotencyKey: data['idempotencyKey'] as String?,
      initiatedAt: (data['initiatedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate() ?? (data['verifiedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? (data['initiatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentLevel': studentLevel,
      'duesId': duesId,
      'duesName': duesName,
      'academicYear': academicYear,
      'amount': amount,
      'currency': currency,
      'status': status.value,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'gatewayProvider': gatewayProvider,
      if (gatewayReference != null) 'gatewayReference': gatewayReference,
      if (gatewayTransactionId != null)
        'gatewayTransactionId': gatewayTransactionId,
      if (receiptId != null) 'receiptId': receiptId,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      if (initiatedAt != null) 'initiatedAt': Timestamp.fromDate(initiatedAt!),
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        duesId,
        academicYear,
        amount,
        status,
        gatewayReference,
        idempotencyKey,
      ];
}
