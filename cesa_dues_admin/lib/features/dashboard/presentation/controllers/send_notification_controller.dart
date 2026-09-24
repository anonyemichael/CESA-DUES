import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:uuid/uuid.dart';

class SendNotificationController extends StateNotifier<AsyncValue<void>> {
  SendNotificationController(this._repo) : super(const AsyncData(null));

  final NotificationRepository _repo;

  Future<void> sendNotification({
    required String title,
    required String body,
    required NotificationTarget target,
    String? studentId,
  }) async {
    state = const AsyncLoading();
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        title: title,
        body: body,
        studentId: studentId,
        targetAudience: target,
        academicYear: '2026/2027', // Ideally from config
        type: NotificationType.announcement,
        createdAt: DateTime.now(),
      );

      await _repo.sendNotification(notification);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final sendNotificationControllerProvider = StateNotifierProvider<SendNotificationController, AsyncValue<void>>((ref) {
  return SendNotificationController(ref.watch(notificationRepositoryProvider));
});
