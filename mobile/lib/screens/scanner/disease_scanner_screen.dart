import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/local/offline_store.dart';
import 'scan_results_screen.dart';

class DiseaseScannerScreen extends StatefulWidget {
  const DiseaseScannerScreen({super.key});

  @override
  State<DiseaseScannerScreen> createState() => _DiseaseScannerScreenState();
}

class _DiseaseScannerScreenState extends State<DiseaseScannerScreen> {
  final OfflineStore _store = OfflineStore();
  String? _selectedAnimalId;
  String? _imagePath;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (_store.animals.isNotEmpty) {
      _selectedAnimalId = _store.animals.first.id;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _runScreening() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया आधी जनावराचा फोटो काढा (Please capture photo first)')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    // On-device TFLite inference simulation (runs offline in 1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() => _isAnalyzing = false);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanResultsScreen(
            imagePath: _imagePath!,
            animalId: _selectedAnimalId,
            predictedLabel: 'लंपी त्वचा रोग / Lumpy Skin Disease (LSD)',
            confidence: 0.84,
            modelVersion: 'mnv3s-2026.11.0',
            observations: const [
              'त्वचेवर गोलाकार गाठी (Cutaneous circumscribed nodules)',
              'मान व खांद्यावर सूज (Subcutaneous edema on neck/flank)',
              'प्राथमिक तपासणी: तातडीने पशुवैद्यकीय सल्ल्याची शिफारस',
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animals = _store.animals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('एआय तपासणी / AI Scanner'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Animal Selector
          Text('जनावर निवडा / Select Animal', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
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

          // Viewfinder / Photo Box
          GestureDetector(
            onTap: () => _showPhotoSheet(),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.primary, width: 2),
                image: _imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(_imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 48),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'फोटो काढण्यासाठी येथे टॅप करा\nTap to Capture Lesion Photo',
                          textAlign: TextAlign.center,
                          style: AppTypography.cardTitle.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'गाठी, जखम किंवा पुरळ स्पष्ट दिसू द्या\nEnsure skin nodules or mouth sores are clearly visible',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption,
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => _showPhotoSheet(),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Instructions Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.cautionAmber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'तपासणी मार्गदर्शन (Screening Tips)',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• चांगल्या प्रकाशात फोटो काढा\n• कॅमेरा जनावराच्या जखमेवर स्थिर ठेवा\n• इंटरनेट नसतानाही तपासणी फोनवरच होते (Offline TFLite)',
                        style: AppTypography.caption.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Action Button
          AppButton(
            label: 'तपासणी सुरू करा / Run Screening',
            icon: Icons.psychology,
            isLoading: _isAnalyzing,
            onPressed: _runScreening,
          ),
          const SizedBox(height: AppSpacing.xl),
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
