import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/location_service.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/veterinarian_model.dart';
import '../../data/models/outbreak_zone_model.dart';
import '../reports/create_report_screen.dart';
import '../reports/reports_history_screen.dart';
import 'vet_consultation_screen.dart';

class NearbyScreen extends StatefulWidget {
  final int initialTabIndex;
  final double? targetLat;
  final double? targetLng;

  const NearbyScreen({
    super.key,
    this.initialTabIndex = 0,
    this.targetLat,
    this.targetLng,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  final OfflineStore _store = OfflineStore();

  double _currentLat = LocationService.defaultLat;
  double _currentLng = LocationService.defaultLng;
  bool _isLoadingLocation = false;
  bool _isGpsActive = false;

  // Search & Filter state for Vets Tab
  String _vetSearchQuery = '';
  String _vetFilter = 'all'; // 'all', 'within_5km', 'polyclinic'

  // Map Layer Filter state
  String _mapLayerFilter = 'all'; // 'all', 'vets', 'outbreaks'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _refreshLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLoadingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _isGpsActive = true;
      } else {
        // Fallback to farmer's registered location
        _currentLat = _store.currentUser?.latitude ?? LocationService.defaultLat;
        _currentLng = _store.currentUser?.longitude ?? LocationService.defaultLng;
        _isGpsActive = false;
      }
    });

    if (widget.targetLat != null && widget.targetLng != null) {
      _mapController.move(LatLng(widget.targetLat!, widget.targetLng!), 14.5);
    }
  }

  Future<void> _callVeterinarian(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Unable to place call to $phone');
      }
    } catch (_) {
      _showSnackBar('Error launching phone app');
    }
  }

  Future<void> _openDirections(double lat, double lng, String label) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: switch to Map Tab inside app and center on coordinate
        _tabController.animateTo(1);
        _mapController.move(LatLng(lat, lng), 15.0);
      }
    } catch (_) {
      _tabController.animateTo(1);
      _mapController.move(LatLng(lat, lng), 15.0);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final nearbyVets = _store.getNearbyVeterinarians(_currentLat, _currentLng);
        final filteredVets = nearbyVets.where((vet) {
          final matchesQuery = vet.name.toLowerCase().contains(_vetSearchQuery.toLowerCase()) ||
              vet.clinicName.toLowerCase().contains(_vetSearchQuery.toLowerCase()) ||
              vet.address.toLowerCase().contains(_vetSearchQuery.toLowerCase());

          if (!matchesQuery) return false;

          if (_vetFilter == 'within_5km') {
            return (vet.distanceKm ?? 0) <= 5.0;
          } else if (_vetFilter == 'polyclinic') {
            return vet.clinicName.toLowerCase().contains('polyclinic') ||
                vet.clinicName.toLowerCase().contains('hospital');
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppStrings.t('nearby_title')),
            actions: [
              IconButton(
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Icon(
                        _isGpsActive ? Icons.my_location : Icons.location_searching,
                        color: _isGpsActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                tooltip: AppStrings.t('center_my_location'),
                onPressed: _refreshLocation,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(102),
              child: Column(
                children: [
                  // Location Status Sub-bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                    color: AppColors.surfaceContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: _isGpsActive ? AppColors.primary : AppColors.cautionAmber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.t('location_phaltan_satara')} (${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E)',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_isGpsActive ? AppColors.successGreen : AppColors.cautionAmber).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isGpsActive ? 'GPS Live' : 'District Center',
                            style: AppTypography.badge.copyWith(
                              fontSize: 9,
                              color: _isGpsActive ? AppColors.successGreen : AppColors.cautionAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Segmented Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.medical_services_outlined, size: 20),
                        text: AppStrings.t('tab_nearby_vets'),
                      ),
                      Tab(
                        icon: const Icon(Icons.map_outlined, size: 20),
                        text: AppStrings.t('tab_outbreak_map'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Tab 1: Nearby Veterinarians List
              _buildVeterinariansTab(filteredVets, nearbyVets.length),

              // Tab 2: Outbreak & Disease GIS Map
              _buildOutbreakMapTab(nearbyVets),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: NEARBY VETERINARIANS LIST
  // ==========================================
  Widget _buildVeterinariansTab(List<VeterinarianModel> vets, int totalVets) {
    return Column(
      children: [
        // Search & Filter Row
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.t('search_vets'),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  suffixIcon: _vetSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _vetSearchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _vetSearchQuery = val),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildVetFilterChip('all', '${AppStrings.t('filter_all')} ($totalVets)'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildVetFilterChip('within_5km', '< 5 km'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildVetFilterChip('polyclinic', 'Polyclinics & Hospitals'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of Veterinarians or Empty State
        Expanded(
          child: vets.isEmpty
              ? _buildEmptyVetsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: vets.length,
                  itemBuilder: (context, index) {
                    final vet = vets[index];
                    return _buildVeterinarianCard(vet);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVetFilterChip(String value, String label) {
    final isSelected = _vetFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _vetFilter = value),
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

  Widget _buildVeterinarianCard(VeterinarianModel vet) {
    final distText = vet.distanceKm != null
        ? '${vet.distanceKm!.toStringAsFixed(1)} ${AppStrings.t('distance_km')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VetConsultationScreen(
                vet: vet,
                onShowOnMap: () {
                  _tabController.animateTo(1);
                  _mapController.move(LatLng(vet.latitude, vet.longitude), 15.0);
                },
              ),
            ),
          );
        },
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Doctor Name & Verification Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vet.name,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 12, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  AppStrings.t('verified_vet'),
                                  style: AppTypography.badge.copyWith(fontSize: 9, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vet.qualification} • Reg: ${vet.registrationNumber}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Clinic Name & Address
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vet.clinicName,
                    style: AppTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vet.address,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                if (distText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      distText,
                      style: AppTypography.badge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Working Hours & Emergency Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.t('working_hours')}: ${vet.workingHours}',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons: Consult/Book, Call & Directions
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.event_available, size: 16),
                    label: const Text('भेट / सल्ला (Consult)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VetConsultationScreen(
                            vet: vet,
                            onShowOnMap: () {
                              _tabController.animateTo(1);
                              _mapController.move(LatLng(vet.latitude, vet.longitude), 15.0);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.call, size: 15),
                    label: Text(AppStrings.t('call_vet'), style: const TextStyle(fontSize: 12)),
                    onPressed: () => _callVeterinarian(vet.phone),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: AppStrings.t('directions'),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 18, color: AppColors.primary),
                  onPressed: () => _openDirections(vet.latitude, vet.longitude, vet.clinicName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVetsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 54,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.t('no_vets_available'),
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.t('check_again_later'),
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.t('retry')),
              onPressed: () {
                setState(() {
                  _vetSearchQuery = '';
                  _vetFilter = 'all';
                });
                _refreshLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: GEOGRAPHICAL OUTBREAK GIS MAP
  // ==========================================
  Widget _buildOutbreakMapTab(List<VeterinarianModel> vets) {
    final outbreakZones = _store.outbreakZones;
    final diseaseCases = _store.diseaseCases;

    return Stack(
      children: [
        // Interactive OpenStreetMap Canvas
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentLat, _currentLng),
            initialZoom: 13.0,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            // OpenStreetMap Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pashuvani.pashu_wani',
            ),

            // Outbreak Zones Shaded Geofence Circles
            if (_mapLayerFilter == 'all' || _mapLayerFilter == 'outbreaks')
              CircleLayer(
                circles: outbreakZones.map((zone) {
                  final isConf = zone.isConfirmed;
                  return CircleMarker(
                    point: LatLng(zone.latitude, zone.longitude),
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: isConf
                        ? AppColors.alertCritical.withValues(alpha: 0.18)
                        : AppColors.cautionAmber.withValues(alpha: 0.18),
                    borderColor: isConf ? AppColors.alertCritical : AppColors.cautionAmber,
                    borderStrokeWidth: 2.0,
                  );
                }).toList(),
              ),

            // Markers Layer: Farmer, Vets, Outbreak Centers, and Case Pins
            MarkerLayer(
              markers: [
                // 1. Farmer Current Location Marker
                Marker(
                  point: LatLng(_currentLat, _currentLng),
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _showFarmerLocationSheet(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 24),
                    ),
                  ),
                ),

                // 2. Verified Veterinarians Markers
                if (_mapLayerFilter == 'all' || _mapLayerFilter == 'vets')
                  ...vets.map((vet) {
                    return Marker(
                      point: LatLng(vet.latitude, vet.longitude),
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _showVetDetailsSheet(vet),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }),

                // 3. Outbreak Zone Centers
                if (_mapLayerFilter == 'all' || _mapLayerFilter == 'outbreaks')
                  ...outbreakZones.map((zone) {
                    return Marker(
                      point: LatLng(zone.latitude, zone.longitude),
                      width: 46,
                      height: 46,
                      child: GestureDetector(
                        onTap: () => _showOutbreakDetailsSheet(zone),
                        child: Container(
                          decoration: BoxDecoration(
                            color: zone.isConfirmed ? AppColors.alertCritical : AppColors.cautionAmber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: (zone.isConfirmed ? AppColors.alertCritical : AppColors.cautionAmber)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            zone.isConfirmed ? Icons.warning : Icons.report_problem,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),

                // 4. Individual Confirmed Case Pins
                if (_mapLayerFilter == 'all' || _mapLayerFilter == 'outbreaks')
                  ...diseaseCases.map((c) {
                    return Marker(
                      point: LatLng(c.latitude, c.longitude),
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => _showCasePinSheet(c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.isConfirmed ? AppColors.alertCritical : AppColors.cautionAmber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.lens, color: Colors.white, size: 12),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),

        // Floating Layer Filter Chips
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMapLayerChip('all', AppStrings.t('filter_all_layers')),
                const SizedBox(width: 8),
                _buildMapLayerChip('vets', AppStrings.t('filter_vets_only')),
                const SizedBox(width: 8),
                _buildMapLayerChip('outbreaks', AppStrings.t('filter_outbreaks_only')),
              ],
            ),
          ),
        ),

        // Map Control Floating Buttons (Right side)
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.add),
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.remove),
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'map_recenter',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.my_location),
                onPressed: () {
                  _mapController.move(LatLng(_currentLat, _currentLng), 14.0);
                },
              ),
            ],
          ),
        ),

        // Collapsible Map Legend Card (Bottom left)
        Positioned(
          bottom: 24,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.t('map_legend'),
                  style: AppTypography.badge.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _buildLegendItem(AppColors.primary, AppStrings.t('legend_farmer')),
                const SizedBox(height: 2),
                _buildLegendItem(AppColors.primaryLight, AppStrings.t('legend_vet')),
                const SizedBox(height: 2),
                _buildLegendItem(AppColors.alertCritical, AppStrings.t('legend_confirmed_outbreak')),
                const SizedBox(height: 2),
                _buildLegendItem(AppColors.cautionAmber, AppStrings.t('legend_suspected_cluster')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapLayerChip(String value, String label) {
    final isSelected = _mapLayerFilter == value;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _mapLayerFilter = value),
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: AppTypography.caption.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  // ==========================================
  // DETAIL BOTTOM SHEETS FOR MAP MARKERS
  // ==========================================
  void _showFarmerLocationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _store.currentUser?.fullName ?? 'Ramesh Jadhav',
                            style: AppTypography.cardTitle.copyWith(fontSize: 16),
                          ),
                          Text(
                            _store.currentUser?.farmName ?? 'Jadhav Dairy Farm',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.t('village')}: ${_store.currentUser?.villageName ?? "Phaltan Rural"}',
                  style: AppTypography.bodyDefault,
                ),
                Text(
                  'GPS Coordinates: $_currentLat, $_currentLng',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.assignment_late_outlined, size: 16),
                        label: Text(AppStrings.t('action_report')),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: Text(AppStrings.t('case_history')),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportsHistoryScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVetDetailsSheet(VeterinarianModel vet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital, color: AppColors.primary, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vet.clinicName,
                        style: AppTypography.cardTitle.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${vet.name} (${vet.qualification})',
                  style: AppTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'MSVC Reg: ${vet.registrationNumber} • ${vet.address}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.t('working_hours')}: ${vet.workingHours}',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: const Text('📅 फार्म भेट / सल्ला बुक करा (Consult & Book Visit)'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VetConsultationScreen(vet: vet),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call, size: 16),
                        label: Text(AppStrings.t('call_vet')),
                        onPressed: () {
                          Navigator.pop(context);
                          _callVeterinarian(vet.phone);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions, size: 16),
                        label: Text(AppStrings.t('directions')),
                        onPressed: () {
                          Navigator.pop(context);
                          _openDirections(vet.latitude, vet.longitude, vet.clinicName);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOutbreakDetailsSheet(OutbreakZoneModel zone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      zone.isConfirmed ? Icons.warning_rounded : Icons.report_problem_outlined,
                      color: zone.isConfirmed ? AppColors.alertCritical : AppColors.cautionAmber,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        zone.isConfirmed
                            ? AppStrings.t('alert_lsd_title')
                            : AppStrings.formatDisease(zone.diseaseCode),
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 16,
                          color: zone.isConfirmed ? AppColors.alertCritical : AppColors.cautionAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${zone.caseCount} ${AppStrings.t('cases_in_zone')} (${(zone.radiusMeters / 1000).toStringAsFixed(1)} km radius)',
                        style: AppTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zone.id == 'zone-lsd-01'
                            ? AppStrings.t('advisory_lsd_cluster')
                            : zone.id == 'zone-fmd-02'
                                ? AppStrings.t('advisory_fmd_cluster')
                                : zone.advisory,
                        style: AppTypography.caption.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${AppStrings.t('advisory_guidelines')}:',
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t('advisory_guidelines_content'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: AppStrings.t('action_report'),
                  icon: Icons.assignment_late_outlined,
                  backgroundColor: AppColors.alertCritical,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateReportScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: Text(AppStrings.t('tab_nearby_vets')),
                    onPressed: () {
                      Navigator.pop(context);
                      _tabController.animateTo(0);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCasePinSheet(DiseaseCasePin pin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.coronavirus_outlined, color: AppColors.alertCritical, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${AppStrings.t('legend_case')}: ${AppStrings.formatDisease(pin.diseaseCode)}',
                        style: AppTypography.cardTitle.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${AppStrings.t('date')}: ${pin.confirmedAt.toIso8601String().substring(0, 10)}',
                  style: AppTypography.caption,
                ),
                Text(
                  'Coordinates: ${pin.latitude.toStringAsFixed(4)}° N, ${pin.longitude.toStringAsFixed(4)}° E',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t('verified_by_dept'),
                  style: AppTypography.bodyDefault.copyWith(fontSize: 13, color: AppColors.successGreen),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertCritical,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.assignment_late_outlined, size: 16),
                        label: Text(AppStrings.t('action_report')),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.medical_services_outlined, size: 16),
                        label: Text(AppStrings.t('tab_nearby_vets')),
                        onPressed: () {
                          Navigator.pop(context);
                          _tabController.animateTo(0);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
