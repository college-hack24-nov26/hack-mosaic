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
      final list = await _repo.mapCases();
      if (!mounted) return;
      setState(() {
        _cases = list;
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

  void _showCaseDetails(CasePoint p) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('vmap_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
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
                        // Confirmed Disease Case Markers
                        MarkerLayer(
                          markers: _cases.map((p) {
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
                          }).toList(),
                        ),
                      ],
                    ),

                    // Top Information Notice
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Container(
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
}
