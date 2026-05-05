import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/nz_region.dart';
import '../../data/models/task_rule.dart';
import '../../data/weekly_task_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _settingsRepository = const AppSettingsRepository();
  final _dataRepository = const GardenDataRepository();
  final _taskService = const WeeklyTaskService();

  late final Future<_InsightsData> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _loadInsightsData();
  }

  Future<_InsightsData> _loadInsightsData() async {
    final settings = await _settingsRepository.loadSettings();
    final regions = await _dataRepository.loadRegions();
    final crops = await _dataRepository.cropsForMonthAndRegion(
      month: DateTime.now().month,
      regionId: settings.regionId,
    );
    final tasks = await _taskService.generateTasks();

    final selectedRegion = _firstWhereOrNull<NzRegion>(
      regions,
      (region) => region.id == settings.regionId,
    );

    final beginnerCrops = crops.where((crop) => crop.beginnerFriendly).toList(growable: false);
    final containerCrops = crops.where((crop) => crop.containerFriendly).toList(growable: false);
    final frostTenderCrops = crops.where((crop) => crop.frostTender).toList(growable: false);
    final frostSuitableCrops = crops.where((crop) => !crop.frostTender).toList(growable: false);

    return _InsightsData(
      settings: settings,
      selectedRegion: selectedRegion,
      plantableCrops: crops,
      beginnerCrops: beginnerCrops,
      containerCrops: containerCrops,
      frostTenderCrops: frostTenderCrops,
      frostSuitableCrops: frostSuitableCrops,
      priorityTasks: tasks.take(4).toList(growable: false),
      nextActions: _buildNextActions(
        settings: settings,
        plantableCrops: crops,
        beginnerCrops: beginnerCrops,
        containerCrops: containerCrops,
        frostTenderCrops: frostTenderCrops,
        frostSuitableCrops: frostSuitableCrops,
        tasks: tasks,
      ),
    );
  }

  List<_NextAction> _buildNextActions({
    required AppSettings settings,
    required List<Crop> plantableCrops,
    required List<Crop> beginnerCrops,
    required List<Crop> containerCrops,
    required List<Crop> frostTenderCrops,
    required List<Crop> frostSuitableCrops,
    required List<TaskRule> tasks,
  }) {
    final actions = <_NextAction>[];

    if (plantableCrops.isEmpty) {
      actions.add(
        const _NextAction(
          icon: Icons.calendar_month_outlined,
          title: 'Check another month',
          description: 'No crops match your saved region for this month. Use the crop calendar to plan ahead.',
        ),
      );
    }

    if (beginnerCrops.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.thumb_up_alt_outlined,
          title: 'Start with reliable crops',
          description: '${beginnerCrops.length} beginner-friendly crops are suitable for this month.',
        ),
      );
    }

    if (settings.gardenType == 'container' && containerCrops.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.inventory_2_outlined,
          title: 'Use container-friendly crops',
          description: '${containerCrops.length} crops suit pots or containers in the current planting window.',
        ),
      );
    }

    if (settings.frostRisk == 'high' && frostSuitableCrops.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.ac_unit_outlined,
          title: 'Prefer frost-safer choices',
          description: '${frostSuitableCrops.length} current crops are less frost tender for your setup.',
        ),
      );
    } else if (frostTenderCrops.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.health_and_safety_outlined,
          title: 'Watch frost-tender crops',
          description: '${frostTenderCrops.length} current crops may need protection in cold snaps.',
        ),
      );
    }

    if (tasks.isNotEmpty) {
      actions.add(
        _NextAction(
          icon: Icons.checklist_outlined,
          title: 'Review this week’s jobs',
          description: '${tasks.length} local task suggestions match your saved setup.',
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        const _NextAction(
          icon: Icons.eco_outlined,
          title: 'Plan ahead',
          description: 'Use the crop guide and calendar to prepare for upcoming planting windows.',
        ),
      );
    }

    return actions.take(5).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garden insights')),
      body: FutureBuilder<_InsightsData>(
        future: _insightsFuture,
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

          final regionName = data.selectedRegion?.name ?? _formatValue(data.settings.regionId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${_monthName(DateTime.now().month)} garden insights',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Local guidance for $regionName based on your saved region, frost risk, wind exposure, garden type, and the offline planting database.',
              ),
              const SizedBox(height: 16),
              _InsightSummaryGrid(data: data),
              const SizedBox(height: 16),
              _PlantingInsightCard(data: data),
              const SizedBox(height: 16),
              _TaskInsightCard(tasks: data.priorityTasks),
              const SizedBox(height: 16),
              _NextActionsCard(actions: data.nextActions),
            ],
          );
        },
      ),
    );
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
          icon: Icons.eco_outlined,
          label: 'Plant now',
          value: data.plantableCrops.length.toString(),
        ),
        _MetricCard(
          icon: Icons.thumb_up_alt_outlined,
          label: 'Beginner picks',
          value: data.beginnerCrops.length.toString(),
        ),
        _MetricCard(
          icon: Icons.inventory_2_outlined,
          label: 'Container crops',
          value: data.containerCrops.length.toString(),
        ),
        _MetricCard(
          icon: Icons.checklist_outlined,
          label: 'Weekly jobs',
          value: data.priorityTasks.length.toString(),
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

class _PlantingInsightCard extends StatelessWidget {
  const _PlantingInsightCard({required this.data});

  final _InsightsData data;

  @override
  Widget build(BuildContext context) {
    final sampleCrops = data.plantableCrops.take(5).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Planting fit',
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
                  avatar: const Icon(Icons.ac_unit_outlined, size: 18),
                  label: Text('Frost-safer: ${data.frostSuitableCrops.length}'),
                ),
                Chip(
                  avatar: const Icon(Icons.warning_amber_outlined, size: 18),
                  label: Text('Frost tender: ${data.frostTenderCrops.length}'),
                ),
                Chip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text('Containers: ${data.containerCrops.length}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sampleCrops.isEmpty)
              const Text('No current planting matches were found for your saved setup.')
            else
              ...sampleCrops.map(
                (crop) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    crop.frostTender ? Icons.warning_amber_outlined : Icons.eco_outlined,
                  ),
                  title: Text(crop.commonName),
                  subtitle: Text(crop.summary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskInsightCard extends StatelessWidget {
  const _TaskInsightCard({required this.tasks});

  final List<TaskRule> tasks;

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
                const Icon(Icons.checklist_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This week',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text('No weekly task suggestions match the current setup yet.')
            else
              ...tasks.map(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.task_alt_outlined),
                  title: Text(task.title),
                  subtitle: Text(task.description),
                ),
              ),
          ],
        ),
      ),
    );
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
    required this.settings,
    required this.selectedRegion,
    required this.plantableCrops,
    required this.beginnerCrops,
    required this.containerCrops,
    required this.frostTenderCrops,
    required this.frostSuitableCrops,
    required this.priorityTasks,
    required this.nextActions,
  });

  final AppSettings settings;
  final NzRegion? selectedRegion;
  final List<Crop> plantableCrops;
  final List<Crop> beginnerCrops;
  final List<Crop> containerCrops;
  final List<Crop> frostTenderCrops;
  final List<Crop> frostSuitableCrops;
  final List<TaskRule> priorityTasks;
  final List<_NextAction> nextActions;
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

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }

  return null;
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
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
