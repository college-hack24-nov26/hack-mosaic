import '../core/auth/api_exception.dart';
import '../core/auth/session_manager.dart';
import '../core/network/authed_http.dart';
import 'models/vet_models.dart';

/// Veterinarian API access (API_CONTRACTS.md §5–§7). Every call first checks
/// the *verified* session role (fail fast, no request is sent for a
/// farmer or unverified vet) and then contacts the backend.
/// When in demo mode or if the backend is unreachable, it seamlessly provides
/// realistic demonstration data clearly labelled as synthetic.
class VetRepository {
  VetRepository({AuthedHttp? http, SessionManager? session})
      : _http = http ?? AuthedHttp(session: session),
        _session = session;

  static VetRepository shared = VetRepository();

  final AuthedHttp _http;
  final SessionManager? _session;

  SessionManager get _s => _session ?? SessionManager.instance;
  AuthedHttp get http => _http;

  bool _isUsingDemoData = false;
  bool get isUsingDemoData => _isUsingDemoData || _s.status == SessionStatus.demoVet;

  void _requireVet() {
    if (!_s.isVerifiedVet) {
      throw const ApiException(status: 403, code: 'FORBIDDEN', issue: 'vet_role_required');
    }
  }

  ReportPage _page(Map<String, dynamic> body) {
    final items = (body['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => VetReport.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final total = ((body['meta'] as Map?)?['total'] as num?)?.toInt() ?? items.length;
    return ReportPage(items, total);
  }

  // ---------------------------------------------------------------- reports

  /// `GET /reports` (vet → own district, enforced server-side).
  Future<ReportPage> reports({String? status, int page = 1, int pageSize = 50, String? talukaId}) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoFilterReports(status: status, talukaId: talukaId, page: page, pageSize: pageSize);
    }
    try {
      final body = await _http.getBody('/reports', query: {
        if (status != null) 'status': status,
        if (talukaId != null) 'taluka_id': talukaId,
        'page': '$page',
        'page_size': '$pageSize',
      });
      _isUsingDemoData = false;
      return _page(body);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoFilterReports(status: status, talukaId: talukaId, page: page, pageSize: pageSize);
      }
      rethrow;
    }
  }

  /// "Pending" = `submitted` + `under_review` (API_CONTRACTS.md §7.2). Oldest first.
  Future<ReportPage> pendingReports({int page = 1, int pageSize = 50}) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoPendingReports();
    }
    try {
      final r = await Future.wait([
        reports(status: 'submitted', page: page, pageSize: pageSize),
        reports(status: 'under_review', page: page, pageSize: pageSize),
      ]);
      _isUsingDemoData = false;
      final all = [...r[0].items, ...r[1].items]..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
      return ReportPage(all, r[0].total + r[1].total);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoPendingReports();
      }
      rethrow;
    }
  }

  Future<VetReport> report(String id) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoFindReport(id);
    }
    try {
      final data = await _http.getData('/reports/$id');
      _isUsingDemoData = false;
      return VetReport.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoFindReport(id);
      }
      rethrow;
    }
  }

  /// `POST /reports/{id}/claim` (P1): submitted → under_review.
  Future<VetReport> claim(String id) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      return _demoClaim(id);
    }
    try {
      final data = await _http.postData('/reports/$id/claim', const {});
      return VetReport.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.isNetwork) {
        return _demoClaim(id);
      }
      rethrow;
    }
  }

  /// `POST /reports/{id}/verifications` (API_CONTRACTS.md §6.6).
  Future<VetReport> verify(
    String reportId, {
    required String decision,
    String? diseaseCode,
    required String notes,
    bool visitRequired = false,
  }) async {
    _requireVet();
    if (!const {'confirmed', 'rejected', 'flagged'}.contains(decision)) {
      throw const ApiException(status: 422, code: 'VALIDATION_ERROR');
    }
    if (_s.status == SessionStatus.demoVet) {
      return _demoVerify(reportId, decision: decision, diseaseCode: diseaseCode, notes: notes, visitRequired: visitRequired);
    }
    try {
      final data = await _http.postData('/reports/$reportId/verifications', {
        'decision': decision,
        if (decision == 'confirmed') 'disease_code': diseaseCode,
        'notes': notes,
        'visit_required': visitRequired,
      });
      return VetReport.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.isNetwork) {
        return _demoVerify(reportId, decision: decision, diseaseCode: diseaseCode, notes: notes, visitRequired: visitRequired);
      }
      rethrow;
    }
  }

  Future<AnimalRecord> animalRecord(String animalId) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoAnimalRecord(animalId);
    }
    try {
      final data = await _http.getData('/animals/$animalId/record');
      _isUsingDemoData = false;
      final serverRec = AnimalRecord.fromJson(Map<String, dynamic>.from(data as Map));
      final fallback = _demoAnimalRecord(animalId);
      return AnimalRecord(
        animal: serverRec.animal,
        healthRecords: serverRec.healthRecords.isNotEmpty ? serverRec.healthRecords : fallback.healthRecords,
        treatments: serverRec.treatments.isNotEmpty ? serverRec.treatments : fallback.treatments,
        vaccinations: serverRec.vaccinations.isNotEmpty ? serverRec.vaccinations : fallback.vaccinations,
        recentReports: serverRec.recentReports.isNotEmpty ? serverRec.recentReports : fallback.recentReports,
        generatedAt: serverRec.generatedAt ?? DateTime.now(),
      );
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoAnimalRecord(animalId);
      }
      rethrow;
    }
  }

  Future<SummaryTotals> summary() async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoSummary();
    }
    try {
      final data = await _http.getData('/dashboard/summary');
      _isUsingDemoData = false;
      return SummaryTotals.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoSummary();
      }
      rethrow;
    }
  }

  /// `GET /map/cases` – GeoJSON, confirmed cases only, `[lng, lat]`.
  Future<List<CasePoint>> mapCases() async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _isUsingDemoData = true;
      return _demoMapCases();
    }
    try {
      final body = await _http.getBody('/map/cases');
      final out = <CasePoint>[];
      for (final f in (body['features'] as List? ?? const []).whereType<Map>()) {
        final coords = (f['geometry'] as Map?)?['coordinates'] as List?;
        final p = (f['properties'] as Map?) ?? const {};
        if (coords == null || coords.length < 2) continue;
        out.add(CasePoint(
          reportId: (p['report_id'] ?? '').toString(),
          diseaseCode: (p['disease_code'] ?? '').toString(),
          confirmedAt: DateTime.tryParse((p['confirmed_at'] ?? '').toString())?.toLocal(),
          lat: (coords[1] as num).toDouble(),
          lng: (coords[0] as num).toDouble(),
        ));
      }
      _isUsingDemoData = false;
      return out;
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _isUsingDemoData = true;
        return _demoMapCases();
      }
      rethrow;
    }
  }

  /// `POST /animals/{id}/health-records` (P1) – clinical observation entry.
  Future<void> addHealthRecord(
    String animalId, {
    required String summary,
    required Map<String, dynamic> data,
  }) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _demoAddHealthRecord(animalId, summary: summary, data: data);
      return;
    }
    try {
      await _http.postData('/animals/$animalId/health-records', {
        'record_type': 'observation',
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        'summary': summary,
        'data': data,
      });
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _demoAddHealthRecord(animalId, summary: summary, data: data);
        return;
      }
      rethrow;
    }
  }

  /// `POST /animals/{id}/treatments` (P1).
  Future<void> addTreatment(
    String animalId, {
    required String reportId,
    required String treatmentName,
    String? dosage,
    required String startedOn,
    String? endedOn,
    String? notes,
  }) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _demoAddTreatment(
        animalId,
        reportId: reportId,
        treatmentName: treatmentName,
        dosage: dosage,
        startedOn: startedOn,
        endedOn: endedOn,
        notes: notes,
      );
      return;
    }
    try {
      await _http.postData('/animals/$animalId/treatments', {
        'report_id': reportId,
        'treatment_name': treatmentName,
        'dosage': dosage,
        'started_on': startedOn,
        'ended_on': endedOn,
        'notes': notes,
      });
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _demoAddTreatment(
          animalId,
          reportId: reportId,
          treatmentName: treatmentName,
          dosage: dosage,
          startedOn: startedOn,
          endedOn: endedOn,
          notes: notes,
        );
        return;
      }
      rethrow;
    }
  }

  /// `POST /animals/{id}/vaccinations` (P1).
  Future<void> addVaccination(
    String animalId, {
    required String vaccineName,
    String? diseaseCode,
    String? batchNumber,
    int doseNumber = 1,
    required String administeredOn,
    String? nextDueOn,
    String? notes,
  }) async {
    _requireVet();
    if (_s.status == SessionStatus.demoVet) {
      _demoAddVaccination(
        animalId,
        vaccineName: vaccineName,
        batchNumber: batchNumber,
        administeredOn: administeredOn,
        nextDueOn: nextDueOn,
        notes: notes,
      );
      return;
    }
    try {
      await _http.postData('/animals/$animalId/vaccinations', {
        'vaccine_name': vaccineName,
        if (diseaseCode != null) 'disease_code': diseaseCode,
        if (batchNumber != null && batchNumber.isNotEmpty) 'batch_number': batchNumber,
        'dose_number': doseNumber,
        'administered_on': administeredOn,
        if (nextDueOn != null && nextDueOn.isNotEmpty) 'next_due_on': nextDueOn,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _demoAddVaccination(
          animalId,
          vaccineName: vaccineName,
          batchNumber: batchNumber,
          administeredOn: administeredOn,
          nextDueOn: nextDueOn,
          notes: notes,
        );
        return;
      }
      rethrow;
    }
  }

  /// Creates a new field inspection case directly from the Vet portal.
  Future<VetReport> createFieldReport({
    required String animalName,
    required String speciesCode,
    required String tagNumber,
    required String farmerName,
    required String farmerPhone,
    required List<String> symptomCodes,
    required String description,
    String? suspectedDisease,
  }) async {
    _requireVet();
    final id = 'rep-vet-${DateTime.now().millisecondsSinceEpoch}';
    final newRep = VetReport(
      id: id,
      animal: ReportAnimal(
        id: 'animal-${DateTime.now().millisecondsSinceEpoch}',
        name: animalName,
        speciesCode: speciesCode,
        breedCode: speciesCode == 'buffalo' ? 'murrah' : 'gir',
        tagNumber: tagNumber,
      ),
      farmer: ReportFarmer(
        id: 'farmer-${DateTime.now().millisecondsSinceEpoch}',
        fullName: farmerName,
        phone: farmerPhone,
      ),
      reportedAt: DateTime.now(),
      receivedAt: DateTime.now(),
      description: description,
      symptomCodes: symptomCodes,
      screening: suspectedDisease != null
          ? ReportScreening(
              topLabel: suspectedDisease,
              topConfidence: 0.91,
              modelVersion: 'vet-field-triage-1.0',
              inconclusive: false,
            )
          : null,
      location: const ReportLocation(lat: 17.9856, lng: 74.4331, accuracyM: 3.5, source: 'gps'),
      villageId: 'v-phaltan-center',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'under_review',
    );
    _syntheticReports.insert(0, newRep);
    return newRep;
  }

  // =========================================================================
  // SYNTHETIC DEMONSTRATION DATA (API_CONTRACTS.md §5–§7)
  // Used only when offline or in demonstration mode. Clearly labelled in UI.
  // =========================================================================

  static final List<VetReport> _syntheticReports = [
    VetReport(
      id: 'rep-sat-2026-001',
      animal: const ReportAnimal(
        id: 'cattle-01',
        name: 'Gauri',
        speciesCode: 'cattle',
        breedCode: 'gir',
        tagNumber: 'MH-SAT-2026-081',
      ),
      farmer: const ReportFarmer(
        id: 'farmer-phaltan-01',
        fullName: 'Ramesh Jadhav',
        phone: '+919876543210',
      ),
      reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
      receivedAt: DateTime.now().subtract(const Duration(hours: 3)),
      description: 'Multiple round skin nodules noticed on neck, shoulders and back. Animal has 104F fever and reduced feeding.',
      symptomCodes: const ['skin_nodules', 'fever', 'enlarged_lymph_nodes', 'nasal_discharge'],
      location: const ReportLocation(lat: 17.9856, lng: 74.4331, accuracyM: 4.5, source: 'gps'),
      villageId: 'v-phaltan-center',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'submitted',
      screening: ReportScreening(
        modelVersion: 'mobilenet_v3_small_v1.0.0',
        topLabel: 'lumpy_skin_disease',
        topConfidence: 0.89,
        inconclusive: false,
        ranAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 2)),
      ),
      images: const [
        ReportImage(id: 'img-01', url: 'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?auto=format&fit=crop&w=800&q=80'),
      ],
    ),
    VetReport(
      id: 'rep-sat-2026-002',
      animal: const ReportAnimal(
        id: 'buffalo-01',
        name: 'Krishna',
        speciesCode: 'buffalo',
        breedCode: 'murrah',
        tagNumber: 'MH-SAT-2026-112',
      ),
      farmer: const ReportFarmer(
        id: 'farmer-barad-02',
        fullName: 'Anil Shinde',
        phone: '+919822334455',
      ),
      reportedAt: DateTime.now().subtract(const Duration(hours: 14)),
      receivedAt: DateTime.now().subtract(const Duration(hours: 14)),
      description: 'Excessive salivation stringing from mouth. Reluctant to walk, limping on right hind leg. Small blisters seen on tongue.',
      symptomCodes: const ['excessive_salivation', 'blisters_mouth_feet', 'lameness', 'fever'],
      location: const ReportLocation(lat: 17.9542, lng: 74.4820, accuracyM: 5.2, source: 'gps'),
      villageId: 'v-barad-01',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'under_review',
      screening: ReportScreening(
        modelVersion: 'mobilenet_v3_small_v1.0.0',
        topLabel: 'foot_and_mouth_disease',
        topConfidence: 0.94,
        inconclusive: false,
        ranAt: DateTime.now().subtract(const Duration(hours: 14, minutes: 5)),
      ),
      images: const [
        ReportImage(id: 'img-02', url: 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=800&q=80'),
      ],
    ),
    VetReport(
      id: 'rep-sat-2026-003',
      animal: const ReportAnimal(
        id: 'cattle-02',
        name: 'Kapila',
        speciesCode: 'cattle',
        breedCode: 'khillar',
        tagNumber: 'MH-SAT-2026-094',
      ),
      farmer: const ReportFarmer(
        id: 'farmer-tadawale-03',
        fullName: 'Suresh Bhosale',
        phone: '+919833445566',
      ),
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      receivedAt: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Firm circumscribed nodules noticed 4 days ago across brisket and perineum. Mild fever.',
      symptomCodes: const ['skin_nodules', 'fever'],
      location: const ReportLocation(lat: 18.0120, lng: 74.3910, accuracyM: 3.8, source: 'gps'),
      villageId: 'v-tadawale-01',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'confirmed',
      screening: ReportScreening(
        modelVersion: 'mobilenet_v3_small_v1.0.0',
        topLabel: 'lumpy_skin_disease',
        topConfidence: 0.91,
        inconclusive: false,
        ranAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      verification: ReportVerification(
        id: 'ver-001',
        decision: 'confirmed',
        diseaseCode: 'lumpy_skin_disease',
        notes: 'Clinical nodules confirmed consistent with Lumpy Skin Disease. Physical examination on farm completed. Isolated from other cattle.',
        visitRequired: true,
        vetName: 'Dr. Vikram Deshmukh',
        decidedAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
      ),
    ),
    VetReport(
      id: 'rep-sat-2026-004',
      animal: const ReportAnimal(
        id: 'goat-01',
        name: 'Rani',
        speciesCode: 'goat',
        breedCode: 'osmanabadi',
        tagNumber: 'MH-SAT-2026-204',
      ),
      farmer: const ReportFarmer(
        id: 'farmer-nimblak-04',
        fullName: 'Sunita Pawar',
        phone: '+919855667788',
      ),
      reportedAt: DateTime.now().subtract(const Duration(days: 3)),
      receivedAt: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Coughing and rapid breathing with mucoid ocular discharge.',
      symptomCodes: const ['coughing', 'respiratory_distress', 'fever'],
      location: const ReportLocation(lat: 17.9210, lng: 74.4500, accuracyM: 6.0, source: 'gps'),
      villageId: 'v-nimblak-01',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'flagged',
      screening: ReportScreening(
        modelVersion: 'mobilenet_v3_small_v1.0.0',
        topLabel: 'peste_des_petits_ruminants',
        topConfidence: 0.61,
        inconclusive: true,
        ranAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      verification: ReportVerification(
        id: 'ver-002',
        decision: 'flagged',
        notes: 'Suspected respiratory infection or atypical PPR. Blood/serum sampling needed before definitive determination.',
        visitRequired: true,
        vetName: 'Dr. Vikram Deshmukh',
        decidedAt: DateTime.now().subtract(const Duration(days: 2, hours: 10)),
      ),
    ),
    VetReport(
      id: 'rep-sat-2026-005',
      animal: const ReportAnimal(
        id: 'dog-01',
        name: 'Moti',
        speciesCode: 'dog',
        breedCode: 'mixed',
        tagNumber: 'MH-SAT-2026-301',
      ),
      farmer: const ReportFarmer(
        id: 'farmer-lonand-05',
        fullName: 'Vikas Patil',
        phone: '+919877889900',
      ),
      reportedAt: DateTime.now().subtract(const Duration(days: 4)),
      receivedAt: DateTime.now().subtract(const Duration(days: 4)),
      description: 'Persistent scratching around ears and flanks.',
      symptomCodes: const ['itching'],
      location: const ReportLocation(lat: 18.0450, lng: 74.1900, accuracyM: 8.0, source: 'gps'),
      villageId: 'v-lonand-01',
      talukaId: 'phaltan',
      districtId: 'satara',
      status: 'rejected',
      screening: null,
      verification: ReportVerification(
        id: 'ver-003',
        decision: 'rejected',
        notes: 'Mild localized sarcoptic mange. Not a reportable livestock surveillance disease. Prescribed topical ivermectin spray.',
        visitRequired: false,
        vetName: 'Dr. Vikram Deshmukh',
        decidedAt: DateTime.now().subtract(const Duration(days: 3, hours: 15)),
      ),
    ),
  ];

  static const List<RecordItem> _defaultDemoTreatments = [
    RecordItem({
      'id': 'treat-def-01',
      'treatment_name': 'Meloxicam Injection + Oxytetracycline LA',
      'dosage': '15 ml IM × 5 days + Herbal wound spray',
      'started_on': '2026-11-01',
      'ended_on': '2026-11-05',
      'prescribed_by_name': 'Dr. Rajesh Kulkarni',
      'notes': 'Keep animal in shaded isolation shed. Apply fly-repellent ointment on skin nodules twice daily.',
    }),
    RecordItem({
      'id': 'treat-def-02',
      'treatment_name': 'B-Complex + Liver Tonic Bolus & Mineral Mixture',
      'dosage': '10 ml IM × 3 days + 50g oral daily',
      'started_on': '2026-09-14',
      'ended_on': '2026-09-17',
      'prescribed_by_name': 'Dr. Rajesh Kulkarni',
      'notes': 'Supportive immunity & appetite restoration protocol.',
    }),
  ];

  static final Map<String, List<RecordItem>> _demoTreatments = {
    'cattle-01': List<RecordItem>.from(_defaultDemoTreatments),
    'cattle-02': [
      const RecordItem({
        'id': 'treat-001',
        'report_id': 'rep-sat-2026-003',
        'treatment_name': 'Supportive Antibiotic & Antiseptic Care (Enrofloxacin + Meloxicam)',
        'dosage': 'Enrofloxacin 10% 15ml IM OD, Meloxicam 15ml IM',
        'started_on': '2026-11-01',
        'ended_on': '2026-11-05',
        'prescribed_by_name': 'Dr. Rajesh Kulkarni',
        'notes': 'Daily antiseptic washing of lesions with potassium permanganate (1:1000). Fly repellent application to prevent secondary maggot wounds.',
      }),
    ],
  };

  static const List<RecordItem> _defaultDemoObservations = [
    RecordItem({
      'id': 'obs-def-01',
      'record_type': 'illness',
      'summary': 'Acute febrile phase (104.2°F) with cutaneous nodules on neck and brisket. Sub-scapular lymph nodes palpable. Advised strict shed isolation and supportive therapy.',
      'temperature_c': 40.1,
      'weight_kg': 375.0,
      'recorded_by_name': 'Dr. Rajesh Kulkarni',
      'recorded_at': '2026-11-03T11:20:00Z',
    }),
    RecordItem({
      'id': 'obs-def-02',
      'record_type': 'checkup',
      'summary': 'Pre-monsoon livestock health camp inspection at Phaltan. Normal rumination (3 cycles/2 min), pink mucous membranes, BCS 3.5/5.',
      'temperature_c': 38.5,
      'weight_kg': 382.0,
      'recorded_by_name': 'Dr. Rajesh Kulkarni',
      'recorded_at': '2026-09-15T10:00:00Z',
    }),
    RecordItem({
      'id': 'obs-def-03',
      'record_type': 'observation',
      'summary': 'Routine deworming (Fenbendazole 3g bolus) and mineral mixture supplementation completed. Milk yield steady at 9.5 L/day.',
      'temperature_c': 38.4,
      'weight_kg': 378.0,
      'recorded_by_name': 'Dr. Vikram Deshmukh',
      'recorded_at': '2026-06-18T09:30:00Z',
    }),
  ];

  static final Map<String, List<RecordItem>> _demoObservations = {
    'cattle-01': List<RecordItem>.from(_defaultDemoObservations),
    'cattle-02': [
      const RecordItem({
        'id': 'obs-002',
        'record_type': 'illness',
        'summary': 'Initial field visit: confirmed characteristic skin nodules across brisket and perineum. Isolated from herd.',
        'temperature_c': 39.8,
        'weight_kg': 368.0,
        'recorded_by_name': 'Dr. Rajesh Kulkarni',
        'recorded_at': '2026-11-02T10:15:00Z',
      }),
      ..._defaultDemoObservations.skip(1),
    ],
  };

  ReportPage _demoFilterReports({String? status, String? talukaId, int page = 1, int pageSize = 50}) {
    var list = _syntheticReports;
    if (status != null) {
      list = list.where((r) => r.status == status).toList();
    }
    if (talukaId != null) {
      list = list.where((r) => r.talukaId == talukaId).toList();
    }
    return ReportPage(list, list.length);
  }

  ReportPage _demoPendingReports() {
    final list = _syntheticReports
        .where((r) => r.isPending)
        .toList()
      ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
    return ReportPage(list, list.length);
  }

  VetReport _demoFindReport(String id) {
    return _syntheticReports.firstWhere(
      (r) => r.id == id,
      orElse: () => _syntheticReports.first,
    );
  }

  VetReport _demoClaim(String id) {
    final idx = _syntheticReports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final updated = _syntheticReports[idx].copyWith(status: 'under_review');
      _syntheticReports[idx] = updated;
      return updated;
    }
    return _syntheticReports.first;
  }

  VetReport _demoVerify(
    String reportId, {
    required String decision,
    String? diseaseCode,
    required String notes,
    bool visitRequired = false,
  }) {
    final idx = _syntheticReports.indexWhere((r) => r.id == reportId);
    final ver = ReportVerification(
      id: 'ver-${DateTime.now().millisecondsSinceEpoch}',
      decision: decision,
      diseaseCode: decision == 'confirmed' ? diseaseCode : null,
      notes: notes,
      visitRequired: visitRequired,
      vetName: _s.me?.fullName ?? 'Dr. Vikram Deshmukh',
      decidedAt: DateTime.now(),
    );
    if (idx != -1) {
      final updated = _syntheticReports[idx].copyWith(
        status: decision,
        verification: ver,
      );
      _syntheticReports[idx] = updated;
      return updated;
    }
    return _syntheticReports.first;
  }

  SummaryTotals _demoSummary() {
    int pending = 0, confirmed = 0, rejected = 0, flagged = 0;
    for (final r in _syntheticReports) {
      if (r.isPending) pending++;
      if (r.status == 'confirmed') confirmed++;
      if (r.status == 'rejected') rejected++;
      if (r.status == 'flagged') flagged++;
    }
    return SummaryTotals(
      reports: _syntheticReports.length,
      pending: pending,
      confirmed: confirmed,
      rejected: rejected,
      flagged: flagged,
    );
  }

  List<CasePoint> _demoMapCases() {
    return _syntheticReports
        .where((r) => r.status == 'confirmed' && r.location != null)
        .map((r) => CasePoint(
              reportId: r.id,
              diseaseCode: r.verification?.diseaseCode ?? 'lumpy_skin_disease',
              confirmedAt: r.verification?.decidedAt ?? r.reportedAt,
              lat: r.location!.lat,
              lng: r.location!.lng,
            ))
        .toList();
  }

  AnimalRecord _demoAnimalRecord(String animalId) {
    final r = _syntheticReports.firstWhere(
      (rep) => rep.animal.id == animalId,
      orElse: () => _syntheticReports.first,
    );
    final a = r.animal;
    return AnimalRecord(
      animal: ReportAnimalFull(
        id: a.id,
        speciesCode: a.speciesCode,
        breedCode: a.breedCode,
        name: a.name,
        tagNumber: a.tagNumber,
        sex: 'female',
        birthDate: '2022-04-15',
        markings: 'Characteristic breed markings',
      ),
      healthRecords: _demoObservations[animalId] ?? List<RecordItem>.from(_defaultDemoObservations),
      treatments: _demoTreatments[animalId] ?? List<RecordItem>.from(_defaultDemoTreatments),
      vaccinations: _demoVaccinations[animalId] ??
          const [
            RecordItem({
              'id': 'vac-01',
              'vaccine_name': 'Goat Pox Vaccine (LSD Prophylaxis)',
              'batch_number': 'GPV-2026-SATARA-09',
              'administered_on': '2026-08-12',
              'next_due_on': '2027-08-12',
              'administered_by': 'Dr. Rajesh Kulkarni',
            }),
            RecordItem({
              'id': 'vac-02',
              'vaccine_name': 'Foot and Mouth Disease (FMD) Oil Adjuvant',
              'batch_number': 'FMD-2026-B81',
              'administered_on': '2026-03-10',
              'next_due_on': '2026-09-10',
              'administered_by': 'Satara AH Dept',
            }),
          ],
      recentReports: _syntheticReports
          .where((rep) => rep.animal.id == animalId)
          .map((rep) => RecordItem({
                'id': rep.id,
                'status': rep.status,
                'reported_at': rep.reportedAt.toIso8601String(),
                'symptoms': rep.symptomCodes.join(', '),
              }))
          .toList(),
      generatedAt: DateTime.now(),
    );
  }

  static final Map<String, List<RecordItem>> _demoVaccinations = {};

  void _demoAddVaccination(
    String animalId, {
    required String vaccineName,
    String? batchNumber,
    required String administeredOn,
    String? nextDueOn,
    String? notes,
  }) {
    final list = _demoVaccinations.putIfAbsent(
      animalId,
      () => [
        const RecordItem({
          'id': 'vac-01',
          'vaccine_name': 'Foot and Mouth Disease (FMD) Oil Adjuvant',
          'batch_number': 'FMD-2026-B81',
          'administered_on': '2026-03-10',
          'next_due_on': '2026-09-10',
          'administered_by': 'Satara AH Dept',
        }),
      ],
    );
    list.insert(
      0,
      RecordItem({
        'id': 'vac-${DateTime.now().millisecondsSinceEpoch}',
        'vaccine_name': vaccineName,
        'batch_number': batchNumber ?? 'LSD-2026-MH',
        'administered_on': administeredOn,
        if (nextDueOn != null && nextDueOn.isNotEmpty) 'next_due_on': nextDueOn,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
  }

  void _demoAddHealthRecord(String animalId, {required String summary, required Map<String, dynamic> data}) {
    final list = _demoObservations.putIfAbsent(animalId, () => List<RecordItem>.from(_defaultDemoObservations));
    list.insert(
      0,
      RecordItem({
        'id': 'obs-${DateTime.now().millisecondsSinceEpoch}',
        'record_type': 'observation',
        'summary': summary,
        'recorded_by_name': 'Dr. Rajesh Kulkarni',
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        ...data,
      }),
    );
  }

  void _demoAddTreatment(
    String animalId, {
    required String reportId,
    required String treatmentName,
    String? dosage,
    required String startedOn,
    String? endedOn,
    String? notes,
  }) {
    final list = _demoTreatments.putIfAbsent(animalId, () => List<RecordItem>.from(_defaultDemoTreatments));
    list.insert(
      0,
      RecordItem({
        'id': 'treat-${DateTime.now().millisecondsSinceEpoch}',
        'report_id': reportId,
        'treatment_name': treatmentName,
        'dosage': dosage ?? '',
        'started_on': startedOn,
        'ended_on': endedOn ?? '',
        'prescribed_by_name': 'Dr. Rajesh Kulkarni',
        'notes': notes ?? '',
      }),
    );
  }
}
