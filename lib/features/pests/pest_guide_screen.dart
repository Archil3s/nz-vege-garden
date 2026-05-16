import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/pest_problem.dart';

class PestTrackerScreen extends StatefulWidget {
  const PestTrackerScreen({super.key});

  @override
  State<PestTrackerScreen> createState() => _PestTrackerScreenState();
}

class _PestTrackerScreenState extends State<PestTrackerScreen> {
  final _repository = const GardenDataRepository();
  final _store = const PestSprayScheduleStore();
  late Future<_PestTrackerData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_PestTrackerData> _loadData() async {
    final problems = await _repository.loadPestProblems();
    final entries = await _store.loadEntries();
    return _PestTrackerData(problems: problems, entries: entries);
  }

  Future<void> _reload() async {
    setState(() => _dataFuture = _loadData());
  }

  Future<void> _openEntryForm({PestSprayEntry? entry}) async {
    final data = await _dataFuture;
    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PestSprayEntryForm(
        problems: data.problems,
        entry: entry,
        onSave: (updatedEntry) async {
          await _store.upsertEntry(updatedEntry);
          if (mounted) Navigator.of(context).pop(true);
        },
      ),
    );

    if (saved == true) await _reload();
  }

  Future<void> _markSprayed(PestSprayEntry entry) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await _store.upsertEntry(
      entry.copyWith(
        lastSprayedDate: today,
        nextSprayDate: today.add(Duration(days: entry.intervalDays)),
      ),
    );
    await _reload();
  }

  Future<void> _deleteEntry(PestSprayEntry entry) async {
    await _store.deleteEntry(entry.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pest & spray planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add issue'),
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
                child: Text('Could not load pest planner: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data ?? const _PestTrackerData(problems: [], entries: []);
          final sortedEntries = data.entries.toList()
            ..sort((a, b) => a.nextSprayDate.compareTo(b.nextSprayDate));

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _HeroCard(entries: sortedEntries),
                const SizedBox(height: 12),
                _PestReferenceCard(problems: data.problems),
                const SizedBox(height: 16),
                Text('Spray schedule', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (sortedEntries.isEmpty)
                  _EmptyScheduleCard(onAdd: () => _openEntryForm())
                else
                  ...sortedEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PestSprayEntryCard(
                        entry: entry,
                        onEdit: () => _openEntryForm(entry: entry),
                        onDelete: () => _deleteEntry(entry),
                        onMarkSprayed: () => _markSprayed(entry),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.entries});

  final List<PestSprayEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    final dueToday = entries.where((entry) => !entry.nextSprayDate.isAfter(now)).length;
    final fungusPlans = entries.where((entry) => entry.issueType == PestIssueType.fungus).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track pest pressure and keep fungus spraying on schedule.', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(icon: Icons.bug_report_outlined, label: '${entries.length} active'),
                _StatChip(icon: Icons.notification_important_outlined, label: '$dueToday due'),
                _StatChip(icon: Icons.sanitizer_outlined, label: '$fungusPlans fungus'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
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
      return [problem.name, problem.summary, ...problem.signs, ...problem.actions, ...problem.prevention]
          .join(' ')
          .toLowerCase()
          .contains(query);
    }).take(6).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick pest and fungus guide', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search symptoms',
                hintText: 'Example: mildew, aphids, yellow leaves',
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

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No pest or fungus issues tracked yet.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Add an issue to record the crop, pressure level, treatment, and next spray date.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add first issue')),
          ],
        ),
      ),
    );
  }
}

