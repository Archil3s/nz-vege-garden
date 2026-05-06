import 'dart:convert';

class GardenQuickLog {
  const GardenQuickLog({
    required this.type,
    required this.label,
    required this.createdAtIso,
    this.cropId,
    this.scope,
    this.note,
  });

  final String type;
  final String label;
  final String createdAtIso;
  final String? cropId;
  final String? scope;
  final String? note;

  DateTime get createdAt {
    return DateTime.tryParse(createdAtIso) ?? DateTime.now();
  }

  bool get isCropSpecific => cropId != null && cropId!.isNotEmpty;

  String get targetLabel {
    if (scope != null && scope!.isNotEmpty) {
      return scope!;
    }

    if (isCropSpecific) {
      return cropId!;
    }

    return 'All garden';
  }

  String toStorageString() {
    return jsonEncode({
      'type': type,
      'label': label,
      'createdAtIso': createdAtIso,
      'cropId': cropId,
      'scope': scope,
      'note': note,
    });
  }

  factory GardenQuickLog.fromStorageString(String value) {
    final decoded = jsonDecode(value);

    if (decoded is! Map) {
      return GardenQuickLog(
        type: 'note',
        label: 'Garden note',
        createdAtIso: DateTime.now().toIso8601String(),
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    return GardenQuickLog(
      type: json['type'] as String? ?? 'note',
      label: json['label'] as String? ?? 'Garden note',
      createdAtIso:
          json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
      cropId: json['cropId'] as String?,
      scope: json['scope'] as String?,
      note: json['note'] as String?,
    );
  }
}
