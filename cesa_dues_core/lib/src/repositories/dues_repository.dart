import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dues.dart';
import '../constants/firestore_paths.dart';
import '../errors/app_exception.dart';
import 'student_repository.dart';

/// Provider for the DuesRepository.
final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  return DuesRepository(ref.watch(firestoreProvider));
});

/// Repository for managing Dues data in Firestore.
class DuesRepository {
  DuesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Dues> get _duesRef =>
      _firestore.collection(FirestorePaths.dues).withConverter<Dues>(
            fromFirestore: (snapshot, _) => Dues.fromFirestore(snapshot),
            toFirestore: (dues, _) => dues.toFirestore(),
          );

  /// Fetches all active dues.
  Future<List<Dues>> getActiveDues() async {
    try {
      final snapshot = await _duesRef
          .where('status', isEqualTo: 'active')
          .get();
      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch active dues.');
    }
  }

  /// Fetches all active dues applicable to a specific academic level.
  Future<List<Dues>> getDuesForLevel(int level) async {
    try {
      final snapshot = await _duesRef
          .where('status', isEqualTo: 'active')
          .where('applicableLevels', arrayContains: level)
          .get();
      final list = snapshot.docs.map((doc) => doc.data()).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch dues for your level.');
    }
  }

  /// Watches all active dues applicable to a specific academic level (real-time).
  Stream<List<Dues>> watchDuesForLevel(int level) {
    return _duesRef
        .where('status', isEqualTo: 'active')
        .where('applicableLevels', arrayContains: level)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => doc.data()).toList();
          list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          return list;
        });
  }

  /// Creates new dues (Admin).
  Future<void> createDues(Dues dues) async {
    try {
      await _duesRef.doc(dues.id).set(dues);
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to create dues.');
    }
  }

  /// Updates existing dues package (Admin).
  Future<void> updateDues(Dues dues) async {
    try {
      await _duesRef.doc(dues.id).set(dues, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to update dues package.');
    }
  }

  /// Deletes or removes dues package (Admin).
  Future<void> deleteDues(String duesId) async {
    try {
      await _duesRef.doc(duesId).delete();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to remove dues package.');
    }
  }
}
