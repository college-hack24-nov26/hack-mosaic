# PASHU WANI — VETERINARIAN MODULE & ROLE-BASED AUTHENTICATION HANDOFF

**Author:** Om (Senior Flutter Engineer, GIS Application Developer, Mobile UI/UX Architect)  
**Date:** 2026-11-03  
**Status:** IMPLEMENTED & VERIFIED  
**Scope:** Mobile Client (`mobile/`) & Cross-Agent Handoff Documentation  
**Branch:** `feature/om-flutter-mobile`  
**Reference Documents:** `AGENTS.md`, `agents/OM_AGENT.md`, `API_CONTRACTS.md` v1.0, `DATABASE_SCHEMA.md` v1.0, `SECURITY.md`, `TESTING_STRATEGY.md`

---

## 1. Executive Summary

We have fully designed, engineered, and verified the complete **Veterinarian Module + Role-Based Authentication** for the Pashu Wani Flutter mobile application.

The application now seamlessly supports two distinct user roles:
1. **Farmer (`farmer`)**: Preserves the complete offline-first livestock management experience, digital QR passport, on-device MobileNetV3 AI screening, disease reporting, nearby verified veterinarians list, and interactive outbreak cluster map.
2. **Veterinarian (`vet`)**: A dedicated veterinary healthcare platform featuring clinical case inboxes, full disease report inspection, animal health records, 3-way clinical verification (`confirmed`, `rejected`, `flagged`), prescription & treatment documentation, confirmed case surveillance mapping, and practitioner profile management.

---

## 2. Architecture & RBAC Security Model

### 2.1 Role Determination (Single Source of Truth)
- In strict adherence to `SECURITY.md` §2 and `API_CONTRACTS.md` §1.3, **the client never chooses or trusts a user role selected from the UI**.
- Role assignment and verification status are derived exclusively from the backend `GET /me` response payload (`MeProfile`).
- The client-side state machine (`SessionManager`) maps the backend account role and status into strongly typed session states:
  - `SessionStatus.unauthenticated` → Routes to `WelcomeScreen`.
  - `SessionStatus.farmer` / `SessionStatus.demoFarmer` → Routes to `MainNavigationScreen`.
  - `SessionStatus.vet` / `SessionStatus.demoVet` → Routes to `VetShell`.
  - `SessionStatus.vetPending` → Routes to `VerificationPendingScreen` (for pending MSVC vetting).
  - `SessionStatus.restricted` → Routes to `AccessRestrictedScreen` (for disabled, rejected, or unsupported roles).

### 2.2 Client-Side Route Guard (`RoleGuard`)
- All veterinarian screens and widgets are wrapped inside `RoleGuard(role: 'vet', child: ...)`.
- If a farmer session or unauthenticated user attempts to mount or navigate to veterinarian screens, `RoleGuard` immediately halts rendering and safely redirects to `AccessRestrictedScreen`.

### 2.3 Secure Storage & Token Lifecycle
- Utilizes `flutter_secure_storage` (`SecureTokenStore`) backed by hardware-backed Android Keystore and iOS Keychain.
- Zero plaintext credentials or JWT tokens in Git or SharedPreferences.
- Transparent single-flight token refresh (`AuthedHttp`) catches 401 Unauthorized, refreshes access tokens via `POST /auth/refresh`, and retries seamlessly.
- **Privacy & Isolation Boundary**: Upon veterinarian login, any cached farmer personal data on the local device is immediately cleared via `OfflineStore().clearProtectedData()`. Upon logout, tokens and cached sensitive data are wiped completely.

---

## 3. Implemented Veterinarian Experiences

### 3.1 Vet Navigation Shell (`VetShell`)
- Dedicated Material 3 bottom navigation bar with 5 tabs:
  1. **Dashboard** (`Icons.dashboard`)
  2. **Case Inbox** (`Icons.assignment`)
  3. **Outbreak Map** (`Icons.map`)
  4. **Animal Records** (`Icons.pets`)
  5. **Profile** (`Icons.person`)
