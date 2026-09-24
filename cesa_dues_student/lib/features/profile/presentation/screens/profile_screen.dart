import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

/// Student Profile Screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsyncValue = ref.watch(currentStudentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Student Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: studentAsyncValue.when(
        data: (student) {
          if (student == null) {
            return const Center(
              child: Text('Profile not found.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(currentStudentProvider),
            child: _buildProfileContent(context, ref, student),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: Text(
            error is AppException ? error.message : 'Error loading profile',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, Student student) {
    final isVerified = student.verificationStatus == VerificationStatus.verified;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Executive Profile Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: Text(
                      student.fullName.isNotEmpty ? student.fullName.substring(0, 1).toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          student.programme,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'INDEX: ${student.indexNumber}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Verification Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isVerified ? AppColors.successBorder : AppColors.warningBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.successLight : AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                  color: isVerified ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerified ? 'Official Student ID Verified' : 'Verification Required',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isVerified ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVerified
                          ? 'Your student profile is authenticated for official clearances.'
                          : 'Upload your student ID card to unlock digital dues clearance.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isVerified) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.pushNamed(
                      AppRouter.idUpload,
                      pathParameters: {'indexNumber': student.indexNumber},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Verify ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Academic Details Section
        _buildSectionCard(
          title: 'Academic Details',
          icon: Icons.school_outlined,
          children: [
            _buildDetailRow('Index Number', student.indexNumber, isMono: true),
            _buildDetailRow('Academic Level', 'Level ${student.level}'),
            _buildDetailRow('Programme', student.programme),
            _buildDetailRow('Academic Session', student.academicYear),
          ],
        ),
        const SizedBox(height: 14),

        // Contact & Account Section
        _buildSectionCard(
          title: 'Account & Security',
          icon: Icons.security_outlined,
          children: [
            _buildDetailRow('Email', (student.email != null && student.email!.isNotEmpty) ? student.email! : 'Connected via Google'),
            if (student.phone != null && student.phone!.isNotEmpty)
              _buildDetailRow('Phone', student.phone!),
            _buildDetailRow('Department', 'Civil Engineering'),
            _buildDetailRow('Institution', 'UENR Sunyani'),
          ],
        ),
        const SizedBox(height: 24),

        // Sign Out Button
        OutlinedButton.icon(
          onPressed: () => _handleSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
          label: const Text('Sign Out from CESA Portal', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.errorBorder),
            backgroundColor: AppColors.errorLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Are you sure you want to sign out of your student account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.goNamed(AppRouter.login);
      }
    }
  }
}
