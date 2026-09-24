import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../models/student.dart';
import '../constants/firestore_paths.dart';
import '../constants/enums.dart';
import '../errors/app_exception.dart';
import 'student_repository.dart';

/// Provider for the NotificationRepository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

/// Repository for managing Notifications data in Firestore.
class NotificationRepository {
  NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<NotificationModel> get _notificationsRef =>
      _firestore.collection(FirestorePaths.notifications).withConverter<NotificationModel>(
            fromFirestore: (snapshot, _) => NotificationModel.fromFirestore(snapshot),
            toFirestore: (notification, _) => notification.toFirestore(),
          );

  /// Fetches all notifications applicable to a specific student.
  Future<List<NotificationModel>> getStudentNotifications(Student student) async {
    try {
      final snapshot = await _notificationsRef.orderBy('createdAt', descending: true).get();
      final allNotifications = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Filter locally due to complex OR conditions across fields
      final applicable = allNotifications.where((n) {
        if (n.targetAudience == NotificationTarget.all) return true;
        if (n.targetAudience == NotificationTarget.level100 && student.level == 100) return true;
        if (n.targetAudience == NotificationTarget.level200 && student.level == 200) return true;
        if (n.targetAudience == NotificationTarget.level300 && student.level == 300) return true;
        if (n.targetAudience == NotificationTarget.level400 && student.level == 400) return true;
        if (n.targetAudience == NotificationTarget.personal && n.studentId == student.indexNumber) return true;
        return false;
      }).toList();

      return applicable;
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch notifications.');
    }
  }

  /// Watches all notifications applicable to a specific student (real-time).
  Stream<List<NotificationModel>> watchStudentNotifications(Student student) {
    return _notificationsRef.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      final allNotifications = snapshot.docs.map((doc) => doc.data()).toList();
      
      final applicable = allNotifications.where((n) {
        if (n.targetAudience == NotificationTarget.all) return true;
        if (n.targetAudience == NotificationTarget.level100 && student.level == 100) return true;
        if (n.targetAudience == NotificationTarget.level200 && student.level == 200) return true;
        if (n.targetAudience == NotificationTarget.level300 && student.level == 300) return true;
        if (n.targetAudience == NotificationTarget.level400 && student.level == 400) return true;
        if (n.targetAudience == NotificationTarget.personal && n.studentId == student.indexNumber) return true;
        return false;
      }).toList();

      return applicable;
    });
  }

  /// Fetches all announcements (Admin view).
  Future<List<NotificationModel>> getAllAnnouncements() async {
    try {
      final snapshot = await _notificationsRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch announcements.');
    }
  }

  /// Sends a new notification.
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _notificationsRef.doc(notification.id).set(notification);
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to send notification.');
    }
  }
}
