import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';

class RevenuePieChart extends StatelessWidget {
  const RevenuePieChart({super.key, required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No payment data available', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    // Aggregate revenue by duesName
    final revenueByDues = <String, double>{};
    for (final payment in payments) {
      if (payment.isSuccessful) {
        revenueByDues[payment.duesName] =
            (revenueByDues[payment.duesName] ?? 0) + payment.amountInCedis;
      }
    }

    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    
    double totalRevenue = revenueByDues.values.fold(0, (sum, val) => sum + val);

    revenueByDues.forEach((duesName, amount) {
      final percentage = totalRevenue > 0 ? (amount / totalRevenue) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Legend with styled badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: revenueByDues.keys.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final name = entry.value;
            final color = colors[idx % colors.length];
            final amount = revenueByDues[name]!;
            final pct = totalRevenue > 0 ? (amount / totalRevenue) * 100 : 0;

            return Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• GHS ${amount.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
