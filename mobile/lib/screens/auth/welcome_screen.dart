import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/offline_store.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget _lang(String code, String label) {
    final active = AppStrings.currentLang == code;
    return GestureDetector(
      onTap: () => OfflineStore().setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: active ? AppColors.primaryDark : Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([session, OfflineStore()]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Brand header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, MediaQuery.of(context).padding.top + AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _lang('mr', 'मराठी'),
                        const SizedBox(width: 6),
                        _lang('en', 'English'),
                        const SizedBox(width: 6),
                        _lang('hi', 'हिंदी'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 50, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppStrings.t('app_name'),
                      style: AppTypography.displayLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t('auth_tagline'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyDefault.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    if (session.sessionExpired)
                      _banner(Icons.lock_clock, AppStrings.t('session_expired'), AppColors.cautionAmber),
                    if (session.serverUnreachable)
                      _banner(Icons.cloud_off, AppStrings.t('err_network'), AppColors.cautionAmber,
                          action: TextButton(
                            onPressed: session.restore,
                            child: Text(AppStrings.t('try_again')),
                          )),
                    AppButton(
                      label: AppStrings.t('auth_login'),
                      icon: Icons.login,
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: AppStrings.t('auth_register_farmer'),
                      icon: Icons.agriculture,
                      isSecondary: true,
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: AppStrings.t('auth_vet_login'),
                      icon: Icons.medical_services_outlined,
                      isSecondary: true,
                      backgroundColor: AppColors.infoBlue,
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const LoginScreen(vetOnly: true))),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    TextButton.icon(
                      onPressed: session.enterDemo,
                      icon: const Icon(Icons.science_outlined, size: 18),
                      label: Text(AppStrings.t('auth_demo')),
                    ),
                    TextButton.icon(
                      onPressed: session.enterDemoVet,
                      icon: const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.infoBlue),
                      label: Text(AppStrings.t('auth_demo_vet'), style: const TextStyle(color: AppColors.infoBlue)),
                    ),
                    Text(
                      AppStrings.t('auth_demo_note'),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _banner(IconData icon, String text, Color color, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textPrimary))),
          if (action != null) action,
        ],
      ),
    );
  }
}

