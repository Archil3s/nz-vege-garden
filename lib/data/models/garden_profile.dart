class GardenProfile {
  const GardenProfile({
    required this.growingCropIds,
    required this.wishlistCropIds,
    required this.avoidedCropIds,
    required this.goalIds,
    required this.experienceLevel,
    required this.setupComplete,
  });

  static const defaultProfile = GardenProfile(
    growingCropIds: [],
    wishlistCropIds: [],
    avoidedCropIds: [],
    goalIds: ['food_production', 'beginner_friendly'],
    experienceLevel: 'beginner',
    setupComplete: false,
  );

  final List<String> growingCropIds;
  final List<String> wishlistCropIds;
  final List<String> avoidedCropIds;
  final List<String> goalIds;
  final String experienceLevel;
  final bool setupComplete;

  GardenProfile copyWith({
    List<String>? growingCropIds,
    List<String>? wishlistCropIds,
    List<String>? avoidedCropIds,
    List<String>? goalIds,
    String? experienceLevel,
    bool? setupComplete,
  }) {
    return GardenProfile(
      growingCropIds: growingCropIds ?? this.growingCropIds,
      wishlistCropIds: wishlistCropIds ?? this.wishlistCropIds,
      avoidedCropIds: avoidedCropIds ?? this.avoidedCropIds,
      goalIds: goalIds ?? this.goalIds,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }

  bool isGrowing(String cropId) => growingCropIds.contains(cropId);
  bool isWishlist(String cropId) => wishlistCropIds.contains(cropId);
  bool isAvoided(String cropId) => avoidedCropIds.contains(cropId);
}
