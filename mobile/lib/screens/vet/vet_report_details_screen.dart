import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/reference_data.dart';
import '../../data/vet_repository.dart';
import 'vet_animal_history_screen.dart';
import 'vet_verification_screen.dart';
import 'vet_treatment_screen.dart';

class VetReportDetailsScreen extends StatefulWidget {
  const VetReportDetailsScreen({super.key, required this.reportId});
  final String reportId;

  @override
  State<VetReportDetailsScreen> createState() => _VetReportDetailsScreenState();
}

class _VetReportDetailsScreenState extends State<VetReportDetailsScreen> {
  final _repo = VetRepository.shared;
  bool _loading = true;
  bool _claiming = false;
  String? _error;
  VetReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rep = await _repo.report(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = rep;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.t('err_network');
      });
    }
  }

  Future<void> _claimCase() async {
    setState(() => _claiming = true);
    try {
      final updated = await _repo.claim(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _claiming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('case_details')),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _claiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('err_generic')),
          backgroundColor: AppColors.alertCritical,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot launch phone dialer for $clean')),
      );
    }
  }

  Future<void> _openCoordinates(double lat, double lng) async {
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot launch maps for $lat, $lng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(AppStrings.t('case_details'))),
        body: const SkeletonList(count: 5, height: 120),
      );
    }

    if (_error != null || _report == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(AppStrings.t('case_details'))),
        body: ErrorState(message: _error ?? AppStrings.t('err_generic'), onRetry: _load),
      );
    }

    final r = _report!;
    final statusColor = AppColors.statusColor(r.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${AppStrings.t('report_label')} #${r.id.length > 8 ? r.id.substring(0, 8) : r.id}'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'आवाजात ऐका / Speak Case Summary',
            icon: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
            onPressed: () {
              final animalLabel = r.animal.name ?? r.animal.speciesCode;
              final diseaseLabel = r.verification?.diseaseCode != null
                  ? ReferenceApi.shared.diseaseName(r.verification!.diseaseCode!)
                  : (r.screening != null ? ReferenceApi.shared.diseaseName(r.screening!.topLabel) : 'Unknown');
              VoiceService().speakEmergencyMarathi(
                'पशुवैद्यकीय अहवाल. जनावर: $animalLabel. शेतकरी: ${r.farmer?.fullName ?? "अज्ञात"}. स्थिती: ${r.status}. प्राथमिक निरीक्षण: $diseaseLabel. हे प्राथमिक तपासणी निरीक्षण आहे, अंतिम निदान पशुवैद्यकाचे आहे.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Mandatory Regulatory Disclaimer Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t('ai_disclaimer'),
                        style: AppTypography.bodySecondary.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t('ai_not_decider'),
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Status & Header Card
          _buildStatusHeaderCard(r, statusColor),

          const SizedBox(height: AppSpacing.md),

          // 3. Animal Details Card
          _buildAnimalCard(r.animal),

          const SizedBox(height: AppSpacing.md),

          // 4. Farmer Details Card
          if (r.farmer != null) _buildFarmerCard(r.farmer!),

          const SizedBox(height: AppSpacing.md),

          // 5. Location Card
          if (r.location != null) _buildLocationCard(r.location!),

          const SizedBox(height: AppSpacing.md),

          // 6. Symptoms & Clinical Description Card
          _buildSymptomsCard(r),

          const SizedBox(height: AppSpacing.md),

          // 7. Photographs Section
          _buildPhotosCard(r),

          const SizedBox(height: AppSpacing.md),

          // 8. Preliminary AI Screening Observation Card
          if (r.screening != null) _buildAiScreeningCard(r.screening!),

          const SizedBox(height: AppSpacing.md),

          // 9. Current Verification Details (if verified)
          if (r.verification != null) _buildVerificationCard(r.verification!, statusColor),

          const SizedBox(height: 80), // spacing for bottom action bar
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(r),
    );
  }

  Widget _buildStatusHeaderCard(VetReport r, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.t('submitted_label')}: ${r.reportedAt.day}/${r.reportedAt.month}/${r.reportedAt.year} ${r.reportedAt.hour.toString().padLeft(2, '0')}:${r.reportedAt.minute.toString().padLeft(2, '0')}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${r.id}',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              r.status.toUpperCase(),
              style: AppTypography.badge.copyWith(color: statusColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(ReportAnimal animal) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pets, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('animal_section'), style: AppTypography.sectionHeading),
                ],
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VetAnimalHistoryScreen(
                      animalId: animal.id,
                      animalName: animal.name,
                      speciesCode: animal.speciesCode,
                    ),
                  ),
                ),
                icon: const Icon(Icons.history, size: 16),
                label: Text(AppStrings.t('animal_history')),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md),
          _detailRow(AppStrings.t('field_species'), animal.speciesCode.toUpperCase()),
          if (animal.name != null) _detailRow(AppStrings.t('reg_full_name'), animal.name!),
          if (animal.breedCode != null) _detailRow(AppStrings.t('field_breed'), animal.breedCode!),
          if (animal.tagNumber != null) _detailRow(AppStrings.t('field_tag'), animal.tagNumber!),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(ReportFarmer farmer) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppStrings.t('farmer_section'), style: AppTypography.sectionHeading),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farmer.fullName, style: AppTypography.cardTitle),
                  if (farmer.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(farmer.phone!, style: AppTypography.bodySecondary),
                  ],
                ],
              ),
              if (farmer.phone != null)
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(farmer.phone!),
                  icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                  label: Text(AppStrings.t('call_farmer')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: AppTypography.button.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ReportLocation loc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('gps_location'), style: AppTypography.sectionHeading),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _openCoordinates(loc.lat, loc.lng),
                icon: const Icon(Icons.map, size: 16),
                label: Text(AppStrings.t('open_maps')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}'
            '${loc.accuracyM != null ? ' (±${loc.accuracyM!.toStringAsFixed(1)} m)' : ''}',
            style: AppTypography.bodyDefault,
          ),
          if (loc.source == 'village_centroid') ...[
            const SizedBox(height: 2),
            Text(AppStrings.t('gps_village'), style: AppTypography.caption),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomsCard(VetReport r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Icon(Icons.sick_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppStrings.t('symptoms_label'), style: AppTypography.sectionHeading),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (r.symptomCodes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: r.symptomCodes.map((code) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    ReferenceApi.shared.symptomName(code),
                    style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              r.description!,
              style: AppTypography.bodyDefault,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosCard(VetReport r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppStrings.t('photos'), style: AppTypography.sectionHeading),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (r.imagesPending)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cautionAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: AppColors.cautionAmber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppStrings.t('photos_pending'), style: AppTypography.caption),
                  ),
                ],
              ),
            )
          else if (r.images.isEmpty)
            Text(AppStrings.t('no_photos'), style: AppTypography.bodySecondary)
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: r.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final img = r.images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      img.url,
                      width: 220,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 160,
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiScreeningCard(ReportScreening s) {
    final confStr = s.topConfidence != null ? '${(s.topConfidence! * 100).toInt()}%' : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.infoBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('ai_obs'), style: AppTypography.sectionHeading.copyWith(color: AppColors.infoBlue)),
                ],
              ),
              if (s.inconclusive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cautionAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppStrings.t('ai_inconclusive'),
                    style: AppTypography.badge.copyWith(color: AppColors.cautionAmber),
                  ),
                ),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Text(
            ReferenceApi.shared.diseaseName(s.topLabel),
            style: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
          ),
          if (confStr != null) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.t('ai_confidence')}: $confStr',
              style: AppTypography.bodySecondary,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Model: ${s.modelVersion}',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(ReportVerification v, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                v.decision == 'confirmed'
                    ? Icons.verified
                    : v.decision == 'flagged'
                        ? Icons.flag
                        : Icons.cancel,
                color: statusColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(AppStrings.t('current_decision'), style: AppTypography.sectionHeading),
            ],
          ),
          const Divider(height: AppSpacing.md),
          _detailRow(AppStrings.t('verify_decision'), v.decision.toUpperCase()),
          if (v.diseaseCode != null)
            _detailRow(AppStrings.t('verify_disease'), ReferenceApi.shared.diseaseName(v.diseaseCode!)),
          if (v.notes != null) _detailRow(AppStrings.t('notes_confirmed'), v.notes!),
          if (v.visitRequired) _detailRow(AppStrings.t('visit_required'), AppStrings.t('yes')),
          if (v.vetName != null) _detailRow(AppStrings.t('decided_by'), v.vetName!),
          if (v.decidedAt != null)
            _detailRow(
              AppStrings.t('decided_at'),
              '${v.decidedAt!.day}/${v.decidedAt!.month}/${v.decidedAt!.year} ${v.decidedAt!.hour.toString().padLeft(2, '0')}:${v.decidedAt!.minute.toString().padLeft(2, '0')}',
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyDefault)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(VetReport r) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (r.status == 'submitted') ...[
              Expanded(
                child: AppButton(
                  label: AppStrings.t('claim_case'),
                  icon: Icons.assignment_ind,
                  isLoading: _claiming,
                  isSecondary: true,
                  onPressed: _claimCase,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (r.status == 'under_review') ...[
              Expanded(
                child: AppButton(
                  label: AppStrings.t('animal_history'),
                  icon: Icons.history,
                  isSecondary: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VetAnimalHistoryScreen(
                          animalId: r.animal.id,
                          animalName: r.animal.name,
                          speciesCode: r.animal.speciesCode,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (r.isPending) ...[
              Expanded(
                child: AppButton(
                  label: AppStrings.t('verify_case'),
                  icon: Icons.rate_review,
                  onPressed: () async {
                    final res = await Navigator.of(context).push<VetReport>(
                      MaterialPageRoute(
                        builder: (_) => VetVerificationScreen(report: r),
                      ),
                    );
                    if (res != null && mounted) {
                      setState(() => _report = res);
                    }
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: AppButton(
                  label: 'निर्णय बदला / Update',
                  icon: Icons.edit_note,
                  isSecondary: true,
                  onPressed: () async {
                    final res = await Navigator.of(context).push<VetReport>(
                      MaterialPageRoute(
                        builder: (_) => VetVerificationScreen(report: r),
                      ),
                    );
                    if (res != null && mounted) {
                      setState(() => _report = res);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: AppStrings.t('document_treatment'),
                  icon: Icons.medication_liquid,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VetTreatmentScreen(report: r),
                      ),
                    );
                    _load();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
