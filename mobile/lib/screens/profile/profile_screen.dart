import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/user_model.dart';
import 'language_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final OfflineStore _store = OfflineStore();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final user = _store.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppStrings.t('nav_profile')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // User Identity Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Ramesh Jadhav',
                            style: AppTypography.screenTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.phone ?? '+919876543210',
                            style: AppTypography.bodySecondary.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.villageName ?? 'Phaltan, Satara (सातारा)',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Farmer Consent for Alerts (PPT S5 Non-negotiable requirement)
              Text(AppStrings.t('alert_consent'), style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.t('alert_consent_title'),
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    AppStrings.t('alert_consent_sub'),
                    style: AppTypography.caption.copyWith(fontSize: 11, height: 1.3),
                  ),
                  value: user?.alertConsent ?? true,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    if (user != null) {
                      final updated = UserModel(
                        id: user.id,
                        phone: user.phone,
                        fullName: user.fullName,
                        role: user.role,
                        villageId: user.villageId,
                        villageName: user.villageName,
                        farmName: user.farmName,
                        latitude: user.latitude,
                        longitude: user.longitude,
                        alertConsent: val,
                      );
                      _store.saveUser(updated);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Offline Sync Queue Management
              Text(AppStrings.t('sync_queue'), style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _store.isOnline ? Icons.cloud_done : Icons.cloud_off,
                              color: _store.isOnline ? AppColors.successGreen : AppColors.cautionAmber,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _store.isOnline ? AppStrings.t('online_connected') : AppStrings.t('offline_simulated'),
                              style: AppTypography.cardTitle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_store.pendingSyncCount > 0 ? AppColors.cautionAmber : AppColors.successGreen).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_store.pendingSyncCount} ${AppStrings.t('pending_sync')}',
                            style: AppTypography.badge.copyWith(
                              color: _store.pendingSyncCount > 0 ? AppColors.cautionAmber : AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: AppStrings.t('sync_now'),
                      icon: Icons.sync,
                      isSecondary: true,
                      isLoading: _store.isSyncing,
                      onPressed: () async {
                        final syncedCount = await _store.syncPendingWithBackend();
                        if (context.mounted) {
                          final remaining = _store.pendingSyncCount;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                remaining == 0
                                    ? 'Synced $syncedCount record(s) with Go Backend API!'
                                    : 'Backend unreachable ($syncedCount synced, $remaining queued safely on device).',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Language Preferences
              Text(AppStrings.t('app_language'), style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ).then((_) => setState(() {}));
                },
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.currentLang == 'mr'
                            ? 'मराठी'
                            : (AppStrings.currentLang == 'hi' ? 'हिंदी' : 'English'),
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // About Project Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pashu Wani • पशुवाणी', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'College of Engineering Phaltan Hackathon 2K26\nHealthcare Theme • Offline-First Livestock Surveillance\nTeam: Om Rajput, Soham Pawar, Lokesh Patil, Khushi Shinde',
                      style: AppTypography.caption.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }
}
