import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

final studentPaymentsProvider = StreamProvider<List<Payment>>((ref) async* {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) {
    yield [];
    return;
  }

  final repository = ref.watch(paymentRepositoryProvider);
  yield* repository.watchStudentPayments(student.indexNumber);
});

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(studentPaymentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentPaymentsProvider);
          try { await ref.read(studentPaymentsProvider.future); } catch (_) {}
        },
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.history_rounded, size: 44, color: AppColors.textSecondary),
                        SizedBox(height: 14),
                        Text('No Payment History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('Your completed transactions and Paystack audit logs will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final date = payment.createdAt;
                final formattedDate = date != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                    : 'Confirmed';
                final isSuccess = payment.status == PaymentStatus.successful;
                    
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(15, 23, 42, 0.03),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              payment.duesName.isNotEmpty ? payment.duesName : 'Annual Departmental Dues',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSuccess ? AppColors.successLight : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSuccess ? AppColors.successBorder : AppColors.warningBorder),
                            ),
                            child: Text(
                              isSuccess ? 'SUCCESSFUL' : payment.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSuccess ? AppColors.success : AppColors.warning,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'GHS ${payment.amountInCedis.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSuccess ? AppColors.textPrimary : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (payment.gatewayReference != null) ...[
                        const Divider(height: 16, color: AppColors.border),
                        Text(
                          'Ref: ${payment.gatewayReference}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error loading payments: $e', style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }
}
