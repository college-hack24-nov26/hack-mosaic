import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../data/local/offline_store.dart';
import 'farmer_home_screen.dart';
import '../animals/animals_list_screen.dart';
import '../reports/create_report_screen.dart';
import '../nearby/nearby_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = OfflineStore();

    final screens = [
      FarmerHomeScreen(onNavigateTab: _onTabTapped),
      const AnimalsListScreen(),
      CreateReportScreen(onReportSubmitted: () => _onTabTapped(3)),
      const NearbyScreen(),
      const ProfileScreen(),
    ];

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final activeCount = store.reports.where((r) => r.status == 'confirmed').length;
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: AppColors.surface,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: AppTypography.badge.copyWith(fontSize: 11),
              unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 11),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: AppStrings.t('nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.pets_outlined),
                  activeIcon: const Icon(Icons.pets),
                  label: AppStrings.t('nav_animals'),
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_alert, color: Colors.white, size: 20),
                  ),
                  label: AppStrings.t('nav_report'),
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    backgroundColor: AppColors.alertCritical,
                    child: const Icon(Icons.explore_outlined),
                  ),
                  activeIcon: const Icon(Icons.explore),
                  label: AppStrings.t('nav_nearby'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_circle_outlined),
                  activeIcon: const Icon(Icons.account_circle),
                  label: AppStrings.t('nav_profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

