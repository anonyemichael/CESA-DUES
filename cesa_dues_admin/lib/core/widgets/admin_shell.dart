import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (int index) => _onItemTapped(index, context),
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primary.withOpacity(0.2),
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: Image.asset('assets/images/logo.jpg', width: 48, errorBuilder: (c,e,s) => const Icon(Icons.admin_panel_settings, size: 48)),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: AppColors.primary),
                  label: Text('Students'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  label: Text('Dues'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
                  label: Text('Reports'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
            label: 'Dues',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.studentsPath)) {
      return 1;
    }
    if (location.startsWith(AppRouter.duesPath)) {
      return 2;
    }
    if (location.startsWith(AppRouter.reportsPath)) {
      return 3;
    }
    return 0; // Default to home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(AppRouter.home);
        break;
      case 1:
        context.goNamed(AppRouter.students);
        break;
      case 2:
        context.goNamed(AppRouter.dues);
        break;
      case 3:
        context.goNamed(AppRouter.reports);
        break;
    }
  }
}
