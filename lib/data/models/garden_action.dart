enum GardenActionType {
  sow,
  transplant,
  plant,
  harvest,
  watch,
  prep,
}

class GardenAction {
  const GardenAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.priority,
    required this.month,
    required this.monthLabel,
    required this.tags,
    required this.steps,
    this.cropId,
    this.cropName,
  });

  final GardenActionType type;
  final String title;
  final String subtitle;
  final String reason;
  final int priority;
  final int month;
  final String monthLabel;
  final List<String> tags;
  final List<String> steps;
  final String? cropId;
  final String? cropName;

  bool get hasCrop => cropId != null && cropName != null;
}
