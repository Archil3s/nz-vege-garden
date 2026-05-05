class SuccessionRule {
  const SuccessionRule({
    required this.id,
    required this.cropId,
    required this.title,
    required this.description,
    required this.startMonth,
    required this.endMonth,
    required this.intervalDays,
    required this.gardenTypes,
    required this.frostRisks,
    required this.windExposures,
    required this.priority,
  });

  final String id;
  final String cropId;
  final String title;
  final String description;
  final int startMonth;
  final int endMonth;
  final int intervalDays;
  final List<String> gardenTypes;
  final List<String> frostRisks;
  final List<String> windExposures;
  final int priority;

  factory SuccessionRule.fromJson(Map<String, dynamic> json) {
    return SuccessionRule(
      id: json['id'] as String,
      cropId: json['cropId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startMonth: json['startMonth'] as int,
      endMonth: json['endMonth'] as int,
      intervalDays: json['intervalDays'] as int,
      gardenTypes: (json['gardenTypes'] as List<dynamic>).cast<String>(),
      frostRisks: (json['frostRisks'] as List<dynamic>).cast<String>(),
      windExposures: (json['windExposures'] as List<dynamic>).cast<String>(),
      priority: json['priority'] as int,
    );
  }

  bool appliesToMonth(int month) {
    if (startMonth <= endMonth) {
      return month >= startMonth && month <= endMonth;
    }

    return month >= startMonth || month <= endMonth;
  }

  bool appliesToGardenType(String selectedGardenType) {
    return gardenTypes.isEmpty || gardenTypes.contains(selectedGardenType);
  }

  bool appliesToFrostRisk(String selectedFrostRisk) {
    return frostRisks.isEmpty || frostRisks.contains(selectedFrostRisk);
  }

  bool appliesToWindExposure(String selectedWindExposure) {
    return windExposures.isEmpty || windExposures.contains(selectedWindExposure);
  }
}
