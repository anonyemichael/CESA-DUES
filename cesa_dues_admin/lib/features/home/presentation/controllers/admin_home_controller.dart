import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return repository.getDashboardStats();
});
