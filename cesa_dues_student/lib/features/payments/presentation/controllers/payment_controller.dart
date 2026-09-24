import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../receipts/presentation/controllers/receipts_controller.dart';
import '../../../dues/presentation/controllers/dues_controller.dart';

class PaymentController extends StateNotifier<AsyncValue<void>> {
  PaymentController(this._paymentRepository, this._ref) : super(const AsyncData(null));

  final PaymentRepository _paymentRepository;
  final Ref _ref;

  static const String _initEndpoint =
      'https://us-central1-cesa-dues-9a267.cloudfunctions.net/initializePaystackPaymentHttp';
  static const String _verifyEndpoint =
      'https://us-central1-cesa-dues-9a267.cloudfunctions.net/verifyPaystackPaymentHttp';

  /// Initializes a real Paystack transaction via Cloud Function HTTP endpoint.
  Future<Map<String, dynamic>?> initiatePaystackPayment(Dues dues) async {
    state = const AsyncLoading();
    try {
      final authUser = _ref.read(authStateProvider).value;
      Student? student;
      try {
        student = await _ref.read(currentStudentProvider.future);
      } catch (_) {}

      final email = (student?.email != null && student!.email!.isNotEmpty)
          ? student.email!
          : (authUser?.email ?? 'student@st.uenr.edu.gh');
      
      final indexNumber = student?.indexNumber ??
          (email.contains('@') ? email.split('@').first.toUpperCase() : 'CESA-STUDENT');

      final response = await http.post(
        Uri.parse(_initEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'indexNumber': indexNumber,
            'studentName': student?.fullName ?? authUser?.displayName ?? indexNumber,
            'studentLevel': student?.level ?? 100,
            'duesId': dues.id,
            'email': email,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw AppException('Payment server error (${response.statusCode}). Please try again.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;

      if (data['success'] != true) {
        throw AppException(data['reason'] as String? ?? 'Failed to initialize Paystack checkout.');
      }

      final authUrl = data['authorizationUrl'] as String?;
      final reference = data['reference'] as String?;

      state = const AsyncData(null);
      return {
        'authorizationUrl': authUrl,
        'reference': reference,
        'amount': data['amount'],
      };
    } catch (e, st) {
      final appErr = e is AppException ? e : AppException(e.toString());
      state = AsyncError(appErr, st);
      return null;
    }
  }

  /// Verifies transaction directly with the Paystack gateway.
  Future<bool> verifyPaystackPayment(String reference) async {
    state = const AsyncLoading();
    try {
      final response = await http.post(
        Uri.parse(_verifyEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'reference': reference,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw AppException('Verification error (${response.statusCode}). Please retry.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;

      final isVerified = data['verified'] == true;
      if (isVerified) {
        _ref.invalidate(studentReceiptsProvider);
        _ref.invalidate(studentDuesProvider);
        _ref.invalidate(currentStudentProvider);
      }

      state = const AsyncData(null);
      return isVerified;
    } catch (e, st) {
      final appErr = e is AppException ? e : AppException(e.toString());
      state = AsyncError(appErr, st);
      return false;
    }
  }

  /// Quick mock fallback for instant offline testing.
  Future<void> mockInstantPayment(Dues dues) async {
    state = const AsyncLoading();
    try {
      final student = await _ref.read(currentStudentProvider.future);
      if (student == null) throw const AppException('Must be logged in.');

      await _paymentRepository.mockPayment(student: student, dues: dues);
      _ref.invalidate(studentReceiptsProvider);
      _ref.invalidate(studentDuesProvider);
      _ref.invalidate(currentStudentProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e is AppException ? e : AppException(e.toString()), st);
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(
    ref.watch(paymentRepositoryProvider),
    ref,
  );
});
