class AppSettings {
  const AppSettings({
    required this.regionId,
    required this.frostRisk,
    required this.windExposure,
    required this.gardenType,
    required this.weeklyReminderEnabled,
    required this.hasCompletedSetup,
  });

  static const defaultSettings = AppSettings(
    regionId: 'canterbury',
    frostRisk: 'high',
    windExposure: 'moderate',
    gardenType: 'raised_bed',
    weeklyReminderEnabled: false,
    hasCompletedSetup: false,
  );

  final String regionId;
  final String frostRisk;
  final String windExposure;
  final String gardenType;
  final bool weeklyReminderEnabled;
  final bool hasCompletedSetup;

  AppSettings copyWith({
    String? regionId,
    String? frostRisk,
    String? windExposure,
    String? gardenType,
    bool? weeklyReminderEnabled,
    bool? hasCompletedSetup,
  }) {
    return AppSettings(
      regionId: regionId ?? this.regionId,
      frostRisk: frostRisk ?? this.frostRisk,
      windExposure: windExposure ?? this.windExposure,
      gardenType: gardenType ?? this.gardenType,
      weeklyReminderEnabled: weeklyReminderEnabled ?? this.weeklyReminderEnabled,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
    );
  }
}
