import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';

/// Shown to a veterinarian whose account is not yet verified. No clinical
/// feature is reachable from here.
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    await SessionManager.instance.restore(); // re-reads GET /me from the server
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.me;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cautionAmber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top, size: 56, color: AppColors.cautionAmber),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(AppStrings.t('pending_title'), style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.md),
              if (me != null) Text(me.fullName, style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.md),
              Text(AppStrings.t('pending_body'), textAlign: TextAlign.center, style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: AppStrings.t('pending_check'),
                icon: Icons.refresh,
                isLoading: _checking,
                onPressed: _checking ? null : _recheck,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: AppStrings.t('logout'),
                icon: Icons.logout,
                isSecondary: true,
                onPressed: SessionManager.instance.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

