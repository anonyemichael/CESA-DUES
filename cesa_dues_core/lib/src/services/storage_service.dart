import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exception.dart';

/// Provider for FirebaseStorage instance.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(firebaseStorageProvider));
});

/// Service for uploading files to Firebase Storage.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Uploads student ID bytes (cross-platform Web + Mobile) and returns the download URL.
  Future<String> uploadStudentIdBytes(String indexNumber, Uint8List imageBytes) async {
    try {
      final path = 'students/$indexNumber/id_photo.jpg';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'indexNumber': indexNumber},
      );

      final uploadTask = await ref.putData(imageBytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to upload ID image. Please try again.');
    }
  }
}
