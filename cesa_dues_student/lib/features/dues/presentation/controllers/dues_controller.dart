import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

/// Provides a stream of dues applicable to the currently logged in student.
final studentDuesProvider = StreamProvider<List<Dues>>((ref) async* {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) {
    yield [];
    return;
  }

  final repository = ref.watch(duesRepositoryProvider);
  yield* repository.watchDuesForLevel(student.level);
});
