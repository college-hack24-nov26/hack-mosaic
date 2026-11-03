class UserModel {
  final String id;
  final String phone;
  final String fullName;
  final String role;
  final String villageId;
  final String? villageName;
  final String? farmName;
  final double? latitude;
  final double? longitude;
  final bool alertConsent;

  UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.villageId,
    this.villageName,
    this.farmName,
    this.latitude,
    this.longitude,
    this.alertConsent = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'role': role,
    'village_id': villageId,
    'village_name': villageName,
    'farm_name': farmName,
    'latitude': latitude,
    'longitude': longitude,
    'alert_consent': alertConsent,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    phone: json['phone'] as String,
    fullName: json['full_name'] as String,
    role: json['role'] as String? ?? 'farmer',
    villageId: json['village_id'] as String? ?? 'v-phaltan-01',
    villageName: json['village_name'] as String?,
    farmName: json['farm_name'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    alertConsent: json['alert_consent'] as bool? ?? true,
  );
}
