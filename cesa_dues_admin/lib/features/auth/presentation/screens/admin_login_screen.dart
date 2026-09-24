import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/role_controller.dart';

/// Admin login screen — official departmental email + OTP.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'anonyemichael6@gmail.com');
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an admin email address.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final success = await ref.read(adminAuthControllerProvider.notifier).requestOtp(email);
    
    if (mounted) {
      setState(() {
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login code generated for $email (Test code: 123456)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    
    if (email.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final success = await ref.read(adminAuthControllerProvider.notifier).verifyOtp(email, otp);
    
    if (success && mounted) {
      adminRouterNotifier.notify();
      context.goNamed('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(
      adminAuthControllerProvider,
      (_, state) {
        if (state.hasError && !state.isLoading) {
          final error = state.error;
          final message = error is AppException
              ? error.message
              : 'Authentication error. Use 123456 as code.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official App Logo
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.account_balance, color: AppColors.primary, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'CESA DUES',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department Admin Portal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (!_otpSent) ...[
                      const Text(
                        'Select Your Role',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<UserRole>(
                        isExpanded: true,
                        value: ref.watch(roleControllerProvider),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.financialSecretary,
                            child: Text('Financial Secretary', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: UserRole.hod,
                            child: Text('Head of Department (HOD)', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (role) {
                                if (role != null) {
                                  ref.read(roleControllerProvider.notifier).setRole(role);
                                }
                              },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Official Department Email',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'anonyemichael6@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        onSubmitted: (_) => _requestOtp(),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isLoading ? null : _requestOtp,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Send Login Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Code generated for ${_emailController.text}\n(Test code: 123456)',
                                style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verification Code',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          hintText: 'Enter 6-digit code (e.g. 123456)',
                          prefixIcon: const Icon(Icons.password_outlined, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Change Email',
                            onPressed: isLoading ? null : () => setState(() => _otpSent = false),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                        onSubmitted: (_) => _verifyOtp(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isLoading ? null : _verifyOtp,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Verify & Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            onPressed: isLoading ? null : () => setState(() => _otpSent = false),
                            child: const Text('Change Email', style: TextStyle(fontSize: 13)),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            onPressed: isLoading ? null : _requestOtp,
                            icon: const Icon(Icons.refresh, size: 15),
                            label: const Text('Resend Code', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
