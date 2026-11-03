import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/local/offline_store.dart';
import '../animals/add_animal_screen.dart';
import '../animals/animal_details_screen.dart';
import '../scanner/disease_scanner_screen.dart';
import '../profile/language_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const FarmerHomeScreen({super.key, required this.onNavigateTab});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final OfflineStore _store = OfflineStore();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final user = _store.currentUser;
        final animals = _store.animals;
        final reports = _store.reports;
        final pendingReports = reports.where((r) => r.status == 'submitted' || r.status == 'under_review').length;
        final confirmedAlerts = reports.where((r) => r.status == 'confirmed').length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('app_name'),
                      style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.villageName ?? 'Phaltan, Satara (सातारा)',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: AppColors.primary),
                tooltip: 'भाषा बदला / Change Language',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
              IconButton(
                icon: Icon(
                  _store.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _store.isOnline ? AppColors.successGreen : AppColors.cautionAmber,
                ),
                tooltip: _store.isOnline ? 'Online' : 'Offline Mode',
                onPressed: () {
                  _store.setOnlineStatus(!_store.isOnline);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_store.isOnline ? 'Switched to Online mode' : 'Switched to Offline simulation'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              SyncStatusBar(
                isOnline: _store.isOnline,
                pendingCount: _store.pendingSyncCount,
                onSyncTap: () async {
                  final syncedCount = await _store.syncPendingWithBackend();
                  if (context.mounted) {
                    final remaining = _store.pendingSyncCount;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          remaining == 0
                              ? 'Synced $syncedCount record(s) with Go backend!'
                              : 'Backend unreachable ($syncedCount synced, $remaining queued safely on device).',
                        ),
                      ),
                    );
                  }
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Farmer Greeting Card
                    _buildGreetingCard(user),
                    const SizedBox(height: AppSpacing.lg),

                    // Overview Stats
                    _buildOverviewStats(animals.length, pendingReports, confirmedAlerts),
                    const SizedBox(height: AppSpacing.lg),

                    // Urgent Surveillance Alert Banner
                    if (confirmedAlerts > 0)
                      _buildSurveillanceAlertBanner(),

                    // Quick Actions Section
                    Text(
                      AppStrings.t('quick_actions'),
                      style: AppTypography.sectionHeading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: AppSpacing.lg),

                    // Regulatory Safety Notice
                    const SafetyDisclaimerCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // Recent Disease Reports
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'अलीकडील अहवाल / Recent Reports',
                            style: AppTypography.sectionHeading,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(3),
                          child: const Text('पहा सर्व / View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRecentReportsList(reports),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingCard(user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.t('greeting'),
                style: AppTypography.cardTitle.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'सातारा जिल्हा / Satara',
                  style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            user?.fullName ?? 'Ramesh Jadhav',
            style: AppTypography.screenTitle.copyWith(color: Colors.white, fontSize: 24),
          ),
          if (user?.farmName != null) ...[
            const SizedBox(height: 2),
            Text(
              user!.farmName!,
              style: AppTypography.bodySecondary.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewStats(int totalAnimals, int pending, int alerts) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: () => widget.onNavigateTab(1),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalAnimals',
                  style: AppTypography.displayLarge.copyWith(color: AppColors.primary, fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t('registered_cattle'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppCard(
            onTap: () => widget.onNavigateTab(3),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pending',
                  style: AppTypography.displayLarge.copyWith(color: AppColors.cautionAmber, fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t('pending_reports'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppCard(
            onTap: () => widget.onNavigateTab(3),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$alerts',
                  style: AppTypography.displayLarge.copyWith(color: AppColors.alertCritical, fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t('active_alerts'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurveillanceAlertBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alertCritical.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.alertCritical.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.alertCritical, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'रोग चेतावणी: लंपी त्वचा रोग (LSD)',
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.alertCritical,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'फलटण तालुक्यात ३ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले रुग्ण आढळले आहेत. आपल्या जनावरांची नियमित तपासणी करा.',
                  style: AppTypography.caption.copyWith(color: AppColors.textPrimary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          icon: Icons.camera_alt,
          title: AppStrings.t('action_scan'),
          subtitle: 'MobileNetV3 TFLite',
          color: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiseaseScannerScreen()),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.add_circle_outline,
          title: AppStrings.t('action_add_animal'),
          subtitle: 'नोंदणी / Register',
          color: AppColors.primaryLight,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.assignment_late_outlined,
          title: AppStrings.t('action_report'),
          subtitle: 'लक्षणे व फोटो पाठवा',
          color: AppColors.cautionAmber,
          onTap: () => widget.onNavigateTab(2),
        ),
        _buildActionCard(
          icon: Icons.qr_code_2,
          title: AppStrings.t('action_passport'),
          subtitle: 'ऑफलाइन आरोग्य पास',
          color: AppColors.infoBlue,
          onTap: () {
            if (_store.animals.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnimalDetailsScreen(animal: _store.animals.first),
                ),
              );
            } else {
              widget.onNavigateTab(1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsList(List reports) {
    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'अद्याप कोणताही अहवाल नाही.\nNo disease reports filed yet.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ),
      );
    }

    return Column(
      children: reports.take(3).map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            onTap: () => widget.onNavigateTab(3),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.animalName ?? 'Cattle #${r.animalId.substring(0, 6)}',
                        style: AppTypography.cardTitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.description ?? 'Symptoms recorded',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: r.status),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

