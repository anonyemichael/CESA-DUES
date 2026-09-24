import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

final studentReceiptsProvider = StreamProvider.autoDispose<List<Payment>>((ref) async* {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) {
    yield [];
    return;
  }

  final repository = ref.watch(paymentRepositoryProvider);
  yield* repository.watchStudentPayments(student.indexNumber);
});
