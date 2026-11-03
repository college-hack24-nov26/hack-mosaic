import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/models/me_model.dart';
import '../network/api_client.dart';
import 'api_exception.dart';

class AuthTokens {
  final String access;
  final String refresh;
  const AuthTokens(this.access, this.refresh);
}

/// Thin HTTP layer for API_CONTRACTS.md §3. No state, no token storage.
class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiClient.baseUrl;

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 15);

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException.network();
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    }
  }

  Map<String, dynamic> _data(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.fromResponse(res);
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return Map<String, dynamic>.from((body as Map)['data'] as Map);
  }

  Map<String, String> get _json => {
        'Content-Type': 'application/json',
        'Accept-Language': 'en',
      };

  AuthTokens _tokens(Map<String, dynamic> d) =>
      AuthTokens(d['access_token'].toString(), d['refresh_token'].toString());

  Future<AuthTokens> login(String phone, String password) async {
    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _json,
          body: jsonEncode({'phone': phone, 'password': password}),
        ));
    return _tokens(_data(res));
  }

  Future<AuthTokens> registerFarmer({
    required String phone,
    required String password,
    required String fullName,
    required String preferredLanguage,
    required String villageId,
  }) async {
    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: _json,
          body: jsonEncode({
            'phone': phone,
            'password': password,
            'full_name': fullName,
            'preferred_language': preferredLanguage,
            'village_id': villageId,
          }),
        ));
    return _tokens(_data(res));
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: _json,
          body: jsonEncode({'refresh_token': refreshToken}),
        ));
    return _tokens(_data(res));
  }

  Future<void> logout(String refreshToken) async {
    final res = await _send(() => _client.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _json,
          body: jsonEncode({'refresh_token': refreshToken}),
        ));
    if (res.statusCode != 204 && (res.statusCode < 200 || res.statusCode >= 300)) {
      throw ApiException.fromResponse(res);
    }
  }

  Future<MeProfile> me(String accessToken) async {
    final res = await _send(() => _client.get(
          Uri.parse('$baseUrl/me'),
          headers: {..._json, 'Authorization': 'Bearer $accessToken'},
        ));
    return MeProfile.fromJson(_data(res));
  }
}

