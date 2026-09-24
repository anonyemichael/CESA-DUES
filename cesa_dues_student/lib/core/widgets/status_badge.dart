import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A status badge chip for payment/verification status display.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  /// Factory for "PAID" status.
  factory StatusBadge.paid() => const StatusBadge(
        label: 'PAID',
        color: AppColors.paid,
        backgroundColor: AppColors.paidBackground,
        icon: Icons.check_circle,
      );

  /// Factory for "UNPAID" status.
  factory StatusBadge.unpaid() => const StatusBadge(
        label: 'UNPAID',
        color: AppColors.unpaid,
        backgroundColor: AppColors.unpaidBackground,
        icon: Icons.schedule,
      );

  /// Factory for "PENDING" status.
  factory StatusBadge.pending() => const StatusBadge(
        label: 'PENDING',
        color: AppColors.pending,
        backgroundColor: AppColors.pendingBackground,
        icon: Icons.hourglass_empty,
      );

  /// Factory for "FAILED" status.
  factory StatusBadge.failed() => const StatusBadge(
        label: 'FAILED',
        color: AppColors.failed,
        backgroundColor: AppColors.failedBackground,
        icon: Icons.error_outline,
      );

  /// Factory for "VERIFIED" status.
  factory StatusBadge.verified() => const StatusBadge(
        label: 'VERIFIED',
        color: AppColors.success,
        backgroundColor: AppColors.successLight,
        icon: Icons.verified,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
