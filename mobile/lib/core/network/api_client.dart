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

  // Android emulator: 10.0.2.2, iOS simulator/desktop: localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
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
}
