class AppSettings {
  const AppSettings({
    required this.regionId,
    required this.frostRisk,
    required this.windExposure,
    required this.gardenType,
  });

  static const defaultSettings = AppSettings(
    regionId: 'canterbury',
    frostRisk: 'high',
    windExposure: 'moderate',
    gardenType: 'raised_bed',
  );

  final String regionId;
  final String frostRisk;
  final String windExposure;
  final String gardenType;

  AppSettings copyWith({
    String? regionId,
    String? frostRisk,
    String? windExposure,
    String? gardenType,
  }) {
    return AppSettings(
      regionId: regionId ?? this.regionId,
      frostRisk: frostRisk ?? this.frostRisk,
      windExposure: windExposure ?? this.windExposure,
      gardenType: gardenType ?? this.gardenType,
    );
  }
}