- Includes top indicator banner when operating in demonstration mode or if the backend server is offline.

### 3.2 Clinical Dashboard (`VetDashboardScreen`)
- **Veterinarian Identity Header**: Doctor name, verified veterinarian badge, assigned district/taluka, and clinic name.
- **Summary Metrics**: Real-time counters for Total Assigned Reports, Pending Review (Amber), Confirmed Cases (Red), Flagged Cases (Amber), and Rejected Cases (Muted).
- **"Waiting Longest" Priority Queue**: Automatically surfaces the oldest pending reports submitted by rural farmers in the veterinarian's district, displaying waiting time (e.g. `2 h ago`, `1 d ago`), animal details, and preliminary AI screening observations.
- **Recent Reports List**: Quick-glance list of latest reports with direct navigation to inspection.

### 3.3 Case Review Inbox (`VetInboxScreen`)
- Tabbed case filtering:
  - **Pending** (`submitted` + `under_review`)
  - **Confirmed** (`confirmed`)
  - **Rejected** (`rejected`)
  - **Flagged** (`flagged`)
- **Real-Time Search**: Instant search by animal name, species, tag number, farmer name, village, or report ID.
- **Rich Case Cards**: Displays species icon, tag number, farmer name, village, relative time tag, symptom tags, and AI screening observation box.
- **Mandatory Regulatory Notice**: Every AI observation prominently displays *"AI screening is preliminary decision support and is not a veterinary diagnosis."*

### 3.4 Disease Report Details (`VetReportDetailsScreen`)
- Complete clinical inspection view:
  - **Prominent Banner**: Mandatory decision-support disclaimer reminding the veterinarian that the AI result does not decide the clinical outcome.
  - **Animal Details**: Species, breed, name, tag number, plus direct CTA to view full health history (`VetAnimalHistoryScreen`).
  - **Farmer Contact**: Farmer name, village, and direct phone dialer integration (`tel:...` via `url_launcher`).
  - **GPS Location**: Coordinates with accuracy radius, source indicator, and "Open in Maps" action.
  - **Reported Symptoms**: Localized symptom chips with farmer's clinical description.
  - **Photographs**: Horizontal scrollable gallery of uploaded lesion photos with error fallbacks and upload-pending indicators.
  - **MobileNetV3 Observation Card**: Model version, predicted disease label, and confidence percentage.
  - **Current Verification Card**: When already decided, displays decision, confirmed disease, clinical notes, farm visit requirement, and deciding veterinarian name.
  - **Action Bar**:
    - If `submitted`: "Take this case for review" (`claim()`).
    - If pending: "Record verification" (navigates to `VetVerificationScreen`).
    - If `confirmed`: "Document treatment" (navigates to `VetTreatmentScreen`).

### 3.5 Clinical Verification (`VetVerificationScreen`)
- **3-Way Decision Selector**: `Confirmed` / `Rejected` / `Flagged`.
- **Disease Selection**: For confirmed cases, loads active diseases from `ReferenceApi.shared.diseases()` and requires selection (highlighting official surveillance diseases).
- **Clinical Notes**: Multiline required field adapting its label and validation based on the chosen decision.
- **Farm Visit Required**: Toggle indicating whether an on-site visit is scheduled.
- **Safety Dialog**: Confirms decision before submission, warning that confirmed cases feed the regional outbreak cluster surveillance system.

### 3.6 Treatment Documentation (`VetTreatmentScreen`)
- Clinical observation recording (up to 500 characters).
- Treatment recommendation entry.
- Medication name, dosage, and duration in days.
- Interactive calendar date picker for scheduled follow-up visits.
- Post-care instructions for the farmer.
- Regulatory safety notice: *"Medication is never suggested from the AI result. Enter only what you prescribe."*

### 3.7 Animal Health History (`VetAnimalHistoryScreen`)
- Registration details: Species, Breed, Tag, Sex, Birth Date, Markings.
- Multi-tab health timeline:
  1. Clinical Observations
  2. Prescribed Treatments
  3. Vaccination History (vaccine name, batch number, next due date)
  4. Previous Disease Reports

