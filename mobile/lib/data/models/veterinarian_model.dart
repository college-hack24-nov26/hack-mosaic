class VeterinarianModel {
  final String id;
  final String name;
  final String qualification;
  final String registrationNumber;
  final String clinicName;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final bool isVerified;
  final bool isParaVet;
  final String workingHours;
  final double? distanceKm;

  const VeterinarianModel({
    required this.id,
    required this.name,
    required this.qualification,
    required this.registrationNumber,
    required this.clinicName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.isVerified = true,
    this.isParaVet = false,
    this.workingHours = '9:00 AM – 5:00 PM',
    this.distanceKm,
  });

  VeterinarianModel copyWith({
    double? distanceKm,
  }) {
    return VeterinarianModel(
      id: id,
      name: name,
      qualification: qualification,
      registrationNumber: registrationNumber,
      clinicName: clinicName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      isVerified: isVerified,
      isParaVet: isParaVet,
      workingHours: workingHours,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'qualification': qualification,
    'registration_number': registrationNumber,
    'clinic_name': clinicName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'phone': phone,
    'is_verified': isVerified,
    'is_para_vet': isParaVet,
    'working_hours': workingHours,
    'distance_km': distanceKm,
  };

  factory VeterinarianModel.fromJson(Map<String, dynamic> json) => VeterinarianModel(
    id: json['id'] as String,
    name: json['name'] as String,
    qualification: json['qualification'] as String? ?? 'B.V.Sc & A.H.',
    registrationNumber: json['registration_number'] as String,
    clinicName: json['clinic_name'] as String,
    address: json['address'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    phone: json['phone'] as String,
    isVerified: json['is_verified'] as bool? ?? true,
    isParaVet: json['is_para_vet'] as bool? ?? false,
    workingHours: json['working_hours'] as String? ?? '9:00 AM – 5:00 PM',
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );
}

