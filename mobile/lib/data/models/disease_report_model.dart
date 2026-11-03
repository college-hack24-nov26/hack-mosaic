class ScreeningResult {
  final String modelVersion;
  final String topLabel;
  final double topConfidence;
  final bool inconclusive;
  final List<Map<String, dynamic>> scores;
  final DateTime ranAt;
  final String disclaimer;

  ScreeningResult({
    required this.modelVersion,
    required this.topLabel,
    required this.topConfidence,
    required this.inconclusive,
    required this.scores,
    required this.ranAt,
    this.disclaimer = 'preliminary_screening_not_a_diagnosis',
  });

  Map<String, dynamic> toJson() => {
    'model_version': modelVersion,
    'top_label': topLabel,
    'top_confidence': topConfidence,
    'inconclusive': inconclusive,
    'scores': scores,
    'ran_at': ranAt.toUtc().toIso8601String(),
    'disclaimer': disclaimer,
  };

  Map<String, dynamic> toApiJson() => {
    'model_version': modelVersion,
    'top_label': topLabel,
    'top_confidence': topConfidence,
    'inconclusive': inconclusive,
    'scores': scores,
    'ran_at': ranAt.toUtc().toIso8601String(),
  };

  factory ScreeningResult.fromJson(Map<String, dynamic> json) => ScreeningResult(
    modelVersion: json['model_version'] as String? ?? 'mnv3s-2026.11.0',
    topLabel: json['top_label'] as String? ?? 'suspected_skin_lesion',
    topConfidence: (json['top_confidence'] as num?)?.toDouble() ?? 0.0,
    inconclusive: json['inconclusive'] as bool? ?? false,
    scores: (json['scores'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [],
    ranAt: json['ran_at'] != null ? DateTime.parse(json['ran_at'] as String) : DateTime.now(),
    disclaimer: json['disclaimer'] as String? ?? 'preliminary_screening_not_a_diagnosis',
  );
}

class DiseaseReportModel {
  final String id;
  final String animalId;
  final String? animalName;
  final DateTime reportedAt;
  final String? description;
  final String descriptionLanguage;
  final List<String> symptomCodes;
  final double? latitude;
  final double? longitude;
  final String? villageId;
  final String status; // 'submitted', 'under_review', 'confirmed', 'rejected', 'flagged'
  final String? confirmedDiseaseCode;
  final String? vetNotes;
  final String? photoPath;
  final ScreeningResult? screening;
  final bool isSynced;

  DiseaseReportModel({
    required this.id,
    required this.animalId,
    this.animalName,
    required this.reportedAt,
    this.description,
    this.descriptionLanguage = 'mr',
    required this.symptomCodes,
    this.latitude,
    this.longitude,
    this.villageId,
    this.status = 'submitted',
    this.confirmedDiseaseCode,
    this.vetNotes,
    this.photoPath,
    this.screening,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'animal_id': animalId,
    'animal_name': animalName,
    'reported_at': reportedAt.toUtc().toIso8601String(),
    'description': description,
    'description_language': descriptionLanguage,
    'symptom_codes': symptomCodes,
    'latitude': latitude,
    'longitude': longitude,
    'village_id': villageId,
    'status': status,
    'confirmed_disease_code': confirmedDiseaseCode,
    'vet_notes': vetNotes,
    'photo_path': photoPath,
    'screening': screening?.toJson(),
    'is_synced': isSynced,
  };

  factory DiseaseReportModel.fromJson(Map<String, dynamic> json) {
    final animalMap = json['animal'] is Map ? Map<String, dynamic>.from(json['animal'] as Map) : null;
    final locationMap = json['location'] is Map ? Map<String, dynamic>.from(json['location'] as Map) : null;
    final verificationMap = json['verification'] is Map ? Map<String, dynamic>.from(json['verification'] as Map) : null;

    return DiseaseReportModel(
      id: json['id'] as String,
      animalId: (json['animal_id'] ?? animalMap?['id'] ?? '') as String,
      animalName: (json['animal_name'] ?? animalMap?['name']) as String?,
      reportedAt: json['reported_at'] != null ? DateTime.parse(json['reported_at'] as String) : DateTime.now(),
      description: json['description'] as String?,
      descriptionLanguage: json['description_language'] as String? ?? 'mr',
      symptomCodes: (json['symptom_codes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      latitude: ((json['latitude'] ?? locationMap?['lat']) as num?)?.toDouble(),
      longitude: ((json['longitude'] ?? locationMap?['lng']) as num?)?.toDouble(),
      villageId: json['village_id'] as String?,
      status: json['status'] as String? ?? 'submitted',
      confirmedDiseaseCode: (json['confirmed_disease_code'] ?? verificationMap?['disease_code']) as String?,
      vetNotes: (json['vet_notes'] ?? verificationMap?['notes']) as String?,
      photoPath: json['photo_path'] as String?,
      screening: json['screening'] != null
          ? ScreeningResult.fromJson(Map<String, dynamic>.from(json['screening'] as Map))
          : null,
      isSynced: json['is_synced'] as bool? ?? (animalMap != null),
    );
  }

  DiseaseReportModel copyWith({
    String? status,
    String? confirmedDiseaseCode,
    String? vetNotes,
    bool? isSynced,
  }) {
    return DiseaseReportModel(
      id: id,
      animalId: animalId,
      animalName: animalName,
      reportedAt: reportedAt,
      description: description,
      descriptionLanguage: descriptionLanguage,
      symptomCodes: symptomCodes,
      latitude: latitude,
      longitude: longitude,
      villageId: villageId,
      status: status ?? this.status,
      confirmedDiseaseCode: confirmedDiseaseCode ?? this.confirmedDiseaseCode,
      vetNotes: vetNotes ?? this.vetNotes,
      photoPath: photoPath,
      screening: screening,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

