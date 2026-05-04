class Crop {
  const Crop({
    required this.id,
    required this.commonName,
    required this.category,
    required this.summary,
    required this.sunRequirement,
    required this.waterRequirement,
    required this.spacingCm,
    required this.daysToHarvestMin,
    required this.daysToHarvestMax,
    required this.frostTender,
    required this.containerFriendly,
    required this.beginnerFriendly,
  });

  final String id;
  final String commonName;
  final String category;
  final String summary;
  final String sunRequirement;
  final String waterRequirement;
  final int spacingCm;
  final int daysToHarvestMin;
  final int daysToHarvestMax;
  final bool frostTender;
  final bool containerFriendly;
  final bool beginnerFriendly;

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      commonName: json['commonName'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      sunRequirement: json['sunRequirement'] as String,
      waterRequirement: json['waterRequirement'] as String,
      spacingCm: json['spacingCm'] as int,
      daysToHarvestMin: json['daysToHarvestMin'] as int,
      daysToHarvestMax: json['daysToHarvestMax'] as int,
      frostTender: json['frostTender'] as bool,
      containerFriendly: json['containerFriendly'] as bool,
      beginnerFriendly: json['beginnerFriendly'] as bool,
    );
  }
}
