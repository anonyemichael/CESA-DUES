import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../controllers/dues_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../receipts/presentation/controllers/receipts_controller.dart';
import '../../../payments/presentation/controllers/payment_controller.dart';
import '../../../payments/presentation/screens/paystack_webview_screen.dart';

class DuesScreen extends ConsumerWidget {
  const DuesScreen({super.key});

  void _startInAppPaystackPayment(BuildContext context, WidgetRef ref, Dues dues) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Connecting to Paystack...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Preparing secure checkout session',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    final res = await ref.read(paymentControllerProvider.notifier).initiatePaystackPayment(dues);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
    }

    if (res != null && res['authorizationUrl'] != null && context.mounted) {
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => PaystackWebViewScreen(
            authorizationUrl: res['authorizationUrl'] as String,
            reference: res['reference'] as String,
            dues: dues,
          ),
        ),
      );

      if (success == true && context.mounted) {
        context.goNamed(AppRouter.receipts);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);
    final duesAsync = ref.watch(studentDuesProvider);
    final receiptsAsync = ref.watch(studentReceiptsProvider);
    final paymentState = ref.watch(paymentControllerProvider);

    final student = studentAsync.asData?.value;
    final receipts = receiptsAsync.asData?.value ?? [];
    final paidDuesIds = receipts.where((p) => p.isSuccessful).map((r) => r.duesId).toSet();

    ref.listen<AsyncValue<void>>(
      paymentControllerProvider,
      (_, state) {
        if (state.hasError && !state.isLoading) {
          final error = state.error;
          final message = error is AppException
              ? error.message
              : 'An error occurred. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Departmental Dues',
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
          ref.invalidate(studentDuesProvider);
          ref.invalidate(studentReceiptsProvider);
          ref.invalidate(currentStudentProvider);
          try {
            await Future.wait([
              ref.read(studentDuesProvider.future),
              ref.read(studentReceiptsProvider.future),
            ]);
          } catch (_) {}
        },
        child: duesAsync.when(
          data: (duesList) {
            final allDues = duesList.isNotEmpty
                ? duesList
                : [
                    Dues(
                      id: 'cesa-annual-dues-2025',
                      name: 'CESA Annual Departmental Dues',
                      amount: 15000,
                      academicYear: '2025/2026',
                      applicableLevels: [student?.level ?? 100],
                      status: DuesStatus.active,
                      description: 'Mandatory annual dues for Civil Engineering students covering departmental development, student welfare, and activities.',
                    ),
                  ];

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allDues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final dues = allDues[index];
                final isPaid = paidDuesIds.contains(dues.id);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPaid ? AppColors.successBorder : AppColors.border,
                      width: isPaid ? 1.5 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(15, 23, 42, 0.04),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Ribbon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isPaid ? AppColors.successLight : const Color(0xFFF1F5F9),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          border: Border(
                            bottom: BorderSide(
                              color: isPaid ? AppColors.successBorder : AppColors.border,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SESSION ${dues.academicYear}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isPaid ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid ? AppColors.success : AppColors.errorLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPaid ? AppColors.success : AppColors.errorBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3,
                                    backgroundColor: isPaid ? Colors.white : AppColors.error,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isPaid ? 'PAID & CLEARED' : 'OUTSTANDING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isPaid ? Colors.white : AppColors.error,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dues.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (dues.description != null && dues.description!.isNotEmpty)
                              Text(
                                dues.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 14),

                            // Amount Box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Amount Payable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'GHS ${dues.amountInCedis.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isPaid ? AppColors.success : AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Fee Breakdown
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What this fee covers:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.check, size: 13, color: Color(0xFF2563EB)),
                                      SizedBox(width: 6),
                                      Text('Departmental Development & Projects', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.check, size: 13, color: Color(0xFF2563EB)),
                                      SizedBox(width: 6),
                                      Text('CESA Student Welfare & Association Levies', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.check, size: 13, color: Color(0xFF2563EB)),
                                      SizedBox(width: 6),
                                      Text('Digital Clearance QR Pass & Official Receipt', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: isPaid
                                  ? ElevatedButton.icon(
                                      onPressed: () => context.goNamed(AppRouter.receipts),
                                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                      label: const Text('View Clearance Pass & Receipt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: paymentState.isLoading
                                          ? null
                                          : () => _startInAppPaystackPayment(context, ref, dues),
                                      icon: const Icon(Icons.lock_outline, size: 16),
                                      label: Text(
                                        paymentState.isLoading ? 'Connecting to Paystack...' : 'Pay with Mobile Money / Card',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => Center(
            child: Text(
              error is AppException ? error.message : 'Failed to load dues.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

