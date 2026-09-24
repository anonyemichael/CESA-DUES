import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/admin_shell.dart';
import '../../features/auth/presentation/screens/admin_login_screen.dart';
import '../../features/dashboard/presentation/screens/hod_dashboard_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/students/presentation/screens/students_screen.dart';
import '../../features/dues/presentation/screens/admin_dues_screen.dart';
import '../../features/dues/presentation/screens/add_dues_screen.dart';
import '../../features/reports/presentation/screens/admin_reports_screen.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AdminRouterNotifier extends ChangeNotifier {
  AdminRouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
    _init();
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn || FirebaseAuth.instance.currentUser != null;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('admin_logged_in') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  void setLoggedIn(bool val) {
    _isLoggedIn = val;
    notifyListeners();
  }

  void notify() => notifyListeners();

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggingIn = state.uri.toString() == AppRouter.loginPath;
    if (!isLoggedIn) {
      return isLoggingIn ? null : AppRouter.loginPath;
    }
    if (isLoggingIn) {
      return AppRouter.homePath;
    }
    return null;
  }
}

final adminRouterNotifier = AdminRouterNotifier();

/// CESA DUES Admin Portal Router.
class AppRouter {
  AppRouter._();

  // Route names
  static const String login = 'login';
  static const String home = 'home';
  static const String finsecDashboard = 'home';
  static const String hodDashboard = 'dashboardHod';
  static const String students = 'students';
  static const String dues = 'dues';
  static const String addDues = 'addDues';
  static const String reports = 'reports';
  static const String dashboardHod = 'dashboardHod';
  static const String scanner = 'scanner';

  // Route paths
  static const String loginPath = '/';
  static const String homePath = '/home';
  static const String studentsPath = '/students';
  static const String duesPath = '/dues';
  static const String addDuesPath = '/dues/add';
  static const String reportsPath = '/reports';
  static const String dashboardHodPath = '/dashboardHod';
  static const String scannerPath = '/scanner';

  static final GoRouter router = GoRouter(
    initialLocation: FirebaseAuth.instance.currentUser != null ? homePath : loginPath,
    refreshListenable: adminRouterNotifier,
    debugLogDiagnostics: false,
    redirect: adminRouterNotifier.redirect,
    routes: [
      GoRoute(
        path: loginPath,
        name: login,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: homePath,
            name: home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: studentsPath,
            name: students,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StudentsScreen(),
            ),
          ),
          GoRoute(
            path: duesPath,
            name: dues,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDuesScreen(),
            ),
          ),
          GoRoute(
            path: addDuesPath,
            name: addDues,
            builder: (context, state) {
              final dues = state.extra as Dues?;
              return AddDuesScreen(initialDues: dues);
            },
          ),
          GoRoute(
            path: reportsPath,
            name: reports,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminReportsScreen(),
            ),
          ),
          GoRoute(
            path: dashboardHodPath,
            name: dashboardHod,
            builder: (context, state) => const HodDashboardScreen(),
          ),
          GoRoute(
            path: scannerPath,
            name: scanner,
            builder: (context, state) => const ScannerScreen(),
          ),
        ],
      ),
    ],
  );
}
