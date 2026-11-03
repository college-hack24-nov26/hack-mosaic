import 'package:flutter/material.dart';
import '../../core/auth/api_exception.dart';
import '../../core/auth/error_messages.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';

final RegExp _phoneRe = RegExp(r'^[6-9][0-9]{9}$');

String? validatePhone(String? v) =>
    (v != null && _phoneRe.hasMatch(v.trim())) ? null : AppStrings.t('err_phone_invalid');

String? validatePassword(String? v) =>
    (v != null && v.length >= 8 && v.length <= 72) ? null : AppStrings.t('err_password_len');

String toE164(String tenDigits) => '+91${tenDigits.trim()}';

/// Login for any account, or (vetOnly) the veterinarian entry point which
/// refuses non-vet accounts. The role is decided by the server either way.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.vetOnly = false, this.session});
  final bool vetOnly;
  final SessionManager? session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  SessionManager get _session => widget.session ?? SessionManager.instance;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _session.login(
        toE164(_phone.text),
        _password.text,
        requireRole: widget.vetOnly ? 'vet' : null,
      );
      if (!mounted) return;
      // AuthGate (root) now shows the dashboard for the server-verified role.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(e, unauthenticatedKey: 'err_credentials');
        if (e is ApiException && e.isForbidden) _error = AppStrings.t('err_forbidden');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vet = widget.vetOnly;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t(vet ? 'auth_login_vet_title' : 'auth_login_farmer_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Icon(vet ? Icons.medical_services_outlined : Icons.agriculture,
                size: 48, color: vet ? AppColors.infoBlue : AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            if (vet)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(AppStrings.t('auth_login_vet_note'), style: AppTypography.bodySecondary),
              ),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    decoration: InputDecoration(
                      labelText: AppStrings.t('auth_phone'),
                      hintText: AppStrings.t('auth_phone_hint'),
                      prefixText: '+91  ',
                      counterText: '',
                    ),
                    validator: validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: AppStrings.t('auth_password'),
                      suffixIcon: IconButton(
                        tooltip: AppStrings.t('auth_show_password'),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.alertCritical.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.alertCritical.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.alertCritical, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, key: const Key('login_error'), style: AppTypography.caption)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: AppStrings.t('auth_login_btn'),
              icon: Icons.login,
              isLoading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            if (vet) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await _session.enterDemoVet();
                  nav.popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.science_outlined, size: 18, color: AppColors.infoBlue),
                label: Text(AppStrings.t('auth_demo_vet'), style: const TextStyle(color: AppColors.infoBlue)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

