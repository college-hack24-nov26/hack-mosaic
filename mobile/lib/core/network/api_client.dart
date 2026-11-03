import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../data/models/animal_model.dart';
import '../../data/models/disease_report_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // USB adb-reverse: localhost, Wi-Fi LAN: 192.168.7.178, Android emulator: 10.0.2.2
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String? _resolvedBaseUrl;

  static String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return 'http://localhost:8080/api/v1';
  }

  /// Probes candidate local endpoints in parallel (USB adb-reverse, Wi-Fi LAN,
  /// Android emulator loopback) and locks onto the first healthy Go backend.
  static Future<void> resolveBestBaseUrl() async {
    final candidates = <String>[
      if (_envBaseUrl.isNotEmpty) _envBaseUrl,
      'http://localhost:8080/api/v1',
      'http://127.0.0.1:8080/api/v1',
      'http://192.168.7.178:8080/api/v1',
      'http://192.168.1.231:8080/api/v1',
      'http://10.0.2.2:8080/api/v1',
    ];
    for (final url in candidates) {
      try {
        final res = await http
            .get(Uri.parse('$url/healthz'))
            .timeout(const Duration(milliseconds: 700));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = url;
          return;
        }
      } catch (_) {}
    }
  }

  String? authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<bool> checkServerHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/healthz')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<AnimalModel>?> fetchAnimals() async {
    if (authToken == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/animals?page=1&page_size=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? const []);
      return list
          .whereType<Map>()
          .map((e) => AnimalModel.fromJson(Map<String, dynamic>.from(e)).copyWith(isSynced: true))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<DiseaseReportModel>?> fetchReports() async {
    if (authToken == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/reports?page=1&page_size=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? const []);
      return list
          .whereType<Map>()
          .map((e) => DiseaseReportModel.fromJson(Map<String, dynamic>.from(e)).copyWith(isSynced: true))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncAnimal(AnimalModel animal) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/animals'),
        headers: _headers,
        body: jsonEncode({
          'id': animal.id,
          'species_code': animal.speciesCode,
          'breed_code': animal.breedCode,
          'name': animal.name,
          'tag_number': animal.tagNumber,
          'sex': animal.sex,
          'birth_date': animal.birthDate,
          'markings': animal.markings,
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncReport(DiseaseReportModel report) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: _headers,
        body: jsonEncode({
          'id': report.id,
          'animal_id': report.animalId,
          'reported_at': report.reportedAt.toUtc().toIso8601String(),
          'description': report.description,
          'description_language': report.descriptionLanguage,
          'symptom_codes': report.symptomCodes,
          'location': report.latitude != null && report.longitude != null
              ? {'lat': report.latitude, 'lng': report.longitude, 'accuracy_m': 10.0}
              : null,
          if (report.villageId != null) 'village_id': report.villageId,
          'expected_image_count': report.photoPath != null ? 1 : 0,
          'screening': report.screening?.toApiJson(),
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadReportImage(String reportId, String filePath, {String? imageId}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/reports/$reportId/images'),
      );
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.fields['id'] = imageId ?? const Uuid().v4();
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedRes = await request.send().timeout(const Duration(seconds: 10));
      return streamedRes.statusCode == 200 || streamedRes.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the live stream of officer-approved outbreak alerts (`GET /api/v1/alerts/live`).
  Future<List<Map<String, dynamic>>> fetchLiveAlerts() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/alerts/live'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode != 200) {
        await resolveBestBaseUrl();
        return const [];
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? const []);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      await resolveBestBaseUrl();
      return const [];
    }
  }
}
