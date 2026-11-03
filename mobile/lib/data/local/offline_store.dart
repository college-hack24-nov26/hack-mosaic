import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/animal_model.dart';
import '../models/disease_report_model.dart';
import '../models/notification_model.dart';

class OfflineStore extends ChangeNotifier {
  static final OfflineStore _instance = OfflineStore._internal();
  factory OfflineStore() => _instance;
  OfflineStore._internal();

  UserModel? _currentUser;
  List<AnimalModel> _animals = [];
  List<DiseaseReportModel> _reports = [];
  List<NotificationModel> _notifications = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  UserModel? get currentUser => _currentUser;
  List<AnimalModel> get animals => List.unmodifiable(_animals);
  List<DiseaseReportModel> get reports => List.unmodifiable(_reports);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

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
        id: 'farmer-phaltan-01',
        phone: '+919876543210',
        fullName: 'Ramesh Jadhav',
        role: 'farmer',
        villageId: 'v-phaltan-center',
        villageName: 'Phaltan Rural (फलटण)',
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
      // Seed initial realistic cattle for Phaltan
      _animals = [
        AnimalModel(
          id: 'cattle-01',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'gir',
          name: 'Gauri (गौरी)',
          tagNumber: 'MH-SAT-2026-081',
          sex: 'female',
          birthDate: '2022-04-15',
          markings: 'White star patch on forehead, curved horns',
          isSynced: true,
        ),
        AnimalModel(
          id: 'cattle-02',
          farmerId: _currentUser!.id,
          speciesCode: 'cattle',
          breedCode: 'khillar',
          name: 'Kapila (कपिला)',
          tagNumber: 'MH-SAT-2026-094',
          sex: 'female',
          birthDate: '2023-01-10',
          markings: 'Grey coat, slender build',
          isSynced: true,
        ),
        AnimalModel(
          id: 'buffalo-01',
          farmerId: _currentUser!.id,
          speciesCode: 'buffalo',
          breedCode: 'murrah',
          name: 'Krishna (कृष्णा)',
          tagNumber: 'MH-SAT-2026-112',
          sex: 'female',
          birthDate: '2021-08-20',
          markings: 'Jet black, curled horns',
          isSynced: true,
        ),
      ];
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
          id: 'rep-01',
          animalId: 'cattle-01',
          animalName: 'Gauri (गौरी)',
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

    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
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
}

