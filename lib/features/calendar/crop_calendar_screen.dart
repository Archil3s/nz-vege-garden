import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/planting_rule.dart';
import '../crops/crop_detail_screen.dart';

class CropCalendarScreen extends StatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  final _dataRepository = const GardenDataRepository();
  final _settingsRepository = const AppSettingsRepository();

  late Future<_CropCalendarData> _calendarFuture;
  late int _selectedMonth;
  String _activityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _calendarFuture = _loadCalendarData();
  }

  Future<_CropCalendarData> _loadCalendarData() async {
    final settings = await _settingsRepository.loadSettings();
    final crops = await _dataRepository.loadCrops();
    final rules = await _dataRepository.loadPlantingRules();
    final cropById = {for (final crop in crops) crop.id: crop};
    final relevantRules = rules
        .where((rule) => rule.appliesToRegion(settings.regionId))
        .where((rule) => cropById.containsKey(rule.cropId))
        .toList(growable: false);

    final entries = <_CalendarEntry>[];

    for (final rule in relevantRules) {
      final crop = cropById[rule.cropId]!;
      entries.add(
        _CalendarEntry(
          crop: crop,
          rule: rule,
          activity: _CalendarActivity.fromMethod(rule.method),
          startMonth: rule.startMonth,
          endMonth: rule.endMonth,
          note: rule.riskNote,
        ),
      );

      final harvestStartMonth = _offsetMonth(
        rule.startMonth,
        (crop.daysToHarvestMin / 30).floor(),
      );
      final harvestEndMonth = _offsetMonth(
        rule.endMonth,
        (crop.daysToHarvestMax / 30).ceil(),
      );

      entries.add(
        _CalendarEntry(
          crop: crop,
          rule: rule,
          activity: _CalendarActivity.harvest,
          startMonth: harvestStartMonth,
          endMonth: harvestEndMonth,
          note:
              'Estimated harvest window based on ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days from ${_formatMethod(rule.method).toLowerCase()}.',
        ),
      );
    }

    return _CropCalendarData(
      regionId: settings.regionId,
      entries: entries,
    );
  }

  List<_CalendarEntry> _entriesForMonth(List<_CalendarEntry> entries) {
    return entries.where((entry) {
      final matchesMonth = _monthInRange(
        month: _selectedMonth,
        startMonth: entry.startMonth,
        endMonth: entry.endMonth,
      );
      final matchesActivity = _activityFilter == 'all' || entry.activity.id == _activityFilter;

      return matchesMonth && matchesActivity;
    }).toList(growable: false)
      ..sort((a, b) {
        final activityCompare = a.activity.sortOrder.compareTo(b.activity.sortOrder);
        if (activityCompare != 0) {
          return activityCompare;
        }

        return a.crop.commonName.compareTo(b.crop.commonName);
      });
  }

  int _offsetMonth(int month, int offset) {
    final zeroBased = month - 1 + offset;
    return (zeroBased % 12) + 1;
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

  String _formatMethod(String method) {
    return method
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop calendar'),
      ),
      body: FutureBuilder<_CropCalendarData>(
        future: _calendarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load crop calendar: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No crop calendar data found.'));
          }

          final entries = _entriesForMonth(data.entries);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Monthly sow, transplant, and harvest guide',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Uses your saved NZ region and the offline planting database. Harvest timing is estimated from crop days-to-harvest data.',
              ),
              const SizedBox(height: 16),
              _MonthSelector(
                selectedMonth: _selectedMonth,
                onMonthSelected: (month) => setState(() => _selectedMonth = month),
              ),
              const SizedBox(height: 16),
              _ActivityFilter(
                selectedActivity: _activityFilter,
                onSelected: (activity) => setState(() => _activityFilter = activity),
              ),
              const SizedBox(height: 16),
              _LegendCard(),
              const SizedBox(height: 16),
              Text(
                '${_monthName(_selectedMonth)} calendar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No ${_activityFilter == 'all' ? 'calendar entries' : _activityFilter} found for ${_monthName(_selectedMonth)}.',
                    ),
                  ),
                )
              else
                ...entries.map(
                  (entry) => _CalendarEntryCard(entry: entry),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = index + 1;
          return ChoiceChip(
            label: Text(_shortMonthName(month)),
            selected: selectedMonth == month,
            onSelected: (_) => onMonthSelected(month),
          );
        },
      ),
    );
  }
}

class _ActivityFilter extends StatelessWidget {
  const _ActivityFilter({
    required this.selectedActivity,
    required this.onSelected,
  });

  final String selectedActivity;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selectedActivity == 'all',
          onSelected: (_) => onSelected('all'),
        ),
        ..._CalendarActivity.values.map(
          (activity) => ChoiceChip(
            avatar: Icon(activity.icon, size: 18),
            label: Text(activity.label),
            selected: selectedActivity == activity.id,
            onSelected: (_) => onSelected(activity.id),
          ),
        ),
      ],
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _CalendarActivity.values
              .map(
                (activity) => _ActivityChip(activity: activity),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _CalendarEntryCard extends StatelessWidget {
  const _CalendarEntryCard({required this.entry});

  final _CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(entry.activity.icon),
        title: Text(entry.crop.commonName),
        subtitle: Text(
          '${entry.activity.label} • ${_monthRange(entry.startMonth, entry.endMonth)}\n${entry.note}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CropDetailScreen(crop: entry.crop),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.activity});

  final _CalendarActivity activity;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(activity.icon, size: 18),
      label: Text(activity.label),
      backgroundColor: activity.backgroundColor(context),
    );
  }
}

class _CropCalendarData {
  const _CropCalendarData({
    required this.regionId,
    required this.entries,
  });

  final String regionId;
  final List<_CalendarEntry> entries;
}

class _CalendarEntry {
  const _CalendarEntry({
    required this.crop,
    required this.rule,
    required this.activity,
    required this.startMonth,
    required this.endMonth,
    required this.note,
  });

  final Crop crop;
  final PlantingRule rule;
  final _CalendarActivity activity;
  final int startMonth;
  final int endMonth;
  final String note;
}

enum _CalendarActivity {
  sow(
    id: 'sow',
    label: 'Sow',
    icon: Icons.grass_outlined,
    sortOrder: 1,
  ),
  transplant(
    id: 'transplant',
    label: 'Transplant',
    icon: Icons.move_down_outlined,
    sortOrder: 2,
  ),
  harvest(
    id: 'harvest',
    label: 'Harvest',
    icon: Icons.shopping_basket_outlined,
    sortOrder: 3,
  );

  const _CalendarActivity({
    required this.id,
    required this.label,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String label;
  final IconData icon;
  final int sortOrder;

  static _CalendarActivity fromMethod(String method) {
    return switch (method) {
      'transplant' => _CalendarActivity.transplant,
      _ => _CalendarActivity.sow,
    };
  }

  Color backgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      _CalendarActivity.sow => scheme.primaryContainer,
      _CalendarActivity.transplant => scheme.secondaryContainer,
      _CalendarActivity.harvest => scheme.tertiaryContainer,
    };
  }
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

String _shortMonthName(int month) {
  return _monthName(month).substring(0, 3);
}

String _monthRange(int startMonth, int endMonth) {
  if (startMonth == endMonth) {
    return _monthName(startMonth);
  }

  return '${_shortMonthName(startMonth)}–${_shortMonthName(endMonth)}';
}
