import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

class ReportController extends StateNotifier<AsyncValue<void>> {
  ReportController(this._paymentRepository, this._studentRepository) : super(const AsyncData(null));

  final PaymentRepository _paymentRepository;
  final StudentRepository _studentRepository;

  Future<bool> generateCsvReport(Dues dues) async {
    state = const AsyncLoading();
    try {
      // 1. Fetch payments
      final payments = await _paymentRepository.getSuccessfulPaymentsByDuesId(dues.id);
      
      if (payments.isEmpty) {
        throw const AppException('No successful payments found for this dues to export.');
      }

      // 2. Prepare CSV Data
      final List<List<dynamic>> rows = [
        ['Payment ID', 'Student Index', 'Amount (GHS)', 'Date', 'Gateway Ref']
      ];

      for (var payment in payments) {
        rows.add([
          payment.id,
          payment.studentId,
          payment.amount.toStringAsFixed(2),
          DateFormat('yyyy-MM-dd HH:mm').format(payment.createdAt ?? DateTime.now()),
          payment.gatewayReference ?? '',
        ]);
      }

      // 3. Convert to CSV string and bytes
      final String csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);

      // 4. Share/download file
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: 'CESA_Dues_Report_${dues.id}.csv',
      );
      await Share.shareXFiles([xFile], subject: 'CESA Dues Report - ${dues.name}');

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      if (e is AppException) {
        state = AsyncError(e, st);
      } else {
        state = AsyncError(const AppException('Failed to generate report.'), st);
      }
      return false;
    }
  }
}

final reportControllerProvider =
    StateNotifierProvider<ReportController, AsyncValue<void>>((ref) {
  return ReportController(
    ref.watch(paymentRepositoryProvider),
    ref.watch(studentRepositoryProvider),
  );
});
