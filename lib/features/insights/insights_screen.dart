import 'package:flutter/material.dart';

import '../../data/crop_rotation_service.dart';
import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_bed_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _soonWindowDays = 14;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garden insights')),
      body: FutureBuilder<_InsightsData>(
        future: _loadInsightsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load insights: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No insight data found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'What is happening in your garden',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Local insights based on saved beds, planted crops, spacing, harvest windows, rotation families, and today’s date.',
              ),
              const SizedBox(height: 16),
              _InsightSummaryGrid(data: data),
              const SizedBox(height: 16),
              _HarvestInsightCard(data: data),
              const SizedBox(height: 16),
              _RotationInsightCard(data: data),
              const SizedBox(height: 16),
              _BedUtilisationCard(data: data),
              const SizedBox(height: 16),
              _NextActionsCard(actions: data.nextActions),
            ],
          );
        },
      ),
    );
  }

  Future<_InsightsData> _loadInsightsData() async {
    const bedRepository = GardenBedRepository();
    const plantingRepository = GardenBedPlantingRepository();
    const dataRepository = GardenDataRepository();
    const rotationService = CropRotationService();

    final beds = await bedRepository.loadGardenBeds();
    final plantings = await plantingRepository.loadPlantings();
    final crops = await dataRepository.loadCrops();

    return _buildInsights(
      beds: beds,
      plantings: plantings,
      crops: crops,
      rotationService: rotationService,
      now: DateTime.now(),
    );
  }

  _InsightsData _buildInsights({
    required List<GardenBed> beds,
    required List<GardenBedPlanting> plantings,
    required List<Crop> crops,
    required CropRotationService rotationService,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final soonDate = today.add(const Duration(days: _soonWindowDays));
    final cropById = {for (final crop in crops) crop.id: crop};
    final activePlantings = plantings
        .where((planting) => planting.status != 'finished' && planting.status != 'failed')
        .toList(growable: false);
    final plannedPlantings = activePlantings
        .where((planting) => planting.status == 'planned')
        .toList(growable: false);
    final growingPlantings = activePlantings
        .where((planting) => planting.status != 'planned')
        .toList(growable: false);

    final totalPlants = activePlantings.fold<int>(
      0,
      (sum, planting) => sum + planting.plantCount,
    );

    final harvestReady = activePlantings
        .where((planting) =>
            planting.expectedHarvestStartDate != null &&
            !today.isBefore(_dateOnly(planting.expectedHarvestStartDate!)))
        .toList(growable: false)
      ..sort(_sortByHarvestStart);

    final harvestSoon = activePlantings
        .where((planting) =>
            planting.expectedHarvestStartDate != null &&
            today.isBefore(_dateOnly(planting.expectedHarvestStartDate!)) &&
            !_dateOnly(planting.expectedHarvestStartDate!).isAfter(soonDate))
        .toList(growable: false)
      ..sort(_sortByHarvestStart);

    final overdueHarvests = activePlantings
        .where((planting) =>
            planting.expectedHarvestEndDate != null &&
            today.isAfter(_dateOnly(planting.expectedHarvestEndDate!)))
        .toList(growable: false)
      ..sort(_sortByHarvestStart);

    final bedInsights = beds.map((bed) {
      final bedPlantings = activePlantings
          .where((planting) => planting.bedId == bed.id)
          .toList(growable: false);
      final plantedCount = bedPlantings.fold<int>(
        0,
        (sum, planting) => sum + planting.plantCount,
      );
      final estimatedCapacity = _estimateBedCapacity(
        bed: bed,
        plantings: bedPlantings,
        cropById: cropById,
      );
      final utilisation = estimatedCapacity == null || estimatedCapacity == 0
          ? null
          : (plantedCount / estimatedCapacity).clamp(0, 2).toDouble();

      return _BedInsight(
        bed: bed,
        plantings: bedPlantings,
        plantedCount: plantedCount,
        estimatedCapacity: estimatedCapacity,
        utilisation: utilisation,
      );
    }).toList(growable: false)
      ..sort((a, b) => a.bed.name.compareTo(b.bed.name));

    final rotationInsights = rotationService.buildBedRotationInsights(
      beds: beds,
      plantings: plantings,
    );
    final rotationRiskCount = rotationInsights
        .where((insight) => insight.hasRisk)
        .length;

    final nextActions = _buildNextActions(
      beds: beds,
      activePlantings: activePlantings,
      plannedPlantings: plannedPlantings,
      harvestReady: harvestReady,
      harvestSoon: harvestSoon,
      overdueHarvests: overdueHarvests,
      bedInsights: bedInsights,
      rotationRiskCount: rotationRiskCount,
    );

    return _InsightsData(
      beds: beds,
      activePlantings: activePlantings,
      plannedPlantings: plannedPlantings,
      growingPlantings: growingPlantings,
      totalPlants: totalPlants,
      harvestReady: harvestReady,
      harvestSoon: harvestSoon,
      overdueHarvests: overdueHarvests,
      bedInsights: bedInsights,
      rotationInsights: rotationInsights,
      rotationRiskCount: rotationRiskCount,
      nextActions: nextActions,
    );
  }

  int _sortByHarvestStart(GardenBedPlanting a, GardenBedPlanting b) {
    final aDate = a.expectedHarvestStartDate ?? DateTime(9999);
    final bDate = b.expectedHarvestStartDate ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int? _estimateBedCapacity({
    required GardenBed bed,
    required List<GardenBedPlanting> plantings,
    required Map<String, Crop> cropById,
  }) {
    final areaSquareMeters = bed.areaSquareMeters;
    if (areaSquareMeters == null || areaSquareMeters <= 0) {
      return null;
    }

    if (plantings.isEmpty) {
      return null;
    }

    final plantAreas = plantings
        .map((planting) => cropById[planting.cropId])
        .whereType<Crop>()
        .map((crop) {
      final spacingMeters = crop.spacingCm / 100;
      return spacingMeters * spacingMeters;
    }).toList(growable: false);

    if (plantAreas.isEmpty) {
      return null;
    }

    final averagePlantArea =
        plantAreas.fold<double>(0, (sum, area) => sum + area) / plantAreas.length;

    if (averagePlantArea <= 0) {
      return null;
    }

    return (areaSquareMeters / averagePlantArea).floor().clamp(1, 999);
  }

  List<_NextAction> _buildNextActions({
    required List<GardenBed> beds,
    required List<GardenBedPlanting> activePlantings,
    required List<GardenBedPlanting> plannedPlantings,
    required List<GardenBedPlanting> harvestReady,
    required List<GardenBedPlanting> harvestSoon,
    required List<GardenBedPlanting> overdueHarvests,
    required List<_BedInsight> bedInsights,
    required int rotationRiskCount,
  }) {
    final actions = <_NextAction>[];

    if (beds.isEmpty) {
      actions.add(
        const _NextAction(
          icon: Icons.yard_outlined,
          title: 'Add your first bed',
          description: 'Create a bed or container so the app can start giving useful insights.',
        ),
      );
    }

    if (plannedPlantings.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.grass_outlined,
          title: 'Move planned crops forward',
          description:
              '${plannedPlantings.length} planned crop entries are waiting to be sown, transplanted, or marked as growing.',
        ),
      );
    }

    if (rotationRiskCount > 0) {
      actions.add(
        _NextAction(
          icon: Icons.sync_problem_outlined,
          title: 'Review crop rotation',
          description:
              '$rotationRiskCount bed${rotationRiskCount == 1 ? '' : 's'} may be repeating the same crop family.',
        ),
      );
    }

    if (overdueHarvests.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.priority_high_outlined,
          title: 'Check overdue harvests',
          description:
              '${overdueHarvests.length} crop entries may be past their expected harvest window.',
        ),
      );
    } else if (harvestReady.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.shopping_basket_outlined,
          title: 'Harvest ready crops',
          description: '${harvestReady.length} crop entries are inside their harvest window.',
        ),
      );
    }

    if (harvestSoon.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.event_available_outlined,
          title: 'Prepare for upcoming harvests',
          description: '${harvestSoon.length} crop entries are expected within 14 days.',
        ),
      );
    }

    final underusedBeds = bedInsights
        .where((insight) => insight.utilisation != null && insight.utilisation! < 0.35)
        .toList(growable: false);
    if (underusedBeds.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.add_circle_outline,
          title: 'Use spare bed space',
          description:
              '${underusedBeds.length} bed${underusedBeds.length == 1 ? '' : 's'} look underused based on crop spacing.',
        ),
      );
    }

    final crowdedBeds = bedInsights
        .where((insight) => insight.utilisation != null && insight.utilisation! > 1.1)
        .toList(growable: false);
    if (crowdedBeds.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.warning_amber_outlined,
          title: 'Review crowded beds',
          description:
              '${crowdedBeds.length} bed${crowdedBeds.length == 1 ? '' : 's'} may be over the estimated spacing capacity.',
        ),
      );
    }

    if (actions.isEmpty && activePlantings.isNotEmpty) {
      actions.add(
        const _NextAction(
          icon: Icons.check_circle_outline,
          title: 'Garden looks steady',
          description: 'No urgent harvest, rotation, or spacing issues detected from local data.',
        ),
      );
    }

    return actions.take(5).toList(growable: false);
  }
}

