import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HarvestTrackerScreen extends StatefulWidget {
  const HarvestTrackerScreen({super.key});

  @override
  State<HarvestTrackerScreen> createState() => _HarvestTrackerScreenState();
}

class _HarvestTrackerScreenState extends State<HarvestTrackerScreen> {
  static const _storageKey = 'harvest_tracker_entries_v1';

  late Future<List<HarvestEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<HarvestEntry>> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_storageKey) ?? const <String>[];

    return rawEntries
        .map((raw) => HarvestEntry.tryParse(raw))
        .whereType<HarvestEntry>()
        .toList()
      ..sort((a, b) => b.harvestedAt.compareTo(a.harvestedAt));
  }

  Future<void> _saveEntries(List<HarvestEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _addEntry(HarvestEntry entry) async {
    final entries = await _entriesFuture;
    await _saveEntries([entry, ...entries]);
    _reload();
  }

  Future<void> _deleteEntry(HarvestEntry entry) async {
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
      builder: (context) => _AddHarvestEntrySheet(onSave: _addEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harvest tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add harvest'),
      ),
      body: FutureBuilder<List<HarvestEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <HarvestEntry>[];
          if (entries.isEmpty) return const _EmptyHarvestState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) return _HarvestSummaryCard(entries: entries);
              final entry = entries[index - 1];
              return _HarvestEntryCard(
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

class _HarvestSummaryCard extends StatelessWidget {
  const _HarvestSummaryCard({required this.entries});

  final List<HarvestEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final crops = entries.map((entry) => entry.cropName.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet().length;
    final bestCrop = _bestCrop(entries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Harvest total',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_formatAmount(total)} kg logged',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.eco_outlined, size: 18),
                  label: Text('$crops crops'),
                ),
                Chip(
                  avatar: const Icon(Icons.star_outline, size: 18),
                  label: Text(bestCrop == null ? 'No leader yet' : 'Top: $bestCrop'),
                ),
                Chip(
                  avatar: const Icon(Icons.history_outlined, size: 18),
                  label: Text('Latest ${_formatDate(entries.first.harvestedAt)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HarvestEntryCard extends StatelessWidget {
  const _HarvestEntryCard({required this.entry, required this.onDelete});

  final HarvestEntry entry;
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
            title: const Text('Delete harvest?'),
            content: const Text('This removes the harvest record from this device.'),
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
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.shopping_basket_outlined)),
          title: Text(entry.cropName),
          subtitle: Text('${_formatDate(entry.harvestedAt)} · ${entry.note.isEmpty ? 'No note' : entry.note}'),
          trailing: Text(
            '${_formatAmount(entry.amount)} kg',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _EmptyHarvestState extends StatelessWidget {
  const _EmptyHarvestState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Track your harvests', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Log crop weights and notes offline so you can see what your garden is producing over time.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddHarvestEntrySheet extends StatefulWidget {
  const _AddHarvestEntrySheet({required this.onSave});

  final Future<void> Function(HarvestEntry entry) onSave;

  @override
  State<_AddHarvestEntrySheet> createState() => _AddHarvestEntrySheetState();
}

class _AddHarvestEntrySheetState extends State<_AddHarvestEntrySheet> {
  final _cropController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cropController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cropName = _cropController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();

    if (cropName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a crop and a harvest weight above 0 kg.')),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.onSave(
      HarvestEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        cropName: cropName,
        amount: amount,
        note: note,
        harvestedAt: DateTime.now(),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add harvest', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _cropController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Crop', hintText: 'e.g. Tomatoes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Weight in kg', hintText: 'e.g. 1.4'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Note', hintText: 'Optional note'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save harvest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HarvestEntry {
  const HarvestEntry({
    required this.id,
    required this.cropName,
    required this.amount,
    required this.note,
    required this.harvestedAt,
  });

  final String id;
  final String cropName;
  final double amount;
  final String note;
  final DateTime harvestedAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'amount': amount,
      'note': note,
      'harvestedAt': harvestedAt.toIso8601String(),
    };
  }

  static HarvestEntry? tryParse(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return HarvestEntry(
        id: data['id'] as String,
        cropName: data['cropName'] as String,
        amount: (data['amount'] as num).toDouble(),
        note: data['note'] as String? ?? '',
        harvestedAt: DateTime.parse(data['harvestedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

String? _bestCrop(List<HarvestEntry> entries) {
  final totals = <String, double>{};
  for (final entry in entries) {
    final name = entry.cropName.trim();
    if (name.isEmpty) continue;
    totals[name] = (totals[name] ?? 0) + entry.amount;
  }
  if (totals.isEmpty) return null;
  return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]}';
}
