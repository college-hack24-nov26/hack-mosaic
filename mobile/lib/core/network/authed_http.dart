import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/api_exception.dart';
import '../auth/session_manager.dart';
import 'api_client.dart';

/// Authenticated JSON client: adds the Bearer token, transparently refreshes
/// once on `401`, and ends the session if the refresh fails. Errors use the
/// standard envelope via [ApiException]. Never logs request/response bodies.
class AuthedHttp {
  AuthedHttp({SessionManager? session, http.Client? client, String? baseUrl})
      : _session = session,
        _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiClient.baseUrl;

  final SessionManager? _session;
  final http.Client _client;
  final String baseUrl;

  SessionManager get session => _session ?? SessionManager.instance;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, Map<String, String?>? query) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) q[k] = v;
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<http.Response> _once(String method, Uri uri, String token, Object? body) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    try {
      final Future<http.Response> f = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
        'PATCH' => _client.patch(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
        _ => throw ArgumentError(method),
      };
      return await f.timeout(_timeout);
    } on TimeoutException {
      throw const ApiException.network();
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    }
  }

  Future<http.Response> send(String method, String path,
      {Map<String, String?>? query, Object? body}) async {
    final uri = _uri(path, query);
    var res = await _once(method, uri, await session.validAccessToken(), body);
    if (res.statusCode == 401) {
      final ok = await session.refreshTokens();
      if (!ok) throw const ApiException.unauthenticated();
      res = await _once(method, uri, await session.validAccessToken(), body);
      if (res.statusCode == 401) {
        await session.expire();
        throw const ApiException.unauthenticated();
      }
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.fromResponse(res);
    }
    return res;
  }

  dynamic _decode(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  /// `{ "data": ... }` → data
  Future<dynamic> getData(String path, {Map<String, String?>? query}) async =>
      (_decode(await send('GET', path, query: query)) as Map)['data'];

  /// Full body (lists need `meta`; GeoJSON has no envelope).
  Future<Map<String, dynamic>> getBody(String path, {Map<String, String?>? query}) async =>
      Map<String, dynamic>.from(_decode(await send('GET', path, query: query)) as Map);

  Future<dynamic> postData(String path, Object body) async {
    final res = await send('POST', path, body: body);
    if (res.statusCode == 204 || res.bodyBytes.isEmpty) return null;
    return (_decode(res) as Map)['data'];
  }

  /// Headers for authenticated image loading (`Image.network(headers: ...)`).
  Future<Map<String, String>> imageHeaders() async =>
      {'Authorization': 'Bearer ${await session.validAccessToken()}'};

  String absoluteUrl(String path) {
    if (path.startsWith('http')) return path;
    // contract returns "/api/v1/reports/..."; baseUrl already ends in /api/v1
    final origin = Uri.parse(baseUrl).replace(path: '', query: null).toString();
    return '$origin$path';
  }
}

