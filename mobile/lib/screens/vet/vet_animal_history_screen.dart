import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/vet_repository.dart';
import 'vet_inbox_screen.dart';
import 'vet_report_details_screen.dart';

/// Full animal health history screen (`GET /animals/{id}/record`).
class VetAnimalHistoryScreen extends StatefulWidget {
  const VetAnimalHistoryScreen({
    super.key,
    required this.animalId,
    this.animalName,
    this.speciesCode,
  });

  final String animalId;
  final String? animalName;
  final String? speciesCode;

  @override
  State<VetAnimalHistoryScreen> createState() => _VetAnimalHistoryScreenState();
}

class _VetAnimalHistoryScreenState extends State<VetAnimalHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = VetRepository.shared;

  bool _loading = true;
  String? _error;
  AnimalRecord? _record;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rec = await _repo.animalRecord(widget.animalId);
      if (!mounted) return;
      setState(() {
        _record = rec;
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

  @override
  Widget build(BuildContext context) {
    final title = widget.animalName ?? widget.speciesCode?.toUpperCase() ?? AppStrings.t('animal_history');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: AppTypography.badge.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: AppStrings.t('health_records')),
            Tab(text: AppStrings.t('treatments')),
            Tab(text: AppStrings.t('vaccinations')),
            Tab(text: AppStrings.t('prev_reports')),
          ],
        ),
      ),
      body: _loading
          ? const SkeletonList(count: 4, height: 120)
          : _error != null || _record == null
              ? ErrorState(message: _error ?? AppStrings.t('err_generic'), onRetry: _load)
              : Column(
                  children: [
                    // Animal Registration Overview Card
                    _buildOverviewCard(_record!.animal),

                    // TabBarView Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_record!.healthRecords, _buildObservationItem, AppStrings.t('health_records')),
                          _buildList(_record!.treatments, _buildTreatmentItem, AppStrings.t('treatments')),
                          _buildList(_record!.vaccinations, _buildVaccinationItem, AppStrings.t('vaccinations')),
                          _buildReportsList(_record!.recentReports),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || _record == null ? null : _buildBottomRecordActions(),
    );
  }

  Widget _buildBottomRecordActions() {
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddNoteAndTreatmentModal,
                icon: const Icon(Icons.medication_liquid, size: 18, color: AppColors.primary),
                label: const Text(
                  'नोंद / उपचार (Add Note)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddVaccinationModal,
                icon: const Icon(Icons.vaccines, size: 18, color: Colors.white),
                label: const Text(
                  'लसीकरण (Vaccinate)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddNoteAndTreatmentModal() async {
    final summaryCtrl = TextEditingController(
      text: 'Clinical examination completed. Vitals recorded; animal under isolation protocol.',
    );
    final treatmentCtrl = TextEditingController(text: 'Meloxicam + Oxytetracycline LA');
    final dosageCtrl = TextEditingController(text: '10 ml IM × 3 days');
    bool includeTreatment = true;
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📝 क्लिनिकल नोंद आणि उपचार (Clinical Note & Treatment)', style: AppTypography.sectionHeading),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: summaryCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'क्लिनिकल निरीक्षण (Clinical Observation)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: includeTreatment,
                      title: const Text('औषधोपचार जोडा (Also log prescribed treatment)'),
                      onChanged: (v) => setModalState(() => includeTreatment = v ?? false),
                    ),
                    if (includeTreatment) ...[
                      TextField(
                        controller: treatmentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'औषध / उपचार नाव (Treatment / Medicine)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: dosageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'मात्रा आणि कालावधी (Dosage & Duration)',
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                setModalState(() => saving = true);
                                final summaryText = summaryCtrl.text.trim().isEmpty
                                    ? 'Clinical observation logged by Veterinarian.'
                                    : summaryCtrl.text.trim();
                                await _repo.addHealthRecord(
                                  widget.animalId,
                                  summary: summaryText,
                                  data: const {'source': 'vet_portal'},
                                );
                                if (includeTreatment && treatmentCtrl.text.trim().isNotEmpty) {
                                  final recentRepId = _record?.recentReports.firstOrNull?.s('id') ?? 'rep-sat-2026-001';
                                  await _repo.addTreatment(
                                    widget.animalId,
                                    reportId: recentRepId,
                                    treatmentName: treatmentCtrl.text.trim(),
                                    dosage: dosageCtrl.text.trim(),
                                    startedOn: DateTime.now().toIso8601String().substring(0, 10),
                                    notes: summaryText,
                                  );
                                }
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          saving ? 'जतन करत आहे...' : 'नोंद जतन करा (Save to Animal Record)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _load();
      _tabController.animateTo(includeTreatment ? 1 : 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical note & treatment saved to animal health passport.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _showAddVaccinationModal() async {
    String selectedVaccine = 'Goat Pox Vaccine (LSD Prophylaxis)';
    final batchCtrl = TextEditingController(text: 'GPV-2026-SATARA-09');
    bool saving = false;

    const vaccines = [
      'Goat Pox Vaccine (LSD Prophylaxis)',
      'FMD Trivalent Vaccine (लाळ खुरकत लस)',
      'HS + BQ Combined Vaccine (घटसर्प-फऱ्या)',
      'Brucella S19 Vaccine',
      'PPR Vaccine (शेळी-मेंढी देवी)',
    ];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💉 लसीकरण नोंदवा (Record Vaccination)', style: AppTypography.sectionHeading),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVaccine,
                    decoration: const InputDecoration(
                      labelText: 'लसीचे नाव (Vaccine Name)',
                      isDense: true,
                    ),
                    items: vaccines.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedVaccine = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: batchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'बॅच क्रमांक (Batch Number)',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              final today = DateTime.now();
                              final nextDue = today.add(const Duration(days: 180));
                              await _repo.addVaccination(
                                widget.animalId,
                                vaccineName: selectedVaccine,
                                batchNumber: batchCtrl.text.trim(),
                                administeredOn: today.toIso8601String().substring(0, 10),
                                nextDueOn: nextDue.toIso8601String().substring(0, 10),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            },
                      icon: const Icon(Icons.vaccines, color: Colors.white),
                      label: Text(
                        saving ? 'जतन करत आहे...' : 'लसीकरण जतन करा (Save Vaccination)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _load();
      _tabController.animateTo(2);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccination recorded in Animal Health Passport.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Widget _buildOverviewCard(ReportAnimalFull animal) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
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
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(Icons.pets, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${animal.speciesCode.toUpperCase()}${animal.name != null ? ' • ${animal.name}' : ''}',
                      style: AppTypography.cardTitle,
                    ),
                    if (animal.tagNumber != null)
                      Text('Tag: ${animal.tagNumber}', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            children: [
              if (animal.breedCode != null)
                Expanded(child: _chip('${AppStrings.t('field_breed')}: ${animal.breedCode}')),
              if (animal.sex != null)
                Expanded(child: _chip('${AppStrings.t('field_sex')}: ${animal.sex}')),
            ],
          ),
          if (animal.markings != null && animal.markings!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.t('field_markings')}: ${animal.markings}',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.primaryDark)),
    );
  }

  Widget _buildList(List<RecordItem> items, Widget Function(RecordItem) builder, String label) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(message: '$label: ${AppStrings.t('none_recorded')}'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => builder(items[i]),
    );
  }

  Widget _buildObservationItem(RecordItem item) {
    final recType = (item.s('record_type') ?? 'observation').toUpperCase();
    final tempC = item.s('temperature_c');
    final weightKg = item.s('weight_kg');
    final vetName = item.s('recorded_by_name');
    final isIllness = recType == 'ILLNESS';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isIllness ? AppColors.alertCritical.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isIllness
                      ? AppColors.alertCritical.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIllness ? Icons.monitor_heart : Icons.fact_check_outlined,
                      size: 13,
                      color: isIllness ? AppColors.alertCritical : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recType,
                      style: AppTypography.badge.copyWith(
                        fontSize: 10,
                        color: isIllness ? AppColors.alertCritical : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (item.s('recorded_at') != null && item.s('recorded_at')!.length >= 10)
                Text(
                  item.s('recorded_at')!.substring(0, 10),
                  style: AppTypography.caption,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.s('summary') ?? '', style: AppTypography.bodyDefault),
          if ((tempC != null && tempC.isNotEmpty) || (weightKg != null && weightKg.isNotEmpty) || (vetName != null && vetName.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (tempC != null && tempC.isNotEmpty)
                  _chip('🌡️ $tempC °C'),
                if (weightKg != null && weightKg.isNotEmpty)
                  _chip('⚖️ $weightKg kg'),
                if (vetName != null && vetName.isNotEmpty)
                  _chip('👨‍⚕️ $vetName'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(RecordItem item) {
    final vetName = item.s('prescribed_by_name');
    final notes = item.s('notes') ?? item.s('instructions');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medication_liquid, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.s('treatment_name') ?? item.s('medication_name') ?? 'Treatment',
                  style: AppTypography.cardTitle,
                ),
              ),
              if (item.s('started_on') != null)
                Text(item.s('started_on')!, style: AppTypography.caption),
            ],
          ),
          if (item.s('dosage') != null && item.s('dosage')!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${AppStrings.t('treat_dosage')}: ${item.s('dosage')}', style: AppTypography.bodySecondary),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notes, style: AppTypography.caption),
          ],
          if (vetName != null && vetName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _chip('👨‍⚕️ $vetName'),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccinationItem(RecordItem item) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.vaccines, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(item.s('vaccine_name') ?? 'Vaccine', style: AppTypography.cardTitle),
              ),
              if (item.s('administered_on') != null)
                Text(item.s('administered_on')!, style: AppTypography.caption),
            ],
          ),
          if (item.s('batch_number') != null) ...[
            const SizedBox(height: 4),
            Text('Batch: ${item.s('batch_number')}', style: AppTypography.caption),
          ],
          if (item.s('notes') != null && item.s('notes')!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.s('notes')!, style: AppTypography.caption),
          ],
          if (item.s('next_due_on') != null) ...[
            const SizedBox(height: 4),
            Text('${AppStrings.t('next_due')}: ${item.s('next_due_on')}',
                style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsList(List<RecordItem> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(message: AppStrings.t('inbox_empty')),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = reports[i];
        final repId = r.s('id') ?? '';
        final status = r.s('status') ?? 'submitted';
        final statusColor = AppColors.statusColor(status);
        final sub = r.s('description') ?? r.s('symptoms') ?? r.s('confirmed_disease_code') ?? '';

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            onTap: repId.isNotEmpty
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => VetReportDetailsScreen(reportId: repId)),
                    )
                : null,
            title: Text('${AppStrings.t('report_label')} #${repId.length > 8 ? repId.substring(0, 8) : repId}'),
            subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status.toUpperCase(), style: AppTypography.badge.copyWith(color: statusColor)),
            ),
          ),
        );
      },
    );
  }
}

