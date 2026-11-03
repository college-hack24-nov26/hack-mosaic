import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
          'reported_at': report.reportedAt.toIso8601String(),
          'description': report.description,
          'symptom_codes': report.symptomCodes,
          'location': report.latitude != null && report.longitude != null
              ? {'lat': report.latitude, 'lng': report.longitude, 'accuracy_m': 10.0}
              : null,
          'expected_image_count': report.photoPath != null ? 1 : 0,
          'screening': report.screening?.toJson(),
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
