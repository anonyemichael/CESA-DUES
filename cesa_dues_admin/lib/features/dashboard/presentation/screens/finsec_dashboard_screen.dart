import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../widgets/send_notification_dialog.dart';
import '../../../reports/presentation/controllers/admin_reports_controller.dart';

/// Financial Secretary Dashboard (Responsive for Mobile, Tablet & Desktop).
class FinsecDashboardScreen extends ConsumerWidget {
  const FinsecDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(adminReportsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CESA DUES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text('FinSec Workspace', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
                  tooltip: 'Send Broadcast',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SendNotificationDialog(),
                  ),
                ),
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
            drawer: _buildDrawer(context),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile: true),
                  const SizedBox(height: 18),
                  _buildKpis(reportAsync, isMobile: true),
                  const SizedBox(height: 24),
                  _buildComplianceCard(),
                  const SizedBox(height: 20),
                  _buildQuickOperations(context),
                ],
              ),
            ),
          );
        }

        // Desktop / Tablet Layout
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              Container(
                width: 240,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  border: Border(right: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: _buildSidebar(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isMobile: false),
                      const SizedBox(height: 28),
                      _buildKpis(reportAsync, isMobile: false),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildComplianceCard()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildQuickOperations(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset('assets/images/logo.jpg', width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CESA DUES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Civil Engineering Dept', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: AppColors.primary),
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Students Directory'),
              onTap: () {
                Navigator.pop(context);
                context.goNamed(AppRouter.students);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Dues Management'),
              onTap: () {
                Navigator.pop(context);
                context.goNamed(AppRouter.dues);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Financial Reports'),
              onTap: () {
                Navigator.pop(context);
                context.goNamed(AppRouter.reports);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_outlined),
              title: const Text('Scan Clearance QR'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(AppRouter.scanner);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () => context.goNamed(AppRouter.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset('assets/images/logo.jpg', width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CESA DUES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('FinSec Workspace', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E293B)),
        const SizedBox(height: 16),
        _navItem(Icons.dashboard_outlined, 'Dashboard', isSelected: true, onTap: () {}),
        _navItem(Icons.people_outline, 'Students Directory', onTap: () => context.goNamed(AppRouter.students)),
        _navItem(Icons.receipt_long_outlined, 'Dues Management', onTap: () => context.goNamed(AppRouter.dues)),
        _navItem(Icons.assessment_outlined, 'Financial Reports', onTap: () => context.goNamed(AppRouter.reports)),
        _navItem(Icons.qr_code_scanner_outlined, 'Scan QR Clearance', onTap: () => context.pushNamed(AppRouter.scanner)),
        _navItem(Icons.campaign_outlined, 'Send Broadcast', onTap: () {
          showDialog(context: context, builder: (context) => const SendNotificationDialog());
        }),
        const Spacer(),
        const Divider(height: 1, color: Color(0xFF1E293B)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: AppColors.accent, child: Text('FS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fin. Secretary', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('anonyemichael6@gmail.com', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 18),
                onPressed: () => context.goNamed(AppRouter.login),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Dashboard',
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Civil Engineering • Session 2025/2026',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildKpis(AsyncValue<List<Payment>> reportAsync, {required bool isMobile}) {
    return reportAsync.when(
      data: (data) {
        const total = 482;
        final paid = data.length;
        final unpaid = total - paid;
        final collected = data.fold(0.0, (double s, Payment p) => s + p.amountInCedis);
        final rate = total > 0 ? (paid / total * 100).toStringAsFixed(1) : '0';

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _kpiCardMobile('ENROLLED', '$total', Icons.people_outline, AppColors.accent),
              _kpiCardMobile('PAID DUES', '$paid ($rate%)', Icons.check_circle_outline, AppColors.success),
              _kpiCardMobile('UNPAID', '$unpaid', Icons.schedule, AppColors.warning),
              _kpiCardMobile('COLLECTED', CurrencyFormatter.formatGhs(collected), Icons.account_balance_wallet_outlined, AppColors.success),
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard('TOTAL ENROLLED', '$total', Icons.people_outline, AppColors.accent),
            _kpiCard('PAID DUES', '$paid', Icons.check_circle_outline, AppColors.success, subtitle: '$rate% compliance'),
            _kpiCard('UNPAID / OUTSTANDING', '$unpaid', Icons.schedule, AppColors.warning),
            _kpiCard('REVENUE COLLECTED', CurrencyFormatter.formatGhs(collected), Icons.account_balance_wallet_outlined, AppColors.success),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildComplianceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dues Compliance by Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('2025/2026', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          _levelBar('Level 100', 0.82, '82.0% (112/136)'),
          const SizedBox(height: 10),
          _levelBar('Level 200', 0.74, '74.2% (98/132)'),
          const SizedBox(height: 10),
          _levelBar('Level 300', 0.68, '68.0% (75/110)'),
          const SizedBox(height: 10),
          _levelBar('Level 400', 0.91, '91.3% (95/104)'),
        ],
      ),
    );
  }

  Widget _buildQuickOperations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Operations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          _quickActionTile(icon: Icons.group_add_outlined, title: 'Student Directory', subtitle: 'Search, promote & import', onTap: () => context.goNamed(AppRouter.students)),
          const SizedBox(height: 8),
          _quickActionTile(icon: Icons.receipt_long_outlined, title: 'Dues Management', subtitle: 'Set rates & deadlines', onTap: () => context.goNamed(AppRouter.dues)),
          const SizedBox(height: 8),
          _quickActionTile(icon: Icons.assessment_outlined, title: 'Financial Reports', subtitle: 'Visual charts & CSV export', onTap: () => context.goNamed(AppRouter.reports)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool isSelected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          border: isSelected ? const Border(left: BorderSide(color: AppColors.accentLight, width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _kpiCardMobile(String label, String value, IconData icon, Color color) {
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
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ],
      ),
    );
  }

  Widget _levelBar(String level, double progress, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(level, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.inputFill,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
