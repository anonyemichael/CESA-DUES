import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

/// Notifies UI about auth loading/error states during sign in.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authService) : super(const AsyncData(null));

  final AuthService _authService;

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _authService.signInWithGoogle();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
  );
});
