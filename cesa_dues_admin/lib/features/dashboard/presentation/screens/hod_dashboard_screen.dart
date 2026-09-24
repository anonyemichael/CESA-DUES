import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../reports/presentation/controllers/admin_reports_controller.dart';
import '../../../students/presentation/controllers/student_list_controller.dart';

/// HOD Executive Monitoring & Compliance Portal (Responsive).
class HodDashboardScreen extends ConsumerStatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  ConsumerState<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends ConsumerState<HodDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(adminReportsProvider);
    final studentsState = ref.watch(studentListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/logo.jpg', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('HOD Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => context.goNamed(AppRouter.login),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Department of Civil Engineering', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Text('Official Academic Session 2025/2026', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // KPI Cards Grid
              reportAsync.when(
                data: (data) {
                  const total = 482;
                  final paid = data.length;
                  final collected = data.fold(0.0, (double s, Payment p) => s + p.amountInCedis);
                  final rate = total > 0 ? (paid / total * 100).toStringAsFixed(1) : '0';

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.35,
                    children: [
                      _executiveCard('REGISTERED', '$total', Icons.people_alt_outlined, AppColors.accent),
                      _executiveCard('COLLECTED', CurrencyFormatter.formatGhs(collected), Icons.account_balance_outlined, AppColors.success),
                      _executiveCard('COMPLIANCE', '$rate%', Icons.verified_outlined, AppColors.primary),
                      _executiveCard('CLEARED', '$paid Students', Icons.check_circle_outline, AppColors.success),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Level Breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Level Clearance Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 14),
                    _levelComplianceRow('Level 100', 0.82, '82.0% (112/136 Paid)'),
                    const SizedBox(height: 10),
                    _levelComplianceRow('Level 200', 0.71, '71.4% (85/119 Paid)'),
                    const SizedBox(height: 10),
                    _levelComplianceRow('Level 300', 0.78, '78.2% (90/115 Paid)'),
                    const SizedBox(height: 10),
                    _levelComplianceRow('Level 400', 0.54, '54.5% (61/112 Paid)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Lookup
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Clearance Lookup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search student name or index...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_searchQuery.isNotEmpty)
                      ...studentsState.students
                          .where((s) =>
                              s.fullName.toLowerCase().contains(_searchQuery) ||
                              s.indexNumber.toLowerCase().contains(_searchQuery))
                          .take(5)
                          .map((s) => _studentClearanceResultTile(s)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _executiveCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              Icon(icon, color: accentColor, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _levelComplianceRow(String level, double progress, String details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(level, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
            Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.inputFill,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _studentClearanceResultTile(Student student) {
    final isVerified = student.verificationStatus == VerificationStatus.verified;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                Text('Index: ${student.indexNumber} • Level ${student.level}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isVerified ? AppColors.successBorder : AppColors.errorBorder),
            ),
            child: Text(
              isVerified ? '● CLEARED' : '○ UNPAID',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isVerified ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
