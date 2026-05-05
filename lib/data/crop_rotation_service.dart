import 'models/garden_bed.dart';
import 'models/garden_bed_planting.dart';

class CropFamilyInfo {
  const CropFamilyInfo({
    required this.id,
    required this.label,
    required this.shortAdvice,
  });

  final String id;
  final String label;
  final String shortAdvice;
}

class BedRotationInsight {
  const BedRotationInsight({
    required this.bed,
    required this.familyCounts,
    required this.riskFamilies,
    required this.recentPlantings,
  });

  final GardenBed bed;
  final Map<String, int> familyCounts;
  final List<CropFamilyInfo> riskFamilies;
  final List<GardenBedPlanting> recentPlantings;

  bool get hasRisk => riskFamilies.isNotEmpty;
}

class CropRotationService {
  const CropRotationService();

  static const _families = <String, CropFamilyInfo>{
    'solanaceae': CropFamilyInfo(
      id: 'solanaceae',
      label: 'Tomato / potato family',
      shortAdvice: 'Avoid repeating tomato, potato, capsicum, or chilli in the same bed too often.',
    ),
    'brassicas': CropFamilyInfo(
      id: 'brassicas',
      label: 'Brassicas',
      shortAdvice: 'Rotate cabbage, broccoli, cauliflower, and kale to reduce pest and disease pressure.',
    ),
    'legumes': CropFamilyInfo(
      id: 'legumes',
      label: 'Legumes',
      shortAdvice: 'Beans and peas are useful before hungry crops because they support soil nitrogen.',
    ),
    'alliums': CropFamilyInfo(
      id: 'alliums',
      label: 'Onion family',
      shortAdvice: 'Rotate onion, garlic, leek, and spring onion to reduce disease buildup.',
    ),
    'cucurbits': CropFamilyInfo(
      id: 'cucurbits',
      label: 'Cucurbits',
      shortAdvice: 'Give courgette, cucumber, and pumpkin room and avoid repeating them in the same bed.',
    ),
    'roots': CropFamilyInfo(
      id: 'roots',
      label: 'Roots',
      shortAdvice: 'Root crops benefit from loose soil and are useful after leafy crops.',
    ),
    'leafy': CropFamilyInfo(
      id: 'leafy',
      label: 'Leafy greens',
      shortAdvice: 'Leafy crops are flexible but still benefit from rotating with roots or legumes.',
    ),
    'herbs': CropFamilyInfo(
      id: 'herbs',
      label: 'Herbs',
      shortAdvice: 'Herbs are generally lower rotation risk and useful around bed edges.',
    ),
    'grasses': CropFamilyInfo(
      id: 'grasses',
      label: 'Corn / grasses',
      shortAdvice: 'Corn is hungry and is often useful after legumes or well-fed soil.',
    ),
  };

  static const _cropFamilies = <String, String>{
    'tomato': 'solanaceae',
    'potato': 'solanaceae',
    'capsicum': 'solanaceae',
    'chilli': 'solanaceae',
    'kale': 'brassicas',
    'cabbage': 'brassicas',
    'broccoli': 'brassicas',
    'cauliflower': 'brassicas',
    'radish': 'brassicas',
    'peas': 'legumes',
    'broad_beans': 'legumes',
    'dwarf_beans': 'legumes',
    'onion': 'alliums',
    'garlic': 'alliums',
    'leek': 'alliums',
    'spring_onion': 'alliums',
    'courgette': 'cucurbits',
    'cucumber': 'cucurbits',
    'pumpkin': 'cucurbits',
    'carrot': 'roots',
    'beetroot': 'roots',
    'kumara': 'roots',
    'lettuce': 'leafy',
    'spinach': 'leafy',
    'silverbeet': 'leafy',
    'basil': 'herbs',
    'parsley': 'herbs',
    'coriander': 'herbs',
    'chives': 'herbs',
    'sweetcorn': 'grasses',
  };

  CropFamilyInfo? familyForCropId(String cropId) {
    final familyId = _cropFamilies[cropId];
    if (familyId == null) {
      return null;
    }

    return _families[familyId];
  }

  List<CropFamilyInfo> allFamiliesForPlantings(List<GardenBedPlanting> plantings) {
    final seen = <String>{};
    final families = <CropFamilyInfo>[];

    for (final planting in plantings) {
      final family = familyForCropId(planting.cropId);
      if (family == null || seen.contains(family.id)) {
        continue;
      }

      seen.add(family.id);
      families.add(family);
    }

    families.sort((a, b) => a.label.compareTo(b.label));
    return families;
  }

  List<BedRotationInsight> buildBedRotationInsights({
    required List<GardenBed> beds,
    required List<GardenBedPlanting> plantings,
  }) {
    return beds.map((bed) {
      final bedPlantings = plantings
          .where((planting) => planting.bedId == bed.id)
          .toList(growable: false)
        ..sort((a, b) => b.plantedDate.compareTo(a.plantedDate));
      final familyCounts = <String, int>{};

      for (final planting in bedPlantings) {
        final family = familyForCropId(planting.cropId);
        if (family == null) {
          continue;
        }

        familyCounts.update(family.id, (count) => count + 1, ifAbsent: () => 1);
      }

      final riskFamilies = familyCounts.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => _families[entry.key])
          .whereType<CropFamilyInfo>()
          .toList(growable: false)
        ..sort((a, b) => a.label.compareTo(b.label));

      return BedRotationInsight(
        bed: bed,
        familyCounts: familyCounts,
        riskFamilies: riskFamilies,
        recentPlantings: bedPlantings.take(5).toList(growable: false),
      );
    }).toList(growable: false);
  }

  CropFamilyInfo? rotationRiskForCropInBed({
    required String cropId,
    required String bedId,
    required List<GardenBedPlanting> plantings,
  }) {
    final family = familyForCropId(cropId);
    if (family == null) {
      return null;
    }

    final hasRecentSameFamily = plantings
        .where((planting) => planting.bedId == bedId)
        .where((planting) => planting.status != 'failed')
        .any((planting) => familyForCropId(planting.cropId)?.id == family.id);

    return hasRecentSameFamily ? family : null;
  }
}
