import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../constants/firestore_paths.dart';
import '../errors/app_exception.dart';

/// Provider for the PaymentRepository.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseFirestore.instance);
});

/// Repository for managing Payments data in Firestore.
class PaymentRepository {
  PaymentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Payment> get _paymentsRef =>
      _firestore.collection(FirestorePaths.payments).withConverter<Payment>(
            fromFirestore: (snapshot, _) => Payment.fromFirestore(snapshot),
            toFirestore: (payment, _) => payment.toFirestore(),
          );

  /// Fetches all payments for a specific student.
  Future<List<Payment>> getStudentPayments(String indexNumber) async {
    try {
      final snapshot = await _paymentsRef
          .where('studentId', isEqualTo: indexNumber)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch payments.');
    }
  }

  /// Watches all payments for a specific student (real-time).
  Stream<List<Payment>> watchStudentPayments(String indexNumber) {
    return _paymentsRef
        .where('studentId', isEqualTo: indexNumber)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Fetches all completed payments for a specific student (Receipts).
  Future<List<Payment>> getStudentReceipts(String indexNumber) async {
    try {
      final snapshot = await _paymentsRef
          .where('studentId', isEqualTo: indexNumber)
          .where('status', isEqualTo: 'successful')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch receipts.');
    }
  }

  /// Fetches all successful payments for a specific dues ID (Admin Reporting).
  Future<List<Payment>> getSuccessfulPaymentsByDuesId(String duesId) async {
    try {
      final snapshot = await _paymentsRef
          .where('duesId', isEqualTo: duesId)
          .where('status', isEqualTo: 'successful')
          .orderBy('createdAt', descending: true)
          .get();
      final rawPayments = snapshot.docs.map((doc) => doc.data()).toList();
      return _enrichPaymentsWithStudentInfo(rawPayments);
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch payments for reporting.');
    }
  }

  /// Fetches all successful payments (Admin Reporting).
  Future<List<Payment>> getAllSuccessfulPayments() async {
    try {
      final snapshot = await _paymentsRef
          .where('status', isEqualTo: 'successful')
          .orderBy('createdAt', descending: true)
          .get();
      final rawPayments = snapshot.docs.map((doc) => doc.data()).toList();
      return _enrichPaymentsWithStudentInfo(rawPayments);
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch all payments.');
    }
  }

  /// Helper to enrich payments with real student names, levels, and dues package names
  Future<List<Payment>> _enrichPaymentsWithStudentInfo(List<Payment> rawPayments) async {
    if (rawPayments.isEmpty) return rawPayments;

    try {
      // 1. Fetch Dues packages dictionary
      final duesMap = <String, Map<String, dynamic>>{};
      try {
        final duesSnaps = await _firestore.collection(FirestorePaths.dues).get();
        for (final dDoc in duesSnaps.docs) {
          final data = dDoc.data();
          duesMap[dDoc.id] = data;
          if (data['name'] != null) {
            duesMap[dDoc.id.toLowerCase()] = data;
          }
        }
      } catch (_) {}

      // 2. Fetch Student roster info
      final studentIds = rawPayments
          .map((p) => p.studentId.toUpperCase().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      final studentsMap = <String, Map<String, dynamic>>{};
      if (studentIds.isNotEmpty) {
        final idList = studentIds.toList();
        for (var i = 0; i < idList.length; i += 30) {
          final chunk = idList.sublist(i, (i + 30 > idList.length) ? idList.length : i + 30);
          final studentSnaps = await _firestore
              .collection(FirestorePaths.students)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final sDoc in studentSnaps.docs) {
            final data = sDoc.data();
            studentsMap[sDoc.id.toUpperCase().trim()] = data;
            if (data['indexNumber'] != null) {
              studentsMap[(data['indexNumber'] as String).toUpperCase().trim()] = data;
            }
          }
        }
      }

      return rawPayments.map((p) {
        final cleanId = p.studentId.toUpperCase().trim();
        final sData = studentsMap[cleanId];
        final dData = duesMap[p.duesId] ?? duesMap[p.duesId.toLowerCase()];

        final resolvedStudentName = (sData?['fullName'] as String?)?.trim();
        final resolvedStudentLevel = (sData?['level'] as num?)?.toInt();
        final resolvedDuesName = (dData?['name'] as String?)?.trim();

        final finalName = (resolvedStudentName != null && resolvedStudentName.isNotEmpty && resolvedStudentName != 'Student')
            ? resolvedStudentName
            : (p.studentName.isNotEmpty && p.studentName != 'Student' ? p.studentName : p.studentId);

        final finalLevel = (resolvedStudentLevel != null && resolvedStudentLevel > 0)
            ? resolvedStudentLevel
            : (p.studentLevel > 0 ? p.studentLevel : 100);

        final finalDuesName = (resolvedDuesName != null && resolvedDuesName.isNotEmpty)
            ? resolvedDuesName
            : (p.duesName.isNotEmpty ? p.duesName : 'Departmental Dues');

        return p.copyWith(
          studentName: finalName,
          studentLevel: finalLevel,
          duesName: finalDuesName,
        );
      }).toList();
    } catch (_) {
      return rawPayments;
    }
  }
}
