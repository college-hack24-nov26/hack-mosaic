library vet_models;

/// Models for the veterinarian module. Field names follow
/// API_CONTRACTS.md §5.5, §6 and §7.2 exactly (snake_case on the wire).

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
Map<String, dynamic>? _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;
List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class ReportAnimal {
  final String id;
  final String? name;
  final String speciesCode;
  final String? breedCode;
  final String? tagNumber;
  const ReportAnimal({required this.id, this.name, required this.speciesCode, this.breedCode, this.tagNumber});

  factory ReportAnimal.fromJson(Map<String, dynamic> j) => ReportAnimal(
        id: j['id'].toString(),
        name: j['name']?.toString(),
        speciesCode: (j['species_code'] ?? '').toString(),
        breedCode: j['breed_code']?.toString(),
        tagNumber: j['tag_number']?.toString(),
      );
}

class ReportFarmer {
  final String id;
  final String fullName;
  final String? phone;
  const ReportFarmer({required this.id, required this.fullName, this.phone});

  factory ReportFarmer.fromJson(Map<String, dynamic> j) => ReportFarmer(
        id: j['id'].toString(),
        fullName: (j['full_name'] ?? '').toString(),
        phone: j['phone']?.toString(),
      );
}

class ReportLocation {
  final double lat;
  final double lng;
  final double? accuracyM;
  final String source; // gps | village_centroid
  const ReportLocation({required this.lat, required this.lng, this.accuracyM, required this.source});

  factory ReportLocation.fromJson(Map<String, dynamic> j) => ReportLocation(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accuracyM: (j['accuracy_m'] as num?)?.toDouble(),
        source: (j['source'] ?? 'gps').toString(),
      );
}

/// MobileNetV3 on-device observation. Preliminary decision support only.
class ReportScreening {
  final String modelVersion;
  final String topLabel;
  final double? topConfidence; // shown only when the model provided it
  final bool inconclusive;
  final DateTime? ranAt;
  const ReportScreening({
    required this.modelVersion,
    required this.topLabel,
    this.topConfidence,
    this.inconclusive = false,
    this.ranAt,
  });

  factory ReportScreening.fromJson(Map<String, dynamic> j) => ReportScreening(
        modelVersion: (j['model_version'] ?? '').toString(),
        topLabel: (j['top_label'] ?? '').toString(),
        topConfidence: (j['top_confidence'] as num?)?.toDouble(),
        inconclusive: j['inconclusive'] == true,
        ranAt: _dt(j['ran_at']),
      );
}

class ReportImage {
  final String id;
  final String url; // path like /api/v1/reports/<id>/images/<image_id>
  const ReportImage({required this.id, required this.url});
  factory ReportImage.fromJson(Map<String, dynamic> j) =>
      ReportImage(id: j['id'].toString(), url: (j['url'] ?? '').toString());
}

class ReportVerification {
  final String id;
  final String decision; // confirmed | rejected | flagged
  final String? diseaseCode;
  final String? notes;
  final bool visitRequired;
  final String? vetName;
  final DateTime? decidedAt;
  const ReportVerification({
    required this.id,
    required this.decision,
    this.diseaseCode,
    this.notes,
    this.visitRequired = false,
    this.vetName,
    this.decidedAt,
  });

  factory ReportVerification.fromJson(Map<String, dynamic> j) => ReportVerification(
        id: j['id'].toString(),
        decision: (j['decision'] ?? '').toString(),
        diseaseCode: j['disease_code']?.toString(),
        notes: j['notes']?.toString(),
        visitRequired: j['visit_required'] == true,
        vetName: _map(j['vet'])?['full_name']?.toString(),
        decidedAt: _dt(j['decided_at']),
      );
}

class VetReport {
  final String id;
  final ReportAnimal animal;
  final ReportFarmer? farmer;
  final DateTime reportedAt;
  final DateTime? receivedAt;
  final String? description;
  final List<String> symptomCodes;
  final ReportLocation? location;
  final String? villageId;
  final String? talukaId;
  final String? districtId;
  final String status; // submitted | under_review | confirmed | rejected | flagged
  final ReportScreening? screening;
  final List<ReportImage> images;
  final bool imagesPending;
  final ReportVerification? verification;

  const VetReport({
    required this.id,
    required this.animal,
    this.farmer,
    required this.reportedAt,
    this.receivedAt,
    this.description,
    this.symptomCodes = const [],
    this.location,
    this.villageId,
    this.talukaId,
    this.districtId,
    required this.status,
    this.screening,
    this.images = const [],
    this.imagesPending = false,
    this.verification,
  });

  bool get isPending => status == 'submitted' || status == 'under_review';

