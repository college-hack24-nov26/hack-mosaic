import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/async_states.dart';
import '../../data/models/vet_models.dart';
import '../../data/reference_data.dart';
import '../../data/vet_repository.dart';
import 'vet_animal_history_screen.dart';
import 'vet_inbox_screen.dart';
import 'vet_report_details_screen.dart';

class VetMapScreen extends StatefulWidget {
  const VetMapScreen({super.key});

  @override
  State<VetMapScreen> createState() => _VetMapScreenState();
}

class _VetMapScreenState extends State<VetMapScreen> {
  final MapController _mapController = MapController();
  final _repo = VetRepository.shared;

  // Default center: Phaltan, Satara
  static const double _defaultLat = 17.9856;
  static const double _defaultLng = 74.4331;

  bool _loading = true;
  String? _error;
  List<CasePoint> _cases = [];
  List<VetReport> _reports = [];
  String _filter = 'all'; // 'all', 'confirmed', 'pending', 'flagged'

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
      final results = await Future.wait([
        _repo.mapCases(),
        _repo.reports(pageSize: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _cases = results[0] as List<CasePoint>;
        _reports = (results[1] as ReportPage).items;
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

  void _showReportPinDetails(VetReport r) {
    final isConfirmed = r.status == 'confirmed';
    final statusColor = AppColors.statusColor(r.status);
    final diseaseName = r.verification?.diseaseCode != null
        ? ReferenceApi.shared.diseaseName(r.verification!.diseaseCode!)
        : (r.screening != null ? ReferenceApi.shared.diseaseName(r.screening!.topLabel) : 'Suspected Case');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConfirmed ? Icons.warning : Icons.assignment_late_outlined,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName,
                          style: AppTypography.screenTitle.copyWith(fontSize: 18),
                        ),
                        Text(
                          '${r.status.toUpperCase()} • ${r.animal.speciesCode.toUpperCase()}${r.animal.name != null ? " (${r.animal.name})" : ""}',
                          style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              if (r.farmer != null) ...[
                Text(
                  '${AppStrings.t('farmer_label')}: ${r.farmer!.fullName}',
                  style: AppTypography.bodyDefault,
                ),
                const SizedBox(height: 4),
              ],
              if (r.location != null)
                Text(
                  '${AppStrings.t('gps_location')}: ${r.location!.lat.toStringAsFixed(4)}, ${r.location!.lng.toStringAsFixed(4)}',
                  style: AppTypography.caption,
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
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
                      icon: const Icon(Icons.history, size: 18),
                      label: Text(AppStrings.t('animal_history')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VetReportDetailsScreen(reportId: r.id),
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.assignment, color: Colors.white, size: 18),
                      label: Text(AppStrings.t('case_details')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCaseDetails(CasePoint p) {
    final matchingReport = _reports.where((r) => r.id == p.reportId).firstOrNull;
    if (matchingReport != null) {
      _showReportPinDetails(matchingReport);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alertCritical.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning, color: AppColors.alertCritical, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ReferenceApi.shared.diseaseName(p.diseaseCode),
                          style: AppTypography.screenTitle.copyWith(fontSize: 18),
                        ),
                        Text(
                          AppStrings.t('vet_stat_confirmed'),
                          style: AppTypography.caption.copyWith(color: AppColors.alertCritical, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              if (p.confirmedAt != null) ...[
                Text(
                  '${AppStrings.t('verify_time')}: ${p.confirmedAt!.day}/${p.confirmedAt!.month}/${p.confirmedAt!.year}',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                '${AppStrings.t('gps_location')}: ${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (p.reportId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VetReportDetailsScreen(reportId: p.reportId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.assignment, color: Colors.white),
                  label: Text(AppStrings.t('case_details')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<VetReport> get _filteredReports {
    final withLoc = _reports.where((r) => r.location != null).toList();
    switch (_filter) {
      case 'confirmed':
        return withLoc.where((r) => r.status == 'confirmed').toList();
      case 'pending':
        return withLoc.where((r) => r.isPending).toList();
      case 'flagged':
        return withLoc.where((r) => r.status == 'flagged').toList();
      default:
        return withLoc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleReports = _filteredReports;
    final reportIds = visibleReports.map((r) => r.id).toSet();
    final extraCases = (_filter == 'all' || _filter == 'confirmed')
        ? _cases.where((c) => !reportIds.contains(c.reportId)).toList()
        : <CasePoint>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('vmap_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'नवीन फील्ड केस / Log Field Case',
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const SkeletonList(count: 3, height: 180)
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : Stack(
                  children: [
                    // Interactive OpenStreetMap
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _cases.isNotEmpty
                            ? LatLng(_cases.first.lat, _cases.first.lng)
                            : const LatLng(_defaultLat, _defaultLng),
                        initialZoom: 12.0,
                        minZoom: 9.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.pashuvani.pashu_wani',
                        ),
                        // Disease Report & Confirmed Case Markers
                        MarkerLayer(
                          markers: [
                            ...visibleReports.map((r) {
                              final isConfirmed = r.status == 'confirmed';
                              final pinColor = AppColors.statusColor(r.status);
                              return Marker(
                                point: LatLng(r.location!.lat, r.location!.lng),
                                width: 48,
                                height: 48,
                                child: GestureDetector(
                                  onTap: () => _showReportPinDetails(r),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: pinColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isConfirmed ? Icons.warning : Icons.pets,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            ...extraCases.map((p) {
                              return Marker(
                                point: LatLng(p.lat, p.lng),
                                width: 48,
                                height: 48,
                                child: GestureDetector(
                                  onTap: () => _showCaseDetails(p),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.alertCritical,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.warning, color: Colors.white, size: 24),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),

                    // Top Filter & Notice Bar
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    AppStrings.t('vmap_note'),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('all', 'सर्व (All: ${_reports.length})', AppColors.primary),
                                const SizedBox(width: 6),
                                _filterChip(
                                  'confirmed',
                                  'पुष्टीकृत (Confirmed)',
                                  AppColors.alertCritical,
                                ),
                                const SizedBox(width: 6),
                                _filterChip(
                                  'pending',
                                  'प्रलंबित (Pending)',
                                  AppColors.cautionAmber,
                                ),
                                const SizedBox(width: 6),
                                _filterChip(
                                  'flagged',
                                  'संशयास्पद (Flagged)',
                                  AppColors.infoBlue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recenter Floating Action Button
                    Positioned(
                      bottom: 24,
                      right: 16,
                      child: FloatingActionButton.small(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _cases.isNotEmpty
                                ? LatLng(_cases.first.lat, _cases.first.lng)
                                : const LatLng(_defaultLat, _defaultLng),
                            13.0,
                          );
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(String key, String label, Color color) {
    final active = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: active ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
