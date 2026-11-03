import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/disease_report_model.dart';
import '../../data/models/veterinarian_model.dart';
import '../reports/create_report_screen.dart';
import '../reports/report_details_screen.dart';

class VetConsultationScreen extends StatefulWidget {
  final VeterinarianModel vet;
  final DiseaseReportModel? attachedReport;
  final VoidCallback? onShowOnMap;

  const VetConsultationScreen({
    super.key,
    required this.vet,
    this.attachedReport,
    this.onShowOnMap,
  });

  @override
  State<VetConsultationScreen> createState() => _VetConsultationScreenState();
}

class _VetConsultationScreenState extends State<VetConsultationScreen> {
  final OfflineStore _store = OfflineStore();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedAnimalId;
  String _visitType = 'urgent_farm_visit'; // urgent_farm_visit | tele_triage | vaccination
  String _timeSlot = 'morning'; // morning | afternoon | evening
  final Set<String> _selectedSymptoms = {'fever', 'skin_nodules'};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final animals = _store.animals;
    if (widget.attachedReport != null) {
      _selectedAnimalId = widget.attachedReport!.animalId;
      _selectedSymptoms
        ..clear()
        ..addAll(widget.attachedReport!.symptomCodes);
      _notesController.text = widget.attachedReport!.description ?? '';
    } else if (animals.isNotEmpty) {
      _selectedAnimalId = animals.first.id;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _callVet() async {
    final clean = widget.vet.phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('डॉक्टरांचा संपर्क क्रमांक: ${widget.vet.phone}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _openDirections() async {
    final lat = widget.vet.latitude;
    final lng = widget.vet.longitude;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    if (widget.onShowOnMap != null) {
      Navigator.of(context).pop();
      widget.onShowOnMap!();
    }
  }

  String _visitTypeLabel(String code) {
    switch (code) {
      case 'urgent_farm_visit':
        return 'तातडीची प्रत्यक्ष फार्म भेट (Urgent Farm Visit)';
      case 'tele_triage':
        return 'फोन / व्हिडिओ सल्ला (Tele-Consultation)';
      case 'vaccination':
        return 'लसीकरण व प्रतिबंधक तपासणी (Vaccination)';
      default:
        return code;
    }
  }

  String _timeSlotLabel(String slot) {
    switch (slot) {
      case 'morning':
        return 'सकाळी ९:०० - १२:०० (Morning)';
      case 'afternoon':
        return 'दुपारी १२:०० - ४:०० (Afternoon)';
      case 'evening':
        return 'संध्याकाळी ४:०० - ७:०० (Evening)';
      default:
        return slot;
    }
  }

  Future<void> _submitConsultationRequest() async {
    final animals = _store.animals;
    if (_selectedAnimalId == null && animals.isNotEmpty) {
      _selectedAnimalId = animals.first.id;
    }
    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया आधी जनावर निवडा (Please register/select an animal first)')),
      );
      return;
    }

    setState(() => _submitting = true);

    final animal = animals.firstWhere(
      (a) => a.id == _selectedAnimalId,
      orElse: () => animals.first,
    );
    final reportId = const Uuid().v4();
    final customNote = _notesController.text.trim();
    final fullDesc = [
      '[पशुवैद्यक विनंती: ${widget.vet.name} • ${widget.vet.clinicName}]',
      'प्रकार: ${_visitTypeLabel(_visitType)}',
      'वेळ: ${_timeSlotLabel(_timeSlot)}',
      if (customNote.isNotEmpty) 'शेतकरी टिपणी: $customNote',
    ].join(' | ');

    final newReport = DiseaseReportModel(
      id: reportId,
      animalId: animal.id,
      animalName: animal.displayName,
      reportedAt: DateTime.now().toUtc(),
      description: fullDesc,
      descriptionLanguage: AppStrings.currentLang,
      symptomCodes: _selectedSymptoms.isEmpty ? ['fever'] : _selectedSymptoms.toList(),
      latitude: _store.currentUser?.latitude ?? 17.9856,
      longitude: _store.currentUser?.longitude ?? 74.4331,
      villageId: _store.currentUser?.villageId,
      status: 'submitted',
      photoPath: widget.attachedReport?.photoPath,
      screening: widget.attachedReport?.screening,
      isSynced: false,
    );

    await _store.addReport(newReport);

    if (_store.isOnline) {
      ApiClient().syncReport(newReport).then((synced) async {
        if (synced) {
          await _store.markReportSynced(newReport.id);
        }
      });
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'भेट व तपासणी विनंती नोंदवली!',
                style: AppTypography.cardTitle.copyWith(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'डॉ. ${widget.vet.name} (${widget.vet.clinicName}) यांच्याकडे तुमची विनंती व जनावराचा अहवाल पाठवला आहे.',
              style: AppTypography.bodyDefault,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('संदर्भ क्र.: #${reportId.substring(0, 8).toUpperCase()}',
                      style: AppTypography.badge.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('जनावर: ${animal.displayName} (${animal.tagNumber ?? "No Tag"})',
                      style: AppTypography.caption),
                  Text('प्रकार: ${_visitTypeLabel(_visitType)}', style: AppTypography.caption),
                  Text('वेळ: ${_timeSlotLabel(_timeSlot)}', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('बंद करा (Close)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.assignment_outlined, size: 16),
            label: const Text('अहवाल स्थिती पहा (View Status)'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ReportDetailsScreen(report: newReport),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vet = widget.vet;
    final animals = _store.animals;
    final distText = vet.distanceKm != null
        ? '${vet.distanceKm!.toStringAsFixed(1)} ${AppStrings.t('distance_km')}'
        : '2.4 km';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(vet.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Doctor Hero Identity Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
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
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.medical_services, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vet.name,
                            style: AppTypography.screenTitle.copyWith(color: Colors.white, fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vet.qualification} • Reg: ${vet.registrationNumber}',
                            style: AppTypography.caption.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppStrings.t('verified_vet'),
                                      style: AppTypography.badge.copyWith(color: Colors.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  distText,
                                  style: AppTypography.badge.copyWith(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vet.clinicName,
                        style: AppTypography.bodyDefault.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vet.address,
                        style: AppTypography.caption.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      '${AppStrings.t('working_hours')}: ${vet.workingHours}',
                      style: AppTypography.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Quick Contact Action Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  onPressed: _callVet,
                  icon: const Icon(Icons.call, size: 18),
                  label: Text(AppStrings.t('call_vet')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  onPressed: _openDirections,
                  icon: const Icon(Icons.directions, size: 18),
                  label: Text(AppStrings.t('directions')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.alertCritical,
                  side: const BorderSide(color: AppColors.alertCritical),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateReportScreen(
                        preselectedAnimalId: _selectedAnimalId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_alert, size: 18),
                label: const Text('फोटो अहवाल'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. Book Farm Visit / Tele-Consultation Card
          Text(
            '📅 पशुवैद्यकीय फार्म भेट / सल्ला बुक करा (Request Vet Visit)',
            style: AppTypography.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '१. आजारी जनावर निवडा (Select Animal)',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (animals.isEmpty)
                  const Text('कोणतेही जनावर नोंदणीकृत नाही.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAnimalId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: animals.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('${a.displayName} (${a.tagNumber ?? "No Tag"})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAnimalId = val),
                  ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  '२. सेवेचा प्रकार (Consultation Type)',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  code: 'urgent_farm_visit',
                  icon: Icons.medical_services_outlined,
                  title: 'तातडीची प्रत्यक्ष फार्म भेट (Urgent Farm Visit)',
                  subtitle: 'पशुवैद्यक प्रत्यक्ष गोठ्यावर येऊन तपासणी व नमुने घेतील',
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  code: 'tele_triage',
                  icon: Icons.phone_in_talk_outlined,
                  title: 'टेलि-कन्सल्टेशन (Phone / Video Triage)',
                  subtitle: 'फोटो व लक्षणांवरून तात्काळ प्राथमिक मार्गदर्शन',
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  code: 'vaccination',
                  icon: Icons.vaccines_outlined,
                  title: 'लसीकरण नोंदणी (Ring Vaccination Request)',
                  subtitle: 'LSD / FMD प्रतिबंधक लसीकरणासाठी नोंदणी करा',
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  '३. पसंतीची वेळ (Preferred Slot)',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _slotChip('morning', 'सकाळी ९–१२'),
                    _slotChip('afternoon', 'दुपारी १२–४'),
                    _slotChip('evening', 'संध्याकाळी ४–७'),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  '४. प्रमुख लक्षणे व माहिती (Symptoms & Notes)',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _symptomChip('skin_nodules', 'त्वचेवर गाठी (Nodules)'),
                    _symptomChip('fever', 'तीव्र ताप (Fever)'),
                    _symptomChip('salivation', 'लाळ गळणे (Salivation)'),
                    _symptomChip('lameness', 'लंगडणे (Lameness)'),
                    _symptomChip('reduced_milk', 'दुधात घट (Drop in Milk)'),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'डॉक्टरांसाठी विशेष माहिती किंवा गोठ्याचा पत्ता लिहा...',
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: 'पशुवैद्यकांकडे विनंती पाठवा (Submit Request)',
                  icon: Icons.send_rounded,
                  isLoading: _submitting,
                  onPressed: _submitConsultationRequest,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          const SafetyDisclaimerCard(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String code,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _visitType == code;
    return InkWell(
      onTap: () => setState(() => _visitType = code),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 13,
                      color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotChip(String code, String label) {
    final selected = _timeSlot == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _timeSlot = code),
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.caption.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _symptomChip(String code, String label) {
    final selected = _selectedSymptoms.contains(code);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTypography.caption.copyWith(
        color: selected ? AppColors.primaryDark : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (v) {
        setState(() {
          if (v) {
            _selectedSymptoms.add(code);
          } else {
            _selectedSymptoms.remove(code);
          }
        });
      },
    );
  }
}
