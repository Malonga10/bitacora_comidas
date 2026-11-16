class MealEntry {
  final int? id;
  final String title;
  final String mealType;
  final String notes;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const MealEntry({
    this.id,
    required this.title,
    required this.mealType,
    required this.notes,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'meal_type': mealType,
      'notes': notes,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      mealType: map['meal_type'] as String,
      notes: (map['notes'] as String?) ?? '',
      imagePath: map['image_path'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MealEntry copyWith({
    int? id,
    String? title,
    String? mealType,
    String? notes,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}