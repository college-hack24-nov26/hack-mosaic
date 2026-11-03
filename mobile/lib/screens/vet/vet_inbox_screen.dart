import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/reference_data.dart';
import '../../data/vet_repository.dart';
import 'vet_report_details_screen.dart';

class VetInboxScreen extends StatefulWidget {
  const VetInboxScreen({super.key});

  @override
  State<VetInboxScreen> createState() => _VetInboxScreenState();
}

class _VetInboxScreenState extends State<VetInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _repo = VetRepository.shared;

  bool _loading = true;
  String? _error;
  List<VetReport> _allReports = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.reports(pageSize: 100);
      if (!mounted) return;
      setState(() {
        _allReports = res.items;
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

  List<VetReport> _filterByTab(int tabIndex) {
    List<VetReport> list;
    switch (tabIndex) {
      case 0: // Pending (submitted + under_review)
        list = _allReports.where((r) => r.isPending).toList()
          ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt)); // oldest first
        break;
      case 1: // Confirmed
        list = _allReports.where((r) => r.status == 'confirmed').toList();
        break;
      case 2: // Rejected
        list = _allReports.where((r) => r.status == 'rejected').toList();
        break;
      case 3: // Flagged
        list = _allReports.where((r) => r.status == 'flagged').toList();
        break;
      default:
        list = _allReports;
    }

    if (_searchQuery.isEmpty) return list;

    return list.where((r) {
      final matchId = r.id.toLowerCase().contains(_searchQuery);
      final matchAnimal = (r.animal.name?.toLowerCase().contains(_searchQuery) ?? false) ||
          r.animal.speciesCode.toLowerCase().contains(_searchQuery) ||
          (r.animal.tagNumber?.toLowerCase().contains(_searchQuery) ?? false);
      final matchFarmer = (r.farmer?.fullName.toLowerCase().contains(_searchQuery) ?? false);
      final matchSymptoms = r.symptomCodes.any((s) => s.toLowerCase().contains(_searchQuery));
      return matchId || matchAnimal || matchFarmer || matchSymptoms;
    }).toList();
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return AppStrings.t('ago_min').replaceAll('{n}', '${diff.inMinutes.clamp(1, 60)}');
    }
    if (diff.inHours < 24) {
      return AppStrings.t('ago_hour').replaceAll('{n}', '${diff.inHours}');
    }
    return AppStrings.t('ago_day').replaceAll('{n}', '${diff.inDays}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('inbox_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.badge.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: AppStrings.t('inbox_pending')),
            Tab(text: AppStrings.t('inbox_confirmed')),
            Tab(text: AppStrings.t('inbox_rejected')),
            Tab(text: AppStrings.t('inbox_flagged')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.t('inbox_search'),
                hintStyle: AppTypography.bodySecondary,
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(0),
                _buildList(1),
                _buildList(2),
                _buildList(3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(int tabIndex) {
    if (_loading) return const SkeletonList(count: 4, height: 130);
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    final items = _filterByTab(tabIndex);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            EmptyState(message: AppStrings.t('inbox_empty')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(VetReport report) {
    final statusColor = AppColors.statusColor(report.status);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VetReportDetailsScreen(reportId: report.id),
            ),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: ID, Status, Ago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.t('report_label')} #${report.id.length > 8 ? report.id.substring(0, 8) : report.id}',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: AppTypography.badge.copyWith(color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatAgo(report.reportedAt), style: AppTypography.caption),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Animal info row
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: Icon(Icons.pets, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.animal.speciesCode.toUpperCase()}${report.animal.name != null ? ' • ${report.animal.name}' : ''}',
                          style: AppTypography.cardTitle,
                        ),
                        if (report.animal.tagNumber != null)
                          Text(
                            'Tag: ${report.animal.tagNumber}',
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),
                  if (report.images.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${report.images.length}', style: AppTypography.caption),
                      ],
                    ),
                ],
              ),

              if (report.farmer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${AppStrings.t('farmer_label')}: ${report.farmer!.fullName}',
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                ),
              ],

              // Symptoms tags
              if (report.symptomCodes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: report.symptomCodes.take(3).map((code) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ReferenceApi.shared.symptomName(code),
                        style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Preliminary AI observation card (with disclaimer)
              if (report.screening != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, size: 16, color: AppColors.infoBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${AppStrings.t('ai_obs')}: ${AppStrings.formatDisease(report.screening!.topLabel)}'
                              '${report.screening!.topConfidence != null ? ' (${(report.screening!.topConfidence! * 100).toInt()}%)' : ''}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.infoBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (report.screening!.inconclusive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cautionAmber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppStrings.t('ai_inconclusive'),
                                style: AppTypography.badge.copyWith(color: AppColors.cautionAmber),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.t('ai_disclaimer'),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Verified decision if confirmed/rejected/flagged
              if (report.verification != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      report.verification!.decision == 'confirmed'
                          ? Icons.verified
                          : report.verification!.decision == 'flagged'
                              ? Icons.flag
                              : Icons.cancel,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppStrings.t('decided_by')}: ${report.verification!.vetName ?? 'Vet'}'
                        '${report.verification!.diseaseCode != null ? ' • ${ReferenceApi.shared.diseaseName(report.verification!.diseaseCode!)}' : ''}',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
