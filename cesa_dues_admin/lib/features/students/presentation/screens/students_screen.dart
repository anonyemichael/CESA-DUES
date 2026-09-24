import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/student_list_controller.dart';
import '../controllers/student_import_controller.dart';
import '../../../auth/presentation/controllers/role_controller.dart';
import '../../../dashboard/presentation/widgets/send_notification_dialog.dart';

/// Master Students Directory (Responsive Mobile & Tablet).
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPromotionDialog(BuildContext context, StudentListController controller) {
    final yearController = TextEditingController(text: '2024/2025');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 8),
            Text('Promote All Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will automatically roll over all students to the next academic level:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• Level 100  ➔  Level 200', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('• Level 200  ➔  Level 300', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('• Level 300  ➔  Level 400', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('• Level 400  ➔  Graduated / Alumni', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('New Academic Session:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: yearController,
              decoration: InputDecoration(
                hintText: 'e.g. 2024/2025',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final count = await controller.promoteAllStudents(yearController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully promoted $count students to the ${yearController.text} session!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Promotion failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Confirm & Promote'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentListControllerProvider);
    final controller = ref.read(studentListControllerProvider.notifier);
    final isHod = ref.watch(roleControllerProvider) == UserRole.hod;

    final importState = ref.watch(studentImportProvider);
    final isImporting = importState is AsyncLoading;

    ref.listen<AsyncValue<int>>(
      studentImportProvider,
      (_, importVal) {
        if (importVal.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import Failed: ${importVal.error}'), backgroundColor: AppColors.error),
          );
        } else if (!importVal.isLoading && importVal.hasValue && (importVal.value ?? 0) > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported ${importVal.value} students!'), backgroundColor: AppColors.success),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Students Master Directory',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh Ledger',
            onPressed: () => controller.loadStudents(isRefresh: true),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Top Action Bar for FinSec (Promote Cohort & Import Roster)
              if (!isHod)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPromotionDialog(context, controller),
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2563EB)),
                          label: const Text('Promote Cohort', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isImporting ? null : () => ref.read(studentImportProvider.notifier).importStudents(),
                          icon: isImporting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.upload_file, size: 16),
                          label: const Text('Import Roster', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search & Filter Toolbar with Quick Level Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by index number or student name...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  controller.updateSearch('');
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      onChanged: (val) {
                        controller.updateSearch(val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Level: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(width: 4),
                          _levelChip(label: 'All Levels', level: null, currentLevel: state.levelFilter, onSelect: controller.updateLevelFilter),
                          const SizedBox(width: 6),
                          _levelChip(label: 'Level 100', level: 100, currentLevel: state.levelFilter, onSelect: controller.updateLevelFilter),
                          const SizedBox(width: 6),
                          _levelChip(label: 'Level 200', level: 200, currentLevel: state.levelFilter, onSelect: controller.updateLevelFilter),
                          const SizedBox(width: 6),
                          _levelChip(label: 'Level 300', level: 300, currentLevel: state.levelFilter, onSelect: controller.updateLevelFilter),
                          const SizedBox(width: 6),
                          _levelChip(label: 'Level 400', level: 400, currentLevel: state.levelFilter, onSelect: controller.updateLevelFilter),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Data Table Area
              Expanded(
                child: state.students.isEmpty && !state.isLoading
                    ? const Center(
                        child: Text(
                          'No students matching the current filter.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.students.length + (state.isLoading ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == state.students.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final student = state.students[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.08),
                                child: Text(
                                  student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              title: Text(
                                student.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              subtitle: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    student.indexNumber,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      'Level ${student.level}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildVerificationBadge(student.verificationStatus),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                                ],
                              ),
                              onTap: () => _showStudentDetailsDialog(context, student, controller, isHod),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetailsDialog(BuildContext context, Student student, StudentListController controller, bool isHod) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Index Number:', student.indexNumber),
              _detailRow('Academic Level:', 'Level ${student.level}'),
              _detailRow('Programme:', student.programme),
              _detailRow('Academic Session:', student.academicYear),
              _detailRow('Verification:', student.verificationStatus.label),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (student.verificationStatus != VerificationStatus.verified && !isHod)
              ElevatedButton(
                onPressed: () {
                  controller.updateVerificationStatus(student.indexNumber, VerificationStatus.verified);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${student.fullName} manually verified.'), backgroundColor: AppColors.success),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve & Verify ID'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => SendNotificationDialog(student: student),
                );
              },
              child: const Text('Send Dues Reminder'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    Color bg;
    Color text;
    Color border;

    switch (status) {
      case VerificationStatus.verified:
        bg = AppColors.successLight;
        text = AppColors.success;
        border = AppColors.successBorder;
        break;
      case VerificationStatus.pending:
        bg = AppColors.warningLight;
        text = AppColors.warning;
        border = AppColors.warningBorder;
        break;
      case VerificationStatus.rejected:
      case VerificationStatus.unverified:
        bg = AppColors.errorLight;
        text = AppColors.error;
        border = AppColors.errorBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _levelChip({
    required String label,
    required int? level,
    required int? currentLevel,
    required Function(int?) onSelect,
  }) {
    final isSelected = currentLevel == level;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.inputFill,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
      onSelected: (_) => onSelect(level),
    );
  }
}
