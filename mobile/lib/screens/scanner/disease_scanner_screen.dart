import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/local/offline_store.dart';
import '../reports/create_report_screen.dart';
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      _snack('Camera error: $e');
    }
  }

  /// Online: Gemini gives preliminary first-aid guidance.
  /// Offline: no fabricated result; the farmer is told and can still file a report.
  Future<void> _runScreening() async {
    if (_imagePath == null) {
      _snack(AppStrings.t('scan_need_photo'));
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final animal = _selectedAnimalId == null
          ? null
          : _store.animals.where((a) => a.id == _selectedAnimalId).firstOrNull;
      final guidance = await GeminiService.analyze(
        image: File(_imagePath!),
        animalLabel: animal == null ? null : '${animal.displayName} (${animal.speciesCode})',
      );
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanResultsScreen(
            imagePath: _imagePath!,
            animalId: _selectedAnimalId,
            guidance: guidance,
          ),
        ),
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      switch (e.failure) {
        case GeminiFailure.noKey:
          _showOfflineSheet(AppStrings.t('scan_no_key'));
        case GeminiFailure.offline:
        case GeminiFailure.timeout:
          _showOfflineSheet(AppStrings.t('scan_offline'));
        case GeminiFailure.badResponse:
          _showOfflineSheet(AppStrings.t('scan_failed'));
      }
    }
  }

  void _showOfflineSheet(String message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.cautionAmber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: AppTypography.bodyDefault)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: AppStrings.t('file_report'),
                icon: Icons.assignment_late_outlined,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CreateReportScreen(
                        preselectedAnimalId: _selectedAnimalId,
                        initialPhotoPath: _imagePath,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animals = _store.animals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('ai_scanner'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(AppStrings.t('select_animal_title'), style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedAnimalId,
            decoration: const InputDecoration(),
            items: animals.map((a) {
              return DropdownMenuItem<String>(
                value: a.id,
                child: Text('${a.displayName} (${a.tagNumber ?? AppStrings.t('no_tag')})'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedAnimalId = val),
          ),
          const SizedBox(height: AppSpacing.lg),

          GestureDetector(
            onTap: _showPhotoSheet,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.primary, width: 2),
                image: _imagePath != null
                    ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                    : null,
              ),
              child: _imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 48),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.t('scan_tap_capture'),
                            textAlign: TextAlign.center,
                            style: AppTypography.cardTitle.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.t('scan_tap_hint'),
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _showPhotoSheet,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

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
                        AppStrings.t('scan_tips_title'),
                        style: AppTypography.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.t('scan_tips_body'),
                        style: AppTypography.caption.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            label: _isAnalyzing ? AppStrings.t('scan_analyzing') : AppStrings.t('run_screening'),
            icon: Icons.psychology,
            isLoading: _isAnalyzing,
            onPressed: _isAnalyzing ? null : _runScreening,
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
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(AppStrings.t('camera')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(AppStrings.t('gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
