import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

final adminReportsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getAllSuccessfulPayments();
});
