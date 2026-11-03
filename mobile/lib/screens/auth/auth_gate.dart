import 'package:flutter/material.dart';
import '../../core/auth/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../home/main_navigation_screen.dart';
import '../vet/vet_shell.dart';
import 'access_restricted_screen.dart';
import 'verification_pending_screen.dart';
import 'welcome_screen.dart';

/// Root router. The destination is a pure function of the session status,
/// which is derived from the server's `GET /me` (never from a UI choice).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.session});
  final SessionManager? session;

  @override
  Widget build(BuildContext context) {
    final s = session ?? SessionManager.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        switch (s.status) {
          case SessionStatus.loading:
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          case SessionStatus.unauthenticated:
            return const WelcomeScreen();
          case SessionStatus.farmer:
          case SessionStatus.demoFarmer:
            return const MainNavigationScreen();
          case SessionStatus.vet:
          case SessionStatus.demoVet:
            return const VetShell();
          case SessionStatus.vetPending:
            return const VerificationPendingScreen();
          case SessionStatus.restricted:
            return const AccessRestrictedScreen();
        }
      },
    );
  }
}

