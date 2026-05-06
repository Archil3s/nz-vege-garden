import 'crop.dart';
import 'garden_quick_log.dart';

class GardenMemorySummary {
  const GardenMemorySummary({
    required this.cropMemories,
    required this.nudges,
    required this.recentLogs,
  });

  final List<CropMemory> cropMemories;
  final List<GardenNudge> nudges;
  final List<GardenQuickLog> recentLogs;
}

class CropMemory {
  const CropMemory({
    required this.crop,
    required this.logs,
    this.lastWatered,
    this.lastSowed,
    this.lastTransplanted,
    this.lastHarvested,
    this.lastPestSeen,
  });

  final Crop crop;
  final List<GardenQuickLog> logs;
  final GardenQuickLog? lastWatered;
  final GardenQuickLog? lastSowed;
  final GardenQuickLog? lastTransplanted;
  final GardenQuickLog? lastHarvested;
  final GardenQuickLog? lastPestSeen;

  bool get hasAnyMemory => logs.isNotEmpty;
}

class GardenNudge {
  const GardenNudge({
    required this.title,
    required this.body,
    required this.priority,
    required this.type,
    this.cropId,
  });

  final String title;
  final String body;
  final int priority;
  final String type;
  final String? cropId;
}
