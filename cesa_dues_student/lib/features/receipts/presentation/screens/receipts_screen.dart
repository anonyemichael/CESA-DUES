import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/receipts_controller.dart';
import 'package:intl/intl.dart';

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(studentReceiptsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Official Receipts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh Receipts',
            onPressed: () => ref.invalidate(studentReceiptsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: receiptsAsync.when(
            data: (allPayments) {
              final payments = allPayments.where((p) => p.isSuccessful).toList();
              if (payments.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(studentReceiptsProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            const Text('No Receipts Issued Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'When you pay your annual departmental dues, your official certified receipt and clearance QR pass will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.goNamed(AppRouter.dues),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Go to Dues Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(studentReceiptsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // Header Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_rounded, color: AppColors.gold, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clearance Verification Records',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Present your digital QR pass to the HOD/FinSec for clearance.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'COMPLETED PAYMENTS (${payments.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...payments.map((payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildOfficialReceiptCard(context, payment),
                        )),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'Failed to load receipts: $e',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialReceiptCard(BuildContext context, Payment payment) {
    final formattedDate = payment.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(payment.createdAt!)
        : 'Confirmed';
    final receiptNo = (payment.receiptId != null && payment.receiptId!.isNotEmpty)
        ? payment.receiptId!
        : 'CESA-REC-${payment.id.length >= 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Institutional Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CESA UENR • CIVIL ENGINEERING',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'OFFICIAL PAYMENT RECEIPT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'CLEARED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Receipt Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        payment.duesName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GHS ${payment.amountInCedis.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Itemized Metadata Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Receipt No:', receiptNo, isMono: true),
                      const Divider(height: 12, color: AppColors.border),
                      _buildReceiptRow('Student Name:', payment.studentName.isNotEmpty ? payment.studentName : 'Student'),
                      const SizedBox(height: 6),
                      _buildReceiptRow('Index Number:', payment.studentId, isMono: true),
                      const SizedBox(height: 6),
                      _buildReceiptRow('Academic Level:', 'Level ${payment.studentLevel}'),
                      const SizedBox(height: 6),
                      _buildReceiptRow('Payment Date:', formattedDate),
                      if (payment.gatewayReference != null) ...[
                        const SizedBox(height: 6),
                        _buildReceiptRow('Reference:', payment.gatewayReference!, isMono: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Verification & QR Section Action
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.pushNamed(AppRouter.qrReceipt, extra: payment);
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Show Clearance QR Pass', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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

          // Receipt Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Officially Authenticated • Civil Engineering Dept. UENR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
