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
      windExposure: 'moderate',
      layoutStyle: _layoutStyle,
      notes:
          'Generated for ${_goal.label.toLowerCase()} • ${draft.peopleToFeed} ${draft.peopleToFeed == 1 ? 'person' : 'people'} • ${draft.monthLabel}.',
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
        notes: 'Generated suggestion: ${item.reason}',
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
                'Build a seasonal bed automatically',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a goal and size. The app picks seasonal crops, estimates plant counts, creates the bed, and opens the design canvas.',
              ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('People to feed', style: Theme.of(context).textTheme.titleLarge),
                      Slider(
                        value: _peopleToFeed.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        label: _peopleToFeed.toString(),
                        onChanged: (value) => setState(() => _peopleToFeed = value.round()),
                      ),
                      Text('Target: $_peopleToFeed ${_peopleToFeed == 1 ? 'person' : 'people'}'),
                    ],
                  ),
                ),
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

    final targetCrops = _peopleToFeed <= 2
        ? 3
        : _peopleToFeed <= 4
            ? 4
            : 5;
    final selected = scored.take(targetCrops).toList(growable: false);
    final zoneArea = selected.isEmpty ? 0 : areaSquareMeters / selected.length;

    final items = selected.map((item) {
      final spacingMeters = math.max(0.1, item.crop.spacingCm / 100);
      final plantArea = spacingMeters * spacingMeters;
      final count = (zoneArea / plantArea).floor().clamp(1, 80);
      return _GeneratedBedItem(
        crop: item.crop,
        method: item.rule.method,
        plantCount: count,
        reason: _reasonFor(item.crop, item.rule),
      );
    }).toList(growable: false);

    return _GeneratedBedDraft(
      lengthCm: lengthCm,
      widthCm: widthCm,
      peopleToFeed: _peopleToFeed,
      monthLabel: _monthName(now.month),
      items: items,
    );
  }

  int _scoreCrop(Crop crop, PlantingRule rule) {
    var score = 0;
    if (crop.beginnerFriendly) score += _goal == _GeneratorGoal.beginner ? 5 : 2;
    if (crop.daysToHarvestMax <= 60) score += _goal == _GeneratorGoal.quickHarvest ? 5 : 2;
    if (crop.category == 'herb') score += _goal == _GeneratorGoal.herbsAndSalad ? 5 : 1;
    if (crop.containerFriendly) score += _goal == _GeneratorGoal.smallSpace ? 5 : 1;
    if (rule.method == 'direct_sow') score += 2;
    if (!crop.frostTender) score += 1;
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
                  child: Text('Generated preview', style: Theme.of(context).textTheme.titleLarge),
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
                Chip(label: Text(draft.monthLabel)),
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
                  title: Text(item.crop.commonName),
                  subtitle: Text('${_formatMethod(item.method)} • ${item.reason}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMethod(String method) {
    return switch (method) {
      'transplant' => 'Transplant',
      'direct_sow' => 'Sow direct',
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
    required this.items,
  });

  final int lengthCm;
  final int widthCm;
  final int peopleToFeed;
  final String monthLabel;
  final List<_GeneratedBedItem> items;
}

class _GeneratedBedItem {
  const _GeneratedBedItem({
    required this.crop,
    required this.method,
    required this.plantCount,
    required this.reason,
  });

  final Crop crop;
  final String method;
  final int plantCount;
  final String reason;
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
