import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/app_card.dart';
import '../../data/local/offline_store.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<Map<String, String>> _languages = [
    {'code': 'mr', 'name': 'मराठी', 'sub': 'महाराष्ट्र'},
    {'code': 'en', 'name': 'English', 'sub': 'English'},
    {'code': 'hi', 'name': 'हिंदी', 'sub': 'भारत'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('choose_language')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: _languages.map((lang) {
          final isSelected = AppStrings.currentLang == lang['code'];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () async {
                await OfflineStore().setLanguage(lang['code']!);
                if (!context.mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language updated to ${lang['name']}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
                Navigator.pop(context);
              },
              color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.translate,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: AppTypography.cardTitle.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        Text(
                          lang['sub']!,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

