import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../core/services/auth_headers.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../receipts/presentation/controllers/receipts_controller.dart';
import '../../../dues/presentation/controllers/dues_controller.dart';

class PaymentController extends StateNotifier<AsyncValue<void>> {
  PaymentController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  static const String _initEndpoint =
      'https://us-central1-cesa-dues-9a267.cloudfunctions.net/initializePaystackPaymentHttp';
  static const String _verifyEndpoint =
      'https://us-central1-cesa-dues-9a267.cloudfunctions.net/verifyPaystackPaymentHttp';

  /// Initializes a real Paystack transaction via Cloud Function HTTP endpoint.
  /// The student, amount and dues are resolved server-side from the sign-in token.
  Future<Map<String, dynamic>?> initiatePaystackPayment(Dues dues) async {
    state = const AsyncLoading();
    try {
      final response = await http.post(
        Uri.parse(_initEndpoint),
        headers: await authedJsonHeaders(),
        body: jsonEncode({
          'data': {'duesId': dues.id},
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
        headers: await authedJsonHeaders(),
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
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(ref);
});
