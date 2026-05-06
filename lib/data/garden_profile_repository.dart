import 'package:shared_preferences/shared_preferences.dart';

import 'models/garden_profile.dart';

class GardenProfileRepository {
  const GardenProfileRepository();

  static const _growingCropIdsKey = 'gardenProfile.growingCropIds';
  static const _wishlistCropIdsKey = 'gardenProfile.wishlistCropIds';
  static const _avoidedCropIdsKey = 'gardenProfile.avoidedCropIds';
  static const _goalIdsKey = 'gardenProfile.goalIds';
  static const _experienceLevelKey = 'gardenProfile.experienceLevel';
  static const _setupCompleteKey = 'gardenProfile.setupComplete';

  Future<GardenProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = GardenProfile.defaultProfile;

    return GardenProfile(
      growingCropIds:
          prefs.getStringList(_growingCropIdsKey) ?? defaults.growingCropIds,
      wishlistCropIds:
          prefs.getStringList(_wishlistCropIdsKey) ?? defaults.wishlistCropIds,
      avoidedCropIds:
          prefs.getStringList(_avoidedCropIdsKey) ?? defaults.avoidedCropIds,
      goalIds: prefs.getStringList(_goalIdsKey) ?? defaults.goalIds,
      experienceLevel:
          prefs.getString(_experienceLevelKey) ?? defaults.experienceLevel,
      setupComplete: prefs.getBool(_setupCompleteKey) ?? defaults.setupComplete,
    );
  }

  Future<void> saveProfile(GardenProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_growingCropIdsKey, profile.growingCropIds);
    await prefs.setStringList(_wishlistCropIdsKey, profile.wishlistCropIds);
    await prefs.setStringList(_avoidedCropIdsKey, profile.avoidedCropIds);
    await prefs.setStringList(_goalIdsKey, profile.goalIds);
    await prefs.setString(_experienceLevelKey, profile.experienceLevel);
    await prefs.setBool(_setupCompleteKey, profile.setupComplete);
  }
}
