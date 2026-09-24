import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../constants/firestore_paths.dart';
import '../constants/enums.dart';
import '../errors/app_exception.dart';

/// Provider for the Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for the StudentRepository.
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(firestoreProvider));
});

/// Repository for managing Student data in Firestore.
class StudentRepository {
  StudentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Student> get _studentsRef =>
      _firestore.collection(FirestorePaths.students).withConverter<Student>(
            fromFirestore: (snapshot, _) => Student.fromFirestore(snapshot),
            toFirestore: (student, _) => student.toFirestore(),
          );

  /// Fetches a student by their index number (document ID).
  Future<Student?> getStudentByIndex(String indexNumber) async {
    try {
      final doc = await _studentsRef.doc(indexNumber.toUpperCase().trim()).get();
      return doc.data();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch student profile.');
    }
  }

  /// Fetches the current logged in student using their Firebase UID.
  Future<Student?> getCurrentStudent(String uid) async {
    try {
      final snapshot = await _studentsRef.where('linkedUid', isEqualTo: uid).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to fetch current student profile.');
    }
  }

  /// Watches the current logged in student using their Firebase UID (real-time).
  Stream<Student?> watchCurrentStudent(String uid) {
    return _studentsRef
        .where('linkedUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    });
  }

  /// Links a user's Google Auth account to a student roster record during Onboarding
  Future<void> linkStudentAccount({
    required String indexNumber,
    required String uid,
    required String email,
    String? fullName,
    int? level,
    String? programme,
  }) async {
    try {
      final cleanIndex = indexNumber.toUpperCase().trim();
      final docRef = _firestore.collection('students').doc(cleanIndex);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final existing = docSnap.data();
        final updates = <String, dynamic>{
          'linkedUid': uid,
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (fullName != null && fullName.isNotEmpty) {
          final currentName = existing?['fullName'] as String?;
          if (currentName == null || currentName.isEmpty || currentName == 'Student' || currentName == 'Civil Engineering Student') {
            updates['fullName'] = fullName;
          }
        }
        if (level != null && level > 0) {
          final currentLevel = (existing?['level'] as num?)?.toInt();
          if (currentLevel == null || currentLevel == 0) {
            updates['level'] = level;
          }
        }
        await docRef.set(updates, SetOptions(merge: true));
      } else {
        // New Student not yet on roster -> Create profile
        await docRef.set({
          'indexNumber': cleanIndex,
          'fullName': (fullName != null && fullName.isNotEmpty) ? fullName : 'Civil Engineering Student',
          'programme': programme ?? 'BSc. Civil Engineering',
          'level': (level != null && level > 0) ? level : 100,
          'academicYear': '2025/2026',
          'linkedUid': uid,
          'email': email,
          'verificationStatus': VerificationStatus.pending.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to link student account.');
    }
  }

  /// Updates the verification status and optional image path.
  Future<void> updateVerificationStatus(String indexNumber, VerificationStatus status, [String? imagePath]) async {
    try {
      final cleanIndex = indexNumber.toUpperCase().trim();
      final docRef = _firestore.collection('students').doc(cleanIndex);
      final updates = <String, dynamic>{
        'verificationStatus': status.value,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (imagePath != null) {
        updates['idCardUrl'] = imagePath;
      }
      await docRef.set(updates, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to update verification status.');
    }
  }

  /// Updates the student's FCM token for push notifications.
  Future<void> updateStudentToken(String indexNumber, String token) async {
    try {
      final cleanIndex = indexNumber.toUpperCase().trim();
      await _firestore.collection('students').doc(cleanIndex).update({
        'fcmToken': token,
      });
    } catch (_) {}
  }

  /// Fetches a list of students with optional search (by index number or name) and level filter.
  Future<List<Student>> getStudents({
    int limit = 100,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    int? levelFilter,
  }) async {
    try {
      final snapshot = await _studentsRef.get();
      var list = snapshot.docs.map((doc) => doc.data()).toList();

      // 1. Filter by Level if specified
      if (levelFilter != null) {
        list = list.where((s) => s.level == levelFilter).toList();
      }

      // 2. Search by Index Number or Full Name
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        list = list.where((s) {
          final index = s.indexNumber.toLowerCase();
          final name = s.fullName.toLowerCase();
          final prog = s.programme.toLowerCase();
          return index.contains(query) || name.contains(query) || prog.contains(query);
        }).toList();
      }

      // Sort alphabetically by name
      list.sort((a, b) => a.fullName.compareTo(b.fullName));

      return list;
    } on FirebaseException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to load students.');
    }
  }
}

