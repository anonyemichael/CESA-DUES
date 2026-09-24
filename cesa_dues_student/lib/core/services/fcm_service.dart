import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    FirebaseMessaging.instance,
    ref.watch(studentRepositoryProvider),
  );
});

class FcmService {
  FcmService(this._messaging, this._studentRepo);

  final FirebaseMessaging _messaging;
  final StudentRepository _studentRepo;

  /// Requests permission and saves the FCM token for the given student UID.
  Future<void> setupAndSaveToken(String indexNumber) async {
    try {
      // 1. Request permission (required on iOS and Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 2. Get the token
        final token = await _messaging.getToken();
        
        if (token != null) {
          // 3. Save to Firestore via Repository
          await _studentRepo.updateStudentToken(indexNumber, token);
        }

        // 4. Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _studentRepo.updateStudentToken(indexNumber, newToken);
        });
      }
    } catch (e) {
      // Silently fail for MVP, push notifications are progressive enhancement.
      print('FCM Setup Error: $e');
    }
  }
}
