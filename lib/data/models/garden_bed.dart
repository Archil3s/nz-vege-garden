class GardenBed {
  const GardenBed({
    required this.id,
    required this.name,
    required this.type,
    required this.lengthCm,
    required this.widthCm,
    required this.layoutStyle,
    required this.sunExposure,
    required this.windExposure,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final int? lengthCm;
  final int? widthCm;
  final String layoutStyle;
  final String sunExposure;
  final String windExposure;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int? get areaSquareCm {
    if (lengthCm == null || widthCm == null) {
      return null;
    }

    return lengthCm! * widthCm!;
  }

  double? get areaSquareMeters {
    final area = areaSquareCm;
    if (area == null) {
      return null;
    }

    return area / 10000;
  }

  GardenBed copyWith({
    String? id,
    String? name,
    String? type,
    int? lengthCm,
    int? widthCm,
    String? layoutStyle,
    String? sunExposure,
    String? windExposure,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GardenBed(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      sunExposure: sunExposure ?? this.sunExposure,
      windExposure: windExposure ?? this.windExposure,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GardenBed.create({
    required String name,
    required String type,
    int? lengthCm,
    int? widthCm,
    String layoutStyle = 'rows',
    String sunExposure = 'full_sun',
    String windExposure = 'moderate',
    String notes = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();

    return GardenBed(
      id: timestamp.microsecondsSinceEpoch.toString(),
      name: name,
      type: type,
      lengthCm: lengthCm,
      widthCm: widthCm,
      layoutStyle: layoutStyle,
      sunExposure: sunExposure,
      windExposure: windExposure,
      notes: notes,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory GardenBed.fromJson(Map<String, dynamic> json) {
    return GardenBed(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      lengthCm: json['lengthCm'] as int?,
      widthCm: json['widthCm'] as int?,
      layoutStyle: json['layoutStyle'] as String? ?? 'rows',
      sunExposure: json['sunExposure'] as String,
      windExposure: json['windExposure'] as String,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'layoutStyle': layoutStyle,
      'sunExposure': sunExposure,
      'windExposure': windExposure,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
