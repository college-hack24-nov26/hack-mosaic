import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/vet_models.dart';
import '../../data/reference_data.dart';
import '../../data/vet_repository.dart';

class VetVerificationScreen extends StatefulWidget {
  const VetVerificationScreen({super.key, required this.report});
  final VetReport report;

  @override
  State<VetVerificationScreen> createState() => _VetVerificationScreenState();
}

class _VetVerificationScreenState extends State<VetVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _repo = VetRepository.shared;

  String _decision = 'confirmed'; // confirmed | rejected | flagged
  String? _selectedDiseaseCode;
  bool _visitRequired = false;
  bool _submitting = false;

  List<RefItem> _diseases = [];
  bool _loadingDiseases = true;

  @override
  void initState() {
    super.initState();
    _loadDiseases();
    // Pre-populate if AI top label is a known disease
    if (widget.report.screening != null) {
      _selectedDiseaseCode = widget.report.screening!.topLabel;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDiseases() async {
    try {
      final list = await ReferenceApi.shared.diseases();
      if (!mounted) return;
      setState(() {
        _diseases = list;
        _loadingDiseases = false;
        if (_selectedDiseaseCode != null && !list.any((d) => d.key == _selectedDiseaseCode)) {
          _selectedDiseaseCode = list.isNotEmpty ? list.first.key : null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDiseases = false);
    }
  }

  String get _notesLabel {
    switch (_decision) {
      case 'confirmed':
        return AppStrings.t('notes_confirmed');
      case 'rejected':
        return AppStrings.t('notes_rejected');
      case 'flagged':
        return AppStrings.t('notes_flagged');
      default:
        return AppStrings.t('notes_confirmed');
    }
  }

  Future<void> _onConfirmSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_decision == 'confirmed' && _selectedDiseaseCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('verify_disease_required')),
          backgroundColor: AppColors.alertCritical,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('confirm_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('confirm_body').replaceAll('{s}', _decision.toUpperCase())),
            if (_decision == 'confirmed') ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.t('confirm_confirmed_note'),
                style: AppTypography.caption.copyWith(color: AppColors.alertCritical, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('close')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(AppStrings.t('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final updated = await _repo.verify(
        widget.report.id,
        decision: _decision,
        diseaseCode: _decision == 'confirmed' ? _selectedDiseaseCode : null,
        notes: _notesController.text.trim(),
        visitRequired: _visitRequired,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('verify_success')),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(updated);
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
        title: Text(AppStrings.t('verify_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Case Overview Pill
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
                          '${widget.report.animal.speciesCode.toUpperCase()} • ${widget.report.animal.name ?? widget.report.animal.tagNumber ?? 'Unknown'}',
                          style: AppTypography.cardTitle,
                        ),
                        if (widget.report.farmer != null)
                          Text(
                            'Farmer: ${widget.report.farmer!.fullName}',
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Decision Selector (Confirmed / Rejected / Flagged)
            Text(AppStrings.t('verify_decision'), style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildDecisionButton(
                  title: AppStrings.t('dec_confirmed'),
                  code: 'confirmed',
                  color: AppColors.alertCritical,
                  icon: Icons.check_circle,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildDecisionButton(
                  title: AppStrings.t('dec_flagged'),
                  code: 'flagged',
                  color: AppColors.cautionAmber,
                  icon: Icons.flag,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildDecisionButton(
                  title: AppStrings.t('dec_rejected'),
                  code: 'rejected',
                  color: AppColors.textMuted,
                  icon: Icons.cancel,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // If Confirmed: Disease Selection Dropdown
            if (_decision == 'confirmed') ...[
              Text(AppStrings.t('verify_disease'), style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingDiseases)
                const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedDiseaseCode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: _diseases.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.key,
                      child: Row(
                        children: [
                          Expanded(child: Text(d.name, style: AppTypography.bodyDefault)),
                          if (d.isSurveillance)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.alertCritical.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Surveillance',
                                style: AppTypography.badge.copyWith(color: AppColors.alertCritical, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDiseaseCode = val),
                  validator: (v) => v == null ? AppStrings.t('verify_disease_required') : null,
                ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Clinical Notes TextField (Required)
            Text(_notesLabel, style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: _decision == 'confirmed'
                    ? 'Enter clinical findings, lesions, physical observations...'
                    : _decision == 'rejected'
                        ? 'State reason why this case is rejected...'
                        : 'Explain why laboratory samples or further inspection is required...',
                hintStyle: AppTypography.bodySecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppStrings.t('notes_required');
                }
                if (v.trim().length > 2000) {
                  return AppStrings.t('notes_max');
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Farm Visit Required Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                title: Text(AppStrings.t('visit_required'), style: AppTypography.bodyDefault),
                value: _visitRequired,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _visitRequired = v),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Regulatory notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                AppStrings.t('ai_not_decider'),
                style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            AppButton(
              label: AppStrings.t('submit_decision'),
              icon: Icons.check,
              isLoading: _submitting,
              onPressed: _onConfirmSubmit,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButton({
    required String title,
    required String code,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _decision == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _decision = code),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 22),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
