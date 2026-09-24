import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/dues/presentation/screens/dues_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';
import '../../features/receipts/presentation/screens/qr_receipt_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/id_upload_screen.dart';
import '../../core/widgets/app_shell.dart';

class AppRouter {
  AppRouter._();

  static const String login = 'login';
  static const String onboarding = 'onboarding';
  static const String idUpload = 'idUpload';
  static const String home = 'home';
  static const String dues = 'dues';
  static const String payments = 'payments';
  static const String receipts = 'receipts';
  static const String profile = 'profile';
  static const String notifications = 'notifications';
  static const String qrReceipt = 'qrReceipt';

  static const String loginPath = '/login';
  static const String onboardingPath = '/onboarding';
  static const String idUploadPath = '/idUpload';
  static const String homePath = '/home';
  static const String duesPath = '/dues';
  static const String paymentsPath = '/payments';
  static const String receiptsPath = '/receipts';
  static const String profilePath = '/profile';
  static const String notificationsPath = '/notifications';
  static const String qrReceiptPath = '/qrReceipt';
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<Student?>>(
      currentStudentProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final studentState = _ref.read(currentStudentProvider);
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    final user = authState.value ?? currentFirebaseUser;
    final currentPath = state.uri.toString();
    final isLoggingIn = currentPath == AppRouter.loginPath;
    final isOnboarding = currentPath == AppRouter.onboardingPath;
    final isIdUploading = currentPath.startsWith(AppRouter.idUploadPath);

    // If auth is still loading and we have no cached firebase user, do not bounce routes
    if (authState.isLoading && currentFirebaseUser == null) {
      return null;
    }

    // Not logged in -> Go to Login
    if (user == null) {
      return isLoggingIn ? null : AppRouter.loginPath;
    }

    // If student query is loading, stay on current page and do not redirect
    if (studentState.isLoading) {
      return null;
    }

    final student = studentState.value;

    // 1. New User: No student profile linked to this Google account -> Go to Onboarding
    if (student == null) {
      return isOnboarding ? null : AppRouter.onboardingPath;
    }

    // 2. If linked student tries to access login or onboarding, redirect to Home
    if (isLoggingIn || isOnboarding) {
      return AppRouter.homePath;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final currentFirebaseUser = FirebaseAuth.instance.currentUser;

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: currentFirebaseUser != null ? AppRouter.homePath : AppRouter.loginPath,
    debugLogDiagnostics: false,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRouter.loginPath,
        name: AppRouter.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRouter.onboardingPath,
        name: AppRouter.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '${AppRouter.idUploadPath}/:indexNumber',
        name: AppRouter.idUpload,
        builder: (context, state) {
          final indexNumber = state.pathParameters['indexNumber']!;
          return IdUploadScreen(indexNumber: indexNumber);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRouter.homePath,
            name: AppRouter.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRouter.duesPath,
            name: AppRouter.dues,
            pageBuilder: (context, state) => const NoTransitionPage(child: DuesScreen()),
          ),
          GoRoute(
            path: AppRouter.paymentsPath,
            name: AppRouter.payments,
            pageBuilder: (context, state) => const NoTransitionPage(child: PaymentsScreen()),
          ),
          GoRoute(
            path: AppRouter.receiptsPath,
            name: AppRouter.receipts,
            pageBuilder: (context, state) => const NoTransitionPage(child: ReceiptsScreen()),
          ),
          GoRoute(
            path: AppRouter.profilePath,
            name: AppRouter.profile,
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: AppRouter.notificationsPath,
            name: AppRouter.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRouter.qrReceiptPath,
            name: AppRouter.qrReceipt,
            builder: (context, state) {
              final payment = state.extra as Payment;
              return QrReceiptScreen(payment: payment);
            },
          ),
        ],
      ),
    ],
  );
});
