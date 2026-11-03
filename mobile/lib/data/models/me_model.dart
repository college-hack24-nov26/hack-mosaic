/// `GET /me` (API_CONTRACTS.md §3.6). Role and profile are decided by the
/// server; the app never derives a role from UI choices.
class MeProfile {
  final String id;
  final String phone;
  final String fullName;
  final String role; // farmer | vet | officer | admin
  final String preferredLanguage;

  /// PROPOSED field (see docs/change-requests/CR-mobile-vet-module-api-gaps.md).
  /// `active | pending_verification | rejected | disabled`. Null when the
  /// backend does not send it yet.
  final String? accountStatus;

  // farmer profile
  final String? villageId;
  final String? farmName;
  final bool alertConsent;
  final double? farmLat;
  final double? farmLng;

  // vet profile
  final String? districtId;
  final String? districtName;
  final String? talukaId;
  final String? talukaName;
  final String? registrationNumber;
  final String? qualification;
  final bool isParaVet;
  final String? clinicName;

  const MeProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.preferredLanguage,
    this.accountStatus,
    this.villageId,
    this.farmName,
    this.alertConsent = false,
    this.farmLat,
    this.farmLng,
    this.districtId,
    this.districtName,
    this.talukaId,
    this.talukaName,
    this.registrationNumber,
    this.qualification,
    this.isParaVet = false,
    this.clinicName,
  });

  bool get isFarmer => role == 'farmer';
  bool get isVet => role == 'vet';
  MeProfile get vet => this;

  factory MeProfile.fromJson(Map<String, dynamic> j) {
    final profile = (j['profile'] is Map) ? Map<String, dynamic>.from(j['profile']) : <String, dynamic>{};
    final farmer = profile['farmer'] is Map ? Map<String, dynamic>.from(profile['farmer']) : null;
    final vet = profile['vet'] is Map ? Map<String, dynamic>.from(profile['vet']) : null;
    final loc = farmer?['farm_location'] is Map ? Map<String, dynamic>.from(farmer!['farm_location']) : null;
    return MeProfile(
      id: j['id'].toString(),
      phone: (j['phone'] ?? '').toString(),
      fullName: (j['full_name'] ?? '').toString(),
      role: (j['role'] ?? '').toString(),
      preferredLanguage: (j['preferred_language'] ?? 'mr').toString(),
      accountStatus: j['account_status']?.toString(),
      villageId: farmer?['village_id']?.toString(),
      farmName: farmer?['farm_name']?.toString(),
      alertConsent: farmer?['alert_consent'] == true,
      farmLat: (loc?['lat'] as num?)?.toDouble(),
      farmLng: (loc?['lng'] as num?)?.toDouble(),
      districtId: vet?['district_id']?.toString(),
      districtName: vet?['district_name']?.toString(),
      talukaId: vet?['taluka_id']?.toString(),
      talukaName: vet?['taluka_name']?.toString(),
      registrationNumber: vet?['registration_number']?.toString(),
      qualification: vet?['qualification']?.toString(),
      isParaVet: vet?['is_para_vet'] == true,
      clinicName: vet?['clinic_name']?.toString(),
    );
  }
}
