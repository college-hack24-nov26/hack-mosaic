import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../localization/app_strings.dart';

class SyncStatusBar extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const SyncStatusBar({
    super.key,
    required this.isOnline,
    this.pendingCount = 0,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isOffline = !isOnline;
    final color = isOffline ? AppColors.cautionAmber : AppColors.infoBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.sync,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOffline
                  ? (pendingCount > 0
                      ? 'Offline Mode • $pendingCount record(s) queued for sync'
                      : AppStrings.t('offline_banner'))
                  : 'Syncing $pendingCount pending record(s) to server...',
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (pendingCount > 0 && onSyncTap != null)
            InkWell(
              onTap: onSyncTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'SYNC NOW',
                  style: AppTypography.badge.copyWith(
                    color: color,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

