import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import '../../../../app/theme/app_colors.dart';

class LevelBarChart extends StatelessWidget {
  const LevelBarChart({super.key, required this.payments});

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

    final paymentsByLevel = <int, int>{
      100: 0,
      200: 0,
      300: 0,
      400: 0,
    };

    for (final payment in payments) {
      if (payment.isSuccessful) {
        final level = payment.studentLevel;
        if (paymentsByLevel.containsKey(level)) {
          paymentsByLevel[level] = paymentsByLevel[level]! + 1;
        }
      }
    }

    final maxVal = paymentsByLevel.values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxVal > 0 ? maxVal + 2 : 5.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(6),
              tooltipMargin: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} Paid',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final level = value.toInt() * 100;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      'L$level',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            _buildBarGroup(1, paymentsByLevel[100]!.toDouble(), const Color(0xFF2563EB)),
            _buildBarGroup(2, paymentsByLevel[200]!.toDouble(), const Color(0xFF0284C7)),
            _buildBarGroup(3, paymentsByLevel[300]!.toDouble(), const Color(0xFF10B981)),
            _buildBarGroup(4, paymentsByLevel[400]!.toDouble(), const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