class _InsightSummaryGrid extends StatelessWidget {
  const _InsightSummaryGrid({required this.data});

  final _InsightsData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _MetricCard(
          icon: Icons.yard_outlined,
          label: 'Beds',
          value: data.beds.length.toString(),
        ),
        _MetricCard(
          icon: Icons.eco_outlined,
          label: 'Active crops',
          value: data.activePlantings.length.toString(),
        ),
        _MetricCard(
          icon: Icons.spa_outlined,
          label: 'Plants',
          value: data.totalPlants.toString(),
        ),
        _MetricCard(
          icon: Icons.sync_problem_outlined,
          label: 'Rotation risks',
          value: data.rotationRiskCount.toString(),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarvestInsightCard extends StatelessWidget {
  const _HarvestInsightCard({required this.data});

  final _InsightsData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Harvest forecast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Ready: ${data.harvestReady.length}'),
                ),
                Chip(
                  avatar: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text('Soon: ${data.harvestSoon.length}'),
                ),
                Chip(
                  avatar: const Icon(Icons.priority_high_outlined, size: 18),
                  label: Text('Overdue: ${data.overdueHarvests.length}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.harvestReady.isEmpty &&
                data.harvestSoon.isEmpty &&
                data.overdueHarvests.isEmpty)
              const Text('No urgent harvest windows detected yet.')
            else
              ...[
                ...data.overdueHarvests.take(3).map(
                      (planting) => _PlantingInsightTile(
                        icon: Icons.priority_high_outlined,
                        planting: planting,
                        label: 'May be overdue',
                      ),
                    ),
                ...data.harvestReady.take(3).map(
                      (planting) => _PlantingInsightTile(
                        icon: Icons.shopping_basket_outlined,
                        planting: planting,
                        label: 'Ready now',
                      ),
                    ),
                ...data.harvestSoon.take(3).map(
                      (planting) => _PlantingInsightTile(
                        icon: Icons.event_available_outlined,
                        planting: planting,
                        label: 'Ready soon',
                      ),
                    ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RotationInsightCard extends StatelessWidget {
  const _RotationInsightCard({required this.data});

  final _InsightsData data;

  @override
  Widget build(BuildContext context) {
    final riskyBeds = data.rotationInsights
        .where((insight) => insight.hasRisk)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_alt_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Crop rotation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.rotationInsights.isEmpty)
              const Text('Add beds and crops to see rotation guidance.')
            else if (riskyBeds.isEmpty)
              const Text('No repeated crop-family risks detected yet.')
            else
              ...riskyBeds.map(
                (insight) => _RotationRiskTile(insight: insight),
              ),
          ],
        ),
      ),
    );
  }
}

