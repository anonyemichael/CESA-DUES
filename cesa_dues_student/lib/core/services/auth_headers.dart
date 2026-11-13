import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// JSON headers carrying the signed-in user's Firebase ID token. The Cloud
/// Functions reject calls without it and derive the student from the token.
Future<Map<String, String>> authedJsonHeaders() async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null) {
    throw const AppException('Your session has expired. Please sign in again.');
  }
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
