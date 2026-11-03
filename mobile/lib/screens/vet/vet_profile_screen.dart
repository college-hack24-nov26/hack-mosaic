import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/local/offline_store.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  final _session = SessionManager.instance;
  bool _loggingOut = false;

  Future<void> _changeLanguage(String lang) async {
    await OfflineStore().setLanguage(lang);
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('logout_title')),
        content: Text(AppStrings.t('logout_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('close')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertCritical),
            child: Text(AppStrings.t('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loggingOut = true);
    await _session.logout();
    // AuthGate dynamically routes to WelcomeScreen once session status changes.
  }

  @override
  Widget build(BuildContext context) {
    final me = _session.me;
    final vet = me?.vet;
    final name = me?.fullName ?? 'Veterinarian';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('vprof_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Identity Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Icon(Icons.medical_services, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  name.startsWith('Dr.') ? name : 'Dr. $name',
                  style: AppTypography.displayLarge.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppColors.successGreen),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.t('vet_verified'),
                        style: AppTypography.badge.copyWith(color: AppColors.successGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Credentials Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('registration'), style: AppTypography.sectionHeading),
                const Divider(height: AppSpacing.md),
                if (vet?.qualification != null)
                  _infoRow(AppStrings.t('vprof_qualification'), vet!.qualification!),
                if (vet?.registrationNumber != null)
                  _infoRow(AppStrings.t('vprof_registration'), vet!.registrationNumber!),
                if (vet?.clinicName != null)
                  _infoRow(AppStrings.t('vprof_clinic'), vet!.clinicName!),
                if (vet?.districtName != null || vet?.districtId != null)
                  _infoRow(AppStrings.t('vet_district'), vet?.districtName ?? vet?.districtId ?? ''),
                if (vet?.talukaName != null || vet?.talukaId != null)
                  _infoRow(AppStrings.t('vprof_taluka'), vet?.talukaName ?? vet?.talukaId ?? ''),
                if (me?.phone != null)
                  _infoRow(AppStrings.t('vprof_contact'), me!.phone),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Language Selector Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(AppStrings.t('settings_language'), style: AppTypography.sectionHeading),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _langButton('mr', 'मराठी'),
                    const SizedBox(width: AppSpacing.sm),
                    _langButton('en', 'English'),
                    const SizedBox(width: AppSpacing.sm),
                    _langButton('hi', 'हिंदी'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 4. Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loggingOut ? null : _confirmLogout,
              icon: const Icon(Icons.logout, color: AppColors.alertCritical),
              label: Text(
                AppStrings.t('logout'),
                style: AppTypography.button.copyWith(color: AppColors.alertCritical),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.alertCritical),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyDefault)),
        ],
      ),
    );
  }

  Widget _langButton(String code, String label) {
    final active = AppStrings.currentLang == code;
    return Expanded(
      child: InkWell(
        onTap: () => _changeLanguage(code),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.badge.copyWith(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