  VetReport copyWith({
    String? status,
    ReportVerification? verification,
    bool? imagesPending,
  }) =>
      VetReport(
        id: id,
        animal: animal,
        farmer: farmer,
        reportedAt: reportedAt,
        receivedAt: receivedAt,
        description: description,
        symptomCodes: symptomCodes,
        location: location,
        villageId: villageId,
        talukaId: talukaId,
        districtId: districtId,
        status: status ?? this.status,
        screening: screening,
        images: images,
        imagesPending: imagesPending ?? this.imagesPending,
        verification: verification ?? this.verification,
      );

  factory VetReport.fromJson(Map<String, dynamic> j) => VetReport(
        id: j['id'].toString(),
        animal: ReportAnimal.fromJson(_map(j['animal']) ?? {'id': '', 'species_code': ''}),
        farmer: _map(j['farmer']) == null ? null : ReportFarmer.fromJson(_map(j['farmer'])!),
        reportedAt: _dt(j['reported_at']) ?? DateTime.now(),
        receivedAt: _dt(j['received_at']),
        description: j['description']?.toString(),
        symptomCodes: (j['symptom_codes'] as List? ?? const []).map((e) => e.toString()).toList(),
        location: _map(j['location']) == null ? null : ReportLocation.fromJson(_map(j['location'])!),
        villageId: j['village_id']?.toString(),
        talukaId: j['taluka_id']?.toString(),
        districtId: j['district_id']?.toString(),
        status: (j['status'] ?? 'submitted').toString(),
        screening: _map(j['screening']) == null ? null : ReportScreening.fromJson(_map(j['screening'])!),
        images: _list(j['images']).map(ReportImage.fromJson).toList(),
        imagesPending: j['images_pending'] == true,
        verification: _map(j['verification']) == null ? null : ReportVerification.fromJson(_map(j['verification'])!),
      );
}

class ReportPage {
  final List<VetReport> items;
  final int total;
  const ReportPage(this.items, this.total);
}

class SummaryTotals {
  final int reports, pending, confirmed, rejected, flagged;
  const SummaryTotals({
    this.reports = 0,
    this.pending = 0,
    this.confirmed = 0,
    this.rejected = 0,
    this.flagged = 0,
  });

  factory SummaryTotals.fromJson(Map<String, dynamic> j) {
    final t = _map(j['totals']) ?? {};
    int n(String k) => (t[k] as num?)?.toInt() ?? 0;
    return SummaryTotals(
      reports: n('reports'),
      pending: n('pending'),
      confirmed: n('confirmed'),
      rejected: n('rejected'),
      flagged: n('flagged'),
    );
  }
}

class RecordItem {
  final Map<String, dynamic> raw;
  const RecordItem(this.raw);
  String? s(String k) => raw[k]?.toString();
}

/// `GET /animals/{id}/record` (API_CONTRACTS.md §5.5)
class AnimalRecord {
  final ReportAnimalFull animal;
  final List<RecordItem> healthRecords;
  final List<RecordItem> vaccinations;
  final List<RecordItem> treatments;
  final List<RecordItem> recentReports;
  final DateTime? generatedAt;

  const AnimalRecord({
    required this.animal,
    this.healthRecords = const [],
    this.vaccinations = const [],
    this.treatments = const [],
    this.recentReports = const [],
    this.generatedAt,
  });

  factory AnimalRecord.fromJson(Map<String, dynamic> j) => AnimalRecord(
        animal: ReportAnimalFull.fromJson(_map(j['animal']) ?? {}),
        healthRecords: _list(j['health_records']).map(RecordItem.new).toList(),
        vaccinations: _list(j['vaccinations']).map(RecordItem.new).toList(),
        treatments: _list(j['treatments']).map(RecordItem.new).toList(),
        recentReports: _list(j['recent_reports']).map(RecordItem.new).toList(),
        generatedAt: _dt(j['generated_at']),
      );
}

class ReportAnimalFull {
  final String id;
  final String speciesCode;
  final String? breedCode;
  final String? name;
  final String? tagNumber;
  final String? sex;
  final String? birthDate;
  final String? markings;
  const ReportAnimalFull({
    required this.id,
    required this.speciesCode,
    this.breedCode,
    this.name,
    this.tagNumber,
    this.sex,
    this.birthDate,
    this.markings,
  });

  factory ReportAnimalFull.fromJson(Map<String, dynamic> j) => ReportAnimalFull(
        id: (j['id'] ?? '').toString(),
        speciesCode: (j['species_code'] ?? '').toString(),
        breedCode: j['breed_code']?.toString(),
        name: j['name']?.toString(),
        tagNumber: j['tag_number']?.toString(),
        sex: j['sex']?.toString(),
        birthDate: j['birth_date']?.toString(),
        markings: j['markings']?.toString(),
      );
}

class CasePoint {
  final String reportId;
  final String diseaseCode;
  final DateTime? confirmedAt;
  final double lat;
  final double lng;
  const CasePoint({
    required this.reportId,
    required this.diseaseCode,
    this.confirmedAt,
    required this.lat,
    required this.lng,
  });
}

