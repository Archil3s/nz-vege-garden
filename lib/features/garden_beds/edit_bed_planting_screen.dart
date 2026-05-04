import 'package:flutter/material.dart';

import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';

class EditBedPlantingScreen extends StatefulWidget {
  const EditBedPlantingScreen({
    required this.bed,
    required this.planting,
    super.key,
  });

  final GardenBed bed;
  final GardenBedPlanting planting;

  @override
  State<EditBedPlantingScreen> createState() => _EditBedPlantingScreenState();
}

class _EditBedPlantingScreenState extends State<EditBedPlantingScreen> {
  static const _statusOptions = [
    'planned',
    'sown',
    'transplanted',
    'growing',
    'harvesting',
    'finished',
    'failed',
  ];

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _dataRepository = const GardenDataRepository();
  final _plantingRepository = const GardenBedPlantingRepository();

  late String _status;
  late DateTime _plantedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.planting.status;
    _plantedDate = widget.planting.plantedDate;
    _notesController.text = widget.planting.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (picked == null) {
      return;
    }

    setState(() => _plantedDate = picked);
  }

  Future<void> _save(Crop? crop) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final expectedHarvestStartDate = crop == null
        ? widget.planting.expectedHarvestStartDate
        : _plantedDate.add(Duration(days: crop.daysToHarvestMin));
    final expectedHarvestEndDate = crop == null
        ? widget.planting.expectedHarvestEndDate
        : _plantedDate.add(Duration(days: crop.daysToHarvestMax));

    final updatedPlanting = widget.planting.copyWith(
      status: _status,
      plantedDate: _plantedDate,
      expectedHarvestStartDate: expectedHarvestStartDate,
      expectedHarvestEndDate: expectedHarvestEndDate,
      notes: _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await _plantingRepository.updatePlanting(updatedPlanting);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    await _plantingRepository.deletePlanting(widget.planting.id);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planting.cropName),
        actions: [
          IconButton(
            tooltip: 'Remove crop',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<Crop>>(
        future: _dataRepository.loadCrops(),
        builder: (context, snapshot) {
          final crops = snapshot.data ?? const <Crop>[];
          final crop = crops.where((item) => item.id == widget.planting.cropId).firstOrNull;
          final expectedHarvestStartDate = crop == null
              ? widget.planting.expectedHarvestStartDate
              : _plantedDate.add(Duration(days: crop.daysToHarvestMin));
          final expectedHarvestEndDate = crop == null
              ? widget.planting.expectedHarvestEndDate
              : _plantedDate.add(Duration(days: crop.daysToHarvestMax));

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.bed.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.planting.cropName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: const Text('Could not refresh crop data'),
                      subtitle: Text('${snapshot.error}'),
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Estimated harvest window'),
                    subtitle: expectedHarvestStartDate == null || expectedHarvestEndDate == null
                        ? const Text('No harvest estimate available.')
                        : Text(
                            '${_formatDate(expectedHarvestStartDate)} to ${_formatDate(expectedHarvestEndDate)}',
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_formatValue(status)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Planting date'),
                    subtitle: Text(_formatDate(_plantedDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _save(crop),
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