/// Animal records lookup and search screen for Veterinarians (Tab 4 in VetShell).
class VetAnimalRecordsSearchScreen extends StatefulWidget {
  const VetAnimalRecordsSearchScreen({super.key});

  @override
  State<VetAnimalRecordsSearchScreen> createState() => _VetAnimalRecordsSearchScreenState();
}

class _VetAnimalRecordsSearchScreenState extends State<VetAnimalRecordsSearchScreen> {
  final _searchController = TextEditingController();
  final _repo = VetRepository.shared;

  bool _loading = true;
  String? _error;
  List<VetReport> _reports = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.reports(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _reports = res.items;
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

  @override
  Widget build(BuildContext context) {
    // Collect distinct animals from reports
    final animalsMap = <String, VetReport>{};
    for (final r in _reports) {
      animalsMap.putIfAbsent(r.animal.id, () => r);
    }
    final animals = animalsMap.values.where((r) {
      if (_query.isEmpty) return true;
      final matchName = r.animal.name?.toLowerCase().contains(_query) ?? false;
      final matchSpecies = r.animal.speciesCode.toLowerCase().contains(_query);
      final matchTag = r.animal.tagNumber?.toLowerCase().contains(_query) ?? false;
      final matchFarmer = r.farmer?.fullName.toLowerCase().contains(_query) ?? false;
      return matchName || matchSpecies || matchTag || matchFarmer;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('animals_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.t('animals_search'),
                hintStyle: AppTypography.bodySecondary,
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const SkeletonList(count: 4, height: 100)
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : animals.isEmpty
                        ? EmptyState(message: AppStrings.t('animals_hint'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: animals.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final rep = animals[i];
                              final a = rep.animal;
                              return Card(
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                    child: Icon(Icons.pets, color: AppColors.primary),
                                  ),
                                  title: Text(
                                    '${a.speciesCode.toUpperCase()}${a.name != null ? ' • ${a.name}' : ''}',
                                    style: AppTypography.cardTitle,
                                  ),
                                  subtitle: Text(
                                    'Tag: ${a.tagNumber ?? 'None'}${rep.farmer != null ? ' • ${rep.farmer!.fullName}' : ''}',
                                    style: AppTypography.caption,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'केस अहवाल / Case Report',
                                        icon: const Icon(Icons.assignment_outlined, color: AppColors.infoBlue, size: 20),
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => VetReportDetailsScreen(reportId: rep.id),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                    ],
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VetAnimalHistoryScreen(
                                        animalId: a.id,
                                        animalName: a.name,
                                        speciesCode: a.speciesCode,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('नवीन फील्ड केस / Field Case', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final nav = Navigator.of(context);
          final created = await showVetFieldCaseModal(context);
          if (created != null && mounted) {
            await _load();
            if (!mounted) return;
            await nav.push(
              MaterialPageRoute(
                builder: (_) => VetReportDetailsScreen(reportId: created.id),
              ),
            );
            _load();
          }
        },
      ),
    );
  }
}
