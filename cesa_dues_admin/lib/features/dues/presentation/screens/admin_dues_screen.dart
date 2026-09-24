import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../controllers/admin_dues_controller.dart';
import '../../../auth/presentation/controllers/role_controller.dart';
import 'package:intl/intl.dart';

/// Dues Configuration & Lifecycle Management (Desktop Ledger).
class AdminDuesScreen extends ConsumerWidget {
  const AdminDuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(adminDuesListProvider);
    final role = ref.watch(roleControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dues Packages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
            tooltip: 'Refresh Dues',
            onPressed: () => ref.invalidate(adminDuesListProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: role != UserRole.hod
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDuesDialog(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Dues Package', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : null,
      body: duesAsync.when(
        data: (duesList) {
          final activeCount = duesList.where((d) => d.isActive).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminDuesListProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Executive Hero Banner
                Container(
                  padding: const EdgeInsets.all(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 12, color: AppColors.gold),
                                SizedBox(width: 5),
                                Text(
                                  'SESSION 2025/2026',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$activeCount Active / ${duesList.length} Total',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Departmental Dues Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Configure levies, fees, and clearance requirements for all cohorts.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE PACKAGES (${duesList.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (role != UserRole.hod)
                      TextButton.icon(
                        onPressed: () => _showCreateDuesDialog(context, ref),
                        icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                        label: const Text('New Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (duesList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('No Dues Packages Found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Create the official dues package for the 2025/2026 academic session.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateDuesDialog(context, ref),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create Dues Package'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...duesList.map((dues) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildDuesCard(context, ref, dues, role),
                      )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildDuesCard(BuildContext context, WidgetRef ref, Dues dues, UserRole role) {
    final isDuesActive = dues.isActive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDuesActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar with Accent Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDuesActive ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDuesActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: isDuesActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dues.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Academic Year ${dues.academicYear}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDuesActive ? AppColors.successLight : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDuesActive ? AppColors.successBorder : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: isDuesActive ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDuesActive ? 'ACTIVE' : 'ARCHIVED',
                        style: TextStyle(
                          color: isDuesActive ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'GHS ${dues.amountInCedis.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'per student',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metadata Chips (Levels & Deadline)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...dues.applicableLevels.map((lvl) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'Level $lvl',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                          ),
                        )),
                    if (dues.deadline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alarm, size: 12, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(dues.deadline!)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (role != UserRole.hod) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showEditDuesDialog(context, ref, dues),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit / Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _confirmDeleteDues(context, ref, dues),
                        icon: const Icon(Icons.delete_outline_rounded, size: 14),
                        label: const Text('Remove Dues', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorLight,
                          foregroundColor: AppColors.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCreateDuesDialog(BuildContext context, WidgetRef ref) {
    context.push(AppRouter.addDuesPath);
  }

  void _showEditDuesDialog(BuildContext context, WidgetRef ref, Dues dues) {
    context.push(AppRouter.addDuesPath, extra: dues);
  }

  void _confirmDeleteDues(BuildContext context, WidgetRef ref, Dues dues) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Remove Dues Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently remove "${dues.name}" (GHS ${dues.amountInCedis.toStringAsFixed(2)})?\n\nThis will remove it from the student dues catalog.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(adminDuesControllerProvider.notifier).deleteDues(dues.id);
              if (success && context.mounted) {
                ref.invalidate(adminDuesListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dues package removed successfully.'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
  }
}

class EditDuesDialog extends ConsumerStatefulWidget {
  const EditDuesDialog({super.key, required this.dues});
  final Dues dues;

  @override
  ConsumerState<EditDuesDialog> createState() => _EditDuesDialogState();
}

class _EditDuesDialogState extends ConsumerState<EditDuesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _academicYearController;
  late bool _isActive;
  late final Map<int, bool> _levels;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dues.name);
    _amountController = TextEditingController(text: widget.dues.amountInCedis.toStringAsFixed(2));
    _academicYearController = TextEditingController(text: widget.dues.academicYear);
    _isActive = widget.dues.isActive;
    _levels = {
      100: widget.dues.applicableLevels.contains(100),
      200: widget.dues.applicableLevels.contains(200),
      300: widget.dues.applicableLevels.contains(300),
      400: widget.dues.applicableLevels.contains(400),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedLevels = _levels.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one applicable level')));
      return;
    }

    final success = await ref.read(adminDuesControllerProvider.notifier).updateDues(
      id: widget.dues.id,
      name: _nameController.text.trim(),
      amountCedis: double.parse(_amountController.text.trim()),
      academicYear: _academicYearController.text.trim(),
      applicableLevels: selectedLevels,
      isActive: _isActive,
      description: widget.dues.description,
      deadline: widget.dues.deadline,
    );

    if (success && mounted) {
      ref.invalidate(adminDuesListProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dues package updated successfully!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(adminDuesControllerProvider).isLoading;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Edit / Change Dues Package', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Dues Title', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (GHS)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _academicYearController,
                decoration: const InputDecoration(labelText: 'Academic Session', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active for Payments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(_isActive ? 'Students can view and pay this dues' : 'Archived / Hidden from students', style: const TextStyle(fontSize: 12)),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 12),
              const Text('Applicable Academic Levels', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ..._levels.keys.map((level) {
                return CheckboxListTile(
                  dense: true,
                  title: Text('Level $level'),
                  value: _levels[level],
                  onChanged: (val) {
                    setState(() {
                      _levels[level] = val ?? false;
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

class CreateDuesDialog extends ConsumerStatefulWidget {
  const CreateDuesDialog({super.key});

  @override
  ConsumerState<CreateDuesDialog> createState() => _CreateDuesDialogState();
}

class _CreateDuesDialogState extends ConsumerState<CreateDuesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _academicYearController = TextEditingController(text: '2025/2026');

  final Map<int, bool> _levels = {
    100: true,
    200: true,
    300: true,
    400: true,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedLevels = _levels.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one applicable level')));
      return;
    }

    final success = await ref.read(adminDuesControllerProvider.notifier).createDues(
      name: _nameController.text.trim(),
      amountCedis: double.parse(_amountController.text.trim()),
      academicYear: _academicYearController.text.trim(),
      applicableLevels: selectedLevels,
    );

    if (success && mounted) {
      ref.invalidate(adminDuesListProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dues package published successfully!'), backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(adminDuesControllerProvider).isLoading;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Configure New Dues Package', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Dues Package Title (e.g. 2025/2026 Annual Dues)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (GHS)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _academicYearController,
                decoration: const InputDecoration(labelText: 'Academic Session'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Applicable Academic Levels', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ..._levels.keys.map((level) {
                return CheckboxListTile(
                  dense: true,
                  title: Text('Level $level'),
                  value: _levels[level],
                  onChanged: (val) {
                    setState(() {
                      _levels[level] = val ?? false;
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Publish Dues'),
        ),
      ],
    );
  }
}
