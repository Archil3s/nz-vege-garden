import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/nz_region.dart';
import 'models/pest_problem.dart';

class GardenDataRepository {
  const GardenDataRepository();

  Future<List<NzRegion>> loadRegions() async {
    final content = await rootBundle.loadString('assets/data/nz_regions.json');
    final data = jsonDecode(content) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(NzRegion.fromJson)
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
}
