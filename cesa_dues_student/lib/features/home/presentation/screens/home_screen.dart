import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../dues/presentation/controllers/dues_controller.dart';
import '../../../receipts/presentation/controllers/receipts_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentStudentProvider);
          ref.invalidate(studentDuesProvider);
          ref.invalidate(studentReceiptsProvider);
          try {
            await ref.read(currentStudentProvider.future);
          } catch (_) {}
        },
        child: SafeArea(
          child: studentAsync.when(
            data: (student) {
              if (student == null) {
                return _buildErrorState('Student profile not found.');
              }
              return _buildDashboard(context, ref, student);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) => _buildErrorState(
              error is AppException ? error.message : 'Failed to load dashboard.',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, Student student) {
    final isVerified = student.verificationStatus == VerificationStatus.verified;
    final duesAsync = ref.watch(studentDuesProvider);
    final historyAsync = ref.watch(studentReceiptsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Institutional Header & Greeting
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CIVIL ENGINEERING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Index: ${student.indexNumber} • Level ${student.level}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification Button with badge
                  Consumer(
                    builder: (context, ref, child) {
                      final count = ref.watch(unreadNotificationsCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                              onPressed: () => context.pushNamed(AppRouter.notifications),
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. ID Verification Banner (if pending or unverified)
              if (!isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.verificationStatus == VerificationStatus.pending
                                  ? 'ID Photo Under Review'
                                  : 'Action Required: Verify Student ID',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.verificationStatus == VerificationStatus.pending
                                  ? 'Your uploaded ID is being reviewed by the department.'
                                  : 'Upload your student ID card to activate dues payments and QR passes.',
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (student.verificationStatus != VerificationStatus.pending) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context.goNamed(
                              AppRouter.idUpload,
                              pathParameters: {'indexNumber': student.indexNumber},
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text('Verify Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. CURRENT DUES HERO CARD
              duesAsync.when(
                data: (duesList) {
                  final annualDues = duesList.isNotEmpty ? duesList.first : null;
                  final receipts = historyAsync.asData?.value ?? [];
                  final paidDuesIds = receipts.where((p) => p.isSuccessful).map((p) => p.duesId).toSet();
                  final isPaid = annualDues != null && paidDuesIds.contains(annualDues.id);
                  return _buildHeroDuesCard(context, annualDues, isVerified, isPaid);
                },
                loading: () => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => _buildHeroDuesCard(context, null, isVerified, false),
              ),
              const SizedBox(height: 24),

              // 4. Quick Services Grid
              const Text(
                'QUICK SERVICES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      label: 'Official\nReceipts',
                      onTap: () => context.goNamed(AppRouter.receipts),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceTile(
                      context,
                      icon: Icons.qr_code_2_outlined,
                      label: 'Clearance\nQR Pass',
                      onTap: () => context.goNamed(AppRouter.profile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceTile(
                      context,
                      icon: Icons.history_outlined,
                      label: 'Payment\nHistory',
                      onTap: () => context.goNamed(AppRouter.dues),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 5. Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.goNamed(AppRouter.receipts),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              historyAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No recent payment activity recorded yet.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: payments.take(3).map((p) {
                      final isSuccess = p.status == PaymentStatus.successful;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSuccess ? AppColors.successLight : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSuccess ? Icons.check_circle_outline : Icons.schedule,
                                color: isSuccess ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.duesName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(p.createdAt ?? DateTime.now()),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'GHS ${p.amountInCedis.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isSuccess ? AppColors.textPrimary : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroDuesCard(BuildContext context, Dues? dues, bool isVerified, bool isPaid) {
    final amountFormatted = dues != null ? 'GHS ${dues.amountInCedis.toStringAsFixed(2)}' : 'GHS 150.00';
    final duesName = dues != null ? dues.name : '2025/2026 Annual Departmental Dues';
    final academicYear = dues != null ? dues.academicYear : '2025/2026';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? AppColors.successBorder : AppColors.border,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ACADEMIC SESSION $academicYear',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successLight : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPaid ? AppColors.successBorder : AppColors.errorBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: isPaid ? AppColors.success : AppColors.error),
                    const SizedBox(width: 5),
                    Text(
                      isPaid ? 'PAID & CLEARED' : 'OUTSTANDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.success : AppColors.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            duesName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amountFormatted,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              if (isPaid) ...[
                const SizedBox(width: 8),
                const Text(
                  '• Settled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                if (isPaid) {
                  context.goNamed(AppRouter.receipts);
                } else {
                  context.goNamed(AppRouter.dues);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isPaid ? Icons.receipt_long : Icons.credit_card, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isPaid ? 'View Official Receipt' : 'Pay Departmental Dues',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
