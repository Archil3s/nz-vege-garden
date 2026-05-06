import 'dart:convert';

class GardenQuickLog {
  const GardenQuickLog({
    required this.type,
    required this.label,
    required this.createdAtIso,
    this.cropId,
    this.note,
  });

  final String type;
  final String label;
  final String createdAtIso;
  final String? cropId;
  final String? note;

  DateTime get createdAt {
    return DateTime.tryParse(createdAtIso) ?? DateTime.now();
  }

  String toStorageString() {
    return jsonEncode({
      'type': type,
      'label': label,
      'createdAtIso': createdAtIso,
      'cropId': cropId,
      'note': note,
    });
  }

  factory GardenQuickLog.fromStorageString(String value) {
    final json = Map<String, dynamic>.from(jsonDecode(value) as Map);

    return GardenQuickLog(
      type: json['type'] as String? ?? 'note',
      label: json['label'] as String? ?? 'Garden note',
      createdAtIso:
          json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
      cropId: json['cropId'] as String?,
      note: json['note'] as String?,
    );
  }
}
