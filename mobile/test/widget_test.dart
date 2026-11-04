import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pashu_wani/main.dart';
import 'package:pashu_wani/core/auth/session_manager.dart';
import 'package:pashu_wani/core/auth/token_store.dart';
import 'package:pashu_wani/core/auth/role_guard.dart';
import 'package:pashu_wani/core/localization/app_strings.dart';
import 'package:pashu_wani/data/local/offline_store.dart';
import 'package:pashu_wani/data/models/animal_model.dart';
import 'package:pashu_wani/data/models/disease_report_model.dart';
import 'package:pashu_wani/data/models/user_model.dart';
import 'package:pashu_wani/data/vet_repository.dart';
import 'package:pashu_wani/screens/auth/welcome_screen.dart';
import 'package:pashu_wani/screens/auth/access_restricted_screen.dart';
import 'package:pashu_wani/screens/home/main_navigation_screen.dart';
import 'package:pashu_wani/screens/vet/vet_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager.resetForTest(tokens: MemoryTokenStore());
    AppStrings.setLanguage('mr');
  });

  testWidgets('PashuWaniApp startup, splash transition to WelcomeScreen, and demo entry', (WidgetTester tester) async {
    await tester.pumpWidget(const PashuWaniApp());
    expect(find.byType(PashuWaniApp), findsOneWidget);

    // Allow splash timer to complete
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Unauthenticated startup correctly displays WelcomeScreen (AuthGate)
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Enter Farmer Demo Mode
    await SessionManager.instance.enterDemo();
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Ramesh Jadhav'), findsOneWidget);
  });

  testWidgets('Veterinarian demo session routes to VetShell with verified badge', (WidgetTester tester) async {
    await tester.pumpWidget(const PashuWaniApp());
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Enter Vet Demo Mode
    await SessionManager.instance.enterDemoVet();
    await tester.pumpAndSettle();

    expect(find.byType(VetShell), findsOneWidget);
    expect(SessionManager.instance.isVerifiedVet, true);
  });

  testWidgets('RoleGuard prevents farmer session from mounting VetShell', (WidgetTester tester) async {
    await SessionManager.instance.enterDemo(); // Farmer session

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleGuard(
          role: 'vet',
          child: VetShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AccessRestrictedScreen), findsOneWidget);
    expect(find.byType(VetShell), findsNothing);
  });

  test('VetRepository verification records decision and updates status', () async {
    await SessionManager.instance.enterDemoVet();
    final repo = VetRepository.shared;

    final pending = await repo.pendingReports();
    expect(pending.items.isNotEmpty, true);
    final targetReport = pending.items.first;

    // Submit clinical verification
    final verified = await repo.verify(
      targetReport.id,
      decision: 'confirmed',
      diseaseCode: 'lumpy_skin_disease',
      notes: 'Firm nodules verified across neck. Isolated from herd.',
      visitRequired: true,
    );

    expect(verified.status, 'confirmed');
    expect(verified.verification?.decision, 'confirmed');
    expect(verified.verification?.diseaseCode, 'lumpy_skin_disease');
    expect(verified.verification?.visitRequired, true);

    // Summary totals reflect updated counts
    final summary = await repo.summary();
    expect(summary.confirmed, greaterThanOrEqualTo(1));
  });

  test('OfflineStore persists animals, reports, screening, alert consent, and language across restarts', () async {
    final store = OfflineStore();
    await store.initialize();

    final initialAnimalsCount = store.animals.length;
    final initialReportsCount = store.reports.length;
    expect(store.pendingSyncCount, 0);

    // 1. Add a new offline animal
    final newAnimal = AnimalModel(
      id: 'animal-test-99',
      farmerId: store.currentUser!.id,
      speciesCode: 'cattle',
      breedCode: 'gir',
      name: 'Nandini',
      tagNumber: 'MH-SAT-2026-999',
      sex: 'female',
      birthDate: '2024-01-15',
      markings: 'Brown coat',
      isSynced: false,
    );
    await store.addAnimal(newAnimal);

    // 2. Add a new offline disease report with preliminary screening result
    final screening = ScreeningResult(
      modelVersion: 'mnv3s-2026.11.0',
      topLabel: 'lumpy_skin_disease',
      topConfidence: 0.84,
      inconclusive: false,
      scores: [
        {'label': 'lumpy_skin_disease', 'score': 0.84},
        {'label': 'normal_skin', 'score': 0.16},
      ],
      ranAt: DateTime.utc(2026, 11, 3, 10, 0, 0),
    );
    final newReport = DiseaseReportModel(
      id: 'report-test-99',
      animalId: newAnimal.id,
      animalName: newAnimal.displayName,
      reportedAt: DateTime.utc(2026, 11, 3, 10, 1, 0),
      description: 'Nodules and fever noticed this morning',
      descriptionLanguage: 'en',
      symptomCodes: ['skin_nodules', 'fever'],
      latitude: 17.9856,
      longitude: 74.4331,
      villageId: 'v-phaltan-center',
      status: 'submitted',
      screening: screening,
      isSynced: false,
    );
    await store.addReport(newReport);

    // 3. Toggle alert consent to false and language to Hindi
    final user = store.currentUser!;
    await store.saveUser(UserModel(
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      role: user.role,
      villageId: user.villageId,
      villageName: user.villageName,
      farmName: user.farmName,
      latitude: user.latitude,
      longitude: user.longitude,
      alertConsent: false,
    ));
    await store.setLanguage('hi');

    expect(store.pendingSyncCount, 2);

    // 4. Re-initialize store (simulating app restart reading from SharedPreferences)
    await store.initialize();

    expect(store.animals.length, initialAnimalsCount + 1);
    expect(store.animals.first.id, 'animal-test-99');
    expect(store.animals.first.isSynced, false);

    expect(store.reports.length, initialReportsCount + 1);
    expect(store.reports.first.id, 'report-test-99');
    expect(store.reports.first.screening?.topLabel, 'lumpy_skin_disease');
    expect(store.reports.first.screening?.modelVersion, 'mnv3s-2026.11.0');
    expect(store.reports.first.isSynced, false);

    expect(store.currentUser?.alertConsent, false);
    expect(AppStrings.currentLang, 'hi');

    // 5. Verify granular sync marking
    await store.markAnimalSynced('animal-test-99');
    expect(store.pendingSyncCount, 1);
    await store.markReportSynced('report-test-99');
    expect(store.pendingSyncCount, 0);
  });

  test('Multilingual strings and mandatory safety disclaimer exist for mr, hi, and en', () {
    for (final lang in ['mr', 'hi', 'en']) {
      AppStrings.setLanguage(lang);
      expect(AppStrings.currentLang, lang);
      final disclaimer = AppStrings.t('safety_disclaimer');
      expect(disclaimer.isNotEmpty, true);
      expect(disclaimer, isNot('safety_disclaimer'));
    }

    AppStrings.setLanguage('en');
    expect(
      AppStrings.t('safety_disclaimer'),
      'This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report.',
    );
  });

  test('ScreeningResult.toApiJson conforms to API_CONTRACTS.md §6.1', () {
    final result = ScreeningResult(
      modelVersion: 'mnv3s-2026.11.0',
      topLabel: 'lumpy_skin_disease',
      topConfidence: 0.78,
      inconclusive: false,
      scores: [
        {'label': 'lumpy_skin_disease', 'score': 0.78},
      ],
      ranAt: DateTime.utc(2026, 11, 3, 10, 11, 30),
    );

    final apiJson = result.toApiJson();
    expect(apiJson['model_version'], 'mnv3s-2026.11.0');
    expect(apiJson['top_label'], 'lumpy_skin_disease');
    expect(apiJson['top_confidence'], 0.78);
    expect(apiJson['inconclusive'], false);
    expect(apiJson['ran_at'], '2026-11-03T10:11:30.000Z');
    expect(apiJson.containsKey('disclaimer'), false);
  });

  test('Nearby veterinarians and outbreak zones load with distance calculation', () async {
    final store = OfflineStore();
    await store.initialize();

    // Verify verified veterinarians
    expect(store.veterinarians.length, greaterThanOrEqualTo(5));
    final nearbyVets = store.getNearbyVeterinarians(17.9856, 74.4331);
    expect(nearbyVets.first.name, 'Dr. Rajesh Kulkarni');
    expect(nearbyVets.first.isVerified, true);
    expect(nearbyVets.first.distanceKm, lessThan(1.5));

    // Verify outbreak surveillance zones
    expect(store.outbreakZones.length, greaterThanOrEqualTo(2));
    final confirmedZone = store.outbreakZones.firstWhere((z) => z.isConfirmed);
    expect(confirmedZone.diseaseCode, 'lumpy_skin_disease');
    expect(confirmedZone.caseCount, 4);
    expect(confirmedZone.radiusMeters, 3200);

    // Verify individual case pins
    expect(store.diseaseCases.isNotEmpty, true);
  });
}
