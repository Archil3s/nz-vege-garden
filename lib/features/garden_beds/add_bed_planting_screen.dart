import 'package:flutter/material.dart';

import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';

class AddBedPlantingScreen extends StatefulWidget {
  const AddBedPlantingScreen({
    required this.bed,
    super.key,
  });

  final GardenBed bed;

  @override
  State<AddBedPlantingScreen> createState() => _AddBedPlantingScreenState();
}

class _AddBedPlantingScreenState extends State<AddBedPlantingScreen> {
  static const _statusOptions = [
    'planned',
    'sown',
    'transplanted',
    'growing',
    'harvesting',
  ];

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _plantCountController = TextEditingController(text: '1');
  final _dataRepository = const GardenDataRepository();
  final _plantingRepository = const GardenBedPlantingRepository();

  String? _selectedCropId;
  String _status = 'planned';
  DateTime _plantedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _plantCountController.dispose();
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

  Future<void> _save(List<Crop> crops) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCrop = crops.firstWhere((crop) => crop.id == _selectedCropId);
    final plantCount = int.parse(_plantCountController.text.trim());
    final expectedHarvestStartDate = _plantedDate.add(
      Duration(days: selectedCrop.daysToHarvestMin),
    );
    final expectedHarvestEndDate = _plantedDate.add(
      Duration(days: selectedCrop.daysToHarvestMax),
    );

    setState(() => _isSaving = true);

    final planting = GardenBedPlanting.create(
      bedId: widget.bed.id,
      cropId: selectedCrop.id,
      cropName: selectedCrop.commonName,
      status: _status,
      plantCount: plantCount,
      plantedDate: _plantedDate,
      expectedHarvestStartDate: expectedHarvestStartDate,
      expectedHarvestEndDate: expectedHarvestEndDate,
      notes: _notesController.text.trim(),
    );

    await _plantingRepository.addPlanting(planting);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  int? _estimateMaxPlants(Crop crop) {
    final areaSquareMeters = widget.bed.areaSquareMeters;
    if (areaSquareMeters == null || areaSquareMeters <= 0 || crop.spacingCm <= 0) {
      return null;
    }

    final plantAreaSquareMeters = (crop.spacingCm / 100) * (crop.spacingCm / 100);
    return (areaSquareMeters / plantAreaSquareMeters).floor().clamp(1, 999);
  }

  String? _validatePlantCount(String? value, Crop? selectedCrop) {
    final trimmed = value?.trim() ?? '';
    final count = int.tryParse(trimmed);

    if (count == null) {
      return 'Enter a whole number.';
    }

    if (count < 1) {
      return 'Add at least 1 plant.';
    }

    if (count > 999) {
      return 'Use 999 or fewer plants.';
    }

    final maxPlants = selectedCrop == null ? null : _estimateMaxPlants(selectedCrop);
    if (maxPlants != null && count > maxPlants) {
      return 'This may exceed spacing. Suggested maximum: $maxPlants.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add crop to ${widget.bed.name}'),
      ),
      body: FutureBuilder<List<Crop>>(
        future: _dataRepository.loadCrops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load crops: ${snapshot.error}'),
              ),
            );
          }

          final crops = snapshot.data ?? const <Crop>[];
          final selectedCrop = _selectedCropId == null
              ? null
              : crops.where((crop) => crop.id == _selectedCropId).firstOrNull;
          final estimatedMax = selectedCrop == null ? null : _estimateMaxPlants(selectedCrop);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCropId,
                  decoration: const InputDecoration(
                    labelText: 'Crop',
                    border: OutlineInputBorder(),
                  ),
                  items: crops
                      .map(
                        (crop) => DropdownMenuItem(
                          value: crop.id,
                          child: Text(crop.commonName),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) => value == null ? 'Choose a crop.' : null,
                  onChanged: (value) {
                    setState(() => _selectedCropId = value);
                  },
                ),
                if (selectedCrop != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: const Text('Estimated harvest window'),
                      subtitle: Text(
                        '${_formatDate(_plantedDate.add(Duration(days: selectedCrop.daysToHarvestMin)))} '
                        'to ${_formatDate(_plantedDate.add(Duration(days: selectedCrop.daysToHarvestMax)))}',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plantCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number of plants',
                    hintText: 'Example: 1, 6, 20',
                    helperText: estimatedMax == null
                        ? 'Used by the visual bed planner to draw individual plants.'
                        : 'Spacing estimate for this bed: up to $estimatedMax plants.',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => _validatePlantCount(value, selectedCrop),
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
                    hintText: 'Example: planted along back row with support.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _save(crops),
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save crop'),
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
