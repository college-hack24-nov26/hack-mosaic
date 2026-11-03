# Pashu Wani (`pashu_wani`) — Mobile Application

An offline-first Flutter application for livestock healthcare reporting, on-device disease screening, veterinary connectivity, and disease surveillance for farmers in Maharashtra (Phaltan–Satara pilot).

---

## 1. Features

- **Offline-First Data Storage:** Local persistent storage for registered animals, disease reports, and outbreak notifications via `OfflineStore` (`SharedPreferences` JSON persistence), surviving app restarts with airplane mode enabled.
- **Multilingual Support (en, mr, hi):** Native localization toggle for Marathi (मराठी - default), English, and Hindi (हिंदी) across all navigation tabs, forms, badges, and clinical safety disclaimers.
- **Animal Registration & Digital QR Passport:** Register cattle and buffalo with ear-tag/Bharat Pashudhan IDs, breed classifications, and generate an offline-scannable digital health QR passport with `snapshot_at` date tracking.
- **Disease Reporting Workflow:** Comprehensive sick animal reporting with photo attachment (`image_picker`), GPS location tagging, interactive multi-symptom checklist (`skin_nodules`, `fever`, `reduced_milk`, `lameness`, `salivation`, `nasal_discharge`, `loss_of_appetite`), and notes.
- **Preliminary AI Screening:** On-device MobileNetV3 lesion image scanner interface with confidence estimation and seamless data handoff to report creation.
- **Regulatory Product Safety Notices:** Prominent, persistent non-diagnosis disclaimers (*"This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report."*) mandated by project safety guidelines.
- **Outbox Synchronization Queue:** Automatic dependency-ordered synchronization (`animals -> reports -> report images`) with Go backend REST API (`POST /api/v1/animals`, `POST /api/v1/reports`, `POST /api/v1/reports/{id}/images`).
- **Farmer Alert Consent:** Profile toggle allowing farmers to opt in or out of local geographic outbreak warnings triggered by vet-confirmed cases.

---

## 2. Tested & Verified Target Device

- **Target Device:** Google Pixel 9 Android Emulator (`emulator-5554`, Android 15 / API 37, ARM64)
- **Screen Geometry:** 1080 × 2424 px, responsive layout verified with 0 horizontal or vertical overflow errors.

---

## 3. Project Structure

```
mobile/
├── android/            # Android Gradle & native host configuration
├── assets/             # Image and ML model assets
├── ios/                # iOS Xcode project host configuration
├── lib/
│   ├── core/
│   │   ├── localization/   # Multilingual dictionary (AppStrings)
│   │   ├── network/        # REST HTTP client (ApiClient)
│   │   ├── theme/          # AppColors, AppTypography, AppSpacing, AppTheme
│   │   └── widgets/        # AppCard, AppButton, StatusBadge, SyncStatusBar, SafetyDisclaimerCard
│   ├── data/
│   │   ├── local/          # OfflineStore ChangeNotifier & persistence
│   │   └── models/         # UserModel, AnimalModel, DiseaseReportModel, NotificationModel
│   ├── screens/
│   │   ├── splash/         # SplashScreen & animated transition
│   │   ├── home/           # MainNavigationScreen & FarmerHomeScreen
│   │   ├── animals/        # AnimalsListScreen, AddAnimalScreen, AnimalDetailsScreen
│   │   ├── reports/        # CreateReportScreen, ReportsHistoryScreen, ReportDetailsScreen
│   │   ├── scanner/        # DiseaseScannerScreen, ScanResultsScreen
│   │   └── profile/        # ProfileScreen, LanguageScreen
│   └── main.dart           # Application entry point
├── test/
│   └── widget_test.dart    # Widget & OfflineStore persistence test suite
└── pubspec.yaml            # Dependencies & assets configuration
```

---

## 4. Development & Testing Commands

```bash
# Get dependencies
flutter pub get

# Static analysis (zero warnings / zero deprecated APIs)
flutter analyze

# Run unit and widget test suite
flutter test

# Build debug APK for Android
flutter build apk --debug

# Run directly on connected Android device/emulator (e.g. Pixel 9)
flutter run -d emulator-5554
```
