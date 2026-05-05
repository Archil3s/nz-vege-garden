import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_bed_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';
import '../../data/models/planting_rule.dart';
import 'visual_bed_layout_screen.dart';

class GenerateGardenBedScreen extends StatefulWidget {
  const GenerateGardenBedScreen({super.key});

  @override
  State<GenerateGardenBedScreen> createState() => _GenerateGardenBedScreenState();
}

class _GenerateGardenBedScreenState extends State<GenerateGardenBedScreen> {
  final _bedRepository = const GardenBedRepository();
  final _plantingRepository = const GardenBedPlantingRepository();
  final _settingsRepository = const AppSettingsRepository();
  final _dataRepository = const GardenDataRepository();

  final _nameController = TextEditingController(text: 'Generated seasonal bed');
  final _lengthController = TextEditingController(text: '240');
  final _widthController = TextEditingController(text: '120');

  _GeneratorGoal _goal = _GeneratorGoal.beginner;
  _PlantingMethodFilter _methodFilter = _PlantingMethodFilter.both;
  _AirflowPreference _airflow = _AirflowPreference.balanced;
  int _peopleToFeed = 2;
  String _layoutStyle = 'companion';
  bool _isSaving = false;

  late Future<_GeneratorData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  Future<_GeneratorData> _loadData() async {
    final settings = await _settingsRepository.loadSettings();
    final crops = await _dataRepository.loadCrops();
    final rules = await _dataRepository.loadPlantingRules();

    return _GeneratorData(
      regionId: settings.regionId,
      crops: crops,
      rules: rules,
    );
  }

