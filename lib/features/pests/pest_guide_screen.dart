import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/nz_region.dart';
import '../../data/models/pest_problem.dart';

const _fallbackRegion = NzRegion(
  id: 'auckland',
  name: 'Auckland',
  island: 'North Island',
  climateSummary: 'Mild winters, humid summers, good year-round growing potential.',
  defaultFrostRisk: 'low',
  defaultWindRisk: 'moderate',
);

const _warmHumidRegionIds = {'northland', 'auckland', 'waikato_bay_of_plenty'};
const _fungusRiskRegionIds = {'northland', 'auckland', 'waikato_bay_of_plenty', 'taranaki_manawatu', 'west_coast'};

class PestTrackerScreen extends StatefulWidget {
  const PestTrackerScreen({super.key});

  @override
  State<PestTrackerScreen> createState() => _PestTrackerScreenState();
}

class _PestTrackerScreenState extends State<PestTrackerScreen> {
  final _repository = const GardenDataRepository();
  final _store = const PestTrackerStore();
  late Future<_PestTrackerData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_PestTrackerData> _loadData() async {
    final problems = await _repository.loadPestProblems();
    final regions = await _repository.loadRegions();
    final observations = await _store.loadObservations();
    final selectedRegionId = await _store.loadSelectedRegionId();
    final weather = await _store.loadWeather();

    return _PestTrackerData(
      problems: problems,
      regions: regions,
      observations: observations,
      selectedRegionId: selectedRegionId,
      weather: weather,
    );
  }

  Future<void> _reload() async => setState(() => _dataFuture = _loadData());

  Future<void> _setRegion(String regionId) async {
    await _store.saveSelectedRegionId(regionId);
    await _reload();
  }

  Future<void> _setWeather(WeatherConditions weather) async {
    await _store.saveWeather(weather);
    await _reload();
  }

  Future<void> _openObservationForm({PestObservation? observation}) async {
    final data = await _dataFuture;
    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PestObservationForm(
        problems: data.problems,
        observation: observation,
        onSave: (updatedObservation) async {
          await _store.upsertObservation(updatedObservation);
          if (mounted) Navigator.of(context).pop(true);
        },
      ),
    );