class _RotationRiskTile extends StatelessWidget {
  const _RotationRiskTile({required this.insight});

  final BedRotationInsight insight;

  @override
  Widget build(BuildContext context) {
    final families = insight.riskFamilies.map((family) => family.label).join(', ');
    final advice = insight.riskFamilies.map((family) => family.shortAdvice).join(' ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.warning_amber_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(insight.bed.name),
      subtitle: Text('$families. $advice'),
    );
  }
}

class _PlantingInsightTile extends StatelessWidget {
  const _PlantingInsightTile({
    required this.icon,
    required this.planting,
    required this.label,
  });

  final IconData icon;
  final GardenBedPlanting planting;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text('${planting.cropName} × ${planting.plantCount}'),
      subtitle: Text('$label • ${_harvestWindow(planting)}'),
    );
  }

  String _harvestWindow(GardenBedPlanting planting) {
    final start = planting.expectedHarvestStartDate;
    final end = planting.expectedHarvestEndDate;
    if (start == null || end == null) {
      return 'No harvest estimate';
    }

    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _BedUtilisationCard extends StatelessWidget {
  const _BedUtilisationCard({required this.data});

  final _InsightsData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bed utilisation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.bedInsights.isEmpty)
              const Text('Add beds to see utilisation insights.')
            else
              ...data.bedInsights.map(
                (insight) => _BedUtilisationTile(insight: insight),
              ),
          ],
        ),
      ),
    );
  }
}

