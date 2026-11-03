import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../localization/app_strings.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        label = AppStrings.t('status_confirmed');
        icon = Icons.verified;
        break;
      case 'under_review':
        label = AppStrings.t('status_under_review');
        icon = Icons.hourglass_top;
        break;
      case 'rejected':
        label = AppStrings.t('status_rejected');
        icon = Icons.cancel_outlined;
        break;
      case 'flagged':
        label = AppStrings.t('status_flagged');
        icon = Icons.flag_outlined;
        break;
      case 'submitted':
      default:
        label = AppStrings.t('status_submitted');
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