    if (saved == true) await _reload();
  }

  Future<void> _deleteObservation(PestObservation observation) async {
    await _store.deleteObservation(observation.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pest tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openObservationForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add pest'),
      ),
      body: FutureBuilder<_PestTrackerData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load pest tracker: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data ?? _PestTrackerData.empty();
          final observations = data.observations.toList()..sort((a, b) => b.sightedDate.compareTo(a.sightedDate));
          final report = PestPressureReport.calculate(
            region: data.selectedRegion,
            weather: data.weather,
            observations: observations,
            date: DateUtils.dateOnly(DateTime.now()),
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _PressureCard(report: report, region: data.selectedRegion, observations: observations),
                const SizedBox(height: 12),
                _WeatherCard(
                  region: data.selectedRegion,
                  regions: data.regions.isEmpty ? const [_fallbackRegion] : data.regions,
                  weather: data.weather,
                  onRegionChanged: _setRegion,
                  onWeatherChanged: _setWeather,
                ),
                const SizedBox(height: 12),
                _PestReferenceCard(problems: data.problems),
                const SizedBox(height: 16),
                Text('Pest sightings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (observations.isEmpty)
                  _EmptyTrackerCard(onAdd: () => _openObservationForm())
                else
                  ...observations.map(
                    (observation) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PestObservationCard(
                        observation: observation,
                        onEdit: () => _openObservationForm(observation: observation),
                        onDelete: () => _deleteObservation(observation),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PressureCard extends StatelessWidget {
  const _PressureCard({required this.report, required this.region, required this.observations});

  final PestPressureReport report;
  final NzRegion region;
  final List<PestObservation> observations;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pest pressure', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(report.level.icon),
              title: Text(report.level.label),
              subtitle: Text(report.message),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.place_outlined, size: 18), label: Text(region.name)),
                Chip(avatar: const Icon(Icons.wb_sunny_outlined, size: 18), label: Text(report.weatherLabel)),
                Chip(avatar: const Icon(Icons.bug_report_outlined, size: 18), label: Text('${report.recentSightings} recent sightings')),
              ],
            ),
            const SizedBox(height: 10),
            ...report.alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(alert)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.region,
    required this.regions,
    required this.weather,
    required this.onRegionChanged,
    required this.onWeatherChanged,
  });

  final NzRegion region;
  final List<NzRegion> regions;
  final WeatherConditions weather;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<WeatherConditions> onWeatherChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather information', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(region.climateSummary),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: region.id,
              decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
              items: regions.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(growable: false),
              onChanged: (value) {
                if (value != null) onRegionChanged(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TemperatureBand>(
              value: weather.temperature,
              decoration: const InputDecoration(labelText: 'Temperature', border: OutlineInputBorder(), prefixIcon: Icon(Icons.thermostat_outlined)),
              items: TemperatureBand.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(growable: false),
              onChanged: (value) {
                if (value != null) onWeatherChanged(weather.copyWith(temperature: value));
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MoistureBand>(
              value: weather.moisture,
              decoration: const InputDecoration(labelText: 'Humidity / leaf wetness', border: OutlineInputBorder(), prefixIcon: Icon(Icons.water_drop_outlined)),
              items: MoistureBand.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(growable: false),
              onChanged: (value) {
                if (value != null) onWeatherChanged(weather.copyWith(moisture: value));
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WindBand>(
              value: weather.wind,
              decoration: const InputDecoration(labelText: 'Wind / airflow', border: OutlineInputBorder(), prefixIcon: Icon(Icons.air_outlined)),
              items: WindBand.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(growable: false),
              onChanged: (value) {
                if (value != null) onWeatherChanged(weather.copyWith(wind: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PestReferenceCard extends StatefulWidget {
  const _PestReferenceCard({required this.problems});
  final List<PestProblem> problems;

  @override
  State<_PestReferenceCard> createState() => _PestReferenceCardState();
}

class _PestReferenceCardState extends State<_PestReferenceCard> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = widget.problems.where((problem) {
      if (query.isEmpty) return problem.category == 'pest' || problem.category == 'disease';
      return [problem.name, problem.summary, ...problem.signs, ...problem.actions, ...problem.prevention].join(' ').toLowerCase().contains(query);
    }).take(6).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pest guide', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search pests or symptoms',
                hintText: 'Example: mildew, aphids, holes, yellow leaves',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            if (matches.isEmpty)
              const Text('No matching guide entries found.')
            else
              ...matches.map((problem) => _ProblemReferenceTile(problem: problem)),
          ],
        ),
      ),
    );
  }
}

class _ProblemReferenceTile extends StatelessWidget {
  const _ProblemReferenceTile({required this.problem});
  final PestProblem problem;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(problem.category == 'disease' ? Icons.coronavirus_outlined : Icons.bug_report_outlined),
      title: Text(problem.name),
      subtitle: Text(problem.summary),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        _MiniSection(title: 'Signs', items: problem.signs),
        _MiniSection(title: 'Actions', items: problem.actions),
        _MiniSection(title: 'Prevention', items: problem.prevention),
      ],
    );
  }
}

class _MiniSection extends StatelessWidget {
  const _MiniSection({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ...items.map((item) => Text('• $item')),
        ],
      ),
    );
  }
}

class _EmptyTrackerCard extends StatelessWidget {
  const _EmptyTrackerCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No pest sightings tracked yet.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Add sightings as you find them. Weather and recent entries control the pest pressure level.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add first pest')),
          ],
        ),
      ),
    );
  }
}

class _PestObservationCard extends StatelessWidget {
  const _PestObservationCard({required this.observation, required this.onEdit, required this.onDelete});
  final PestObservation observation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ageDays = DateUtils.dateOnly(DateTime.now()).difference(observation.sightedDate).inDays;
    final ageLabel = ageDays == 0 ? 'Seen today' : ageDays == 1 ? 'Seen yesterday' : 'Seen $ageDays days ago';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(observation.issueType.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(observation.name, style: Theme.of(context).textTheme.titleMedium),
                      Text('${observation.cropOrArea} • ${observation.severity.label}'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: Icon(observation.issueType.icon, size: 18), label: Text(observation.issueType.label)),
                Chip(avatar: const Icon(Icons.speed_outlined, size: 18), label: Text(observation.severity.label)),
                Chip(avatar: const Icon(Icons.event_outlined, size: 18), label: Text(ageLabel)),
              ],
            ),
            if (observation.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(observation.notes),
            ],
          ],
        ),
      ),
    );
  }
}

