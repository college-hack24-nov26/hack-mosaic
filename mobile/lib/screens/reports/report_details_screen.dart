import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../core/services/voice_service.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/disease_report_model.dart';
import '../animals/animal_details_screen.dart';
import '../nearby/nearby_screen.dart';
import '../nearby/vet_consultation_screen.dart';

class ReportDetailsScreen extends StatelessWidget {
  final DiseaseReportModel report;

  const ReportDetailsScreen({super.key, required this.report});

  void _speakReportSummary(BuildContext context) {
    final statusMr = report.status == 'confirmed'
        ? 'पशुवैद्यकांनी पुष्टी केलेला अहवाल'
        : 'पशुवैद्यकांच्या तपासणीसाठी प्रलंबित अहवाल';
    final text = '${report.animalName ?? "जनावर"} चा रोग अहवाल. स्थिती: $statusMr. '
        '${report.vetNotes ?? report.description ?? ""} '
        '${AppStrings.t('safety_disclaimer')}';
    VoiceService().speakEmergencyMarathi(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔊 मराठी आवाज सुरू आहे... (Speaking report summary in Marathi)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = OfflineStore();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(report.animalName ?? AppStrings.t('case_history')),
        actions: [
          IconButton(
            tooltip: 'अहवाल ऐका (Voice)',
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            onPressed: () => _speakReportSummary(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Case Status Banner Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t('case_status'),
                      style: AppTypography.cardTitle,
                    ),
                    StatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWorkflowProgress(report.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vet Verification & Prescription Box (If available)
          if (report.vetNotes != null || report.status == 'confirmed')
            _buildVetVerificationCard(),

          // Preliminary Screening Observations (If ran)
          if (report.screening != null)
            _buildScreeningObservationsCard(),

          // Observed Symptoms
          Text(AppStrings.t('observed_symptoms'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: report.symptomCodes.map((code) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _formatSymptomName(code),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Photo Evidence (If attached)
          if (report.photoPath != null && File(report.photoPath!).existsSync()) ...[
            Text(AppStrings.t('image_evidence'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.file(
                File(report.photoPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Farmer Notes
          Text(AppStrings.t('farmer_description'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              report.description ?? 'No specific notes recorded.',
              style: AppTypography.bodyDefault,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Geospatial Coordinates Card
          if (report.latitude != null && report.longitude != null) ...[
            AppCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NearbyScreen(
                      initialTabIndex: 1,
                      targetLat: report.latitude,
                      targetLng: report.longitude,
                    ),
                  ),
                );
              },
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.surfaceContainer,
              child: Row(
                children: [
                  const Icon(Icons.map, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'स्थान: ${report.latitude!.toStringAsFixed(4)}° N, ${report.longitude!.toStringAsFixed(4)}° E (Satara Surveillance Cluster)',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Interactive Follow-up Actions
          Text('पुढील कृती (Follow-Up Actions)', style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: '👨‍⚕️ पशुवैद्यक भेट / सल्ला बुक करा (Consult Veterinarian)',
            icon: Icons.event_available,
            onPressed: () {
              final vets = store.getNearbyVeterinarians(
                report.latitude ?? 17.9856,
                report.longitude ?? 74.4331,
              );
              if (vets.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VetConsultationScreen(
                      vet: vets.first,
                      attachedReport: report,
                    ),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NearbyScreen(initialTabIndex: 0)),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('डिजिटल पासपोर्ट'),
                  onPressed: () {
                    final match = store.animals.where((a) => a.id == report.animalId).toList();
                    final animal = match.isNotEmpty
                        ? match.first
                        : (store.animals.isNotEmpty ? store.animals.first : null);
                    if (animal != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AnimalDetailsScreen(animal: animal)),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('उद्रेक नकाशा'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NearbyScreen(
                          initialTabIndex: 1,
                          targetLat: report.latitude,
                          targetLng: report.longitude,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Regulatory Safety Disclaimer
          const SafetyDisclaimerCard(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildWorkflowProgress(String status) {
    int step = 1;
    if (status == 'under_review') step = 2;
    if (status == 'confirmed' || status == 'rejected' || status == 'flagged') step = 3;

    return Row(
      children: [
        _buildStepCircle(1, 'नोंदवले\nFiled', step >= 1, step == 1),
        Expanded(child: Container(height: 2, color: step >= 2 ? AppColors.primary : AppColors.border)),
        _buildStepCircle(2, 'तपासणी\nReview', step >= 2, step == 2),
        Expanded(child: Container(height: 2, color: step >= 3 ? AppColors.primary : AppColors.border)),
        _buildStepCircle(3, 'निर्णय\nDecision', step >= 3, step == 3),
      ],
    );
  }

  Widget _buildStepCircle(int number, String label, bool isCompleted, bool isCurrent) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('$number', style: AppTypography.badge),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVetVerificationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                AppStrings.t('clinical_decision'),
                style: AppTypography.cardTitle.copyWith(color: AppColors.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (report.confirmedDiseaseCode != null) ...[
            Text(
              '${AppStrings.t('confirmed_disease')}: ${AppStrings.formatDisease(report.confirmedDiseaseCode!)}',
              style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.alertCritical),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            report.vetNotes ?? AppStrings.t('vet_verified_notice'),
            style: AppTypography.bodyDefault.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningObservationsCard() {
    final s = report.screening!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.infoBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                AppStrings.t('decision_support_banner'),
                style: AppTypography.cardTitle.copyWith(color: AppColors.infoBlue, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.t('observed_symptoms')}: ${s.topLabel} (${(s.topConfidence * 100).toStringAsFixed(1)}%)',
            style: AppTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.t('model_version_notice'),
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatSymptomName(String code) {
    return AppStrings.formatSymptom(code);
  }
}
