import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/vet_repository.dart';
import 'vet_report_details_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key, this.onNavigateToInbox, this.onNavigateToMap});

  final VoidCallback? onNavigateToInbox;
  final VoidCallback? onNavigateToMap;

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  final _repo = VetRepository.shared;
  bool _loading = true;
  String? _error;
  SummaryTotals _totals = const SummaryTotals();
  List<VetReport> _pending = [];
  List<VetReport> _recent = [];

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
      final summaryFuture = _repo.summary();
      final pendingFuture = _repo.pendingReports(pageSize: 5);
      final recentFuture = _repo.reports(pageSize: 5);

      final results = await Future.wait([summaryFuture, pendingFuture, recentFuture]);
      if (!mounted) return;

      setState(() {
        _totals = results[0] as SummaryTotals;
        _pending = (results[1] as ReportPage).items;
        _recent = (results[2] as ReportPage).items;
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
    final session = SessionManager.instance;
    final vet = session.me?.vet;
    final vetName = session.me?.fullName ?? 'Veterinarian';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('vet_nav_dashboard')),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: AppStrings.t('try_again'),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const SkeletonList(count: 4, height: 120)
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    children: [
                      // 1. Vet Profile Header Card
                      _buildProfileCard(vetName, vet),

                      const SizedBox(height: AppSpacing.lg),

                      // 2. Metrics Statistics Grid
                      _buildMetricsSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // 3. Waiting Longest (Priority Queue)
                      _buildWaitingLongestSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // 4. Recent Reports
                      _buildRecentReportsSection(),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
      ),
    );
  }

  Widget _buildProfileCard(String name, dynamic vet) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(Icons.medical_services, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('vet_welcome'),
                      style: AppTypography.caption.copyWith(color: Colors.white70),
                    ),
                    Text(
                      name.startsWith('Dr.') ? name : 'Dr. $name',
                      style: AppTypography.screenTitle.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white70),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.t('vet_verified'),
                      style: AppTypography.badge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (vet?.districtName != null || vet?.districtId != null)
                _infoChip(Icons.location_on, '${AppStrings.t('vet_district')}: ${vet?.districtName ?? vet?.districtId}'),
              if (vet?.talukaName != null || vet?.talukaId != null)
                _infoChip(Icons.domain, vet?.talukaName ?? vet?.talukaId),
              if (vet?.clinicName != null && (vet?.clinicName as String).isNotEmpty)
                _infoChip(Icons.local_hospital, vet!.clinicName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.t('vet_stat_total'), style: AppTypography.sectionHeading),
            Text(
              '${_totals.reports}',
              style: AppTypography.sectionHeading.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppStrings.t('vet_dash_note'), style: AppTypography.caption),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: AppStrings.t('vet_stat_pending'),
                count: _totals.pending,
                color: AppColors.cautionAmber,
                icon: Icons.hourglass_top,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _statCard(
                label: AppStrings.t('vet_stat_confirmed'),
                count: _totals.confirmed,
                color: AppColors.alertCritical,
                icon: Icons.check_circle_outline,
                onTap: widget.onNavigateToInbox,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: AppStrings.t('vet_stat_flagged'),
                count: _totals.flagged,
                color: AppColors.cautionAmber,
                icon: Icons.flag_outlined,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _statCard(
                label: AppStrings.t('vet_stat_rejected'),
                count: _totals.rejected,
                color: AppColors.textMuted,
                icon: Icons.cancel_outlined,
                onTap: widget.onNavigateToInbox,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: AppTypography.sectionHeading.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingLongestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.t('vet_waiting_longest'), style: AppTypography.sectionHeading),
            if (_pending.isNotEmpty && widget.onNavigateToInbox != null)
              TextButton(
                onPressed: widget.onNavigateToInbox,
                child: Text(AppStrings.t('vet_view_all')),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_pending.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(AppStrings.t('vet_nothing_pending'), style: AppTypography.bodySecondary),
                ),
              ],
            ),
          )
        else
          ..._pending.map((report) => _buildReportItem(report, isPriority: true)),
      ],
    );
  }

  Widget _buildRecentReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.t('vet_recent'), style: AppTypography.sectionHeading),
            if (widget.onNavigateToInbox != null)
              TextButton(
                onPressed: widget.onNavigateToInbox,
                child: Text(AppStrings.t('vet_view_all')),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_recent.isEmpty)
          EmptyState(message: AppStrings.t('inbox_empty'))
        else
          ..._recent.map((report) => _buildReportItem(report)),
      ],
    );
  }

  Widget _buildReportItem(VetReport report, {bool isPriority = false}) {
    final statusColor = AppColors.statusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isPriority ? AppColors.cautionAmber.withValues(alpha: 0.4) : AppColors.border,
          width: isPriority ? 1.5 : 1.0,
        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      Text(
                        _formatAgo(report.reportedAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.pets, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${report.animal.speciesCode.toUpperCase()} • ${report.animal.name ?? report.animal.tagNumber ?? 'Unknown'}',
                    style: AppTypography.cardTitle,
                  ),
                ],
              ),
              if (report.farmer != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      report.farmer!.fullName,
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                ),
              ],
              if (report.screening != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, size: 14, color: AppColors.infoBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${AppStrings.t('ai_obs')}: ${AppStrings.formatDisease(report.screening!.topLabel)}'
                          '${report.screening!.topConfidence != null ? ' (${(report.screening!.topConfidence! * 100).toInt()}%)' : ''}',
                          style: AppTypography.caption.copyWith(color: AppColors.infoBlue, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
