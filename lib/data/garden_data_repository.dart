import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/crop.dart';
import 'models/nz_region.dart';
import 'models/pest_problem.dart';
import 'models/planting_rule.dart';
import 'models/succession_rule.dart';
import 'models/task_rule.dart';

class GardenDataRepository {
  const GardenDataRepository();

  Future<List<Crop>> loadCrops() async {
    final content = await rootBundle.loadString('assets/data/crops.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(Crop.fromJson)
        .toList(growable: false);
  }

  Future<List<NzRegion>> loadRegions() async {
    final content = await rootBundle.loadString('assets/data/nz_regions.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(NzRegion.fromJson)
        .toList(growable: false);
  }

  Future<List<PlantingRule>> loadPlantingRules() async {
    final content = await rootBundle.loadString('assets/data/planting_rules.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(PlantingRule.fromJson)
        .toList(growable: false);
  }

  Future<List<PestProblem>> loadPestProblems() async {
    final content = await rootBundle.loadString('assets/data/pests.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(PestProblem.fromJson)
        .toList(growable: false);
  }

  Future<List<TaskRule>> loadTaskRules() async {
    final content = await rootBundle.loadString('assets/data/task_rules.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(TaskRule.fromJson)
        .toList(growable: false);
  }

  Future<List<SuccessionRule>> loadSuccessionRules() async {
    final content = await rootBundle.loadString('assets/data/succession_rules.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(SuccessionRule.fromJson)
        .toList(growable: false);
  }

  Future<List<Crop>> cropsForMonthAndRegion({
    required int month,
    required String regionId,
    String? method,
  }) async {
    final crops = await loadCrops();
    final rules = await loadPlantingRules();

    final normalizedMethod = method?.trim().toLowerCase();
    final matchingCropIds = rules
        .where((rule) => rule.appliesToMonth(month))
        .where((rule) => rule.appliesToRegion(regionId))
        .where(
          (rule) => normalizedMethod == null ||
              normalizedMethod.isEmpty ||
              normalizedMethod == 'both' ||
              rule.method.toLowerCase() == normalizedMethod,
        )
        .map((rule) => rule.cropId)
        .toSet();

    return crops
        .where((crop) => matchingCropIds.contains(crop.id))
        .toList(growable: false);
  }
}
