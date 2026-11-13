import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../models/student.dart';
import '../constants/firestore_paths.dart';
import '../constants/app_constants.dart';
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

  /// Broadcast audiences a student belongs to: everyone plus their own level.
  List<String> _broadcastAudiences(Student student) => [
        NotificationTarget.all.value,
        if (AppConstants.academicLevels.contains(student.level)) 'level_${student.level}',
      ];

  static int _newestFirst(NotificationModel a, NotificationModel b) =>
      (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));

  List<NotificationModel> _merge(Iterable<NotificationModel> a, Iterable<NotificationModel> b) {
    final byId = {for (final n in [...a, ...b]) n.id: n};
    return byId.values.toList()..sort(_newestFirst);
  }

  // Two scoped queries (broadcasts for the student's audiences, and messages
  // addressed to the student) instead of one unscoped read. The Firestore security
  // rules only allow reads that are provably limited to what the student may see.
  Query<NotificationModel> _broadcastQuery(Student student) =>
      _notificationsRef.where('targetAudience', whereIn: _broadcastAudiences(student));

  Query<NotificationModel> _personalQuery(Student student) =>
      _notificationsRef.where('studentId', isEqualTo: student.indexNumber);

  /// Fetches all notifications applicable to a specific student.
  Future<List<NotificationModel>> getStudentNotifications(Student student) async {
    try {
      final results = await Future.wait([
        _broadcastQuery(student).get(),
        _personalQuery(student).get(),
      ]);
      return _merge(
        results[0].docs.map((d) => d.data()),
        results[1].docs.map((d) => d.data()),
      );
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch notifications.');
    }
  }

  /// Watches all notifications applicable to a specific student (real-time).
  Stream<List<NotificationModel>> watchStudentNotifications(Student student) {
    late final StreamController<List<NotificationModel>> controller;
    StreamSubscription<QuerySnapshot<NotificationModel>>? broadcastSub;
    StreamSubscription<QuerySnapshot<NotificationModel>>? personalSub;
    var broadcast = <NotificationModel>[];
    var personal = <NotificationModel>[];

    void emit() => controller.add(_merge(broadcast, personal));

    controller = StreamController<List<NotificationModel>>(
      onListen: () {
        broadcastSub = _broadcastQuery(student).snapshots().listen((snap) {
          broadcast = snap.docs.map((d) => d.data()).toList();
          emit();
        }, onError: controller.addError);
        personalSub = _personalQuery(student).snapshots().listen((snap) {
          personal = snap.docs.map((d) => d.data()).toList();
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await broadcastSub?.cancel();
        await personalSub?.cancel();
      },
    );
    return controller.stream;
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
