import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/admin_reports_controller.dart';
import '../widgets/revenue_pie_chart.dart';
import '../widgets/level_bar_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

/// Redesigned Payment Reports & Analytics Ledger.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  int? _selectedLevel; // null = All Levels
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Financial Reports & Audit',
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
            tooltip: 'Refresh Reports',
            onPressed: () => ref.invalidate(adminReportsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'Export CSV Ledger',
            onPressed: () => _exportCsv(paymentsAsync.value ?? []),
          ),
        ],
      ),
      body: paymentsAsync.when(
        data: (allPayments) {
          if (allPayments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No payment records found yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          // Filter by selected level and search query
          final filteredPayments = allPayments.where((p) {
            final matchesLevel = _selectedLevel == null || p.studentLevel == _selectedLevel;
            final query = _searchQuery.toLowerCase().trim();
            final matchesSearch = query.isEmpty ||
                p.studentId.toLowerCase().contains(query) ||
                p.studentName.toLowerCase().contains(query) ||
                p.duesName.toLowerCase().contains(query);
            return matchesLevel && matchesSearch;
          }).toList();

          final totalRevenue = filteredPayments.fold<double>(
            0.0,
            (sum, p) => sum + p.amountInCedis,
          );

          final grandTotal = allPayments.fold<double>(
            0.0,
            (sum, p) => sum + p.amountInCedis,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. KPI Summary Cards Grid
                    _buildKpiGrid(
                      totalRevenue: totalRevenue,
                      totalCount: filteredPayments.length,
                      grandTotal: grandTotal,
                      allCount: allPayments.length,
                    ),
                    const SizedBox(height: 16),

                    // 2. Interactive Level Filter Tabs & Search Bar
                    _buildFilterToolbar(),
                    const SizedBox(height: 16),

                    // 3. Analytics Charts (Pie & Bar)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 700) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _chartCard(
                                  title: 'Revenue by Dues Package',
                                  child: RevenuePieChart(payments: filteredPayments),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _chartCard(
                                  title: 'Payments by Academic Level',
                                  child: LevelBarChart(payments: filteredPayments),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _chartCard(
                                title: 'Revenue Distribution',
                                child: RevenuePieChart(payments: filteredPayments),
                              ),
                              const SizedBox(height: 14),
                              _chartCard(
                                title: 'Payments by Academic Level',
                                child: LevelBarChart(payments: filteredPayments),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4. Detailed Transactions Header & Export Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Payment Audit Ledger (${filteredPayments.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _exportCsv(filteredPayments),
                          icon: const Icon(Icons.download, size: 15),
                          label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 5. Transactions Table / Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: filteredPayments.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Text('No transactions match the selected filter.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                columnSpacing: 18,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Index Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Dues Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: filteredPayments.map((payment) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(DateFormat('dd MMM yyyy').format(payment.createdAt ?? DateTime.now()), style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(payment.studentId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                      DataCell(
                                        Text(
                                          (payment.studentName.isNotEmpty && payment.studentName != 'Student')
                                              ? payment.studentName
                                              : payment.studentId,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text('Level ${payment.studentLevel}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                        ),
                                      ),
                                      DataCell(Text(payment.duesName, style: const TextStyle(fontSize: 12))),
                                      DataCell(
                                        Text(
                                          'GHS ${payment.amountInCedis.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successLight,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.successBorder),
                                          ),
                                          child: const Text('PAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success)),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error loading reports: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildKpiGrid({
    required double totalRevenue,
    required int totalCount,
    required double grandTotal,
    required int allCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.25 : 1.7,
          children: [
            _kpiCard(
              title: _selectedLevel == null ? 'Total Revenue' : 'Level $_selectedLevel Rev.',
              value: 'GHS ${totalRevenue.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              bg: const Color(0xFFEFF6FF),
            ),
            _kpiCard(
              title: _selectedLevel == null ? 'Paid Transactions' : 'Level $_selectedLevel Paid',
              value: '$totalCount',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              bg: const Color(0xFFECFDF5),
            ),
            _kpiCard(
              title: 'Avg. Payment',
              value: totalCount > 0 ? 'GHS ${(totalRevenue / totalCount).toStringAsFixed(2)}' : 'GHS 0.00',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFF59E0B),
              bg: const Color(0xFFFFFBEB),
            ),
            _kpiCard(
              title: 'All Levels Grand Total',
              value: 'GHS ${grandTotal.toStringAsFixed(2)}',
              icon: Icons.pie_chart_outline_rounded,
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by index, student name, or package...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 10),

          // Academic Level Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Level: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                _levelChip(label: 'All Levels', level: null),
                const SizedBox(width: 4),
                _levelChip(label: 'Level 100', level: 100),
                const SizedBox(width: 4),
                _levelChip(label: 'Level 200', level: 200),
                const SizedBox(width: 4),
                _levelChip(label: 'Level 300', level: 300),
                const SizedBox(width: 4),
                _levelChip(label: 'Level 400', level: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelChip({required String label, required int? level}) {
    final isSelected = _selectedLevel == level;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.inputFill,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
      onSelected: (_) {
        setState(() {
          _selectedLevel = level;
        });
      },
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  OverlayEntry? _notificationOverlay;

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
    _searchController.dispose();
    super.dispose();
  }

  void _showDownloadPushNotification(XFile xFile, String fileName) {
    _notificationOverlay?.remove();
    _notificationOverlay = null;

    if (!mounted) return;
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -60.0, end: 0.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(0, val),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFF334155), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_done_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Download Complete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '• just now',
                              style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$fileName saved to Downloads',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      entry.remove();
                      _notificationOverlay = null;
                      if (!kIsWeb) {
                        try {
                          final result = await OpenFilex.open(xFile.path);
                          if (result.type != ResultType.done) {
                            await Share.shareXFiles([xFile], subject: 'CESA Dues Report');
                          }
                        } catch (_) {
                          await Share.shareXFiles([xFile], subject: 'CESA Dues Report');
                        }
                      } else {
                        await Share.shareXFiles([xFile], subject: 'CESA Dues Report');
                      }
                    },
                    child: Text(kIsWeb ? 'SAVED' : 'OPEN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      entry.remove();
                      _notificationOverlay = null;
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _notificationOverlay = entry;
    overlay.insert(entry);

    // Auto-dismiss smoothly after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (_notificationOverlay == entry) {
        entry.remove();
        _notificationOverlay = null;
      }
    });
  }

  Future<void> _exportCsv(List<Payment> payments) async {
    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment records to export.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final rows = <List<dynamic>>[];
      rows.add(['Date', 'Index Number', 'Student Name', 'Academic Level', 'Dues Package', 'Amount (GHS)', 'Status']);

      for (final p in payments) {
        final displayName = (p.studentName.isNotEmpty && p.studentName != 'Student')
            ? p.studentName
            : p.studentId;
        rows.add([
          DateFormat('yyyy-MM-dd HH:mm').format(p.createdAt ?? DateTime.now()),
          p.studentId,
          displayName,
          'Level ${p.studentLevel}',
          p.duesName,
          p.amountInCedis.toStringAsFixed(2),
          'SUCCESSFUL'
        ]);
      }

      final csvString = const ListToCsvConverter().convert(rows);
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'CESA_Dues_Report_$dateStr.csv';
      final bytes = utf8.encode(csvString);

      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: fileName,
      );

      try {
        await xFile.saveTo(fileName);
      } catch (_) {}

      // Trigger native-looking Push Notification HUD
      _showDownloadPushNotification(xFile, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
