import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  OnboardingController(this._studentRepo, this._authService, this._storage) 
      : super(const AsyncData(null));

  final StudentRepository _studentRepo;
  final AuthService _authService;
  final FirebaseStorage _storage;

  Future<void> completeProfile({
    required String indexNumber,
    required String fullName,
    required int level,
    Uint8List? idImageBytes,
  }) async {
    state = const AsyncLoading();
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw const AppException('Not authenticated. Please sign in again.');
      }

      String? imageUrl;
      
      // Upload image if provided
      if (idImageBytes != null) {
        final ref = _storage.ref().child('student_ids').child(user.uid);
        await ref.putData(idImageBytes, SettableMetadata(contentType: 'image/jpeg'));
        imageUrl = await ref.getDownloadURL();
      }

      // Link student record and upload ID
      await _studentRepo.linkStudentAccount(
        indexNumber: indexNumber,
        uid: user.uid,
        email: user.email ?? '',
        fullName: fullName,
        level: level,
        programme: 'BSc. Civil Engineering',
      );

      if (imageUrl != null) {
        await _studentRepo.updateVerificationStatus(indexNumber, VerificationStatus.pending, imageUrl);
      }
      
      state = const AsyncData(null);
    } catch (e, st) {
      if (e is AppException) {
        state = AsyncError(e, st);
      } else {
        state = AsyncError(const AppException('Failed to complete profile.'), st);
      }
    }
  }
}

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final onboardingControllerProvider = 
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(
    ref.watch(studentRepositoryProvider),
    ref.watch(authServiceProvider),
    ref.watch(firebaseStorageProvider),
  );
});
