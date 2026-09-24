import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../core/services/fcm_service.dart';

final currentStudentProvider = StreamProvider<Student?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  
  if (uid == null) {
    yield null;
    return;
  }
  
  final repository = ref.watch(studentRepositoryProvider);
  final stream = repository.watchCurrentStudent(uid);
  
  await for (final student in stream) {
    if (student != null && student.fcmToken == null) {
      // Background request to setup push notifications once logged in
      ref.read(fcmServiceProvider).setupAndSaveToken(student.indexNumber);
    }
    yield student;
  }
});
