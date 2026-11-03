import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_strings.dart';
import '../../data/local/offline_store.dart';
import '../../data/models/me_model.dart';
import '../../data/models/user_model.dart';
import '../network/api_client.dart';
import 'api_exception.dart';
import 'auth_api.dart';
import 'token_store.dart';

enum SessionStatus {
  loading,
  unauthenticated,
  farmer,

  /// Local, clearly-labelled synthetic data. Never grants vet access.
  demoFarmer,
  vet,

  /// Local, clearly-labelled synthetic veterinarian data for offline demos.
  demoVet,
  vetPending,
  restricted,
}

/// Central session / role manager.
///
/// The role is **always** taken from the server's `GET /me`; it is never
/// chosen in the UI. Client-side gating here is UX only: the backend enforces
/// every authorisation decision (API_CONTRACTS.md §1.3, SECURITY.md §2).
class SessionManager extends ChangeNotifier {
  SessionManager({AuthApi? api, TokenStore? tokens})
      : _api = api ?? AuthApi(),
        _tokens = tokens ?? SecureTokenStore();

  static SessionManager instance = SessionManager();

  final AuthApi _api;
  final TokenStore _tokens;

  static const _prefDemo = 'demo_mode';
  static const _prefLastRole = 'last_verified_role';

  SessionStatus _status = SessionStatus.loading;
  MeProfile? _me;
  String? _access;
  String? _refresh;
  String? _restrictedReason; // disabled | rejected | unsupported_role
  bool _sessionExpired = false;
  bool _serverUnreachable = false;
  Future<bool>? _refreshing;

  SessionStatus get status => _status;
  MeProfile? get me => _me;
  String? get restrictedReason => _restrictedReason;
  bool get sessionExpired => _sessionExpired;
  bool get serverUnreachable => _serverUnreachable;
  bool get isAuthenticated => _access != null;
  bool get isFarmerSession => _status == SessionStatus.farmer || _status == SessionStatus.demoFarmer;
  bool get isDemo => _status == SessionStatus.demoFarmer || _status == SessionStatus.demoVet;

  /// True only for an active veterinarian (server-verified or synthetic demo).
  bool get isVerifiedVet =>
      (_status == SessionStatus.vet || _status == SessionStatus.demoVet) && (_me?.isVet ?? false);

  void _set(SessionStatus s) {
    _status = s;
    notifyListeners();
  }

  // ---------------------------------------------------------------- restore

