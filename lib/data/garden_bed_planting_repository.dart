import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/garden_bed_planting.dart';

class GardenBedPlantingRepository {
  const GardenBedPlantingRepository();

  static const _plantingsKey = 'gardenBedPlantings.items';

  Future<List<GardenBedPlanting>> loadPlantings() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPlantings = prefs.getString(_plantingsKey);

    if (encodedPlantings == null || encodedPlantings.isEmpty) {
      return const [];
    }

    final data = jsonDecode(encodedPlantings) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(GardenBedPlanting.fromJson)
        .toList(growable: false);
  }

  Future<List<GardenBedPlanting>> loadPlantingsForBed(String bedId) async {
    final plantings = await loadPlantings();

    return plantings
        .where((planting) => planting.bedId == bedId)
        .toList(growable: false);
  }

  Future<void> savePlantings(List<GardenBedPlanting> plantings) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPlantings = jsonEncode(
      plantings.map((planting) => planting.toJson()).toList(growable: false),
    );

    await prefs.setString(_plantingsKey, encodedPlantings);
  }

  Future<GardenBedPlanting> addPlanting(GardenBedPlanting planting) async {
    final plantings = await loadPlantings();
    final updatedPlantings = [...plantings, planting];

    await savePlantings(updatedPlantings);
    return planting;
  }

  Future<void> updatePlanting(GardenBedPlanting updatedPlanting) async {
    final plantings = await loadPlantings();
    final updatedPlantings = plantings
        .map((planting) => planting.id == updatedPlanting.id ? updatedPlanting : planting)
        .toList(growable: false);

    await savePlantings(updatedPlantings);
  }

  Future<void> deletePlanting(String id) async {
    final plantings = await loadPlantings();
    final updatedPlantings = plantings
        .where((planting) => planting.id != id)
        .toList(growable: false);

    await savePlantings(updatedPlantings);
  }

  Future<void> deletePlantingsForBed(String bedId) async {
    final plantings = await loadPlantings();
    final updatedPlantings = plantings
        .where((planting) => planting.bedId != bedId)
        .toList(growable: false);

    await savePlantings(updatedPlantings);
  }
}
