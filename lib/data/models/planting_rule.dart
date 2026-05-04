class PlantingRule {
  const PlantingRule({
    required this.cropId,
    required this.regionId,
    required this.method,
    required this.startMonth,
    required this.endMonth,
    required this.riskNote,
  });

  final String cropId;
  final String regionId;
  final String method;
  final int startMonth;
  final int endMonth;
  final String riskNote;

  factory PlantingRule.fromJson(Map<String, dynamic> json) {
    return PlantingRule(
      cropId: json['cropId'] as String,
      regionId: json['regionId'] as String,
      method: json['method'] as String,
      startMonth: json['startMonth'] as int,
      endMonth: json['endMonth'] as int,
      riskNote: json['riskNote'] as String,
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
}
