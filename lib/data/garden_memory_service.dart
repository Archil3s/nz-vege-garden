import 'models/crop.dart';
import 'models/garden_memory.dart';
import 'models/garden_profile.dart';
import 'models/garden_quick_log.dart';

class GardenMemoryService {
  const GardenMemoryService();

  GardenMemorySummary buildSummary({
    required GardenProfile profile,
    required Map<String, Crop> cropById,
    required List<GardenQuickLog> logs,
    required DateTime now,
  }) {
    final cropMemories = profile.growingCropIds
        .map((cropId) => cropById[cropId])
        .whereType<Crop>()
        .map((crop) => _buildCropMemory(crop, logs))
        .toList(growable: false)
      ..sort((a, b) {
        final aDate = a.logs.isEmpty ? DateTime(1900) : a.logs.first.createdAt;
        final bDate = b.logs.isEmpty ? DateTime(1900) : b.logs.first.createdAt;

        return bDate.compareTo(aDate);
      });

    final nudges = <GardenNudge>[
      ..._buildCropNudges(cropMemories, now),
      ..._buildGardenLogNudges(profile, logs, now),
    ]..sort((a, b) => b.priority.compareTo(a.priority));

    return GardenMemorySummary(
      cropMemories: cropMemories,
      nudges: nudges.take(8).toList(growable: false),
      recentLogs: logs.take(12).toList(growable: false),
    );
  }

  CropMemory _buildCropMemory(Crop crop, List<GardenQuickLog> logs) {
    final cropLogs = logs
        .where((log) => log.cropId == crop.id)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return CropMemory(
      crop: crop,
      logs: cropLogs,
      lastWatered: _latestOfType(cropLogs, 'watered'),
      lastSowed: _latestOfType(cropLogs, 'sowed'),
      lastTransplanted: _latestOfType(cropLogs, 'transplanted'),
      lastHarvested: _latestOfType(cropLogs, 'harvested'),
      lastPestSeen: _latestOfType(cropLogs, 'pest_seen'),
    );
  }

  GardenQuickLog? _latestOfType(List<GardenQuickLog> logs, String type) {
    for (final log in logs) {
      if (log.type == type) {
        return log;
      }
    }

    return null;
  }

  List<GardenNudge> _buildCropNudges(
    List<CropMemory> cropMemories,
    DateTime now,
  ) {
    final nudges = <GardenNudge>[];

    for (final memory in cropMemories) {
      final crop = memory.crop;

      if (memory.lastWatered == null) {
        nudges.add(
          GardenNudge(
            title: 'No water log for ${crop.commonName}',
            body: 'Log watering once so the app can start tracking this crop.',
            priority: crop.waterRequirement == 'high' ? 88 : 62,
            type: 'water',
            cropId: crop.id,
          ),
        );
      } else {
        final days = now.difference(memory.lastWatered!.createdAt).inDays;

        if (days >= 3 && crop.waterRequirement != 'low') {
          nudges.add(
            GardenNudge(
              title: 'Check ${crop.commonName} moisture',
              body:
                  'Last watered $days days ago. Check the root zone, not just the surface.',
              priority: crop.waterRequirement == 'high' ? 92 : 74,
              type: 'water',
              cropId: crop.id,
            ),
          );
        }
      }

      if (memory.lastPestSeen != null) {
        final days = now.difference(memory.lastPestSeen!.createdAt).inDays;

        if (days <= 7) {
          nudges.add(
            GardenNudge(
              title: 'Re-check ${crop.commonName}',
              body:
                  'You logged pest activity $days days ago. Check leaf undersides again.',
              priority: 90 - days,
              type: 'pest',
              cropId: crop.id,
            ),
          );
        }
      }

      if (memory.lastSowed != null) {
        final days = now.difference(memory.lastSowed!.createdAt).inDays;

        if (days >= 7 && days <= 21) {
          nudges.add(
            GardenNudge(
              title: 'Check ${crop.commonName} seedlings',
              body:
                  'Sowed $days days ago. Check germination, moisture, slugs, and thinning.',
              priority: 76,
              type: 'seedlings',
              cropId: crop.id,
            ),
          );
        }
      }

      if (crop.frostTender) {
        nudges.add(
          GardenNudge(
            title: '${crop.commonName} is frost tender',
            body: 'Keep frost protection in mind if cold nights are coming.',
            priority: 55,
            type: 'frost',
            cropId: crop.id,
          ),
        );
      }
    }

    return nudges;
  }

  List<GardenNudge> _buildGardenLogNudges(
    GardenProfile profile,
    List<GardenQuickLog> logs,
    DateTime now,
  ) {
    final nudges = <GardenNudge>[];

    final lastContainerWater = _latestScope(logs, 'watered', 'Containers');
    if (lastContainerWater != null) {
      final days = now.difference(lastContainerWater.createdAt).inDays;

      if (days >= 2) {
        nudges.add(
          GardenNudge(
            title: 'Check containers',
            body: 'Containers were last logged watered $days days ago.',
            priority: 78,
            type: 'containers',
          ),
        );
      }
    }

    final lastPest = _latestType(logs, 'pest_seen');
    if (lastPest != null) {
      final days = now.difference(lastPest.createdAt).inDays;

      if (days <= 7) {
        nudges.add(
          GardenNudge(
            title: 'Follow up pest sighting',
            body:
                'You logged a pest issue $days days ago. Look for fresh damage.',
            priority: 84,
            type: 'pest',
            cropId: lastPest.cropId,
          ),
        );
      }
    }

    if (profile.growingCropIds.isEmpty) {
      nudges.add(
        const GardenNudge(
          title: 'Add crops to your Garden Passport',
          body:
              'Crop-specific memory starts once you add what you are growing.',
          priority: 80,
          type: 'passport',
        ),
      );
    }

    return nudges;
  }

  GardenQuickLog? _latestType(List<GardenQuickLog> logs, String type) {
    for (final log in logs) {
      if (log.type == type) {
        return log;
      }
    }

    return null;
  }

  GardenQuickLog? _latestScope(
    List<GardenQuickLog> logs,
    String type,
    String scope,
  ) {
    for (final log in logs) {
      if (log.type == type && log.scope == scope) {
        return log;
      }
    }

    return null;
  }
}
