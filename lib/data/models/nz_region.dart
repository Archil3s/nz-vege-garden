class NzRegion {
  const NzRegion({
    required this.id,
    required this.name,
    required this.island,
    required this.climateSummary,
    required this.defaultFrostRisk,
    required this.defaultWindRisk,
  });

  final String id;
  final String name;
  final String island;
  final String climateSummary;
  final String defaultFrostRisk;
  final String defaultWindRisk;

  factory NzRegion.fromJson(Map<String, dynamic> json) {
    return NzRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      island: json['island'] as String,
      climateSummary: json['climateSummary'] as String,
      defaultFrostRisk: json['defaultFrostRisk'] as String,
      defaultWindRisk: json['defaultWindRisk'] as String,
    );
  }
}
