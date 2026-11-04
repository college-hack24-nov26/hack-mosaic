import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../models/user_model.dart';
import '../models/animal_model.dart';
import '../models/disease_report_model.dart';
import '../models/notification_model.dart';
import '../models/veterinarian_model.dart';
import '../models/outbreak_zone_model.dart';

class OfflineStore extends ChangeNotifier {
  static final OfflineStore _instance = OfflineStore._internal();
  factory OfflineStore() => _instance;
  OfflineStore._internal();

  UserModel? _currentUser;
  List<AnimalModel> _animals = [];
  List<DiseaseReportModel> _reports = [];
  List<NotificationModel> _notifications = [];
  List<VeterinarianModel> _veterinarians = [];
  List<OutbreakZoneModel> _outbreakZones = [];
  List<DiseaseCasePin> _diseaseCases = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  UserModel? get currentUser => _currentUser;
  List<AnimalModel> get animals => List.unmodifiable(_animals);
  List<DiseaseReportModel> get reports => List.unmodifiable(_reports);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  List<VeterinarianModel> get veterinarians => List.unmodifiable(_veterinarians);
  List<OutbreakZoneModel> get outbreakZones => List.unmodifiable(_outbreakZones);
  List<DiseaseCasePin> get diseaseCases => List.unmodifiable(_diseaseCases);
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  List<VeterinarianModel> getNearbyVeterinarians(double userLat, double userLon) {
    final list = _veterinarians.map((v) {
      final dist = LocationService.calculateDistanceKm(userLat, userLon, v.latitude, v.longitude);
      return v.copyWith(distanceKm: dist);
    }).toList();
    list.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return list;
  }

  int get pendingSyncCount {
    final unsyncedAnimals = _animals.where((a) => !a.isSynced).length;
    final unsyncedReports = _reports.where((r) => !r.isSynced).length;
    return unsyncedAnimals + unsyncedReports;
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    AppStrings.setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', AppStrings.currentLang);
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 0. Load Preferred Language
    final savedLang = prefs.getString('preferred_language');
    if (savedLang != null) {
      AppStrings.setLanguage(savedLang);
    }

    // 1. Load User
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
    } else {
      // Default demo farmer profile in Phaltan, Satara
      _currentUser = UserModel(
        id: '11111111-1111-4111-8111-111111111301',
        phone: '+919876543210',
        fullName: 'Ramesh Jadhav',
        role: 'farmer',
        villageId: '11111111-1111-4111-8111-111111111104',
        villageName: 'Phaltan Rural',
        farmName: 'Jadhav Dairy Farm',
        latitude: 17.9856,
        longitude: 74.4331,
        alertConsent: true,
      );
      await saveUser(_currentUser!);
    }

    // 2. Load Animals
    final animalsJson = prefs.getString('animals_list');
    if (animalsJson != null) {
      final List<dynamic> decoded = jsonDecode(animalsJson);
      _animals = decoded.map((e) => AnimalModel.fromJson(e)).toList();
    } else {
      // Seed initial realistic cattle for Phaltan aligned with PostgreSQL seed IDs
      _animals = [
        AnimalModel(
          id: '33333333-3333-4333-8333-333333333077',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'gir',
          name: 'Tulsi',
          tagNumber: 'MH-SAT-2026-777',
          sex: 'female',
          birthDate: '2022-06-12',
          markings: 'Reddish-brown coat, curved horns',
          isSynced: true,
        ),
        AnimalModel(
          id: '33333333-3333-4333-8333-333333333001',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'gir',
          name: 'Gauri',
          tagNumber: 'MH-SAT-2026-081',
          sex: 'female',
          birthDate: '2022-04-15',
          markings: 'White star patch on forehead, curved horns',
          isSynced: true,
        ),
        AnimalModel(
          id: '33333333-3333-4333-8333-333333333003',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'khillar',
          name: 'Kapila',
          tagNumber: 'MH-SAT-2026-094',
          sex: 'female',
          birthDate: '2023-01-10',
          markings: 'Grey coat, slender build',
          isSynced: true,
        ),
        AnimalModel(
          id: '33333333-3333-4333-8333-333333333002',
          farmerId: _currentUser!.id,
          speciesCode: 'buffalo',
          breedCode: 'murrah',
          name: 'Krishna',
          tagNumber: 'MH-SAT-2026-112',
          sex: 'female',
          birthDate: '2021-08-20',
          markings: 'Jet black, curled horns',
          isSynced: true,
        ),
      ];
      await _persistAnimals();
    }
    if (!_animals.any((a) => a.name?.toLowerCase() == 'tulsi')) {
      _animals.insert(
        0,
        AnimalModel(
          id: '33333333-3333-4333-8333-333333333077',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'gir',
          name: 'Tulsi',
          tagNumber: 'MH-SAT-2026-777',
          sex: 'female',
          birthDate: '2022-06-12',
          markings: 'Reddish-brown coat, curved horns',
          isSynced: true,
        ),
      );
      await _persistAnimals();
    }

