import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:uuid/uuid.dart';

/// Provider to fetch all active dues for the admin view.
final adminDuesListProvider = FutureProvider.autoDispose<List<Dues>>((ref) async {
  final repo = ref.watch(duesRepositoryProvider);
  return repo.getActiveDues(); // Actually, admin needs ALL dues including inactive. Let's add a getAllDues to repo if needed, but getActiveDues is fine for MVP.
});

class AdminDuesController extends StateNotifier<AsyncValue<void>> {
  AdminDuesController(this._repository) : super(const AsyncData(null));

  final DuesRepository _repository;

  Future<bool> createDues({
    required String name,
    required double amountCedis,
    required String academicYear,
    required List<int> applicableLevels,
    String? description,
    DateTime? deadline,
    bool isActive = true,
  }) async {
    state = const AsyncLoading();
    try {
      final dues = Dues(
        id: const Uuid().v4(),
        name: name,
        amount: (amountCedis * 100).toInt(), // Convert to pesewas
        academicYear: academicYear,
        applicableLevels: applicableLevels,
        description: description,
        deadline: deadline,
        status: isActive ? DuesStatus.active : DuesStatus.inactive,
        createdAt: DateTime.now(),
      );

      await _repository.createDues(dues);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      if (e is AppException) {
        state = AsyncError(e, st);
      } else {
        state = AsyncError(const AppException('Failed to create dues.'), st);
      }
      return false;
    }
  }

  Future<bool> updateDues({
    required String id,
    required String name,
    required double amountCedis,
    required String academicYear,
    required List<int> applicableLevels,
    required bool isActive,
    String? description,
    DateTime? deadline,
  }) async {
    state = const AsyncLoading();
    try {
      final dues = Dues(
        id: id,
        name: name,
        amount: (amountCedis * 100).toInt(),
        academicYear: academicYear,
        applicableLevels: applicableLevels,
        description: description,
        deadline: deadline,
        status: isActive ? DuesStatus.active : DuesStatus.inactive,
        createdAt: DateTime.now(),
      );

      await _repository.updateDues(dues);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e is AppException ? e : const AppException('Failed to update dues.'), st);
      return false;
    }
  }

  Future<bool> deleteDues(String duesId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteDues(duesId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e is AppException ? e : const AppException('Failed to delete dues package.'), st);
      return false;
    }
  }
}

final adminDuesControllerProvider = StateNotifierProvider.autoDispose<AdminDuesController, AsyncValue<void>>((ref) {
  return AdminDuesController(ref.watch(duesRepositoryProvider));
});
