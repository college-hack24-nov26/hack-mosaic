import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/disease_report_model.dart';
import 'report_details_screen.dart';

class ReportsHistoryScreen extends StatefulWidget {
  const ReportsHistoryScreen({super.key});

  @override
  State<ReportsHistoryScreen> createState() => _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState extends State<ReportsHistoryScreen> {
  final OfflineStore _store = OfflineStore();
  String _selectedFilter = 'all'; // 'all', 'pending', 'confirmed'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final allReports = _store.reports;
        final filteredReports = allReports.where((r) {
          if (_selectedFilter == 'pending') {
            return r.status == 'submitted' || r.status == 'under_review';
          }
          if (_selectedFilter == 'confirmed') {
            return r.status == 'confirmed';
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('तपासणी अहवाल / Case History'),
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'सर्व / All (${allReports.length})'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('pending', 'प्रलंबित / Pending'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('confirmed', 'पुष्टी झालेले / Confirmed'),
                  ],
                ),
              ),

              // Reports List
              Expanded(
                child: filteredReports.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _buildReportCard(report);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.surfaceContainerHigh,
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      backgroundColor: AppColors.surface,
    );
  }

  Widget _buildReportCard(DiseaseReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailsScreen(report: report),
            ),
          );
        },
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.animalName ?? 'जनावर / Animal',
                    style: AppTypography.cardTitle.copyWith(fontSize: 16),
                  ),
                ),
                StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.description ?? 'No notes provided',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySecondary.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'दिनांक: ${report.reportedAt.toIso8601String().substring(0, 10)}',
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                if (!report.isSynced)
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 12, color: AppColors.cautionAmber),
                      const SizedBox(width: 4),
                      Text(
                        'Pending Sync',
                        style: AppTypography.badge.copyWith(color: AppColors.cautionAmber, fontSize: 10),
                      ),
                    ],
                  )
                else
                  Text(
                    'तपशील पहा >',
                    style: AppTypography.badge.copyWith(color: AppColors.primary, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'कोणतेही अहवाल आढळले नाहीत.\nNo disease reports match this filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}
