import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

class IdVerificationController extends StateNotifier<AsyncValue<void>> {
  IdVerificationController(this._repository) : super(const AsyncData(null));

  final StudentRepository _repository;

  /// Simulates OCR scanning and updates the student's status.
  /// Returns the resulting VerificationStatus so the UI knows how to react.
  Future<VerificationStatus?> simulateScanAndVerify(String indexNumber) async {
    state = const AsyncLoading();
    try {
      // Fast 1.5s simulated OCR scanning
      await Future.delayed(const Duration(milliseconds: 1500));

      // 100% automated verification
      const newStatus = VerificationStatus.verified;

      // Update in Firestore
      await _repository.updateVerificationStatus(indexNumber, newStatus, 'simulated_image_path.jpg');
      
      if (mounted) {
        state = const AsyncData(null);
      }
      return newStatus;
    } catch (e, st) {
      if (mounted) {
        state = AsyncError(e, st);
      }
      return null;
    }
  }
}

final idVerificationControllerProvider = StateNotifierProvider.autoDispose<IdVerificationController, AsyncValue<void>>((ref) {
  return IdVerificationController(ref.watch(studentRepositoryProvider));
});
