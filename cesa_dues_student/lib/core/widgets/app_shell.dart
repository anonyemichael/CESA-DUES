import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';

/// Main application shell with bottom navigation bar.
/// Used by ShellRoute to provide consistent navigation across main screens.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.homePath)) return 0;
    if (location.startsWith(AppRouter.duesPath)) return 1;
    if (location.startsWith(AppRouter.paymentsPath)) return 2;
    if (location.startsWith(AppRouter.receiptsPath)) return 3;
    if (location.startsWith(AppRouter.profilePath)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(AppRouter.home);
      case 1:
        context.goNamed(AppRouter.dues);
      case 2:
        context.goNamed(AppRouter.payments);
      case 3:
        context.goNamed(AppRouter.receipts);
      case 4:
        context.goNamed(AppRouter.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex(context),
              onDestinationSelected: (int index) => _onTap(context, index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: Image.asset('assets/images/logo.jpg', width: 48, errorBuilder: (c,e,s) => const Icon(Icons.school, size: 48)),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Dues'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment),
                  label: Text('Payments'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.qr_code_outlined),
                  selectedIcon: Icon(Icons.qr_code),
                  label: Text('Receipts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outlined),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Dues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_outlined),
            activeIcon: Icon(Icons.qr_code),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