  Future<void> restore() async {
    _status = SessionStatus.loading;
    _serverUnreachable = false;
    _access = await _tokens.read(TokenKeys.access);
    _refresh = await _tokens.read(TokenKeys.refresh);
    final prefs = await SharedPreferences.getInstance();

    if (_access == null && _refresh == null) {
      final demoMode = prefs.getString(_prefDemo);
      if (demoMode == 'vet') {
        await enterDemoVet();
        return;
      }
      if (demoMode == 'farmer' || prefs.getBool(_prefDemo) == true) {
        _set(SessionStatus.demoFarmer);
        return;
      }
      _set(SessionStatus.unauthenticated);
      return;
    }

    try {
      final me = await _fetchMe();
      await _apply(me);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        // Offline-first: a previously verified *farmer* may keep using the
        // data already on this device. Vet features need the server.
        _serverUnreachable = true;
        final lastRole = prefs.getString(_prefLastRole);
        if (lastRole == 'farmer' && OfflineStore().currentUser != null) {
          ApiClient().authToken = _access;
          _set(SessionStatus.farmer);
        } else {
          _set(SessionStatus.unauthenticated);
        }
      } else if (e.isForbidden) {
        _restrictedReason = 'disabled';
        _set(SessionStatus.restricted);
      } else {
        await expire();
      }
    }
  }

  // ------------------------------------------------------------ login / reg

  /// [requireRole] lets the vet login screen refuse non-vet accounts. The
  /// role itself still comes from the server.
  Future<void> login(String phone, String password, {String? requireRole}) async {
    final t = await _api.login(phone, password);
    await _finishAuth(t, requireRole: requireRole);
  }

  Future<void> registerFarmer({
    required String phone,
    required String password,
    required String fullName,
    required String preferredLanguage,
    required String villageId,
  }) async {
    final t = await _api.registerFarmer(
      phone: phone,
      password: password,
      fullName: fullName,
      preferredLanguage: preferredLanguage,
      villageId: villageId,
    );
    await _finishAuth(t, requireRole: 'farmer');
  }

  Future<void> _finishAuth(AuthTokens t, {String? requireRole}) async {
    await _setTokens(t);
    try {
      final me = await _fetchMe();
      if (requireRole != null && me.role != requireRole) {
        await logout();
        throw const ApiException(status: 403, code: 'ROLE_MISMATCH');
      }
      _sessionExpired = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefDemo);
      await _apply(me);
    } on ApiException catch (e) {
      if (e.code == 'ROLE_MISMATCH') rethrow;
      // /me failed right after a successful login: do not keep a half session.
      await _clearLocal();
      _set(SessionStatus.unauthenticated);
      rethrow;
    }
  }

  Future<MeProfile> _fetchMe() async {
    try {
      return await _api.me(_access!);
    } on ApiException catch (e) {
      if (!e.isUnauthenticated) rethrow;
      final ok = await refreshTokens();
      if (!ok) throw const ApiException.unauthenticated();
      return _api.me(_access!);
    }
  }

  Future<void> _apply(MeProfile me) async {
    _me = me;
    _restrictedReason = null;
    ApiClient().authToken = _access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLastRole, me.role);
    final store = OfflineStore();

    switch (me.role) {
      case 'farmer':
        if (store.currentUser?.id != me.id) {
          await store.startSessionFor(UserModel(
            id: me.id,
            phone: me.phone,
            fullName: me.fullName,
            role: 'farmer',
            villageId: me.villageId ?? '',
            farmName: me.farmName,
            latitude: me.farmLat,
            longitude: me.farmLng,
            alertConsent: me.alertConsent,
          ));
        }
        _set(SessionStatus.farmer);
      case 'vet':
        // A vet device must not retain any farmer's personal data.
        await store.clearProtectedData();
        switch (me.accountStatus) {
          case null:
          case 'active':
            _set(SessionStatus.vet);
          case 'pending_verification':
            _set(SessionStatus.vetPending);
          case 'rejected':
            _restrictedReason = 'rejected';
            _set(SessionStatus.restricted);
          default:
            _restrictedReason = 'disabled';
            _set(SessionStatus.restricted);
        }
      default:
        _restrictedReason = 'unsupported_role';
        _set(SessionStatus.restricted);
    }
  }

  // ---------------------------------------------------------------- tokens

  Future<void> _setTokens(AuthTokens t) async {
    _access = t.access;
    _refresh = t.refresh;
    ApiClient().authToken = _access;
    await _tokens.write(TokenKeys.access, t.access);
    await _tokens.write(TokenKeys.refresh, t.refresh);
  }

  Future<String> validAccessToken() async {
    final t = _access;
    if (t == null) throw const ApiException.unauthenticated();
    return t;
  }

  /// Single-flight refresh. Returns false when the session is dead (the
  /// session is then expired); throws a network [ApiException] when offline.
  Future<bool> refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final rt = _refresh;
    if (rt == null) {
      await expire();
      return false;
    }
    try {
      final t = await _api.refresh(rt);
      await _setTokens(t);
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) rethrow;
      await expire();
      return false;
    }
  }

  // ---------------------------------------------------------------- logout

  /// Revokes the refresh token server-side (best effort), then clears tokens
  /// and every protected cache on this device.
  Future<void> logout() async {
    final rt = _refresh;
    if (rt != null) {
      try {
        await _api.logout(rt);
      } catch (_) {
        // Offline: local session is still cleared below.
      }
    }
    await _clearLocal();
    _sessionExpired = false;
    _set(SessionStatus.unauthenticated);
  }

  /// Called when the server rejects the session and it cannot be refreshed.
  Future<void> expire() async {
    await _clearLocal();
    _sessionExpired = true;
    _set(SessionStatus.unauthenticated);
  }

  Future<void> _clearLocal() async {
    _access = null;
    _refresh = null;
    _me = null;
    _refreshing = null;
    ApiClient().authToken = null;
    await _tokens.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefLastRole);
    await prefs.remove(_prefDemo);
    await OfflineStore().clearProtectedData();
  }

  // ------------------------------------------------------------------ demo

  /// Local synthetic farmer data for offline demos. Grants no server access
  /// and can never open veterinarian screens.
  Future<void> enterDemo() async {
    await _clearLocal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDemo, 'farmer');
    await OfflineStore().initialize(); // re-seeds the synthetic demo farmer
    _sessionExpired = false;
    _set(SessionStatus.demoFarmer);
  }

  /// Local synthetic veterinarian profile for offline demonstration.
  /// Clearly labelled as demonstration data.
  Future<void> enterDemoVet() async {
    await _clearLocal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDemo, 'vet');
    _me = MeProfile(
      id: 'vet-phaltan-01',
      phone: '+919822012345',
      fullName: 'Dr. Vikram Deshmukh',
      role: 'vet',
      accountStatus: 'active',
      preferredLanguage: AppStrings.currentLang,
      districtId: 'satara',
      districtName: 'Satara',
      talukaId: 'phaltan',
      talukaName: 'Phaltan',
      clinicName: 'Phaltan Taluka Veterinary Polyclinic',
      registrationNumber: 'MSVC-2018-04921',
      qualification: 'B.V.Sc & A.H., M.V.Sc (Pathology)',
      isParaVet: false,
    );
    _sessionExpired = false;
    _set(SessionStatus.demoVet);
  }

  /// Test hook.
  @visibleForTesting
  static void resetForTest({AuthApi? api, TokenStore? tokens}) {
    instance = SessionManager(api: api, tokens: tokens ?? MemoryTokenStore());
  }
}

