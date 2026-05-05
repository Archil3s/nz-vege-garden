class TaskRule {
  const TaskRule({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.startMonth,
    required this.endMonth,
    required this.regionId,
    required this.cropIds,
    required this.gardenTypes,
    required this.frostRisks,
    required this.windExposures,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final String taskType;
  final int startMonth;
  final int endMonth;
  final String regionId;
  final List<String> cropIds;
  final List<String> gardenTypes;
  final List<String> frostRisks;
  final List<String> windExposures;
  final int priority;

  factory TaskRule.fromJson(Map<String, dynamic> json) {
    return TaskRule(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      taskType: json['taskType'] as String,
      startMonth: json['startMonth'] as int,
      endMonth: json['endMonth'] as int,
      regionId: json['regionId'] as String,
      cropIds: (json['cropIds'] as List<dynamic>).cast<String>(),
      gardenTypes: (json['gardenTypes'] as List<dynamic>).cast<String>(),
      frostRisks: (json['frostRisks'] as List<dynamic>).cast<String>(),
      windExposures: (json['windExposures'] as List<dynamic>).cast<String>(),
      priority: json['priority'] as int,
    );
  }

  factory TaskRule.generated({
    required String id,
    required String title,
    required String description,
    required String taskType,
    required int startMonth,
    required int endMonth,
    required List<String> cropIds,
    required int priority,
  }) {
    return TaskRule(
      id: id,
      title: title,
      description: description,
      taskType: taskType,
      startMonth: startMonth,
      endMonth: endMonth,
      regionId: 'all',
      cropIds: cropIds,
      gardenTypes: const [],
      frostRisks: const [],
      windExposures: const [],
      priority: priority,
    );
  }

  bool appliesToMonth(int month) {
    if (startMonth <= endMonth) {
      return month >= startMonth && month <= endMonth;
    }

    return month >= startMonth || month <= endMonth;
  }

  bool appliesToRegion(String selectedRegionId) {
    return regionId == 'all' || regionId == selectedRegionId;
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
