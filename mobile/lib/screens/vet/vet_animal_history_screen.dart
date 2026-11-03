import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/vet_repository.dart';
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
    );
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
              const Icon(Icons.notes, size: 18, color: AppColors.primary),
              if (item.s('recorded_at') != null)
                Text(
                  item.s('recorded_at')!.substring(0, 10),
                  style: AppTypography.caption,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.s('summary') ?? '', style: AppTypography.bodyDefault),
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(RecordItem item) {
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
              Text(item.s('treatment_name') ?? 'Treatment', style: AppTypography.cardTitle),
              if (item.s('started_on') != null)
                Text(item.s('started_on')!, style: AppTypography.caption),
            ],
          ),
          if (item.s('dosage') != null && item.s('dosage')!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${AppStrings.t('treat_dosage')}: ${item.s('dosage')}', style: AppTypography.bodySecondary),
          ],
          if (item.s('notes') != null && item.s('notes')!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.s('notes')!, style: AppTypography.caption),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.s('vaccine_name') ?? 'Vaccine', style: AppTypography.cardTitle),
              if (item.s('administered_on') != null)
                Text(item.s('administered_on')!, style: AppTypography.caption),
            ],
          ),
          if (item.s('batch_number') != null) ...[
            const SizedBox(height: 4),
            Text('Batch: ${item.s('batch_number')}', style: AppTypography.caption),
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
            subtitle: Text(r.s('symptoms') ?? ''),
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
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
    );
  }
}
