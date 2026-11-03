class AnimalModel {
  final String id;
  final String farmerId;
  final String speciesCode; // 'cattle', 'buffalo'
  final String? breedCode; // 'gir', 'khillar', 'murrah', etc.
  final String? name;
  final String? tagNumber;
  final String sex; // 'female', 'male'
  final String? birthDate;
  final String? markings;
  final String? photoPath;
  final bool isSynced;
  final DateTime createdAt;

  AnimalModel({
    required this.id,
    required this.farmerId,
    required this.speciesCode,
    this.breedCode,
    this.name,
    this.tagNumber,
    required this.sex,
    this.birthDate,
    this.markings,
    this.photoPath,
    this.isSynced = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => name?.isNotEmpty == true ? name! : (tagNumber ?? 'Unnamed Cattle');

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'species_code': speciesCode,
    'breed_code': breedCode,
    'name': name,
    'tag_number': tagNumber,
    'sex': sex,
    'birth_date': birthDate,
    'markings': markings,
    'photo_path': photoPath,
    'is_synced': isSynced,
    'created_at': createdAt.toIso8601String(),
  };

  factory AnimalModel.fromJson(Map<String, dynamic> json) => AnimalModel(
    id: json['id'] as String,
    farmerId: json['farmer_id'] as String? ?? 'demo-farmer',
    speciesCode: json['species_code'] as String? ?? 'cattle',
    breedCode: json['breed_code'] as String?,
    name: json['name'] as String?,
    tagNumber: json['tag_number'] as String?,
    sex: json['sex'] as String? ?? 'female',
    birthDate: json['birth_date'] as String?,
    markings: json['markings'] as String?,
    photoPath: json['photo_path'] as String?,
    isSynced: json['is_synced'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
  );

  AnimalModel copyWith({
    String? id,
    String? farmerId,
    String? speciesCode,
    String? breedCode,
    String? name,
    String? tagNumber,
    String? sex,
    String? birthDate,
    String? markings,
    String? photoPath,
    bool? isSynced,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      speciesCode: speciesCode ?? this.speciesCode,
      breedCode: breedCode ?? this.breedCode,
      name: name ?? this.name,
      tagNumber: tagNumber ?? this.tagNumber,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      markings: markings ?? this.markings,
      photoPath: photoPath ?? this.photoPath,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
    );
  }
}
