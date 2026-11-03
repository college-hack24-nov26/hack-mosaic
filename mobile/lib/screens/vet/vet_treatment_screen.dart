import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/vet_models.dart';
import '../../data/vet_repository.dart';

class VetTreatmentScreen extends StatefulWidget {
  const VetTreatmentScreen({super.key, required this.report});
  final VetReport report;

  @override
  State<VetTreatmentScreen> createState() => _VetTreatmentScreenState();
}

class _VetTreatmentScreenState extends State<VetTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _obsController = TextEditingController();
  final _treatmentNameController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _repo = VetRepository.shared;

  DateTime? _followUpDate;
  bool _submitting = false;

  @override
  void dispose() {
    _obsController.dispose();
    _treatmentNameController.dispose();
    _medicationController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _submit() async {
    final obs = _obsController.text.trim();
    final treatment = _treatmentNameController.text.trim();

    if (obs.isEmpty && treatment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('treat_need_one')),
          backgroundColor: AppColors.alertCritical,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final animalId = widget.report.animal.id;

    try {
      // 1. If clinical observations were entered, record them
      if (obs.isNotEmpty) {
        await _repo.addHealthRecord(
          animalId,
          summary: obs,
          data: {
            'report_id': widget.report.id,
            'instructions': _instructionsController.text.trim(),
            if (_followUpDate != null) 'follow_up_date': DateFormat('yyyy-MM-dd').format(_followUpDate!),
          },
        );
      }

      // 2. If treatment recommendation was entered, record treatment
      if (treatment.isNotEmpty) {
        final dosageText = [
          if (_medicationController.text.trim().isNotEmpty) _medicationController.text.trim(),
          if (_dosageController.text.trim().isNotEmpty) _dosageController.text.trim(),
          if (_durationController.text.trim().isNotEmpty) '${_durationController.text.trim()} days',
        ].join(', ');

        await _repo.addTreatment(
          animalId,
          reportId: widget.report.id,
          treatmentName: treatment,
          dosage: dosageText.isNotEmpty ? dosageText : null,
          startedOn: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          endedOn: _durationController.text.trim().isNotEmpty
              ? DateFormat('yyyy-MM-dd').format(
                  DateTime.now().add(Duration(days: int.tryParse(_durationController.text.trim()) ?? 3)))
              : null,
          notes: _instructionsController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('treat_saved')),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('err_generic')),
          backgroundColor: AppColors.alertCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('treat_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Patient Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.report.animal.speciesCode.toUpperCase()} • ${widget.report.animal.name ?? widget.report.animal.tagNumber ?? 'Animal'}',
                          style: AppTypography.cardTitle,
                        ),
                        if (widget.report.farmer != null)
                          Text(
                            '${AppStrings.t('farmer_label')}: ${widget.report.farmer!.fullName}',
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Mandatory AI Prescribing Disclaimer Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.t('treat_ai_note'),
                      style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Clinical Observations
            Text(AppStrings.t('treat_observations'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _obsController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Observed clinical condition, vital signs, physical exam findings...',
                hintStyle: AppTypography.bodySecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Treatment Recommendation
            Text(AppStrings.t('treat_recommendation'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _treatmentNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'e.g. Antibiotic therapy, Antiseptic dressing, Hydration',
                hintStyle: AppTypography.bodySecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Medication Details (Name & Dosage)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('treat_medication'), style: AppTypography.bodySecondary),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _medicationController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          hintText: 'e.g. Enrofloxacin 10%',
                          hintStyle: AppTypography.bodySecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('treat_dosage'), style: AppTypography.bodySecondary),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _dosageController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          hintText: 'e.g. 15 ml IM OD',
                          hintStyle: AppTypography.bodySecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Duration & Follow-Up Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('treat_duration'), style: AppTypography.bodySecondary),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          hintText: 'e.g. 5',
                          hintStyle: AppTypography.bodySecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('treat_follow_up'), style: AppTypography.bodySecondary),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickFollowUpDate,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _followUpDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_followUpDate!)
                                    : AppStrings.t('pick_date'),
                                style: _followUpDate != null
                                    ? AppTypography.bodyDefault
                                    : AppTypography.bodySecondary,
                              ),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Instructions for Farmer
            Text(AppStrings.t('treat_instructions'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Isolate animal from herd, provide clean water, fly repellent...',
                hintStyle: AppTypography.bodySecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save Record Button
            AppButton(
              label: AppStrings.t('treat_save'),
              icon: Icons.save,
              isLoading: _submitting,
              onPressed: _submit,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
