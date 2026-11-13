import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'role_controller.dart';
import '../../../../app/router/app_router.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'us-central1');
});

/// Admin authentication (HOD / Financial Secretary).
///
/// The one-time code is generated, e-mailed and verified **only** by the
/// `requestAdminLogin` / `verifyAdminLogin` Cloud Functions. On success the
/// function returns a Firebase custom token carrying the `admin` and `role`
/// claims, which is what the Firestore security rules check.
class AdminAuthController extends StateNotifier<AsyncValue<void>> {
  AdminAuthController(this._authService, this._functions, this._ref)
      : super(const AsyncData(null));

  final AuthService _authService;
  final FirebaseFunctions _functions;
  final Ref _ref;

  static const _timeout = Duration(seconds: 25);

  Future<bool> requestOtp(String email) async {
    state = const AsyncLoading();
    final trimmedEmail = email.toLowerCase().trim();
    try {
      final callable = _functions.httpsCallable('requestAdminLogin');
      await callable.call<dynamic>({
        'email': trimmedEmail,
        'role': _ref.read(roleControllerProvider).value,
      }).timeout(_timeout);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(_mapError(e, 'Could not send the login code. Please try again.'), st);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = const AsyncLoading();
    final trimmedEmail = email.toLowerCase().trim();
    final trimmedOtp = otp.trim();
    try {
      final callable = _functions.httpsCallable('verifyAdminLogin');
      final result = await callable.call<dynamic>({
        'email': trimmedEmail,
        'otp': trimmedOtp,
      }).timeout(_timeout);

      final data = Map<String, dynamic>.from(result.data as Map);
      final customToken = data['token'] as String?;
      if (customToken == null || customToken.isEmpty) {
        throw const AppException('The server did not return a sign-in token.');
      }
      await _authService.signInWithCustomToken(customToken);

      final roleValue = data['role'] as String? ?? UserRole.financialSecretary.value;
      final role = UserRole.values.firstWhere(
        (r) => r.value == roleValue,
        orElse: () => UserRole.financialSecretary,
      );
      await _ref.read(roleControllerProvider.notifier).setRole(role);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      await prefs.setString('admin_email', trimmedEmail);

      adminRouterNotifier.setLoggedIn(true);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(_mapError(e, 'Invalid or expired code. Please request a new one.'), st);
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_logged_in');
    await prefs.remove('admin_email');
    adminRouterNotifier.setLoggedIn(false);
    await _authService.signOut();
  }

  AppException _mapError(Object e, String fallback) {
    if (e is AppException) return e;
    if (e is FirebaseFunctionsException) {
      return AppException(e.message?.isNotEmpty == true ? e.message! : fallback);
    }
    return AppException(fallback);
  }
}

final adminAuthControllerProvider =
    StateNotifierProvider<AdminAuthController, AsyncValue<void>>((ref) {
  return AdminAuthController(
    ref.watch(authServiceProvider),
    ref.watch(firebaseFunctionsProvider),
    ref,
  );
});
