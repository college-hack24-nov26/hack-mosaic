import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/auth/api_exception.dart';
import '../core/localization/app_strings.dart';
import '../core/network/api_client.dart';

class RefItem {
  final String key; // code, or id for locations
  final String nameEn;
  final String nameMr;
  final String nameHi;
  final bool isSurveillance;
  const RefItem(this.key, this.nameEn, this.nameMr, this.nameHi, {this.isSurveillance = false});

  String get name {
    switch (AppStrings.currentLang) {
      case 'mr':
        return nameMr.isNotEmpty ? nameMr : nameEn;
      case 'hi':
        return nameHi.isNotEmpty ? nameHi : nameEn;
      default:
        return nameEn;
    }
  }
}

/// Public reference data (API_CONTRACTS.md §4). Unauthenticated, cached in
/// memory. Used by registration (locations) and the vet module (diseases,
/// symptoms).
class ReferenceApi {
  ReferenceApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiClient.baseUrl;

  static ReferenceApi shared = ReferenceApi();

  final http.Client _client;
  final String baseUrl;

  final Map<String, List<RefItem>> _cache = {};

  Future<List<RefItem>> _fetch(String path, Map<String, String> q, RefItem Function(Map<String, dynamic>) map) async {
    final cacheKey = '$path?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final hit = _cache[cacheKey];
    if (hit != null) return hit;
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw ApiException.fromResponse(res);
      final list = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['data'] as List;
      final items = list.whereType<Map>().map((e) => map(Map<String, dynamic>.from(e))).toList();
      return _cache[cacheKey] = items;
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException.network();
    }
  }

  RefItem _byCode(Map<String, dynamic> j) => RefItem(
        j['code'].toString(),
        (j['name_en'] ?? '').toString(),
        (j['name_mr'] ?? '').toString(),
        (j['name_hi'] ?? '').toString(),
        isSurveillance: j['is_surveillance'] == true,
      );

  RefItem _byId(Map<String, dynamic> j) => RefItem(
        j['id'].toString(),
        (j['name_en'] ?? '').toString(),
        (j['name_mr'] ?? '').toString(),
        (j['name_hi'] ?? '').toString(),
      );

  Future<List<RefItem>> locations(String level, {String? parentId}) =>
      _fetch('/reference/locations', {'level': level, if (parentId != null) 'parent_id': parentId}, _byId);

  Future<List<RefItem>> diseases() => _fetch('/reference/diseases', {}, _byCode);
  Future<List<RefItem>> symptoms() => _fetch('/reference/symptoms', {}, _byCode);

  /// Resolves a district id to a display name by walking state → district.
  /// Returns null when it cannot be resolved (never invents a name).
  Future<String?> districtName(String districtId) async {
    try {
      for (final state in await locations('state')) {
        for (final d in await locations('district', parentId: state.key)) {
          if (d.key == districtId) return d.name;
        }
      }
    } catch (_) {}
    return null;
  }

  String diseaseName(String code) {
    for (final e in _cache.entries) {
      if (e.key.startsWith('/reference/diseases')) {
        for (final i in e.value) {
          if (i.key == code) return i.name;
        }
      }
    }
    return AppStrings.formatDisease(code);
  }

  String symptomName(String code) {
    for (final e in _cache.entries) {
      if (e.key.startsWith('/reference/symptoms')) {
        for (final i in e.value) {
          if (i.key == code) return i.name;
        }
      }
    }
    return AppStrings.formatSymptom(code);
  }

  /// Best-effort warm-up; failures are ignored (code-based fallbacks apply).
  Future<void> warmUp() async {
    try {
      await Future.wait([diseases(), symptoms()]);
    } catch (_) {}
  }
}

