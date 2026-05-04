class PestProblem {
  const PestProblem({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.signs,
    required this.commonCrops,
    required this.actions,
    required this.prevention,
    required this.seasonNotes,
  });

  final String id;
  final String name;
  final String category;
  final String summary;
  final List<String> signs;
  final List<String> commonCrops;
  final List<String> actions;
  final List<String> prevention;
  final String seasonNotes;

  factory PestProblem.fromJson(Map<String, dynamic> json) {
    return PestProblem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      signs: (json['signs'] as List<dynamic>).cast<String>(),
      commonCrops: (json['commonCrops'] as List<dynamic>).cast<String>(),
      actions: (json['actions'] as List<dynamic>).cast<String>(),
      prevention: (json['prevention'] as List<dynamic>).cast<String>(),
      seasonNotes: json['seasonNotes'] as String,
    );
  }
}
