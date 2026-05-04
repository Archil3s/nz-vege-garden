import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/garden_bed.dart';

class GardenBedRepository {
  const GardenBedRepository();

  static const _gardenBedsKey = 'gardenBeds.items';

  Future<List<GardenBed>> loadGardenBeds() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedBeds = prefs.getString(_gardenBedsKey);

    if (encodedBeds == null || encodedBeds.isEmpty) {
      return const [];
    }

    final data = jsonDecode(encodedBeds) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(GardenBed.fromJson)
        .toList(growable: false);
  }

  Future<void> saveGardenBeds(List<GardenBed> beds) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedBeds = jsonEncode(
      beds.map((bed) => bed.toJson()).toList(growable: false),
    );

    await prefs.setString(_gardenBedsKey, encodedBeds);
  }

  Future<GardenBed> addGardenBed(GardenBed bed) async {
    final beds = await loadGardenBeds();
    final updatedBeds = [...beds, bed];

    await saveGardenBeds(updatedBeds);
    return bed;
  }

  Future<void> updateGardenBed(GardenBed updatedBed) async {
    final beds = await loadGardenBeds();
    final updatedBeds = beds
        .map((bed) => bed.id == updatedBed.id ? updatedBed : bed)
        .toList(growable: false);

    await saveGardenBeds(updatedBeds);
  }

  Future<void> deleteGardenBed(String id) async {
    final beds = await loadGardenBeds();
    final updatedBeds = beds.where((bed) => bed.id != id).toList(growable: false);

    await saveGardenBeds(updatedBeds);
  }
}
