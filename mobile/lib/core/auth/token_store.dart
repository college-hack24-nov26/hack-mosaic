import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage for JWT access/refresh tokens. Tokens never go to SharedPreferences.
abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class TokenKeys {
  TokenKeys._();
  static const access = 'access_token';
  static const refresh = 'refresh_token';
}

/// Android Keystore / iOS Keychain backed storage.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> clear() => _s.deleteAll();
}

/// Used by unit tests only.
class MemoryTokenStore implements TokenStore {
  final Map<String, String> _m = {};

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, String value) async => _m[key] = value;

  @override
  Future<void> clear() async => _m.clear();
}