### 3.8 Outbreak Surveillance Map (`VetMapScreen`)
- Interactive map rendered using `flutter_map` with OpenStreetMap tile layers.
- Maps verified confirmed disease cases with prominent red surveillance markers.
- Tapping a pin opens a bottom sheet with disease name, confirmation timestamp, coordinates, and direct link to inspect the full case report.
- Recenter button to quickly navigate to the district center.

### 3.9 Veterinarian Profile & Language (`VetProfileScreen`)
- Displays practitioner credentials: Qualification, MSVC Registration Number, Clinic Name, Assigned Taluka and District.
- 1-tap language switcher across Marathi (`mr`), English (`en`), and Hindi (`hi`).
- Clean logout dialog clearing access/refresh tokens and returning safely to `WelcomeScreen`.

---

## 4. Verification & Test Evidence

### 4.1 Static Analysis (`flutter analyze`)
```
Analyzing mobile...
No issues found! (ran in 1.3s)
```
- **0 errors, 0 warnings, 0 hints**. Strict linter adherence.

### 4.2 Automated Test Suite (`flutter test`)
```
00:01 +8: All tests passed!
```
The test suite in `mobile/test/widget_test.dart` covers:
1. `PashuWaniApp startup, splash transition to WelcomeScreen, and demo entry` — Verified.
2. `Veterinarian demo session routes to VetShell with verified badge` — Verified.
3. `RoleGuard prevents farmer session from mounting VetShell` — Verified.
4. `VetRepository verification records decision and updates status` — Verified.
5. `OfflineStore persists animals, reports, screening, alert consent, and language across restarts` — Verified.
6. `Multilingual strings and mandatory safety disclaimer exist for mr, hi, and en` — Verified.
7. `ScreeningResult.toApiJson conforms to API_CONTRACTS.md §6.1` — Verified.
8. `Nearby veterinarians and outbreak zones load with distance calculation` — Verified.

---

## 5. Artifacts and Source Locations

| Component | File Path |
|---|---|
| Auth Gate & Routing | `mobile/lib/screens/auth/auth_gate.dart` |
| Welcome Screen | `mobile/lib/screens/auth/welcome_screen.dart` |
| Login Screen | `mobile/lib/screens/auth/login_screen.dart` |
| Registration Screen | `mobile/lib/screens/auth/register_screen.dart` |
| Pending Screen | `mobile/lib/screens/auth/verification_pending_screen.dart` |
| Restricted Screen | `mobile/lib/screens/auth/access_restricted_screen.dart` |
| Role Guard | `mobile/lib/core/auth/role_guard.dart` |
| Session Manager | `mobile/lib/core/auth/session_manager.dart` |
| Token Store | `mobile/lib/core/auth/token_store.dart` |
| Authenticated HTTP | `mobile/lib/core/network/authed_http.dart` |
| Vet Repository | `mobile/lib/data/vet_repository.dart` |
| Vet Models | `mobile/lib/data/models/vet_models.dart` |
| Vet Navigation Shell | `mobile/lib/screens/vet/vet_shell.dart` |
| Vet Dashboard | `mobile/lib/screens/vet/vet_dashboard_screen.dart` |
| Vet Case Inbox | `mobile/lib/screens/vet/vet_inbox_screen.dart` |
| Vet Report Details | `mobile/lib/screens/vet/vet_report_details_screen.dart` |
| Vet Verification | `mobile/lib/screens/vet/vet_verification_screen.dart` |
| Vet Treatment | `mobile/lib/screens/vet/vet_treatment_screen.dart` |
| Vet Animal History | `mobile/lib/screens/vet/vet_animal_history_screen.dart` |
| Vet Surveillance Map | `mobile/lib/screens/vet/vet_map_screen.dart` |
| Vet Profile | `mobile/lib/screens/vet/vet_profile_screen.dart` |
| Localization Strings | `mobile/lib/core/localization/vet_strings.dart` |
