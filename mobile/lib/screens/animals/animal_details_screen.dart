import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/animal_model.dart';
import '../reports/create_report_screen.dart';

class AnimalDetailsScreen extends StatelessWidget {
  final AnimalModel animal;

  const AnimalDetailsScreen({super.key, required this.animal});

  String _buildQrPayload() {
    final payload = {
      'v': 1,
      'animal_id': animal.id,
      'species': animal.speciesCode,
      'breed': animal.breedCode ?? 'crossbred',
      'tag': animal.tagNumber ?? 'UNTAGGED',
      'name': animal.displayName,
      'sex': animal.sex,
      'vaccinations': [
        {'v': 'FMD Raksha', 'd': '2026-06-12'},
        {'v': 'LSD Goat Pox', 'd': '2026-09-05'},
      ],
      'snapshot_at': DateTime.now().toIso8601String().substring(0, 10),
    };
    return jsonEncode(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isCattle = animal.speciesCode == 'cattle';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(animal.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'पशुवैद्यक स्कॅनसाठी कॉपी करा (Copy QR Passport)',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _buildQrPayload()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('डिजिटल QR पासपोर्ट कॉपी झाला! पशुवैद्यक पोर्टलवरील स्कॅनरमध्ये थेट तपासा.'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Animal Header Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    isCattle ? Icons.pets : Icons.agriculture,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.displayName,
                        style: AppTypography.screenTitle.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'टॅग: ${animal.tagNumber ?? "No Tag ID"}',
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'प्रजाती: ${animal.speciesCode.toUpperCase()} • जात: ${animal.breedCode?.toUpperCase() ?? "Crossbred"}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Offline QR Code Passport Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.t('action_passport'),
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: _buildQrPayload(),
                    version: QrVersions.auto,
                    size: 190.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.textPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${AppStrings.t('date')}: ${DateTime.now().toIso8601String().substring(0, 10)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.currentLang == 'en'
                      ? 'Field veterinarians can scan this code offline to inspect verified records.'
                      : (AppStrings.currentLang == 'hi'
                          ? 'पशु चिकित्सक ऑफ़लाइन स्कैन करके रिकॉर्ड देख सकते हैं।'
                          : 'पशुवैद्यक अधिकारी इंटरनेटशिवाय हा कोड स्कॅन करून इतिहास पाहू शकतात.'),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Identity Specifications
          Text(AppStrings.t('details'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildInfoRow(AppStrings.t('gender'), animal.sex == 'female' ? AppStrings.t('gender_female') : AppStrings.t('gender_male')),
                const Divider(height: 16),
                _buildInfoRow(AppStrings.t('birth_date'), animal.birthDate ?? '2 years'),
                const Divider(height: 16),
                _buildInfoRow(AppStrings.t('identification_markings'), animal.markings ?? (AppStrings.currentLang == 'en' ? 'White forehead patch' : (AppStrings.currentLang == 'hi' ? 'माथे पर सफेद निशान' : 'कपाळावर पांढरा डाग'))),
                const Divider(height: 16),
                _buildInfoRow(AppStrings.t('sync_status'), animal.isSynced ? AppStrings.t('synced_cloud') : AppStrings.t('queued_device')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Medical & Vaccination Timeline
          Text(AppStrings.t('vaccination_history'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildVaccinationItem(
                  title: AppStrings.currentLang == 'en' ? 'Foot & Mouth Vaccine (FMD Raksha)' : (AppStrings.currentLang == 'hi' ? 'खुरपका-मुंहपका टीका (FMD)' : 'लाळ्या खुरकूत लस (FMD Raksha)'),
                  date: '12 जून 2026',
                  status: AppStrings.currentLang == 'en' ? 'Verified' : 'प्रमाणित',
                  vet: AppStrings.currentLang == 'en' ? 'Dr. Sanjay Patil' : 'डॉ. संजय पाटील',
                ),
                const Divider(height: 20),
                _buildVaccinationItem(
                  title: AppStrings.currentLang == 'en' ? 'Lumpy Skin Disease Vaccine' : (AppStrings.currentLang == 'hi' ? 'लंपी त्वचा रोग टीका' : 'लंपी त्वचा रोग लस (LSD)'),
                  date: '05 सप्टेंबर 2026',
                  status: AppStrings.currentLang == 'en' ? 'Verified' : 'प्रमाणित',
                  vet: AppStrings.currentLang == 'en' ? 'Dr. Sanjay Patil' : 'डॉ. संजय पाटील',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Report Illness Button for this Animal
          AppButton(
            label: AppStrings.t('report_illness_btn'),
            icon: Icons.assignment_late_outlined,
            backgroundColor: AppColors.alertCritical,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(
                    preselectedAnimalId: animal.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySecondary),
        Text(value, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildVaccinationItem({
    required String title,
    required String date,
    required String status,
    required String vet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.successGreen, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text('दिनांक: $date • पशुवैद्यक: $vet', style: AppTypography.caption),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: AppTypography.badge.copyWith(color: AppColors.successGreen, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
