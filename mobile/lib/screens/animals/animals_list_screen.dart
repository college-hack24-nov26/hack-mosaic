import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/animal_model.dart';
import 'add_animal_screen.dart';
import 'animal_details_screen.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key});

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  final OfflineStore _store = OfflineStore();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'cattle', 'buffalo'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final allAnimals = _store.animals;
        final filteredAnimals = allAnimals.where((a) {
          final matchesSearch = a.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (a.tagNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          final matchesFilter = _selectedFilter == 'all' || a.speciesCode == _selectedFilter;
          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppStrings.t('nav_animals')),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                tooltip: 'नवीन जनावर जोडा / Add Animal',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                color: AppColors.surface,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'नाव किंवा टॅग नंबर शोधा... / Search tag...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'सर्व / All (${allAnimals.length})'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('cattle', 'गाय/बैल / Cattle'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('buffalo', 'म्हैस / Buffalo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Animal Cards List
              Expanded(
                child: filteredAnimals.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: filteredAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = filteredAnimals[index];
                          return _buildAnimalCard(animal);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(AppStrings.t('action_add_animal')),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
              );
            },
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

  Widget _buildAnimalCard(AnimalModel animal) {
    final isCattle = animal.speciesCode == 'cattle';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnimalDetailsScreen(animal: animal),
            ),
          );
        },
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                isCattle ? Icons.pets : Icons.agriculture,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal.displayName,
                          style: AppTypography.cardTitle.copyWith(fontSize: 16),
                        ),
                      ),
                      if (!animal.isSynced)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cautionAmber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 10, color: AppColors.cautionAmber),
                              const SizedBox(width: 3),
                              Text(
                                'Pending Sync',
                                style: AppTypography.badge.copyWith(color: AppColors.cautionAmber, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'टॅग: ${animal.tagNumber ?? "No Tag"} • जात: ${animal.breedCode?.toUpperCase() ?? "Crossbred"}',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'लिंग: ${animal.sex == "female" ? "मादी (Female)" : "नर (Male)"}',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
            const Icon(Icons.pets, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('empty_animals'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyDefault.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(AppStrings.t('action_add_animal')),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

