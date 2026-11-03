import 'package:flutter/material.dart';
import '../auth/session_manager.dart';
import '../../screens/auth/access_restricted_screen.dart';

/// Defence-in-depth route guard. The **backend** is the real authority; this
/// guard only stops a non-vet session from ever building a vet screen.
class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key, required this.role, required this.child, this.session});

  final String role; // 'vet' | 'farmer'
  final Widget child;
  final SessionManager? session;

  @override
  Widget build(BuildContext context) {
    final s = session ?? SessionManager.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final allowed = switch (role) {
          'vet' => s.isVerifiedVet,
          'farmer' => s.isFarmerSession,
          _ => false,
        };
        if (!allowed) return const AccessRestrictedScreen(reasonOverride: 'forbidden_route');
        return child;
      },
    );
  }
}

