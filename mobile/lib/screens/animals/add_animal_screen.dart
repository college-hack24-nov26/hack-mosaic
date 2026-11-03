import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/animal_model.dart';
import '../../core/network/api_client.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _markingsController = TextEditingController();

  String _selectedSpecies = 'cattle';
  String _selectedBreed = 'gir';
  String _selectedSex = 'female';
  String? _photoPath;
  bool _isSaving = false;

  final Map<String, List<Map<String, String>>> _breedsBySpecies = {
    'cattle': [
      {'code': 'gir', 'name': 'Gir'},
      {'code': 'khillar', 'name': 'Khillar'},
      {'code': 'deoni', 'name': 'Deoni'},
      {'code': 'dangi', 'name': 'Dangi'},
      {'code': 'hf_cross', 'name': 'HF Cross'},
      {'code': 'jersey_cross', 'name': 'Jersey Cross'},
      {'code': 'other', 'name': 'Other'},
    ],
    'buffalo': [
      {'code': 'murrah', 'name': 'Murrah'},
      {'code': 'jaffarabadi', 'name': 'Jaffarabadi'},
      {'code': 'pandharpuri', 'name': 'Pandharpuri'},
      {'code': 'mehsana', 'name': 'Mehsana'},
      {'code': 'other', 'name': 'Other'},
    ],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _markingsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo error: $e')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final store = OfflineStore();
    final newAnimalId = const Uuid().v4();
    final newAnimal = AnimalModel(
      id: newAnimalId,
      farmerId: store.currentUser?.id ?? 'demo-farmer',
      speciesCode: _selectedSpecies,
      breedCode: _selectedBreed,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      tagNumber: _tagController.text.trim().isNotEmpty ? _tagController.text.trim() : null,
      sex: _selectedSex,
      birthDate: DateTime.now().subtract(const Duration(days: 730)).toIso8601String().substring(0, 10),
      markings: _markingsController.text.trim().isNotEmpty ? _markingsController.text.trim() : null,
      photoPath: _photoPath,
      isSynced: false,
    );

    await store.addAnimal(newAnimal);

    // Attempt background sync if online
    if (store.isOnline) {
      ApiClient().syncAnimal(newAnimal).then((synced) {
        if (synced) {
          store.markAnimalSynced(newAnimal.id);
        }
      });
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.isOnline
                ? 'जनावर यशस्वीरीत्या नोंदवले गेले! (Animal saved)'
                : 'ऑफलाइन जतन केले! नेटवर्क आल्यावर सिंक होईल. (Saved offline)',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _breedsBySpecies[_selectedSpecies] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('action_add_animal')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Photo Picker Container
            Center(
              child: GestureDetector(
                onTap: () => _showPhotoSourceSheet(),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border, width: 2),
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
                            const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.primary),
                            const SizedBox(height: 6),
                            Text(
                              'फोटो जोडा\nAdd Photo',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Species Toggle
            Text(AppStrings.t('species'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    title: AppStrings.t('species_cattle'),
                    icon: Icons.pets,
                    isSelected: _selectedSpecies == 'cattle',
                    onTap: () {
                      setState(() {
                        _selectedSpecies = 'cattle';
                        _selectedBreed = 'gir';
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildChoiceCard(
                    title: AppStrings.t('species_buffalo'),
                    icon: Icons.agriculture,
                    isSelected: _selectedSpecies == 'buffalo',
                    onTap: () {
                      setState(() {
                        _selectedSpecies = 'buffalo';
                        _selectedBreed = 'murrah';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Breed Dropdown
            Text(AppStrings.t('breed'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedSpecies),
              initialValue: _selectedBreed,
              decoration: const InputDecoration(),
              items: breeds.map((b) {
                return DropdownMenuItem<String>(
                  value: b['code'],
                  child: Text(AppStrings.formatBreed(b['code']!)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBreed = val);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Animal Name
            Text(AppStrings.t('animal_name'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppStrings.currentLang == 'en'
                    ? 'e.g. Gauri, Kapila, Laxmi'
                    : (AppStrings.currentLang == 'hi'
                        ? 'उदा. गौरी, कपिला, लक्ष्मी'
                        : 'उदा. गौरी, कपिला, लक्ष्मी'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Ear Tag / Bharat Pashudhan ID
            Text(AppStrings.t('tag_number'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                hintText: 'उदा. MH-SAT-2026-XXXX (Optional)',
                prefixIcon: Icon(Icons.tag, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sex Selection
            Text(AppStrings.t('gender'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    title: AppStrings.t('gender_female'),
                    icon: Icons.female,
                    isSelected: _selectedSex == 'female',
                    onTap: () => setState(() => _selectedSex = 'female'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildChoiceCard(
                    title: AppStrings.t('gender_male'),
                    icon: Icons.male,
                    isSelected: _selectedSex == 'male',
                    onTap: () => setState(() => _selectedSex = 'male'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Markings
            Text(AppStrings.t('identification_markings'), style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _markingsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.currentLang == 'en'
                    ? 'e.g., White star on forehead, curved horns'
                    : (AppStrings.currentLang == 'hi'
                        ? 'उदा. माथे पर सफेद तारा, मुड़े हुए सींग'
                        : 'उदा. कपाळावर पांढरा ठिपका, वळलेली शिंगे'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Save Button
            AppButton(
              label: AppStrings.t('add_animal_btn'),
              icon: Icons.check_circle_outline,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceSheet() {
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

