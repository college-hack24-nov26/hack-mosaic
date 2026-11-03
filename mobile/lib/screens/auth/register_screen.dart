import 'package:flutter/material.dart';
import '../../core/auth/error_messages.dart';
import '../../core/auth/session_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../data/reference_data.dart';
import 'login_screen.dart';

/// Farmer-only self registration (API_CONTRACTS.md §3.1). Veterinarian
/// accounts cannot be created here.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.session, this.reference});
  final SessionManager? session;
  final ReferenceApi? reference;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  List<RefItem> _states = [], _districts = [], _talukas = [], _villages = [];
  String? _state, _district, _taluka, _village;
  bool _loadingLoc = true;
  bool _locError = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  SessionManager get _session => widget.session ?? SessionManager.instance;
  ReferenceApi get _ref => widget.reference ?? ReferenceApi.shared;

  @override
  void initState() {
    super.initState();
    _loadLevel('state');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadLevel(String level, {String? parent}) async {
    setState(() {
      _loadingLoc = true;
      _locError = false;
    });
    try {
      final items = await _ref.locations(level, parentId: parent);
      if (!mounted) return;
      setState(() {
        switch (level) {
          case 'state':
            _states = items;
          case 'district':
            _districts = items;
          case 'taluka':
            _talukas = items;
          default:
            _villages = items;
        }
        _loadingLoc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLoc = false;
        _locError = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _session.registerFarmer(
        phone: toE164(_phone.text),
        password: _password.text,
        fullName: _name.text.trim(),
        preferredLanguage: AppStrings.currentLang,
        villageId: _village!,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(e, conflictKey: 'err_phone_exists');
      });
    }
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<RefItem> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-${items.length}-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text(AppStrings.t('reg_select')),
      items: items.map((i) => DropdownMenuItem(value: i.key, child: Text(i.name, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: items.isEmpty ? null : onChanged,
      validator: (v) => v == null ? AppStrings.t('err_required') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('reg_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: AppStrings.t('reg_full_name')),
                    validator: (v) {
                      final n = v?.trim().length ?? 0;
                      return (n >= 2 && n <= 100) ? null : AppStrings.t('err_name_len');
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
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
                    decoration: InputDecoration(
                      labelText: AppStrings.t('auth_password'),
                      suffixIcon: IconButton(
                        tooltip: AppStrings.t('auth_show_password'),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _dropdown(
                    label: AppStrings.t('reg_state'),
                    value: _state,
                    items: _states,
                    onChanged: (v) {
                      setState(() {
                        _state = v;
                        _district = _taluka = _village = null;
                        _districts = _talukas = _villages = [];
                      });
                      if (v != null) _loadLevel('district', parent: v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _dropdown(
                    label: AppStrings.t('reg_district'),
                    value: _district,
                    items: _districts,
                    onChanged: (v) {
                      setState(() {
                        _district = v;
                        _taluka = _village = null;
                        _talukas = _villages = [];
                      });
                      if (v != null) _loadLevel('taluka', parent: v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _dropdown(
                    label: AppStrings.t('reg_taluka'),
                    value: _taluka,
                    items: _talukas,
                    onChanged: (v) {
                      setState(() {
                        _taluka = v;
                        _village = null;
                        _villages = [];
                      });
                      if (v != null) _loadLevel('village', parent: v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _dropdown(
                    label: AppStrings.t('reg_village'),
                    value: _village,
                    items: _villages,
                    onChanged: (v) => setState(() => _village = v),
                  ),
                ],
              ),
            ),
            if (_loadingLoc)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            if (_locError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(AppStrings.t('reg_locations_failed'),
                    style: AppTypography.caption.copyWith(color: AppColors.alertCritical)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(_error!, key: const Key('register_error'),
                    style: AppTypography.caption.copyWith(color: AppColors.alertCritical)),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: AppStrings.t('reg_btn'),
              icon: Icons.person_add_alt_1,
              isLoading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.t('reg_vet_note'),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

