import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

class StudentListState {
  const StudentListState({
    this.students = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.searchQuery = '',
    this.levelFilter,
    this.error,
  });

  final List<Student> students;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String searchQuery;
  final int? levelFilter;
  final AppException? error;

  StudentListState copyWith({
    List<Student>? students,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    int? levelFilter,
    bool clearLevelFilter = false,
    AppException? error,
  }) {
    return StudentListState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      searchQuery: searchQuery ?? this.searchQuery,
      levelFilter: clearLevelFilter ? null : (levelFilter ?? this.levelFilter),
      error: error,
    );
  }
}

class StudentListController extends StateNotifier<StudentListState> {
  StudentListController(this._repository) : super(const StudentListState()) {
    loadStudents();
  }

  final StudentRepository _repository;
  static const int _limit = 50;
  final _firestore = FirebaseFirestore.instance;

  Future<void> loadStudents({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (!isRefresh && !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      students: isRefresh ? [] : state.students,
      lastDocument: isRefresh ? null : state.lastDocument,
    );

    try {
      final newStudents = await _repository.getStudents(
        limit: _limit,
        startAfter: state.lastDocument,
        searchQuery: state.searchQuery,
        levelFilter: state.levelFilter,
      );

      state = state.copyWith(
        students: isRefresh ? newStudents : [...state.students, ...newStudents],
        hasMore: newStudents.length == _limit,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: const AppException('Failed to load students'));
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(
      searchQuery: query,
      students: [],
      hasMore: true,
      lastDocument: null,
    );
    loadStudents(isRefresh: true);
  }

  void updateLevelFilter(int? level) {
    state = state.copyWith(
      levelFilter: level,
      clearLevelFilter: level == null,
      students: [],
      hasMore: true,
      lastDocument: null,
    );
    loadStudents(isRefresh: true);
  }

  Future<void> updateVerificationStatus(String indexNumber, VerificationStatus newStatus) async {
    try {
      await _repository.updateVerificationStatus(indexNumber, newStatus);
      loadStudents(isRefresh: true);
    } catch (e) {
      state = state.copyWith(error: const AppException('Failed to update verification status'));
    }
  }

  /// 1-Click Roll-over: Promotes all students to the next academic level (100 -> 200, 200 -> 300, 300 -> 400, 400 -> Graduated)
  Future<int> promoteAllStudents(String newAcademicYear) async {
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _firestore.collection('students').get();
      int updatedCount = 0;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final currentLevel = data['level'] is int ? data['level'] as int : int.tryParse(data['level'].toString()) ?? 100;
        
        int nextLevel = currentLevel + 100;
        bool isGraduated = false;
        if (currentLevel >= 400) {
          nextLevel = 500; // 500 = Alumni / Graduated
          isGraduated = true;
        }

        batch.update(doc.reference, {
          'level': nextLevel,
          'academicYear': newAcademicYear,
          'isGraduated': isGraduated,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }

      await batch.commit();
      await loadStudents(isRefresh: true);
      return updatedCount;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppException('Promotion failed: $e'));
      rethrow;
    }
  }
}

final studentListControllerProvider =
    StateNotifierProvider<StudentListController, StudentListState>((ref) {
  return StudentListController(ref.watch(studentRepositoryProvider));
});
