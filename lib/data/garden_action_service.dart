import 'models/app_settings.dart';
import 'models/crop.dart';
import 'models/garden_action.dart';
import 'models/planting_rule.dart';

class GardenActionService {
  const GardenActionService();

  List<GardenAction> buildActions({
    required List<Crop> crops,
    required List<PlantingRule> rules,
    required AppSettings settings,
    required int month,
  }) {
    final cropById = {for (final crop in crops) crop.id: crop};
    final actions = <GardenAction>[];

    final relevantRules = rules
        .where((rule) => rule.appliesToRegion(settings.regionId))
        .where((rule) => cropById.containsKey(rule.cropId))
        .toList(growable: false);

    for (final rule in relevantRules) {
      final crop = cropById[rule.cropId]!;

      if (rule.appliesToMonth(month)) {
        final type = _typeForMethod(rule.method);
        actions.add(
          GardenAction(
            type: type,
            title: '${_verbForType(type)} ${crop.commonName}',
            subtitle: _subtitleForCropAction(
                crop: crop, type: type, settings: settings),
            reason: rule.riskNote,
            priority: _priorityForCropAction(
              crop: crop,
              type: type,
              settings: settings,
              month: month,
            ),
            month: month,
            monthLabel: _monthName(month),
            tags: _tagsForCrop(crop, rule),
            steps: _stepsForCropAction(
                crop: crop, type: type, rule: rule, settings: settings),
            cropId: crop.id,
            cropName: crop.commonName,
          ),
        );
      }

      final harvestStart = _offsetMonth(
        rule.startMonth,
        (crop.daysToHarvestMin / 30).floor(),
      );
      final harvestEnd = _offsetMonth(
        rule.endMonth,
        (crop.daysToHarvestMax / 30).ceil(),
      );

      if (_monthInRange(
          month: month, startMonth: harvestStart, endMonth: harvestEnd)) {
        actions.add(
          GardenAction(
            type: GardenActionType.harvest,
            title: 'Check ${crop.commonName}',
            subtitle:
                'Likely harvest window based on ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days.',
            reason:
                'Harvest timing is estimated from the planting window and days-to-harvest data.',
            priority: _priorityForCropAction(
              crop: crop,
              type: GardenActionType.harvest,
              settings: settings,
              month: month,
            ),
            month: month,
            monthLabel: _monthName(month),
            tags: [
              'Harvest',
              '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
              if (crop.beginnerFriendly) 'Easy',
            ],
            steps: [
              'Check mature plants every few days during the harvest window.',
              'Pick gently to avoid damaging stems, roots, or new flowers.',
              'Harvest regularly for crops that keep producing.',
              'Log the harvest if you want to compare varieties later.',
            ],
            cropId: crop.id,
            cropName: crop.commonName,
          ),
        );
      }
    }

    actions.addAll(_watchActions(settings: settings, month: month));

    if (actions
        .where((action) => action.type != GardenActionType.watch)
        .isEmpty) {
      actions.add(_quietMonthPrepAction(month));
    }

    actions.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final typeCompare = a.type.index.compareTo(b.type.index);
      if (typeCompare != 0) {
        return typeCompare;
      }

      return a.title.compareTo(b.title);
    });

    return actions;
  }

  GardenActionType _typeForMethod(String method) {
    return switch (method) {
      'transplant' => GardenActionType.transplant,
      'plant_tubers' => GardenActionType.plant,
      'plant_crowns' => GardenActionType.plant,
      _ => GardenActionType.sow,
    };
  }

  String _verbForType(GardenActionType type) {
    return switch (type) {
      GardenActionType.sow => 'Sow',
      GardenActionType.transplant => 'Transplant',
      GardenActionType.plant => 'Plant',
      GardenActionType.harvest => 'Harvest',
      GardenActionType.watch => 'Watch',
      GardenActionType.prep => 'Prepare',
    };
  }

  String _subtitleForCropAction({
    required Crop crop,
    required GardenActionType type,
    required AppSettings settings,
  }) {
    if (settings.gardenType == 'container' && crop.containerFriendly) {
      return 'Good container option. ${crop.spacingCm} cm spacing.';
    }

    if (crop.beginnerFriendly) {
      return 'Beginner-friendly. ${crop.spacingCm} cm spacing.';
    }

    if (crop.frostTender && settings.frostRisk == 'high') {
      return 'Frost tender. Use protection or wait for warmer nights.';
    }

    return '${crop.spacingCm} cm spacing · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days.';
  }

  int _priorityForCropAction({
    required Crop crop,
    required GardenActionType type,
    required AppSettings settings,
    required int month,
  }) {
    var score = 50;

    score += switch (type) {
      GardenActionType.sow => 12,
      GardenActionType.transplant => 14,
      GardenActionType.plant => 13,
      GardenActionType.harvest => 7,
      GardenActionType.watch => 5,
      GardenActionType.prep => 2,
    };

    if (crop.beginnerFriendly) {
      score += 10;
    }

    if (settings.gardenType == 'container') {
      score += crop.containerFriendly ? 12 : -12;
    }

    if (settings.frostRisk == 'high' && crop.frostTender) {
      score -= _isCoolMonth(month) ? 18 : 5;
    }

    if (settings.windExposure == 'exposed' &&
        type == GardenActionType.transplant) {
      score -= 5;
    }

    if (crop.waterRequirement == 'regular') {
      score += 2;
    }

    return score;
  }

  List<String> _tagsForCrop(Crop crop, PlantingRule rule) {
    return [
      _formatMethod(rule.method),
      '${crop.spacingCm} cm',
      '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
      if (crop.containerFriendly) 'Container',
      if (crop.beginnerFriendly) 'Easy',
      if (crop.frostTender) 'Frost tender',
    ];
  }

  List<String> _stepsForCropAction({
    required Crop crop,
    required GardenActionType type,
    required PlantingRule rule,
    required AppSettings settings,
  }) {
    return switch (type) {
      GardenActionType.sow => [
          'Prepare a fine, weed-free seed bed or seed tray.',
          'Sow small batches so harvests are staggered.',
          'Aim for ${crop.spacingCm} cm final spacing.',
          'Water gently and keep the surface evenly moist until germination.',
          if (crop.frostTender || settings.frostRisk == 'high')
            'Protect from cold nights or start under cover.',
          'Label the crop and sowing date.',
        ],
      GardenActionType.transplant => [
          'Harden seedlings off for a few days before planting outside.',
          'Water seedlings and the bed before transplanting.',
          'Plant at ${crop.spacingCm} cm spacing.',
          'Firm soil gently around roots and water in well.',
          if (settings.windExposure == 'exposed')
            'Use temporary wind shelter while seedlings establish.',
          if (crop.frostTender || settings.frostRisk == 'high')
            'Keep frost protection ready for cold nights.',
        ],
      GardenActionType.plant => [
          'Prepare loose, free-draining soil with compost.',
          'Check spacing before planting: about ${crop.spacingCm} cm between plants.',
          'Plant at the right depth for tubers, cloves, crowns, or divisions.',
          'Water in well, then avoid waterlogging while roots establish.',
          'Mark the row clearly so new shoots are not disturbed.',
        ],
      GardenActionType.harvest => [
          'Check plants every few days during the harvest window.',
          'Harvest gently to avoid damaging nearby growth.',
          'Pick regularly for crops that keep producing.',
          'Record notes if you want to compare varieties later.',
        ],
      GardenActionType.watch => [
          rule.riskNote,
        ],
      GardenActionType.prep => [
          'Prepare beds with compost.',
          'Clean trays and labels.',
          'Check irrigation and mulch.',
          'Look ahead to next month’s sowing windows.',
        ],
    };
  }

  List<GardenAction> _watchActions({
    required AppSettings settings,
    required int month,
  }) {
    final actions = <GardenAction>[];

    if (settings.frostRisk == 'high' && _isCoolMonth(month)) {
      actions.add(
        GardenAction(
          type: GardenActionType.watch,
          title: 'Watch cold nights',
          subtitle: 'Frost risk is high in your saved settings.',
          reason:
              'Tender seedlings and warm-season crops can be damaged by cold nights.',
          priority: 82,
          month: month,
          monthLabel: _monthName(month),
          tags: const ['Frost', 'Protection', 'Seedlings'],
          steps: const [
            'Check overnight lows before transplanting tender crops.',
            'Use frost cloth, cloches, or move pots under cover.',
            'Avoid heavy watering late in the day before frost.',
            'Wait for warmer nights before planting frost-tender crops outside.',
          ],
        ),
      );
    }

    if (_isHotMonth(month)) {
      actions.add(
        GardenAction(
          type: GardenActionType.watch,
          title: 'Watch heat and dry soil',
          subtitle: 'Warm months can dry containers and seedlings quickly.',
          reason:
              'Heat stress, bolting, and uneven watering are common in summer.',
          priority: 76,
          month: month,
          monthLabel: _monthName(month),
          tags: const ['Heat', 'Water', 'Mulch'],
          steps: const [
            'Water early morning or evening.',
            'Check containers before garden beds.',
            'Mulch bare soil to reduce evaporation.',
            'Give leafy greens afternoon shade in hot spells.',
          ],
        ),
      );
    }

    if (settings.windExposure == 'exposed') {
      actions.add(
        GardenAction(
          type: GardenActionType.watch,
          title: 'Shelter new seedlings',
          subtitle: 'Your garden is marked as exposed to wind.',
          reason:
              'Wind dries seedlings, damages leaves, and increases transplant shock.',
          priority: 68,
          month: month,
          monthLabel: _monthName(month),
          tags: const ['Wind', 'Shelter', 'Transplants'],
          steps: const [
            'Use temporary wind cloth or shelter around new seedlings.',
            'Water before and after transplanting.',
            'Stake tall crops early.',
            'Keep mulch clear of stems but cover exposed soil.',
          ],
        ),
      );
    }

    return actions;
  }

  GardenAction _quietMonthPrepAction(int month) {
    return GardenAction(
      type: GardenActionType.prep,
      title: 'Prepare the garden',
      subtitle:
          'Quiet month. Use it to get ready for the next planting window.',
      reason:
          'Good preparation makes the next sowing or transplanting window easier.',
      priority: 55,
      month: month,
      monthLabel: _monthName(month),
      tags: const ['Prep', 'Compost', 'Planning'],
      steps: const [
        'Top up beds with compost.',
        'Clean seed trays and labels.',
        'Check irrigation, mulch, and supports.',
        'Look ahead to next month’s sowing jobs.',
      ],
    );
  }

  bool _isCoolMonth(int month) {
    return month >= 4 && month <= 9;
  }

  bool _isHotMonth(int month) {
    return month == 12 || month == 1 || month == 2;
  }

  bool _monthInRange({
    required int month,
    required int startMonth,
    required int endMonth,
  }) {
    if (startMonth <= endMonth) {
      return month >= startMonth && month <= endMonth;
    }

    return month >= startMonth || month <= endMonth;
  }

  int _offsetMonth(int month, int offset) {
    final zeroBased = month - 1 + offset;
    return (zeroBased % 12) + 1;
  }

  String _formatMethod(String method) {
    return method
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _monthName(int month) {
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }
}
