import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/admin_home_controller.dart';
import 'package:cesa_dues_admin/features/auth/presentation/controllers/admin_auth_controller.dart';
import 'package:cesa_dues_admin/features/auth/presentation/controllers/role_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final role = ref.watch(roleControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role == UserRole.hod ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: role == UserRole.hod ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Text(
                role == UserRole.hod ? 'HOD PORTAL' : 'FINANCIAL SECRETARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: role == UserRole.hod ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan Clearance QR',
            onPressed: () => context.pushNamed(AppRouter.scanner),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          try {
            await ref.read(adminStatsProvider.future);
          } catch (_) {}
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero QR Scanner Banner (Organized & overflow-free)
                  _buildScannerHero(context),
                  const SizedBox(height: 24),

                  // 2. Metrics & Analytics Title
                  const Text(
                    'Executive Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Stats Grid
                  statsAsync.when(
                    data: (stats) => _buildStatsGrid(context, stats),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          e is AppException ? e.message : 'Failed to load statistics.',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. Quick Actions Section
                  const Text(
                    'Management Modules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Action Cards
                  _buildActionCard(
                    context,
                    title: 'Student Directory & Search',
                    subtitle: 'Lookup students by Index Number and Level 100-400',
                    icon: Icons.people_alt_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => context.goNamed(AppRouter.students),
                  ),
                  const SizedBox(height: 12),

                  if (role == UserRole.financialSecretary) ...[
                    _buildActionCard(
                      context,
                      title: 'Dues Packages & Configuration',
                      subtitle: 'Add, change, edit, or remove departmental dues',
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF059669),
                      onTap: () => context.goNamed(AppRouter.dues),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildActionCard(
                    context,
                    title: 'Financial Reports & Auditing',
                    subtitle: 'Live payment breakdown charts and CSV export ledger',
                    icon: Icons.analytics_rounded,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () => context.goNamed(AppRouter.reports),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Clearance Scanner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verify official student payment passes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed(AppRouter.scanner),
            icon: const Icon(Icons.camera_alt_rounded, size: 16),
            label: const Text('Open QR Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.2 : 1.6,
          children: [
            _buildStatCard(
              title: 'Total Revenue',
              value: 'GHS ${stats.totalRevenue.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              bg: const Color(0xFFEFF6FF),
            ),
            _buildStatCard(
              title: 'Total Students',
              value: stats.totalStudents.toString(),
              icon: Icons.school_rounded,
              color: const Color(0xFF0284C7),
              bg: const Color(0xFFF0F9FF),
            ),
            _buildStatCard(
              title: 'Pending ID Check',
              value: stats.pendingVerifications.toString(),
              icon: Icons.pending_actions_rounded,
              color: stats.pendingVerifications > 0 ? AppColors.warning : AppColors.success,
              bg: stats.pendingVerifications > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
            ),
            _buildStatCard(
              title: 'Active Dues',
              value: stats.activeDuesCount.toString(),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.02),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 13),
          ],
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of the Admin Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(adminAuthControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.goNamed(AppRouter.login);
      }
    }
  }
}