    // 3. Load Reports
    final reportsJson = prefs.getString('reports_list');
    if (reportsJson != null) {
      final List<dynamic> decoded = jsonDecode(reportsJson);
      _reports = decoded.map((e) => DiseaseReportModel.fromJson(e)).toList();
    } else {
      // Seed one confirmed past record & one recent submitted report
      _reports = [
        DiseaseReportModel(
          id: '11111111-1111-4111-8111-111111111502',
          animalId: '11111111-1111-4111-8111-111111111402',
          animalName: 'Kapila',
          reportedAt: DateTime.now().subtract(const Duration(days: 3)),
          description: 'High fever and circular nodules observed along the neck and back.',
          symptomCodes: ['skin_nodules', 'fever', 'reduced_milk'],
          latitude: 17.9856,
          longitude: 74.4331,
          status: 'confirmed',
          confirmedDiseaseCode: 'lumpy_skin_disease',
          vetNotes: 'Dr. Patil examined animal on farm. Confirmed mild Lumpy Skin Disease. Prescribed antibiotic cover and antiseptic ointment.',
          isSynced: true,
        ),
      ];
      await _persistReports();
    }

    // 4. Load Notifications / Alerts
    final notifsJson = prefs.getString('notifications_list');
    if (notifsJson != null) {
      final List<dynamic> decoded = jsonDecode(notifsJson);
      _notifications = decoded.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      _notifications = [
        NotificationModel(
          id: 'notif-01',
          type: 'alert',
          title: 'संसर्ग चेतावणी: लंपी त्वचा रोग (LSD)',
          body: 'फलटण तालुक्यात ३ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले लंपी आजाराचे रुग्ण आढळले आहेत. कृपया जनावरांना वेगळे ठेवा आणि डास-माशांपासून संरक्षण करा.',
          alertId: 'alert-satara-01',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        NotificationModel(
          id: 'notif-02',
          type: 'report_update',
          title: 'पशुवैद्यक अहवाल अद्यतन',
          body: 'तुमच्या "गौरी" गायीच्या तपासणी अहवालाची डॉ. पाटील यांनी पुष्टी केली आहे.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      await _persistNotifications();
    }

    // 5. Load Verified Veterinarians (Phaltan / Satara District)
    const rajeshKulkarniVet = VeterinarianModel(
      id: '22222222-2222-4222-8222-222222222101',
      name: 'Dr. Rajesh Kulkarni',
      qualification: 'M.V.Sc (Veterinary Medicine)',
      registrationNumber: 'MSVC-2026-SAT-01',
      clinicName: 'Taluka Veterinary Polyclinic, Phaltan',
      address: 'Station Road, Phaltan, Dist. Satara',
      latitude: 17.9860,
      longitude: 74.4340,
      phone: '+919890112233',
      workingHours: '9:00 AM – 6:00 PM (Emergency 24x7)',
      isVerified: true,
    );

    final vetsJson = prefs.getString('vets_list');
    if (vetsJson != null) {
      final List<dynamic> decoded = jsonDecode(vetsJson);
      _veterinarians = decoded.map((e) => VeterinarianModel.fromJson(e)).toList();
      if (!_veterinarians.any((v) => v.name.toLowerCase().contains('rajesh kulkarni'))) {
        _veterinarians.insert(0, rajeshKulkarniVet);
        await _persistVeterinarians();
      }
    } else {
      _veterinarians = [
        rajeshKulkarniVet,
        const VeterinarianModel(
          id: 'vet-phaltan-01',
          name: 'Dr. Sanjay Patil',
          qualification: 'B.V.Sc & A.H., M.V.Sc (Surgery)',
          registrationNumber: 'MSVC-14208',
          clinicName: 'Govt. Taluka Veterinary Polyclinic',
          address: 'Shivaji Chowk, Phaltan Rural',
          latitude: 17.9892,
          longitude: 74.4295,
          phone: '+919822451102',
          workingHours: '9:00 AM – 5:00 PM (Emergency 24x7)',
          isVerified: true,
        ),
        const VeterinarianModel(
          id: 'vet-barad-02',
          name: 'Dr. Snehal More',
          qualification: 'B.V.Sc & A.H.',
          registrationNumber: 'MSVC-18934',
          clinicName: 'Veterinary Dispensary Grade-1, Barad',
          address: 'Pandharpur Road, Barad, Tal. Phaltan',
          latitude: 17.9412,
          longitude: 74.4921,
          phone: '+919423367890',
          workingHours: '8:30 AM – 4:30 PM',
          isVerified: true,
        ),
        const VeterinarianModel(
          id: 'vet-taradgaon-03',
          name: 'Dr. Priya Shinde',
          qualification: 'B.V.Sc & A.H., M.V.Sc (Medicine)',
          registrationNumber: 'MSVC-20145',
          clinicName: 'Livestock Healthcare Center, Taradgaon',
          address: 'Taradgaon Center, Phaltan',
          latitude: 18.0125,
          longitude: 74.3410,
          phone: '+919975411223',
          workingHours: '9:00 AM – 5:00 PM',
          isVerified: true,
        ),
        const VeterinarianModel(
          id: 'vet-lonand-04',
          name: 'Dr. Anand Deshmukh',
          qualification: 'B.V.Sc & A.H.',
          registrationNumber: 'MSVC-11520',
          clinicName: 'Government Veterinary Hospital, Lonand',
          address: 'Station Road, Lonand, Khandala-Phaltan Border',
          latitude: 18.0415,
          longitude: 74.1920,
          phone: '+919850123456',
          workingHours: '9:00 AM – 5:00 PM',
          isVerified: true,
        ),
      ];
      await _persistVeterinarians();
    }

    // 6. Load Outbreak Surveillance Zones
    final outbreaksJson = prefs.getString('outbreaks_list');
    if (outbreaksJson != null) {
      final List<dynamic> decoded = jsonDecode(outbreaksJson);
      _outbreakZones = decoded.map((e) => OutbreakZoneModel.fromJson(e)).toList();
    } else {
      _outbreakZones = [
        OutbreakZoneModel(
          id: 'zone-lsd-01',
          diseaseCode: 'lumpy_skin_disease',
          diseaseName: 'Lumpy Skin Disease (LSD)',
          status: 'confirmed',
          latitude: 17.9910,
          longitude: 74.4320,
          radiusMeters: 3200,
          caseCount: 4,
          detectedAt: DateTime.now().subtract(const Duration(days: 3)),
          advisory: 'Cluster of 4 veterinarian-confirmed cases. Ring vaccination active in Phaltan rural cluster.',
        ),
        OutbreakZoneModel(
          id: 'zone-fmd-02',
          diseaseCode: 'foot_and_mouth',
          diseaseName: 'Foot & Mouth Disease (FMD)',
          status: 'suspected',
          latitude: 17.9450,
          longitude: 74.4890,
          radiusMeters: 2000,
          caseCount: 2,
          detectedAt: DateTime.now().subtract(const Duration(days: 1)),
          advisory: 'Suspected cluster under veterinarian review near Barad village.',
        ),
      ];
      await _persistOutbreaks();
    }

    // 7. Load Individual Case Pins
    final casesJson = prefs.getString('cases_list');
    if (casesJson != null) {
      final List<dynamic> decoded = jsonDecode(casesJson);
      _diseaseCases = decoded.map((e) => DiseaseCasePin.fromJson(e)).toList();
    } else {
      _diseaseCases = [
        DiseaseCasePin(
          id: 'case-01',
          reportId: 'rep-01',
          diseaseCode: 'lumpy_skin_disease',
          latitude: 17.9945,
          longitude: 74.4310,
          confirmedAt: DateTime.now().subtract(const Duration(days: 3)),
          isConfirmed: true,
        ),
        DiseaseCasePin(
          id: 'case-02',
          reportId: 'rep-02',
          diseaseCode: 'lumpy_skin_disease',
          latitude: 17.9880,
          longitude: 74.4365,
          confirmedAt: DateTime.now().subtract(const Duration(days: 2)),
          isConfirmed: true,
        ),
        DiseaseCasePin(
          id: 'case-03',
          reportId: 'rep-03',
          diseaseCode: 'lumpy_skin_disease',
          latitude: 17.9820,
          longitude: 74.4280,
          confirmedAt: DateTime.now().subtract(const Duration(days: 1)),
          isConfirmed: true,
        ),
        DiseaseCasePin(
          id: 'case-04',
          reportId: 'rep-04',
          diseaseCode: 'foot_and_mouth',
          latitude: 17.9480,
          longitude: 74.4850,
          confirmedAt: DateTime.now().subtract(const Duration(days: 1)),
          isConfirmed: false,
        ),
      ];
      await _persistDiseaseCases();
    }

    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Begins a fresh authenticated farmer session: wipes any previous user's
  /// (or demo) data so nothing leaks between accounts, stores the server
  /// profile, and pulls the farmer's animals and reports from the backend.
  Future<void> startSessionFor(UserModel user) async {
    await clearProtectedData();
    await saveUser(user);
    await refreshFromBackend();
  }

  /// Pulls the authenticated farmer's animals and reports from the Go backend,
  /// preserving any local unsynced records.
  Future<void> refreshFromBackend() async {
    final api = ApiClient();
    if (api.authToken == null) return;

    final remoteAnimals = await api.fetchAnimals();
    if (remoteAnimals != null) {
      final unsyncedLocal = _animals.where((a) => !a.isSynced && !remoteAnimals.any((r) => r.id == a.id)).toList();
      _animals = [...unsyncedLocal, ...remoteAnimals];
      await _persistAnimals();
    }

    final remoteReports = await api.fetchReports();
    if (remoteReports != null) {
      final unsyncedLocal = _reports.where((l) => !l.isSynced && !remoteReports.any((r) => r.id == l.id)).toList();
      _reports = [...unsyncedLocal, ...remoteReports];
      await _persistReports();
    }

    notifyListeners();
  }

  /// Removes personal data cached on the device (logout / session expiry).
  /// Reference-style data (vets directory, outbreak zones) is kept.
  Future<void> clearProtectedData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['current_user', 'animals_list', 'reports_list', 'notifications_list']) {
      await prefs.remove(k);
    }
    _currentUser = null;
    _animals = [];
    _reports = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> addAnimal(AnimalModel animal) async {
    _animals.insert(0, animal);
    await _persistAnimals();
    notifyListeners();
  }

  Future<void> addReport(DiseaseReportModel report) async {
    _reports.insert(0, report);
    await _persistReports();
    notifyListeners();
  }

  Future<void> markAnimalSynced(String animalId) async {
    _animals = _animals
        .map((a) => a.id == animalId ? a.copyWith(isSynced: true) : a)
        .toList();
    await _persistAnimals();
    notifyListeners();
  }

  Future<void> markReportSynced(String reportId) async {
    _reports = _reports
        .map((r) => r.id == reportId ? r.copyWith(isSynced: true) : r)
        .toList();
    await _persistReports();
    notifyListeners();
  }

  /// Attempts to synchronize all pending animals and reports with the Go backend
  /// in dependency order (animals -> reports -> report images).
  /// Only records that receive a 200/201 response from the backend are marked synced.
  Future<int> syncPendingWithBackend() async {
    if (_isSyncing || !_isOnline) return 0;

    _isSyncing = true;
    notifyListeners();

    int syncedCount = 0;
    try {
      final api = ApiClient();

      // 1. Sync pending animals first (dependency order per ARCHITECTURE.md §5)
      for (int i = 0; i < _animals.length; i++) {
        final animal = _animals[i];
        if (!animal.isSynced) {
          final ok = await api.syncAnimal(animal);
          if (ok) {
            _animals[i] = animal.copyWith(isSynced: true);
            syncedCount++;
          }
        }
      }
      if (syncedCount > 0) {
        await _persistAnimals();
      }

      // 2. Sync pending reports and any attached images
      int reportsSynced = 0;
      for (int i = 0; i < _reports.length; i++) {
        final report = _reports[i];
        if (!report.isSynced) {
          final ok = await api.syncReport(report);
          if (ok) {
            if (report.photoPath != null) {
              await api.uploadReportImage(report.id, report.photoPath!);
            }
            _reports[i] = report.copyWith(isSynced: true);
            reportsSynced++;
            syncedCount++;
          }
        }
      }
      if (reportsSynced > 0) {
        await _persistReports();
      }
      await refreshFromBackend();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
    return syncedCount;
  }

  Future<void> markAllSynced() async {
    _animals = _animals.map((a) => a.copyWith(isSynced: true)).toList();
    _reports = _reports.map((r) => r.copyWith(isSynced: true)).toList();
    await _persistAnimals();
    await _persistReports();
    notifyListeners();
  }

  Future<void> _persistAnimals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'animals_list',
      jsonEncode(_animals.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> _persistReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reports_list',
      jsonEncode(_reports.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _persistNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications_list',
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _persistVeterinarians() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'vets_list',
      jsonEncode(_veterinarians.map((v) => v.toJson()).toList()),
    );
  }

  Future<void> _persistOutbreaks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'outbreaks_list',
      jsonEncode(_outbreakZones.map((z) => z.toJson()).toList()),
    );
  }

  Future<void> _persistDiseaseCases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cases_list',
      jsonEncode(_diseaseCases.map((c) => c.toJson()).toList()),
    );
  }
}

