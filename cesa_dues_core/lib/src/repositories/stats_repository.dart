import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/firestore_paths.dart';
import '../errors/app_exception.dart';
import 'student_repository.dart';

/// Provider for the StatsRepository.
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(firestoreProvider));
});

/// Admin Dashboard Statistics model.
class AdminStats {
  const AdminStats({
    required this.totalStudents,
    required this.pendingVerifications,
    required this.totalRevenue,
    this.activeDuesCount = 1,
  });

  final int totalStudents;
  final int pendingVerifications;
  final double totalRevenue;
  final int activeDuesCount;
}

/// Repository for aggregating admin dashboard statistics.
class StatsRepository {
  StatsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Fetches aggregate statistics for the dashboard.
  Future<AdminStats> getDashboardStats() async {
    try {
      // 1. Students Count & Pending Verifications
      final studentsSnap = await _firestore.collection(FirestorePaths.students).get();
      final totalStudents = studentsSnap.docs.length;
      final pendingCount = studentsSnap.docs.where((doc) {
        final data = doc.data();
        return data['verificationStatus'] == 'pending';
      }).length;

      // 2. Total Successful Revenue (convert pesewas to Cedis)
      final paymentsSnap = await _firestore.collection(FirestorePaths.payments).get();
      double totalRevenueCedis = 0.0;
      for (final doc in paymentsSnap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        if (status == 'successful' || status == 'completed') {
          final amount = data['amount'];
          if (amount is num) {
            totalRevenueCedis += (amount / 100);
          }
        }
      }

      // 3. Active Dues Count
      final duesSnap = await _firestore.collection(FirestorePaths.dues).get();
      final activeDuesCount = duesSnap.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'active';
      }).length;

      return AdminStats(
        totalStudents: totalStudents,
        pendingVerifications: pendingCount,
        totalRevenue: totalRevenueCedis,
        activeDuesCount: activeDuesCount > 0 ? activeDuesCount : (duesSnap.docs.isNotEmpty ? duesSnap.docs.length : 1),
      );
    } catch (e) {
      return const AdminStats(
        totalStudents: 0,
        pendingVerifications: 0,
        totalRevenue: 0.0,
        activeDuesCount: 1,
      );
    }
  }
}
