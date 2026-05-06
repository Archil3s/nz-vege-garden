import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';

class AppSettingsRepository {
  const AppSettingsRepository();

  static const _regionIdKey = 'settings.regionId';
  static const _frostRiskKey = 'settings.frostRisk';
  static const _windExposureKey = 'settings.windExposure';
  static const _gardenTypeKey = 'settings.gardenType';
  static const _weeklyReminderEnabledKey = 'settings.weeklyReminderEnabled';
  static const _hasCompletedSetupKey = 'settings.hasCompletedSetup';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = AppSettings.defaultSettings;

    return AppSettings(
      regionId: prefs.getString(_regionIdKey) ?? defaults.regionId,
      frostRisk: prefs.getString(_frostRiskKey) ?? defaults.frostRisk,
      windExposure: prefs.getString(_windExposureKey) ?? defaults.windExposure,
      gardenType: prefs.getString(_gardenTypeKey) ?? defaults.gardenType,
      weeklyReminderEnabled:
          prefs.getBool(_weeklyReminderEnabledKey) ?? defaults.weeklyReminderEnabled,
      hasCompletedSetup:
          prefs.getBool(_hasCompletedSetupKey) ?? defaults.hasCompletedSetup,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_regionIdKey, settings.regionId);
    await prefs.setString(_frostRiskKey, settings.frostRisk);
    await prefs.setString(_windExposureKey, settings.windExposure);
    await prefs.setString(_gardenTypeKey, settings.gardenType);
    await prefs.setBool(_weeklyReminderEnabledKey, settings.weeklyReminderEnabled);
    await prefs.setBool(_hasCompletedSetupKey, settings.hasCompletedSetup);
  }

  Future<void> updateRegion(String regionId) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(regionId: regionId));
  }

  Future<void> updateFrostRisk(String frostRisk) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(frostRisk: frostRisk));
  }

  Future<void> updateWindExposure(String windExposure) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(windExposure: windExposure));
  }

  Future<void> updateGardenType(String gardenType) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(gardenType: gardenType));
  }

  Future<void> updateWeeklyReminderEnabled(bool enabled) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(weeklyReminderEnabled: enabled));
  }

  Future<void> completeSetup(AppSettings settings) async {
    await saveSettings(settings.copyWith(hasCompletedSetup: true));
  }
}