class _PestSprayEntryCard extends StatelessWidget {
  const _PestSprayEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkSprayed,
  });

  final PestSprayEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkSprayed;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final daysUntilDue = entry.nextSprayDate.difference(today).inDays;
    final dueLabel = daysUntilDue < 0
        ? '${daysUntilDue.abs()} days overdue'
        : daysUntilDue == 0
            ? 'Due today'
            : 'Due in $daysUntilDue days';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(entry.issueType.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                      Text('${entry.cropOrArea} • ${entry.severity.label}'),
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
                Chip(avatar: const Icon(Icons.calendar_today_outlined, size: 18), label: Text(dueLabel)),
                Chip(avatar: const Icon(Icons.repeat_outlined, size: 18), label: Text('Every ${entry.intervalDays} days')),
                if (entry.treatment.isNotEmpty)
                  Chip(avatar: const Icon(Icons.sanitizer_outlined, size: 18), label: Text(entry.treatment)),
              ],
            ),
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.notes),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Next spray: ${DateFormat.yMMMd().format(entry.nextSprayDate)}')),
                FilledButton.tonalIcon(
                  onPressed: onMarkSprayed,
                  icon: const Icon(Icons.check),
                  label: const Text('Sprayed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PestSprayEntryForm extends StatefulWidget {
  const _PestSprayEntryForm({required this.problems, required this.onSave, this.entry});

  final List<PestProblem> problems;
  final PestSprayEntry? entry;
  final ValueChanged<PestSprayEntry> onSave;

  @override
  State<_PestSprayEntryForm> createState() => _PestSprayEntryFormState();
}

class _PestSprayEntryFormState extends State<_PestSprayEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _cropController;
  late final TextEditingController _treatmentController;
  late final TextEditingController _notesController;
  late PestIssueType _issueType;
  late PestSeverity _severity;
  late int _intervalDays;
  late DateTime _nextSprayDate;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _cropController = TextEditingController(text: entry?.cropOrArea ?? '');
    _treatmentController = TextEditingController(text: entry?.treatment ?? 'Fungus spray');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _issueType = entry?.issueType ?? PestIssueType.fungus;
    _severity = entry?.severity ?? PestSeverity.medium;
    _intervalDays = entry?.intervalDays ?? 7;
    _nextSprayDate = entry?.nextSprayDate ?? DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cropController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickNextSprayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextSprayDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _nextSprayDate = DateUtils.dateOnly(picked));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final current = widget.entry;
    widget.onSave(
      PestSprayEntry(
        id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        cropOrArea: _cropController.text.trim(),
        issueType: _issueType,
        severity: _severity,
        treatment: _treatmentController.text.trim(),
        notes: _notesController.text.trim(),
        intervalDays: _intervalDays,
        firstSeenDate: current?.firstSeenDate ?? DateUtils.dateOnly(DateTime.now()),
        lastSprayedDate: current?.lastSprayedDate,
        nextSprayDate: _nextSprayDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problemNames = widget.problems.map((problem) => problem.name).toList(growable: false)..sort();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(widget.entry == null ? 'Add pest or fungus issue' : 'Edit issue', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<PestIssueType>(
              value: _issueType,
              decoration: const InputDecoration(labelText: 'Issue type', border: OutlineInputBorder()),
              items: PestIssueType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _issueType = value);
              },
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return problemNames.take(8);
                return problemNames.where((name) => name.toLowerCase().contains(query)).take(8);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text.isEmpty && _titleController.text.isNotEmpty) {
                  controller.text = _titleController.text;
                }
                controller.addListener(() => _titleController.text = controller.text);
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Pest, fungus, or symptom', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Add the issue name.' : null,
                );
              },
              onSelected: (value) => _titleController.text = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cropController,
              decoration: const InputDecoration(labelText: 'Crop or area', hintText: 'Tomatoes, roses, greenhouse...', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Add the crop or area.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PestSeverity>(
              value: _severity,
              decoration: const InputDecoration(labelText: 'Pressure level', border: OutlineInputBorder()),
              items: PestSeverity.values
                  .map((severity) => DropdownMenuItem(value: severity, child: Text(severity.label)))
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _severity = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _treatmentController,
              decoration: const InputDecoration(labelText: 'Treatment / spray', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _intervalDays,
              decoration: const InputDecoration(labelText: 'Repeat spray every', border: OutlineInputBorder()),
              items: const [3, 5, 7, 10, 14, 21]
                  .map((days) => DropdownMenuItem(value: days, child: Text('$days days')))
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _intervalDays = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickNextSprayDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('Next spray: ${DateFormat.yMMMd().format(_nextSprayDate)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save schedule')),
          ],
        ),
      ),
    );
  }
}

enum PestIssueType {
  pest('Pest', Icons.bug_report_outlined),
  fungus('Fungus / disease', Icons.coronavirus_outlined),
  prevention('Prevention', Icons.health_and_safety_outlined);

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

class PestSprayEntry {
  const PestSprayEntry({
    required this.id,
    required this.title,
    required this.cropOrArea,
    required this.issueType,
    required this.severity,
    required this.treatment,
    required this.notes,
    required this.intervalDays,
    required this.firstSeenDate,
    required this.lastSprayedDate,
    required this.nextSprayDate,
  });

  final String id;
  final String title;
  final String cropOrArea;
  final PestIssueType issueType;
  final PestSeverity severity;
  final String treatment;
  final String notes;
  final int intervalDays;
  final DateTime firstSeenDate;
  final DateTime? lastSprayedDate;
  final DateTime nextSprayDate;

  PestSprayEntry copyWith({DateTime? lastSprayedDate, DateTime? nextSprayDate}) {
    return PestSprayEntry(
      id: id,
      title: title,
      cropOrArea: cropOrArea,
      issueType: issueType,
      severity: severity,
      treatment: treatment,
      notes: notes,
      intervalDays: intervalDays,
      firstSeenDate: firstSeenDate,
      lastSprayedDate: lastSprayedDate ?? this.lastSprayedDate,
      nextSprayDate: nextSprayDate ?? this.nextSprayDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cropOrArea': cropOrArea,
        'issueType': issueType.name,
        'severity': severity.name,
        'treatment': treatment,
        'notes': notes,
        'intervalDays': intervalDays,
        'firstSeenDate': firstSeenDate.toIso8601String(),
        'lastSprayedDate': lastSprayedDate?.toIso8601String(),
        'nextSprayDate': nextSprayDate.toIso8601String(),
      };

  factory PestSprayEntry.fromJson(Map<String, dynamic> json) {
    return PestSprayEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      cropOrArea: json['cropOrArea'] as String,
      issueType: PestIssueType.values.byName(json['issueType'] as String),
      severity: PestSeverity.values.byName(json['severity'] as String),
      treatment: json['treatment'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      intervalDays: json['intervalDays'] as int,
      firstSeenDate: DateTime.parse(json['firstSeenDate'] as String),
      lastSprayedDate: json['lastSprayedDate'] == null ? null : DateTime.parse(json['lastSprayedDate'] as String),
      nextSprayDate: DateTime.parse(json['nextSprayDate'] as String),
    );
  }
}

class PestSprayScheduleStore {
  const PestSprayScheduleStore();

  static const _entriesKey = 'pestSpray.entries';

  Future<List<PestSprayEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_entriesKey) ?? const [];
    return rawEntries
        .map((raw) => PestSprayEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> upsertEntry(PestSprayEntry entry) async {
    final entries = await loadEntries();
    final nextEntries = [
      for (final existing in entries)
        if (existing.id != entry.id) existing,
      entry,
    ];
    await _saveEntries(nextEntries);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    await _saveEntries(entries.where((entry) => entry.id != id).toList(growable: false));
  }

  Future<void> _saveEntries(List<PestSprayEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _entriesKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(growable: false),
    );
  }
}

class _PestTrackerData {
  const _PestTrackerData({required this.problems, required this.entries});

  final List<PestProblem> problems;
  final List<PestSprayEntry> entries;
}