class _PestObservationForm extends StatefulWidget {
  const _PestObservationForm({required this.problems, required this.onSave, this.observation});
  final List<PestProblem> problems;
  final PestObservation? observation;
  final ValueChanged<PestObservation> onSave;

  @override
  State<_PestObservationForm> createState() => _PestObservationFormState();
}

class _PestObservationFormState extends State<_PestObservationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cropController;
  late final TextEditingController _notesController;
  late PestIssueType _issueType;
  late PestSeverity _severity;
  late DateTime _sightedDate;

  @override
  void initState() {
    super.initState();
    final observation = widget.observation;
    _nameController = TextEditingController(text: observation?.name ?? '');
    _cropController = TextEditingController(text: observation?.cropOrArea ?? '');
    _notesController = TextEditingController(text: observation?.notes ?? '');
    _issueType = observation?.issueType ?? PestIssueType.pest;
    _severity = observation?.severity ?? PestSeverity.medium;
    _sightedDate = observation?.sightedDate ?? DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cropController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSightedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sightedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _sightedDate = DateUtils.dateOnly(picked));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final current = widget.observation;
    widget.onSave(PestObservation(
      id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      cropOrArea: _cropController.text.trim(),
      issueType: _issueType,
      severity: _severity,
      notes: _notesController.text.trim(),
      sightedDate: _sightedDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final problemNames = widget.problems.map((problem) => problem.name).toList(growable: false)..sort();
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(widget.observation == null ? 'Add pest sighting' : 'Edit pest sighting', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<PestIssueType>(
              value: _issueType,
              decoration: const InputDecoration(labelText: 'Issue type', border: OutlineInputBorder()),
              items: PestIssueType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _issueType = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Pest or symptom',
                hintText: problemNames.isEmpty ? 'Example: Aphids' : 'Example: ${problemNames.first}',
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Add the pest or symptom.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cropController,
              decoration: const InputDecoration(labelText: 'Crop or area', hintText: 'Tomatoes, citrus, greenhouse...', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Add the crop or area.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PestSeverity>(
              value: _severity,
              decoration: const InputDecoration(labelText: 'Pressure level', border: OutlineInputBorder()),
              items: PestSeverity.values.map((severity) => DropdownMenuItem(value: severity, child: Text(severity.label))).toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _severity = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _pickSightedDate, icon: const Icon(Icons.event_outlined), label: Text('Sighted: ${DateFormat.yMMMd().format(_sightedDate)}')),
            const SizedBox(height: 12),
            TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), minLines: 2, maxLines: 4),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save sighting')),
          ],
        ),
      ),
    );
  }
}

