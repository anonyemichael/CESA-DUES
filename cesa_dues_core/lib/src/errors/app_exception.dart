// Application-specific exceptions with user-friendly messages.
// Never expose raw Firebase/system errors to users.

/// Base exception for CESA DUES application errors.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppException($code): $message';
}

/// Authentication-related errors.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Network/connectivity errors.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Connection is slow. Please try again.',
  ]);
}

/// Firestore data errors.
class DataException extends AppException {
  const DataException(super.message, {super.code, super.originalError});
}

/// Payment-related errors.
class PaymentException extends AppException {
  const PaymentException(super.message, {super.code, super.originalError});
}

/// Student verification errors.
class VerificationException extends AppException {
  const VerificationException(super.message, {super.code, super.originalError});
}

/// Authorization/permission errors.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

/// Resource not found.
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'The requested resource was not found.',
  ]);
}

/// Maps Firebase and other errors to user-friendly AppExceptions.
class ErrorMapper {
  ErrorMapper._();

  static AppException fromFirebaseCode(String code) {
    switch (code) {
      case 'network-request-failed':
        return const NetworkException();
      case 'permission-denied':
        return const UnauthorizedException();
      case 'not-found':
        return const NotFoundException();
      case 'unavailable':
        return const NetworkException(
          'Service is temporarily unavailable. Please try again.',
        );
      case 'unauthenticated':
        return const AuthException('Please sign in to continue.');
      case 'already-exists':
        return const DataException('This record already exists.');
      case 'deadline-exceeded':
        return const NetworkException(
          'Request timed out. Please check your connection.',
        );
      case 'invalid-argument':
        return const DataException('Invalid data provided.');
      case 'email-already-in-use':
        return const AuthException(
          'An account with this email already exists.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('Invalid email or password.');
      case 'user-not-found':
        return const AuthException('No account found with this email.');
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please wait a moment and try again.',
        );
      case 'weak-password':
        return const AuthException(
          'Password is too weak. Use at least 6 characters.',
        );
      case 'popup-closed-by-user':
        return const AuthException('Sign in was cancelled.');
      case 'popup-blocked':
        return const AuthException(
          'Sign-in popup was blocked by browser. Please allow popups for this site.',
        );
      case 'unauthorized-domain':
        return const AuthException(
          'Domain not authorized. Please add cesa-dues-student.web.app to Authorized Domains in Firebase Console > Authentication > Settings.',
        );
      case 'operation-not-allowed':
        return const AuthException(
          'Google Sign-In is disabled. Please enable Google provider in Firebase Console > Authentication > Sign-in method.',
        );
      case 'account-exists-with-different-credential':
        return const AuthException(
          'An account already exists with the same email address but different sign-in credentials.',
        );
      default:
        return AppException(
          'Authentication failed ($code). Please try again.',
          code: code,
        );
    }
  }
}
