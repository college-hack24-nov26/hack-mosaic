import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/safety_disclaimer_card.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/disease_report_model.dart';
import '../../core/network/api_client.dart';

class CreateReportScreen extends StatefulWidget {
  final String? preselectedAnimalId;
  final VoidCallback? onReportSubmitted;

  const CreateReportScreen({
    super.key,
    this.preselectedAnimalId,
    this.onReportSubmitted,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final OfflineStore _store = OfflineStore();
  final _descriptionController = TextEditingController();

  String? _selectedAnimalId;
  String _selectedCondition = 'lumpy_skin_disease';
  final Set<String> _selectedSymptoms = {'skin_nodules', 'fever'};
  String? _photoPath;
  bool _isSubmitting = false;

  // Real coordinates for Phaltan / Satara demonstration
  double _currentLat = 17.9856;
  double _currentLng = 74.4331;
  bool _hasGps = true;

  final List<Map<String, String>> _conditions = [
    {'code': 'lumpy_skin_disease', 'name': 'लंपी त्वचा रोग (Lumpy Skin Disease)'},
    {'code': 'foot_and_mouth', 'name': 'लाळ्या खुरकूत (Foot & Mouth Disease)'},
    {'code': 'hemorrhagic_septicemia', 'name': 'घटसर्प (Hemorrhagic Septicemia)'},
    {'code': 'black_quarter', 'name': 'फाशी / एकटांग्या (Black Quarter)'},
    {'code': 'general_illness', 'name': 'इतर संशयित आजार (General Illness)'},
  ];

  final List<Map<String, dynamic>> _symptoms = [
    {'code': 'skin_nodules', 'icon': Icons.grain, 'name': 'त्वचेवर गाठी (Nodules)'},
    {'code': 'fever', 'icon': Icons.thermostat, 'name': 'तीव्र ताप (High Fever)'},
    {'code': 'reduced_milk', 'icon': Icons.water_drop, 'name': 'दुधात घट (Drop in Milk)'},
    {'code': 'lameness', 'icon': Icons.accessible, 'name': 'लंगडणे (Lameness)'},
    {'code': 'salivation', 'icon': Icons.bubble_chart, 'name': 'लाळ गळणे (Salivation)'},
    {'code': 'nasal_discharge', 'icon': Icons.air, 'name': 'नाकातून स्राव (Discharge)'},
    {'code': 'appetite_loss', 'icon': Icons.no_food, 'name': 'चारा न खाणे (Off Feed)'},
  ];

  @override
  void initState() {
    super.initState();
    final animals = _store.animals;
    if (widget.preselectedAnimalId != null && animals.any((a) => a.id == widget.preselectedAnimalId)) {
      _selectedAnimalId = widget.preselectedAnimalId;
    } else if (animals.isNotEmpty) {
      _selectedAnimalId = animals.first.id;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (picked != null) {
        setState(() => _photoPath = picked.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _handleSubmitReport() async {
    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया आजारी जनावर निवडा (Please select an animal)')),
      );
      return;
    }

    if (_selectedSymptoms.isEmpty && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया लक्षणे किंवा माहिती नोंदवा (Select symptoms or enter notes)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final selectedAnimal = _store.animals.firstWhere((a) => a.id == _selectedAnimalId);
    final reportId = const Uuid().v4();

    final newReport = DiseaseReportModel(
      id: reportId,
      animalId: _selectedAnimalId!,
      animalName: selectedAnimal.displayName,
      reportedAt: DateTime.now(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Reported with symptoms: ${_selectedSymptoms.join(", ")}',
      symptomCodes: _selectedSymptoms.toList(),
      latitude: _hasGps ? _currentLat : null,
      longitude: _hasGps ? _currentLng : null,
      status: 'submitted',
      photoPath: _photoPath,
      isSynced: false,
    );

    await _store.addReport(newReport);

    // Attempt background sync if online
    if (_store.isOnline) {
      ApiClient().syncReport(newReport).then((synced) {
        if (synced) {
          _store.markAllSynced();
        }
      });
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _store.isOnline
                ? 'अहवाल पशुवैद्यक अधिकाऱ्यांकडे पाठवला आहे! (Report submitted to vet)'
                : 'ऑफलाइन नोंदवले! नेटवर्क आल्यावर पाठवले जाईल. (Saved in offline queue)',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );

      if (widget.onReportSubmitted != null) {
        widget.onReportSubmitted!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animals = _store.animals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('nav_report')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Step 1: Select Animal
          Text(AppStrings.t('select_animal'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          if (animals.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'पशु नोंदणी उपलब्ध नाही. कृपया आधी जनावर जोडा.\nNo registered animals found.',
                style: AppTypography.bodySecondary,
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedAnimalId,
              decoration: const InputDecoration(),
              items: animals.map((a) {
                return DropdownMenuItem<String>(
                  value: a.id,
                  child: Text('${a.displayName} (${a.tagNumber ?? "No Tag"})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAnimalId = val),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Step 2: Suspected Disease Category
          Text('संशयित आजार / Suspected Category', style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _selectedCondition,
            decoration: const InputDecoration(),
            items: _conditions.map((c) {
              return DropdownMenuItem<String>(
                value: c['code'],
                child: Text(c['name']!, style: AppTypography.bodyDefault.copyWith(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCondition = val!),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 3: Observed Symptoms (Interactive Chips)
          Text(AppStrings.t('select_symptoms'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _symptoms.map((s) {
              final isSelected = _selectedSymptoms.contains(s['code']);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(s['name'] as String),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: AppTypography.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.add(s['code'] as String);
                    } else {
                      _selectedSymptoms.remove(s['code'] as String);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 4: Photo Evidence Attachment
          Text('जनावराचा फोटो / Photo Attachment', style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _showPhotoSheet(),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 1.5),
                image: _photoPath != null
                    ? DecorationImage(
                        image: FileImage(File(_photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photoPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          'गाठी किंवा जखमेचा फोटो काढा\nTap to Capture Lesion Photo',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 5: Location Card (Epidemiological Surveillance)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surfaceContainer,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'स्थान नोंदणी (GPS Surveillance)',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'अक्षांश: $_currentLat, रेखांश: $_currentLng (फलटण, सातारा)',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _hasGps,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _hasGps = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Additional Notes
          Text(AppStrings.t('report_description'), style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'उदा. दोन दिवसांपासून ताप आहे, चारा खात नाही... (Any other observations)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Regulatory Safety Notice
          const SafetyDisclaimerCard(),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          AppButton(
            label: AppStrings.t('submit_report'),
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _handleSubmitReport,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('कॅमेरा (Camera)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('गॅलरी (Gallery)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