enum PestIssueType {
  pest('Pest', Icons.bug_report_outlined),
  fungus('Fungus / disease', Icons.coronavirus_outlined),
  prevention('Risk watch', Icons.health_and_safety_outlined);
  const PestIssueType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum PestSeverity {
  low('Low pressure'),
  medium('Medium pressure'),
  high('High pressure');
  const PestSeverity(this.label);
  final String label;
}

enum PestPressureLevel {
  low('Low pressure', Icons.check_circle_outline),
  moderate('Moderate pressure', Icons.warning_amber_outlined),
  high('High pressure', Icons.notification_important_outlined);
  const PestPressureLevel(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum TemperatureBand {
  cool('Cool'),
  mild('Mild'),
  warm('Warm'),
  hot('Hot');
  const TemperatureBand(this.label);
  final String label;
}

enum MoistureBand {
  dry('Dry'),
  normal('Normal'),
  humid('Humid / wet leaves'),
  rainy('Rainy');
  const MoistureBand(this.label);
  final String label;
}

enum WindBand {
  sheltered('Sheltered'),
  breezy('Breezy'),
  windy('Windy');
  const WindBand(this.label);
  final String label;
}

class WeatherConditions {
  const WeatherConditions({required this.temperature, required this.moisture, required this.wind});
  static const defaults = WeatherConditions(temperature: TemperatureBand.mild, moisture: MoistureBand.normal, wind: WindBand.breezy);

  final TemperatureBand temperature;
  final MoistureBand moisture;
  final WindBand wind;

  WeatherConditions copyWith({TemperatureBand? temperature, MoistureBand? moisture, WindBand? wind}) {
    return WeatherConditions(
      temperature: temperature ?? this.temperature,
      moisture: moisture ?? this.moisture,
      wind: wind ?? this.wind,
    );
  }

  Map<String, dynamic> toJson() => {'temperature': temperature.name, 'moisture': moisture.name, 'wind': wind.name};

  factory WeatherConditions.fromJson(Map<String, dynamic> json) {
    return WeatherConditions(
      temperature: _enumByName(TemperatureBand.values, json['temperature'], TemperatureBand.mild),
      moisture: _enumByName(MoistureBand.values, json['moisture'], MoistureBand.normal),
      wind: _enumByName(WindBand.values, json['wind'], WindBand.breezy),
    );
  }
}

class PestPressureReport {
  const PestPressureReport({required this.level, required this.score, required this.recentSightings, required this.message, required this.weatherLabel, required this.alerts});

  final PestPressureLevel level;
  final int score;
  final int recentSightings;
  final String message;
  final String weatherLabel;
  final List<String> alerts;

  factory PestPressureReport.calculate({required NzRegion region, required WeatherConditions weather, required List<PestObservation> observations, required DateTime date}) {
    var score = 1;
    final month = date.month;
    final isWarmSeason = const [12, 1, 2, 3].contains(month);
    final isShoulderSeason = const [4, 5, 9, 10, 11].contains(month);
    final isFungusSeason = const [4, 5, 9, 10, 11, 12, 1, 2, 3].contains(month);

    if (_warmHumidRegionIds.contains(region.id)) score += 2;
    if (_fungusRiskRegionIds.contains(region.id)) score += 1;
    if (isWarmSeason) score += 2;
    if (isShoulderSeason) score += 1;
    if (weather.temperature == TemperatureBand.warm || weather.temperature == TemperatureBand.hot) score += 2;
    if (weather.moisture == MoistureBand.humid || weather.moisture == MoistureBand.rainy) score += 2;
    if (weather.wind == WindBand.sheltered) score += 1;

    final recentObservations = observations.where((observation) {
      final age = date.difference(observation.sightedDate).inDays;
      return age >= 0 && age <= 14;
    }).toList(growable: false);
    final recentHighPressure = recentObservations.where((observation) => observation.severity == PestSeverity.high).length;
    final recentFungus = recentObservations.where((observation) => observation.issueType == PestIssueType.fungus).length;

    score += recentObservations.length > 3 ? 3 : recentObservations.length;
    score += recentHighPressure * 2;
    if (recentFungus > 0 && isFungusSeason) score += 2;

    final level = score >= 9 ? PestPressureLevel.high : score >= 5 ? PestPressureLevel.moderate : PestPressureLevel.low;
    final alerts = <String>[];

    if (level == PestPressureLevel.high) {
      alerts.add('Inspect vulnerable plants every 2-3 days.');
      alerts.add('Remove badly affected leaves and isolate heavy infestations early.');
    } else if (level == PestPressureLevel.moderate) {
      alerts.add('Check new growth and leaf undersides this week.');
    } else {
      alerts.add('Low risk: keep monitoring and maintain good airflow.');
    }

    if ((weather.moisture == MoistureBand.humid || weather.moisture == MoistureBand.rainy || recentFungus > 0) && isFungusSeason) {
      alerts.add('Fungus watch: avoid wet leaves overnight and improve airflow.');
    }

    return PestPressureReport(
      level: level,
      score: score,
      recentSightings: recentObservations.length,
      message: '${region.name}: ${region.climateSummary}',
      weatherLabel: '${weather.temperature.label}, ${weather.moisture.label}, ${weather.wind.label}',
      alerts: alerts,
    );
  }
}

class PestObservation {
  const PestObservation({required this.id, required this.name, required this.cropOrArea, required this.issueType, required this.severity, required this.notes, required this.sightedDate});

  final String id;
  final String name;
  final String cropOrArea;
  final PestIssueType issueType;
  final PestSeverity severity;
  final String notes;
  final DateTime sightedDate;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cropOrArea': cropOrArea, 'issueType': issueType.name, 'severity': severity.name, 'notes': notes, 'sightedDate': sightedDate.toIso8601String()};

  factory PestObservation.fromJson(Map<String, dynamic> json) {
    return PestObservation(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? json['title'] as String? ?? 'Pest sighting',
      cropOrArea: json['cropOrArea'] as String? ?? 'Garden',
      issueType: _enumByName(PestIssueType.values, json['issueType'], PestIssueType.pest),
      severity: _enumByName(PestSeverity.values, json['severity'], PestSeverity.medium),
      notes: json['notes'] as String? ?? '',
      sightedDate: _dateOnlyFromJson(json['sightedDate'] ?? json['firstSeenDate']),
    );
  }
}

class PestTrackerStore {
  const PestTrackerStore();

  static const _observationsKey = 'pestTracker.observations';
  static const _legacySprayEntriesKey = 'pestSpray.entries';
  static const _regionKey = 'pestTracker.regionId';
  static const _weatherKey = 'pestTracker.weather';

  Future<List<PestObservation>> loadObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final rawObservations = prefs.getStringList(_observationsKey) ?? const [];
    if (rawObservations.isNotEmpty) {
      return rawObservations.map((raw) => PestObservation.fromJson(jsonDecode(raw) as Map<String, dynamic>)).toList(growable: false);
    }

    final legacyEntries = prefs.getStringList(_legacySprayEntriesKey) ?? const [];
    if (legacyEntries.isEmpty) return const [];

    final migrated = legacyEntries.map((raw) => PestObservation.fromJson(jsonDecode(raw) as Map<String, dynamic>)).toList(growable: false);
    await _saveObservations(migrated);
    return migrated;
  }

  Future<void> upsertObservation(PestObservation observation) async {
    final observations = await loadObservations();
    await _saveObservations([for (final existing in observations) if (existing.id != observation.id) existing, observation]);
  }

  Future<void> deleteObservation(String id) async {
    final observations = await loadObservations();
    await _saveObservations(observations.where((observation) => observation.id != id).toList(growable: false));
  }

  Future<String> loadSelectedRegionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionKey) ?? _fallbackRegion.id;
  }

