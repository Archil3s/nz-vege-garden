class GardenBedPlanting {
  const GardenBedPlanting({
    required this.id,
    required this.bedId,
    required this.cropId,
    required this.cropName,
    required this.status,
    required this.plantedDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bedId;
  final String cropId;
  final String cropName;
  final String status;
  final DateTime plantedDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  GardenBedPlanting copyWith({
    String? id,
    String? bedId,
    String? cropId,
    String? cropName,
    String? status,
    DateTime? plantedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GardenBedPlanting(
      id: id ?? this.id,
      bedId: bedId ?? this.bedId,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      status: status ?? this.status,
      plantedDate: plantedDate ?? this.plantedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GardenBedPlanting.create({
    required String bedId,
    required String cropId,
    required String cropName,
    String status = 'planned',
    DateTime? plantedDate,
    String notes = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();

    return GardenBedPlanting(
      id: timestamp.microsecondsSinceEpoch.toString(),
      bedId: bedId,
      cropId: cropId,
      cropName: cropName,
      status: status,
      plantedDate: plantedDate ?? timestamp,
      notes: notes,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory GardenBedPlanting.fromJson(Map<String, dynamic> json) {
    return GardenBedPlanting(
      id: json['id'] as String,
      bedId: json['bedId'] as String,
      cropId: json['cropId'] as String,
      cropName: json['cropName'] as String,
      status: json['status'] as String,
      plantedDate: DateTime.parse(json['plantedDate'] as String),
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedId': bedId,
      'cropId': cropId,
      'cropName': cropName,
      'status': status,
      'plantedDate': plantedDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
