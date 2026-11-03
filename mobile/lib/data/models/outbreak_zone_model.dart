class OutbreakZoneModel {
  final String id;
  final String diseaseCode;
  final String diseaseName;
  final String status; // 'confirmed' or 'suspected'
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int caseCount;
  final DateTime detectedAt;
  final String advisory;

  const OutbreakZoneModel({
    required this.id,
    required this.diseaseCode,
    required this.diseaseName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.caseCount,
    required this.detectedAt,
    required this.advisory,
  });

  bool get isConfirmed => status == 'confirmed';

  Map<String, dynamic> toJson() => {
    'id': id,
    'disease_code': diseaseCode,
    'disease_name': diseaseName,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
    'radius_meters': radiusMeters,
    'case_count': caseCount,
    'detected_at': detectedAt.toIso8601String(),
    'advisory': advisory,
  };

  factory OutbreakZoneModel.fromJson(Map<String, dynamic> json) => OutbreakZoneModel(
    id: json['id'] as String,
    diseaseCode: json['disease_code'] as String,
    diseaseName: json['disease_name'] as String,
    status: json['status'] as String? ?? 'confirmed',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 3000.0,
    caseCount: json['case_count'] as int? ?? 1,
    detectedAt: json['detected_at'] != null
        ? DateTime.parse(json['detected_at'] as String)
        : DateTime.now(),
    advisory: json['advisory'] as String? ?? '',
  );
}

class DiseaseCasePin {
  final String id;
  final String reportId;
  final String diseaseCode;
  final double latitude;
  final double longitude;
  final DateTime confirmedAt;
  final String species;
  final bool isConfirmed;

  const DiseaseCasePin({
    required this.id,
    required this.reportId,
    required this.diseaseCode,
    required this.latitude,
    required this.longitude,
    required this.confirmedAt,
    this.species = 'cattle',
    this.isConfirmed = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_id': reportId,
    'disease_code': diseaseCode,
    'latitude': latitude,
    'longitude': longitude,
    'confirmed_at': confirmedAt.toIso8601String(),
    'species': species,
    'is_confirmed': isConfirmed,
  };

  factory DiseaseCasePin.fromJson(Map<String, dynamic> json) => DiseaseCasePin(
    id: json['id'] as String,
    reportId: json['report_id'] as String,
    diseaseCode: json['disease_code'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    confirmedAt: json['confirmed_at'] != null
        ? DateTime.parse(json['confirmed_at'] as String)
        : DateTime.now(),
    species: json['species'] as String? ?? 'cattle',
    isConfirmed: json['is_confirmed'] as bool? ?? true,
  );
}