  Future<void> _saveGeneratedBed(_GeneratedBedDraft draft) async {
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final bed = GardenBed.create(
      name: _nameController.text.trim().isEmpty
          ? 'Generated seasonal bed'
          : _nameController.text.trim(),
      type: 'raised_bed',
      lengthCm: draft.lengthCm,
      widthCm: draft.widthCm,
      sunExposure: 'full_sun',
      windExposure: draft.airflow.storageValue,
      layoutStyle: _layoutStyle,
      notes:
          'Live seasonal plan for ${_goal.label.toLowerCase()} • ${draft.peopleToFeed} ${draft.peopleToFeed == 1 ? 'person' : 'people'} • ${draft.monthLabel} • ${draft.airflow.label} airflow • ${draft.methodLabel}.',
      now: now,
    );

    await _bedRepository.addGardenBed(bed);

    final plantings = draft.items.map((item) {
      final expectedHarvestStartDate = now.add(Duration(days: item.crop.daysToHarvestMin));
      final expectedHarvestEndDate = now.add(Duration(days: item.crop.daysToHarvestMax));

      return GardenBedPlanting.create(
        bedId: bed.id,
        cropId: item.crop.id,
        cropName: item.crop.commonName,
        status: 'planned',
        plantCount: item.plantCount,
        plantedDate: now,
        expectedHarvestStartDate: expectedHarvestStartDate,
        expectedHarvestEndDate: expectedHarvestEndDate,
        notes:
            'Generated suggestion: ${item.reason}. Layout role: ${item.layoutRole}. ${item.airflowNote}',
        now: now.add(Duration(microseconds: draft.items.indexOf(item))),
      );
    }).toList(growable: false);

    final existingPlantings = await _plantingRepository.loadPlantings();
    await _plantingRepository.savePlantings([...existingPlantings, ...plantings]);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VisualBedLayoutScreen(
          bed: bed,
          plantings: plantings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate garden bed')),
      body: FutureBuilder<_GeneratorData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load generator data: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No generator data found.'));
          }

          final draft = _buildDraft(data);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Text(
                'Live seasonal bed planner',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Uses the current month, saved NZ region, sow/transplant timing, family size, spacing, and airflow to suggest a practical planted bed.',
              ),
              const SizedBox(height: 16),
              _LiveSeasonCard(draft: draft),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bed name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Length cm',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Width cm',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GoalSelector(
                selectedGoal: _goal,
                onChanged: (goal) => setState(() => _goal = goal),
              ),
              const SizedBox(height: 16),
              _MethodSelector(
                selectedFilter: _methodFilter,
                onChanged: (filter) => setState(() => _methodFilter = filter),
              ),
              const SizedBox(height: 16),
              _FamilySizeCard(
                peopleToFeed: _peopleToFeed,
                onChanged: (value) => setState(() => _peopleToFeed = value),
              ),
              const SizedBox(height: 16),
              _AirflowSelector(
                airflow: _airflow,
                onChanged: (value) => setState(() => _airflow = value),
              ),
              const SizedBox(height: 16),
              _LayoutStyleSelector(
                selectedStyle: _layoutStyle,
                onChanged: (style) => setState(() => _layoutStyle = style),
              ),
              const SizedBox(height: 16),
              _DraftPreviewCard(draft: draft),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: draft.items.isEmpty || _isSaving ? null : () => _saveGeneratedBed(draft),
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Create bed and open design'),
              ),
            ],
          );
        },
      ),
    );
  }

  _GeneratedBedDraft _buildDraft(_GeneratorData data) {
    final now = DateTime.now();
    final cropById = {for (final crop in data.crops) crop.id: crop};
    final lengthCm = int.tryParse(_lengthController.text.trim())?.clamp(60, 1000) ?? 240;
    final widthCm = int.tryParse(_widthController.text.trim())?.clamp(40, 300) ?? 120;
    final areaSquareMeters = (lengthCm * widthCm) / 10000;
    final seasonalRules = data.rules
        .where((rule) => rule.appliesToMonth(now.month))
        .where((rule) => rule.appliesToRegion(data.regionId))
        .where((rule) => cropById.containsKey(rule.cropId))
        .where(_methodFilter.allows)
        .toList(growable: false);

    final scored = seasonalRules.map((rule) {
      final crop = cropById[rule.cropId]!;
      return _ScoredGeneratorCrop(
        crop: crop,
        rule: rule,
        score: _scoreCrop(crop, rule),
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        return scoreComparison == 0
            ? a.crop.commonName.compareTo(b.crop.commonName)
            : scoreComparison;
      });

    final targetCrops = _targetCropCount(areaSquareMeters);
    final selected = _balancedCropSelection(scored, targetCrops);
    final utilisation = _spaceUtilisationFactor();
    final zoneArea = selected.isEmpty ? 0 : areaSquareMeters / selected.length;
    final familyMultiplier = (0.82 + _peopleToFeed * 0.08).clamp(0.9, 1.28).toDouble();

    final items = selected.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final spacingMeters = math.max(0.1, item.crop.spacingCm / 100);
      final plantArea = spacingMeters * spacingMeters;
      final baseCount = zoneArea / plantArea;
      final count = (baseCount * utilisation * familyMultiplier).floor().clamp(1, 80);

      return _GeneratedBedItem(
        crop: item.crop,
        method: item.rule.method,
        plantCount: count,
        reason: _reasonFor(item.crop, item.rule),
        layoutRole: _layoutRoleFor(index, selected.length, item.crop),
        airflowNote: _airflowNoteFor(item.crop),
      );
    }).toList(growable: false);

    return _GeneratedBedDraft(
      lengthCm: lengthCm,
      widthCm: widthCm,
      peopleToFeed: _peopleToFeed,
      monthLabel: _monthName(now.month),
      methodLabel: _methodFilter.label,
      airflow: _airflow,
      utilisationPercent: (utilisation * 100).round(),
      availableSeasonalCropCount: seasonalRules.length,
      items: items,
    );
  }

  int _targetCropCount(double areaSquareMeters) {
    final byFamilySize = _peopleToFeed <= 2
        ? 3
        : _peopleToFeed <= 4
            ? 4
            : 5;
    final byArea = areaSquareMeters < 1.2
        ? 3
        : areaSquareMeters < 2.6
            ? 4
            : 5;
    return math.min(byFamilySize, byArea);
  }

  List<_ScoredGeneratorCrop> _balancedCropSelection(
    List<_ScoredGeneratorCrop> scored,
    int targetCrops,
  ) {
    final selected = <_ScoredGeneratorCrop>[];
    final usedCategories = <String>{};

    for (final item in scored) {
      if (selected.length >= targetCrops) break;
      if (usedCategories.contains(item.crop.category) && selected.length < targetCrops - 1) {
        continue;
      }
      selected.add(item);
      usedCategories.add(item.crop.category);
    }

    for (final item in scored) {
      if (selected.length >= targetCrops) break;
      if (!selected.contains(item)) {
        selected.add(item);
      }
    }

    return selected;
  }

  double _spaceUtilisationFactor() {
    return switch (_airflow) {
      _AirflowPreference.open => 0.68,
      _AirflowPreference.balanced => 0.82,
      _AirflowPreference.intensive => 0.95,
    };
  }

  int _scoreCrop(Crop crop, PlantingRule rule) {
    var score = 0;
    if (crop.beginnerFriendly) score += _goal == _GeneratorGoal.beginner ? 5 : 2;
    if (crop.daysToHarvestMax <= 60) score += _goal == _GeneratorGoal.quickHarvest ? 5 : 2;
    if (crop.category == 'herb') score += _goal == _GeneratorGoal.herbsAndSalad ? 5 : 1;
    if (crop.containerFriendly) score += _goal == _GeneratorGoal.smallSpace ? 5 : 1;
    if (rule.method == 'direct_sow') score += _methodFilter == _PlantingMethodFilter.directSow ? 5 : 2;
    if (rule.method == 'transplant') score += _methodFilter == _PlantingMethodFilter.transplant ? 5 : 2;
    if (!crop.frostTender) score += 1;
    if (_airflow == _AirflowPreference.open && crop.spacingCm >= 35) score += 2;
    if (_airflow == _AirflowPreference.intensive && crop.spacingCm <= 30) score += 2;
    return score;
  }

  String _reasonFor(Crop crop, PlantingRule rule) {
    final parts = <String>[];
    if (crop.beginnerFriendly) parts.add('beginner friendly');
    if (crop.daysToHarvestMax <= 60) parts.add('quick harvest');
    if (crop.containerFriendly) parts.add('space efficient');
    parts.add(rule.method == 'transplant' ? 'transplant now' : 'sow direct now');
    return parts.join(', ');
  }

  String _layoutRoleFor(int index, int total, Crop crop) {
    if (total == 1) return 'main crop block';
    if (index == 0) return 'anchor crop';
    if (index == total - 1 && crop.spacingCm <= 25) return 'edge filler';
    if (crop.category == 'herb') return 'edge companion';
    if (crop.spacingCm >= 45) return 'airflow crop';
    return 'supporting crop block';
  }

  String _airflowNoteFor(Crop crop) {
    return switch (_airflow) {
      _AirflowPreference.open =>
        'Open spacing selected: keep extra room around ${crop.commonName.toLowerCase()} for airflow and access.',
      _AirflowPreference.balanced =>
        'Balanced spacing selected: leaves enough room for growth while using the bed efficiently.',
      _AirflowPreference.intensive =>
        'Intensive spacing selected: watch watering, feeding, and airflow as the bed fills.',
    };
  }
}

