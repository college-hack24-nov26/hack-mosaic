import 'package:flutter/material.dart';
import '../../core/auth/role_guard.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/vet_repository.dart';
import 'vet_dashboard_screen.dart';
import 'vet_inbox_screen.dart';
import 'vet_map_screen.dart';
import 'vet_animal_history_screen.dart';
import 'vet_profile_screen.dart';

/// Navigation shell for verified veterinarians.
/// Protected by [RoleGuard] so no farmer or unverified user can mount it.
class VetShell extends StatefulWidget {
  const VetShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<VetShell> createState() => VetShellState();
}

class VetShellState extends State<VetShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void switchTab(int index) {
    if (mounted && index >= 0 && index < 5) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final isDemo = session.status == SessionStatus.demoVet || VetRepository.shared.isUsingDemoData;

    return RoleGuard(
      role: 'vet',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            if (isDemo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.cautionAmber,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.science_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppStrings.t('vet_demo_banner'),
                          textAlign: TextAlign.center,
                          style: AppTypography.badge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  VetDashboardScreen(onNavigateToInbox: () => switchTab(1), onNavigateToMap: () => switchTab(2)),
                  const VetInboxScreen(),
                  const VetMapScreen(),
                  const VetAnimalRecordsSearchScreen(),
                  const VetProfileScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.surfaceContainerHigh,
          elevation: 3,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: AppColors.primary),
              label: AppStrings.t('vet_nav_dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment, color: AppColors.primary),
              label: AppStrings.t('vet_nav_inbox'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map, color: AppColors.primary),
              label: AppStrings.t('vet_nav_map'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.pets_outlined),
              selectedIcon: const Icon(Icons.pets, color: AppColors.primary),
              label: AppStrings.t('vet_nav_animals'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: AppStrings.t('vet_nav_profile'),
            ),
          ],
        ),
      ),
    );
  }
}
