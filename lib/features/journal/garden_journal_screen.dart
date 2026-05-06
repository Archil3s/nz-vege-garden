import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GardenJournalScreen extends StatefulWidget {
  const GardenJournalScreen({super.key});

  @override
  State<GardenJournalScreen> createState() => _GardenJournalScreenState();
}

class _GardenJournalScreenState extends State<GardenJournalScreen> {
  static const _storageKey = 'garden_journal_entries_v1';

  late Future<List<GardenJournalEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<GardenJournalEntry>> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_storageKey) ?? const <String>[];

    final entries = rawEntries
        .map((raw) => GardenJournalEntry.tryParse(raw))
        .whereType<GardenJournalEntry>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return entries;
  }

  Future<void> _saveEntries(List<GardenJournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _addEntry(GardenJournalEntry entry) async {
    final entries = await _entriesFuture;
    await _saveEntries([entry, ...entries]);
    _reload();
  }

  Future<void> _deleteEntry(GardenJournalEntry entry) async {
    final entries = await _entriesFuture;
    await _saveEntries(entries.where((candidate) => candidate.id != entry.id).toList());
    _reload();
  }

  void _reload() {
    setState(() {
      _entriesFuture = _loadEntries();
    });
  }

  void _openAddSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AddJournalEntrySheet(onSave: _addEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garden journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add note'),
      ),
      body: FutureBuilder<List<GardenJournalEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <GardenJournalEntry>[];
          if (entries.isEmpty) {
            return const _EmptyJournalState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _JournalSummaryCard(entries: entries);
              }

              final entry = entries[index - 1];
              return _JournalEntryCard(
                entry: entry,
                onDelete: () => _deleteEntry(entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _JournalSummaryCard extends StatelessWidget {
  const _JournalSummaryCard({required this.entries});

  final List<GardenJournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latest = entries.first;
    final categories = entries.map((entry) => entry.category).toSet().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Offline garden notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${entries.length} notes saved on this device'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text('$categories categories'),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text('Latest ${_formatDate(latest.createdAt)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry, required this.onDelete});

  final GardenJournalEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.selectionClick();
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This removes the note from this device.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Icon(_iconForCategory(entry.category))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.category} · ${_formatDate(entry.createdAt)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(entry.note, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a garden journal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Save observations, pest sightings, harvest notes, and weather comments offline on this device.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddJournalEntrySheet extends StatefulWidget {
  const _AddJournalEntrySheet({required this.onSave});

  final Future<void> Function(GardenJournalEntry entry) onSave;

  @override
  State<_AddJournalEntrySheet> createState() => _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState extends State<_AddJournalEntrySheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = _categories.first;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and note before saving.')),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.onSave(
      GardenJournalEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        note: note,
        category: _category,
        createdAt: DateTime.now(),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New garden note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. First tomato flowers',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'What changed in the garden?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GardenJournalEntry {
  const GardenJournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final String category;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static GardenJournalEntry? tryParse(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return GardenJournalEntry(
        id: data['id'] as String,
        title: data['title'] as String,
        note: data['note'] as String,
        category: data['category'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

const _categories = [
  'Observation',
  'Pest',
  'Harvest',
  'Weather',
  'Soil',
  'Idea',
];

IconData _iconForCategory(String category) {
  return switch (category) {
    'Pest' => Icons.bug_report_outlined,
    'Harvest' => Icons.shopping_basket_outlined,
    'Weather' => Icons.wb_cloudy_outlined,
    'Soil' => Icons.grass_outlined,
    'Idea' => Icons.lightbulb_outline,
    _ => Icons.visibility_outlined,
  };
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]}';
}
