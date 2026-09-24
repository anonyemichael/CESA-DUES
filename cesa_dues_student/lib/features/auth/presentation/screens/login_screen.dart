import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';


/// Premium Institutional Student Welcome & Authentication Screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (success && mounted) {
      context.goNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (_, state) {
        if (state.hasError && !state.isLoading) {
          final error = state.error;
          final message = error is AppException
              ? error.message
              : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient Hero Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFFF8FAFC),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Logo Badge with Double-Ring Elevation
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                offset: const Offset(0, 8),
                                blurRadius: 20,
                              ),
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.school,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brand Header
                      const Text(
                        'CESA DUES',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Civil Engineering Students\' Association',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Modern Feature Cards
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                              offset: const Offset(0, 6),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildFeatureTile(
                              icon: Icons.verified_rounded,
                              iconBg: const Color(0xFFECFDF5),
                              iconColor: const Color(0xFF059669),
                              title: 'Official Digital Receipts',
                              subtitle: 'Instant tamper-proof receipts for departmental dues',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                            _buildFeatureTile(
                              icon: Icons.account_balance_wallet_rounded,
                              iconBg: const Color(0xFFEFF6FF),
                              iconColor: const Color(0xFF2563EB),
                              title: 'Direct MoMo & Card Payments',
                              subtitle: 'Fast, automated dues payment powered by Paystack',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                            _buildFeatureTile(
                              icon: Icons.qr_code_2_rounded,
                              iconBg: const Color(0xFFF5F3FF),
                              iconColor: const Color(0xFF7C3AED),
                              title: 'Instant QR Verification',
                              subtitle: 'Quick, seamless clearance check for departmental activities',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Premium Official Google Sign In Button
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: isLoading ? null : _signInWithGoogle,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                              ),
                              child: isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E293B)),
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset('assets/images/google_logo.png', width: 22, height: 22, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, size: 24)),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            'Continue with Google Account',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Institutional Footer
                      const Text(
                        'Department of Civil & Environmental Engineering\nUniversity of Energy and Natural Resources (UENR)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}
