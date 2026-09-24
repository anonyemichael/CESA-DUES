import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(studentNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final studentNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final student = ref.watch(currentStudentProvider).valueOrNull;
  if (student == null) {
    return const Stream.empty();
  }
  
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchStudentNotifications(student);
});

class NotificationsController extends StateNotifier<AsyncValue<void>> {
  NotificationsController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      // In a real app, we would update the notification's isRead field.
      // For broadcasts, we would maintain a subcollection of read notifications per user.
      // For this prototype, if it's personal, we update it.
      if (notification.targetAudience == NotificationTarget.personal) {
        final firestore = _ref.read(firestoreProvider);
        await firestore.collection(FirestorePaths.notifications).doc(notification.id).update({
          'isRead': true,
        });
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final notificationsControllerProvider = StateNotifierProvider.autoDispose<NotificationsController, AsyncValue<void>>((ref) {
  return NotificationsController(ref);
});