  Future<void> saveSelectedRegionId(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, regionId);
  }

  Future<WeatherConditions> loadWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weatherKey);
    if (raw == null) return WeatherConditions.defaults;
    return WeatherConditions.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveWeather(WeatherConditions weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherKey, jsonEncode(weather.toJson()));
  }

  Future<void> _saveObservations(List<PestObservation> observations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_observationsKey, observations.map((observation) => jsonEncode(observation.toJson())).toList(growable: false));
  }
}

class _PestTrackerData {
  const _PestTrackerData({required this.problems, required this.regions, required this.observations, required this.selectedRegionId, required this.weather});

  factory _PestTrackerData.empty() {
    return const _PestTrackerData(
      problems: [],
      regions: [_fallbackRegion],
      observations: [],
      selectedRegionId: 'auckland',
      weather: WeatherConditions.defaults,
    );
  }

  final List<PestProblem> problems;
  final List<NzRegion> regions;
  final List<PestObservation> observations;
  final String selectedRegionId;
  final WeatherConditions weather;

  NzRegion get selectedRegion {
    if (regions.isEmpty) return _fallbackRegion;
    return regions.firstWhere((region) => region.id == selectedRegionId, orElse: () => regions.first);
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  final text = name?.toString();
  return values.firstWhere((value) => value.name == text, orElse: () => fallback);
}

DateTime _dateOnlyFromJson(Object? value) {
  if (value is String && value.trim().isNotEmpty) return DateUtils.dateOnly(DateTime.parse(value));
  return DateUtils.dateOnly(DateTime.now());
}