class _BedUtilisationTile extends StatelessWidget {
  const _BedUtilisationTile({required this.insight});

  final _BedInsight insight;

  @override
  Widget build(BuildContext context) {
    final utilisation = insight.utilisation;
    final progress = utilisation == null ? 0.0 : utilisation.clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(insight.bed.name)),
              Text(_statusText()),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            insight.estimatedCapacity == null
                ? '${insight.plantedCount} plants • add dimensions and crop spacing for utilisation.'
                : '${insight.plantedCount}/${insight.estimatedCapacity} estimated plants used.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _statusText() {
    final utilisation = insight.utilisation;
    if (utilisation == null) {
      return 'Unknown';
    }

    if (utilisation > 1.1) {
      return 'Crowded';
    }

    if (utilisation < 0.35) {
      return 'Spare room';
    }

    return '${(utilisation * 100).round()}%';
  }
}

class _NextActionsCard extends StatelessWidget {
  const _NextActionsCard({required this.actions});

  final List<_NextAction> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Suggested next actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              const Text('No suggested actions yet.')
            else
              ...actions.map(
                (action) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(action.icon),
                  title: Text(action.title),
                  subtitle: Text(action.description),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightsData {
  const _InsightsData({
    required this.beds,
    required this.activePlantings,
    required this.plannedPlantings,
    required this.growingPlantings,
    required this.totalPlants,
    required this.harvestReady,
    required this.harvestSoon,
    required this.overdueHarvests,
    required this.bedInsights,
    required this.rotationInsights,
    required this.rotationRiskCount,
    required this.nextActions,
  });

  final List<GardenBed> beds;
  final List<GardenBedPlanting> activePlantings;
  final List<GardenBedPlanting> plannedPlantings;
  final List<GardenBedPlanting> growingPlantings;
  final int totalPlants;
  final List<GardenBedPlanting> harvestReady;
  final List<GardenBedPlanting> harvestSoon;
  final List<GardenBedPlanting> overdueHarvests;
  final List<_BedInsight> bedInsights;
  final List<BedRotationInsight> rotationInsights;
  final int rotationRiskCount;
  final List<_NextAction> nextActions;
}

class _BedInsight {
  const _BedInsight({
    required this.bed,
    required this.plantings,
    required this.plantedCount,
    required this.estimatedCapacity,
    required this.utilisation,
  });

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;
  final int plantedCount;
  final int? estimatedCapacity;
  final double? utilisation;
}

class _NextAction {
  const _NextAction({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
