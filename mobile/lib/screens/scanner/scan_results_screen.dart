import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/models/disease_report_model.dart';
import '../reports/create_report_screen.dart';

class ScanResultsScreen extends StatelessWidget {
  final String imagePath;
  final String? animalId;
  final String predictedLabel;
  final double confidence;
  final String modelVersion;
  final List<String> observations;

  const ScanResultsScreen({
    super.key,
    required this.imagePath,
    this.animalId,
    required this.predictedLabel,
    required this.confidence,
    required this.modelVersion,
    required this.observations,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('screening_result')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Analyzed Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Image.file(
              File(imagePath),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Diagnostic Summary Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t('decision_support_banner'),
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        modelVersion,
                        style: AppTypography.badge.copyWith(color: AppColors.primary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  predictedLabel,
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.alertCritical,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Confidence Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: confidence,
                          minHeight: 10,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.alertCritical),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '$percent%',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.alertCritical,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t('statistical_prob'),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Visual Observations Card
          Text(AppStrings.t('visual_observations'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: observations.map((obs) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lens, size: 8, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(obs, style: AppTypography.bodyDefault.copyWith(fontSize: 13)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Mandatory Clinical Disclaimer
          const SafetyDisclaimerCard(),
          const SizedBox(height: AppSpacing.xl),

          // Proceed to Report Button
          AppButton(
            label: AppStrings.t('file_report'),
            icon: Icons.assignment_late_outlined,
            backgroundColor: AppColors.primary,
            onPressed: () {
              final screeningResult = ScreeningResult(
                modelVersion: modelVersion,
                topLabel: 'lumpy_skin_disease',
                topConfidence: confidence,
                inconclusive: false,
                scores: [
                  {'label': 'lumpy_skin_disease', 'score': confidence},
                  {'label': 'normal_skin', 'score': double.parse((1.0 - confidence).toStringAsFixed(2))},
                ],
                ranAt: DateTime.now().toUtc(),
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(
                    preselectedAnimalId: animalId,
                    initialPhotoPath: imagePath,
                    initialScreening: screeningResult,
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
}
