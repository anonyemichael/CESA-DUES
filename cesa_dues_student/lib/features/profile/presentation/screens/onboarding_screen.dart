import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _indexController = TextEditingController();
  final _nameController = TextEditingController();
  
  int _selectedLevel = 100;
  bool _isCheckingRoster = false;
  bool _rosterFound = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _indexController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _lookupIndexNumber() async {
    final indexNumber = _indexController.text.trim().toUpperCase();
    if (indexNumber.length < 5) return;

    setState(() => _isCheckingRoster = true);

    try {
      final repo = ref.read(studentRepositoryProvider);
      final student = await repo.getStudentByIndex(indexNumber);

      if (mounted) {
        if (student != null) {
          setState(() {
            _rosterFound = true;
            _nameController.text = student.fullName;
            _selectedLevel = student.level;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found roster record for ${student.fullName}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          setState(() {
            _rosterFound = false;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCheckingRoster = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) {
      context.goNamed(AppRouter.login);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final indexNumber = _indexController.text.trim().toUpperCase();
      final fullName = _nameController.text.trim();
      final email = authUser.email ?? '';

      final repo = ref.read(studentRepositoryProvider);
      await repo.linkStudentAccount(
        indexNumber: indexNumber,
        uid: authUser.uid,
        email: email,
        fullName: fullName.isNotEmpty ? fullName : (authUser.displayName ?? 'Civil Engineering Student'),
        level: _selectedLevel,
        programme: 'BSc. Civil Engineering',
      );

      // Refresh student provider
      ref.invalidate(currentStudentProvider);

      if (mounted) {
        // Proceed to ID Card verification
        context.go('${AppRouter.idUploadPath}/$indexNumber');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error linking profile: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Student Setup', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.goNamed(AppRouter.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_pin_circle_outlined, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                'Step 1: Link Index Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Student Registration',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Link your Google account with your official departmental Index Number.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Logged in email pill
                      if (user?.email != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_circle, color: Color(0xFF64748B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  user!.email!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Index Number
                      const Text('Official Index Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _indexController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. GCVE1400 or UEB2019420',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          suffixIcon: _isCheckingRoster
                              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                              : IconButton(
                                  icon: const Icon(Icons.search, size: 20),
                                  tooltip: 'Look up index',
                                  onPressed: _lookupIndexNumber,
                                ),
                        ),
                        onChanged: (val) {
                          if (val.length >= 6) _lookupIndexNumber();
                        },
                        validator: (v) => (v == null || v.trim().length < 4) ? 'Enter a valid index number' : null,
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      const Text('Full Legal Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Michael Anonye',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Academic Level
                      const Text('Academic Level *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: _selectedLevel,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.school_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(value: 100, child: Text('Level 100 (Freshman)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 200, child: Text('Level 200 (Sophomore)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 300, child: Text('Level 300 (Junior)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 400, child: Text('Level 400 (Final Year)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedLevel = v);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit & Proceed Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Next: Upload Student ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
