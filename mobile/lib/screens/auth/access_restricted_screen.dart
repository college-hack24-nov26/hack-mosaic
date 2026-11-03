import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';

/// Disabled / rejected / unsupported-role accounts, and blocked routes.
class AccessRestrictedScreen extends StatelessWidget {
  const AccessRestrictedScreen({super.key, this.reasonOverride});

  /// `forbidden_route` is used by RoleGuard when a session opens a screen
  /// that belongs to another role.
  final String? reasonOverride;

  @override
  Widget build(BuildContext context) {
    final reason = reasonOverride ?? SessionManager.instance.restrictedReason;
    final key = switch (reason) {
      'rejected' => 'restricted_rejected',
      'unsupported_role' => 'restricted_role',
      'forbidden_route' => 'restricted_route',
      _ => 'restricted_disabled',
    };
    final isRoute = reason == 'forbidden_route';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isRoute ? AppBar() : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.alertCritical.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 56, color: AppColors.alertCritical),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(AppStrings.t('restricted_title'), style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.md),
              Text(AppStrings.t(key),
                  key: const Key('restricted_message'),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.xxl),
              if (!isRoute)
                AppButton(
                  label: AppStrings.t('logout'),
                  icon: Icons.logout,
                  onPressed: SessionManager.instance.logout,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

