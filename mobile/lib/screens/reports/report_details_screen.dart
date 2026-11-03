import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/models/disease_report_model.dart';

class ReportDetailsScreen extends StatelessWidget {
  final DiseaseReportModel report;

  const ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(report.animalName ?? 'तपासणी अहवाल / Report'),
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
                      'केस स्थिती / Case Status',
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
          Text('नोंदवलेली लक्षणे / Observed Symptoms', style: AppTypography.sectionHeading),
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
            Text('फोटो पुरावा / Image Evidence', style: AppTypography.sectionHeading),
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
          Text('शेतकऱ्याची नोंद / Farmer Description', style: AppTypography.sectionHeading),
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

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
                'पशुवैद्यक तपासणी निष्कर्ष / Clinical Decision',
                style: AppTypography.cardTitle.copyWith(color: AppColors.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (report.confirmedDiseaseCode != null) ...[
            Text(
              'पुष्टी झालेला रोग: ${report.confirmedDiseaseCode?.replaceAll("_", " ").toUpperCase()}',
              style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.alertCritical),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            report.vetNotes ?? 'पशुवैद्यकांनी केसची तपासणी केली आहे.',
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
        color: AppColors.infoBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.infoBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                'एआय प्राथमिक निरीक्षण (Decision Support)',
                style: AppTypography.cardTitle.copyWith(color: AppColors.infoBlue, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'संशयित लक्षण: ${s.topLabel} (${(s.topConfidence * 100).toStringAsFixed(1)}% विश्वासार्हता)',
            style: AppTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'मॉडेल आवृत्ती: ${s.modelVersion} • हे वैद्यकीय निदान नाही.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatSymptomName(String code) {
    switch (code) {
      case 'skin_nodules':
        return 'गाठी (Skin Nodules)';
      case 'fever':
        return 'ताप (Fever)';
      case 'reduced_milk':
        return 'दुधात घट (Drop in Milk)';
      case 'lameness':
        return 'लंगडणे (Lameness)';
      case 'salivation':
        return 'लाळ गळणे (Salivation)';
      case 'nasal_discharge':
        return 'नाकातून स्राव (Discharge)';
      case 'appetite_loss':
        return 'चारा न खाणे (Off Feed)';
      default:
        return code.replaceAll('_', ' ');
    }
  }
}
