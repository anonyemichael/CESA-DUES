import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/admin_dues_controller.dart';

/// Clean and focused Add / Edit Dues Screen.
class AddDuesScreen extends ConsumerStatefulWidget {
  const AddDuesScreen({super.key, this.initialDues});

  final Dues? initialDues;

  @override
  ConsumerState<AddDuesScreen> createState() => _AddDuesScreenState();
}

class _AddDuesScreenState extends ConsumerState<AddDuesScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _descriptionController;

  final Map<int, bool> _levels = {
    100: true,
    200: true,
    300: true,
    400: true,
  };

  DateTime? _deadline;
  bool _isActive = true;

  bool get _isEditMode => widget.initialDues != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDues;
    _nameController = TextEditingController(text: d?.name ?? '');
    _amountController = TextEditingController(
      text: d != null ? d.amountInCedis.toStringAsFixed(2) : '',
    );
    _academicYearController = TextEditingController(text: d?.academicYear ?? '2025/2026');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _isActive = d?.isActive ?? true;
    _deadline = d?.deadline;

    if (d != null) {
      _levels[100] = d.applicableLevels.contains(100);
      _levels[200] = d.applicableLevels.contains(200);
      _levels[300] = d.applicableLevels.contains(300);
      _levels[400] = d.applicableLevels.contains(400);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _academicYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() {
        _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedLevels = _levels.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one academic level.')),
      );
      return;
    }

    final amountVal = double.tryParse(_amountController.text.trim());
    if (amountVal == null || amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final academicYear = _academicYearController.text.trim();
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    bool success;
    if (_isEditMode) {
      success = await ref.read(adminDuesControllerProvider.notifier).updateDues(
            id: widget.initialDues!.id,
            name: name,
            amountCedis: amountVal,
            academicYear: academicYear,
            applicableLevels: selectedLevels,
            isActive: _isActive,
            description: description,
            deadline: _deadline,
          );
    } else {
      success = await ref.read(adminDuesControllerProvider.notifier).createDues(
            name: name,
            amountCedis: amountVal,
            academicYear: academicYear,
            applicableLevels: selectedLevels,
            isActive: _isActive,
            description: description,
            deadline: _deadline,
          );
    }

    if (success && mounted) {
      ref.invalidate(adminDuesListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Dues updated successfully!' : 'Dues package created!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(adminDuesControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Dues Package' : 'Add Dues Package',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Name
              const Text(
                'Dues Title',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. 2025/2026 Annual Dues',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Amount & Academic Year in a row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount (GHS)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: 'GH₵ ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            if (double.tryParse(val.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Academic Year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Academic Session',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _academicYearController,
                          decoration: InputDecoration(
                            hintText: '2025/2026',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Applicable Levels
              const Text(
                'Applicable Levels',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _levels.keys.map((level) {
                  final isSelected = _levels[level] ?? false;
                  return FilterChip(
                    label: Text('Level $level', style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    )),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderStrong,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (val) => setState(() => _levels[level] = val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Deadline
              const Text(
                'Deadline (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _deadline != null
                              ? DateFormat('d MMMM yyyy').format(_deadline!)
                              : 'No deadline set',
                          style: TextStyle(
                            fontSize: 14,
                            color: _deadline != null ? AppColors.textPrimary : AppColors.textHint,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes for students...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Active Switch
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  title: const Text('Active for Payments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    _isActive ? 'Students can view and pay this dues' : 'Hidden from students (Draft)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Create Dues Package',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