class _LiveSeasonCard extends StatelessWidget {
  const _LiveSeasonCard({required this.draft});

  final _GeneratedBedDraft draft;

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
                const Icon(Icons.sensors_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live seasonal filter',
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
                Chip(label: Text(draft.monthLabel)),
                Chip(label: Text(draft.methodLabel)),
                Chip(label: Text('${draft.availableSeasonalCropCount} seasonal options')),
                Chip(label: Text('${draft.utilisationPercent}% spacing use')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The plan updates from local seasonal data whenever you change method, family size, dimensions, or airflow.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSelector extends StatelessWidget {
  const _GoalSelector({required this.selectedGoal, required this.onChanged});

  final _GeneratorGoal selectedGoal;
  final ValueChanged<_GeneratorGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _GeneratorGoal.values.map((goal) {
                return ChoiceChip(
                  label: Text(goal.label),
                  selected: selectedGoal == goal,
                  onSelected: (_) => onChanged(goal),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.selectedFilter, required this.onChanged});

  final _PlantingMethodFilter selectedFilter;
  final ValueChanged<_PlantingMethodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What can go in now', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<_PlantingMethodFilter>(
              selected: {selectedFilter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onChanged(selection.first),
              segments: const [
                ButtonSegment(
                  value: _PlantingMethodFilter.both,
                  icon: Icon(Icons.all_inclusive_outlined),
                  label: Text('Both'),
                ),
                ButtonSegment(
                  value: _PlantingMethodFilter.directSow,
                  icon: Icon(Icons.grass_outlined),
                  label: Text('Sow'),
                ),
                ButtonSegment(
                  value: _PlantingMethodFilter.transplant,
                  icon: Icon(Icons.move_down_outlined),
                  label: Text('Plant'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(selectedFilter.description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FamilySizeCard extends StatelessWidget {
  const _FamilySizeCard({required this.peopleToFeed, required this.onChanged});

  final int peopleToFeed;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Family size target', style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: peopleToFeed.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              label: peopleToFeed.toString(),
              onChanged: (value) => onChanged(value.round()),
            ),
            Text('Target: $peopleToFeed ${peopleToFeed == 1 ? 'person' : 'people'}'),
          ],
        ),
      ),
    );
  }
}

class _AirflowSelector extends StatelessWidget {
  const _AirflowSelector({required this.airflow, required this.onChanged});

  final _AirflowPreference airflow;
  final ValueChanged<_AirflowPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spacing and airflow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _AirflowPreference.values.map((value) {
                return ChoiceChip(
                  avatar: Icon(value.icon, size: 18),
                  label: Text(value.label),
                  selected: airflow == value,
                  onSelected: (_) => onChanged(value),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(airflow.description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LayoutStyleSelector extends StatelessWidget {
  const _LayoutStyleSelector({required this.selectedStyle, required this.onChanged});

  final String selectedStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design style', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              selected: {selectedStyle},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onChanged(selection.first),
              segments: const [
                ButtonSegment(value: 'ordered', label: Text('Rows'), icon: Icon(Icons.grid_view_outlined)),
                ButtonSegment(value: 'companion', label: Text('Mixed'), icon: Icon(Icons.hub_outlined)),
                ButtonSegment(value: 'showcase', label: Text('Show'), icon: Icon(Icons.auto_awesome_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftPreviewCard extends StatelessWidget {
  const _DraftPreviewCard({required this.draft});

  final _GeneratedBedDraft draft;

  @override
  Widget build(BuildContext context) {
    final area = draft.lengthCm * draft.widthCm / 10000;
    final directSowCount = draft.items.where((item) => item.method == 'direct_sow').length;
    final transplantCount = draft.items.where((item) => item.method == 'transplant').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Generated layout plan', style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${draft.lengthCm} × ${draft.widthCm} cm')),
                Chip(label: Text('${area.toStringAsFixed(2)} m²')),
                Chip(label: Text('${draft.peopleToFeed} people')),
                Chip(label: Text('Sow: $directSowCount')),
                Chip(label: Text('Plant: $transplantCount')),
                Chip(label: Text(draft.airflow.label)),
              ],
            ),
            const SizedBox(height: 12),
            if (draft.items.isEmpty)
              const Text('No seasonal crop matches found for this setup.')
            else
              ...draft.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(item.plantCount.toString())),
                  title: Text('${item.crop.commonName} × ${item.plantCount}'),
                  subtitle: Text(
                    '${_formatMethod(item.method)} • ${item.layoutRole}\n${item.reason}\n${item.airflowNote}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMethod(String method) {
    return switch (method) {
      'transplant' => 'Transplant now',
      'direct_sow' => 'Direct sow now',
      _ => method,
    };
  }
}

class _GeneratorData {
  const _GeneratorData({required this.regionId, required this.crops, required this.rules});

  final String regionId;
  final List<Crop> crops;
  final List<PlantingRule> rules;
}

class _GeneratedBedDraft {
  const _GeneratedBedDraft({
    required this.lengthCm,
    required this.widthCm,
    required this.peopleToFeed,
    required this.monthLabel,
    required this.methodLabel,
    required this.airflow,
    required this.utilisationPercent,
    required this.availableSeasonalCropCount,
    required this.items,
  });

  final int lengthCm;
  final int widthCm;
  final int peopleToFeed;
  final String monthLabel;
  final String methodLabel;
  final _AirflowPreference airflow;
  final int utilisationPercent;
  final int availableSeasonalCropCount;
  final List<_GeneratedBedItem> items;
}

class _GeneratedBedItem {
  const _GeneratedBedItem({
    required this.crop,
    required this.method,
    required this.plantCount,
    required this.reason,
    required this.layoutRole,
    required this.airflowNote,
  });

  final Crop crop;
  final String method;
  final int plantCount;
  final String reason;
  final String layoutRole;
  final String airflowNote;
}

class _ScoredGeneratorCrop {
  const _ScoredGeneratorCrop({required this.crop, required this.rule, required this.score});

  final Crop crop;
  final PlantingRule rule;
  final int score;
}

enum _GeneratorGoal {
  beginner('Beginner'),
  quickHarvest('Quick harvest'),
  herbsAndSalad('Herbs & salad'),
  smallSpace('Small space');

  const _GeneratorGoal(this.label);

  final String label;
}

enum _PlantingMethodFilter {
  both('Direct sow + transplant', 'Uses everything that can be sown or transplanted in the current month.'),
  directSow('Direct sow only', 'Only uses crops that can be sown directly now.'),
  transplant('Transplant only', 'Only uses crops that can be planted out as seedlings now.');

  const _PlantingMethodFilter(this.label, this.description);

  final String label;
  final String description;

  bool allows(PlantingRule rule) {
    return switch (this) {
      _PlantingMethodFilter.both => true,
      _PlantingMethodFilter.directSow => rule.method == 'direct_sow',
      _PlantingMethodFilter.transplant => rule.method == 'transplant',
    };
  }
}

enum _AirflowPreference {
  open('Open', 'More spacing for airflow, access, and lower disease pressure.', 'exposed', Icons.air_outlined),
  balanced('Balanced', 'A practical middle ground between yield, airflow, and easy maintenance.', 'moderate', Icons.tune_outlined),
  intensive('Intensive', 'Higher plant density for more output. Best if watering and feeding are consistent.', 'sheltered', Icons.density_medium_outlined);

  const _AirflowPreference(this.label, this.description, this.storageValue, this.icon);

  final String label;
  final String description;
  final String storageValue;
  final IconData icon;
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
