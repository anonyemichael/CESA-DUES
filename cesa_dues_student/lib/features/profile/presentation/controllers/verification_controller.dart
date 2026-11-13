import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../core/services/auth_headers.dart';
import 'profile_controller.dart';

class VerificationController extends StateNotifier<AsyncValue<void>> {
  VerificationController(this._storageService, this._ref) : super(const AsyncData(null));

  final StorageService _storageService;
  final Ref _ref;

  static const String _verifyEndpoint =
      'https://us-central1-cesa-dues-9a267.cloudfunctions.net/verifyStudentIdOcr';

  Future<bool> uploadAndVerify(String indexNumber, Uint8List imageBytes) async {
    state = const AsyncLoading();
    try {
      final cleanIndex = indexNumber.toUpperCase().trim();

      // 1. Upload image bytes to Firebase Storage
      final uid = _ref.read(authStateProvider).value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw const AppException('Your session has expired. Please sign in again.');
      }
      final imageUrl = await _storageService.uploadStudentIdBytes(uid, cleanIndex, imageBytes);

      // 2. Call Cloud Vision AI OCR Verification Function via direct HTTP POST
      final response = await http.post(
        Uri.parse(_verifyEndpoint),
        headers: await authedJsonHeaders(),
        body: jsonEncode({
          'data': {
            'imageUrl': imageUrl,
            'indexNumber': cleanIndex,
          }
        }),
      );

      if (response.statusCode != 200) {
        state = AsyncError(
          AppException('Server returned error (${response.statusCode}). Please try again.'),
          StackTrace.current,
        );
        return false;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;
      final isVerified = data['verified'] == true;
      // Auto-check could not confirm the index number: the ID is now pending the
      // Financial Secretary's manual approval, which is a successful submission.
      final sentForReview = data['pending'] == true;

      if (!isVerified && sentForReview) {
        _ref.invalidate(currentStudentProvider);
        state = const AsyncData(null);
        return true;
      }

      if (!isVerified) {
        final reason = data['reason'] as String? ?? 'Could not verify student ID. Please ensure the card is clear and well-lit.';
        state = AsyncError(AppException(reason), StackTrace.current);
        return false;
      }

      // Invalidate current student provider so router advances immediately
      _ref.invalidate(currentStudentProvider);

      state = const AsyncData(null);
      return true;
    } on FirebaseException catch (e) {
      state = AsyncError(
        AppException(e.message ?? 'Upload failed.', code: e.code),
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      state = AsyncError(AppException(e.toString()), st);
      return false;
    }
  }
}

final verificationControllerProvider =
    StateNotifierProvider<VerificationController, AsyncValue<void>>((ref) {
  return VerificationController(
    ref.watch(storageServiceProvider),
    ref,
  );
});
