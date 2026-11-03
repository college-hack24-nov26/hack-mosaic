import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/models/disease_report_model.dart';
import '../reports/create_report_screen.dart';

class ScanResultsScreen extends StatefulWidget {
  final String imagePath;
  final String? animalId;
  final GeminiGuidance guidance;

  const ScanResultsScreen({
    super.key,
    required this.imagePath,
    this.animalId,
    required this.guidance,
  });

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  final VoiceService _voice = VoiceService();
  bool _speaking = false;

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  String get _spokenText {
    final g = widget.guidance;
    final base = g.spokenSummary.isNotEmpty
        ? g.spokenSummary
        : [...g.observations, ...g.interimCare].join('. ');
    return '$base ${AppStrings.t('safety_disclaimer')}';
  }

  Future<void> _toggleVoice() async {
    if (_speaking) {
      await _voice.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    final ok = await _voice.speak(_spokenText);
    if (!mounted) return;
    if (!ok) {
      setState(() => _speaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('voice_unavailable'))),
      );
    }
  }

  Color get _urgencyColor {
    switch (widget.guidance.urgency) {
      case 'high':
        return AppColors.alertCritical;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppColors.cautionAmber;
    }
  }

  String get _urgencyLabel {
    switch (widget.guidance.urgency) {
      case 'high':
        return AppStrings.t('urgency_high');
      case 'low':
        return AppStrings.t('urgency_low');
      default:
        return AppStrings.t('urgency_medium');
    }
  }

  Widget _bulletCard(List<String> items, {Color dot = AppColors.primary}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: items.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.lens, size: 8, color: dot),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: AppTypography.bodyDefault.copyWith(fontSize: 13))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guidance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('screening_result'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Image.file(File(widget.imagePath), height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('ai_guidance_title'), style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _urgencyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    _urgencyLabel,
                    style: AppTypography.badge.copyWith(color: _urgencyColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up),
                    label: Text(AppStrings.t(_speaking ? 'stop_listening' : 'listen_guidance')),
                    onPressed: _toggleVoice,
                  ),
                ),
                const SizedBox(height: 8),
                Text(AppStrings.t('generated_by_ai'), style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (g.observations.isNotEmpty) ...[
            Text(AppStrings.t('visual_observations'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            _bulletCard(g.observations),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (g.possibleConditions.isNotEmpty) ...[
            Text(AppStrings.t('possible_signs'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            _bulletCard(g.possibleConditions, dot: AppColors.cautionAmber),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (g.interimCare.isNotEmpty) ...[
            Text(AppStrings.t('interim_care'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            _bulletCard(g.interimCare),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (g.warningSigns.isNotEmpty) ...[
            Text(AppStrings.t('warning_signs'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            _bulletCard(g.warningSigns, dot: AppColors.alertCritical),
            const SizedBox(height: AppSpacing.lg),
          ],

          const SafetyDisclaimerCard(),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: AppStrings.t('file_report'),
            icon: Icons.assignment_late_outlined,
            backgroundColor: AppColors.primary,
            onPressed: () {
              _voice.stop();
              final topCond = g.possibleConditions.isNotEmpty
                  ? g.possibleConditions.first
                  : 'preliminary_skin_observation';
              final conf = g.urgency == 'high'
                  ? 0.88
                  : (g.urgency == 'medium' ? 0.74 : 0.55);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(
                    preselectedAnimalId: widget.animalId,
                    initialPhotoPath: widget.imagePath,
                    initialScreening: ScreeningResult(
                      modelVersion: 'gemini-2.5-flash-preliminary',
                      topLabel: topCond,
                      topConfidence: conf,
                      inconclusive: g.urgency == 'low',
                      scores: [
                        {'label': topCond, 'score': conf},
                      ],
                      ranAt: DateTime.now().toUtc(),
                    ),
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
