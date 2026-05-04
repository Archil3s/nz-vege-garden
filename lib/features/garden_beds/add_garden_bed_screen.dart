import 'package:flutter/material.dart';

import '../../data/garden_bed_repository.dart';
import '../../data/models/garden_bed.dart';

class AddGardenBedScreen extends StatefulWidget {
  const AddGardenBedScreen({super.key});

  @override
  State<AddGardenBedScreen> createState() => _AddGardenBedScreenState();
}

class _AddGardenBedScreenState extends State<AddGardenBedScreen> {
  static const _bedTypeOptions = [
    'open_bed',
    'raised_bed',
    'container',
    'greenhouse',
  ];

  static const _sunExposureOptions = [
    'full_sun',
    'part_shade',
    'mostly_shade',
  ];

  static const _windExposureOptions = [
    'sheltered',
    'moderate',
    'exposed',
    'coastal',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _notesController = TextEditingController();

  String _bedType = 'raised_bed';
  String _sunExposure = 'full_sun';
  String _windExposure = 'moderate';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveGardenBed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final lengthCm = int.tryParse(_lengthController.text.trim());
    final widthCm = int.tryParse(_widthController.text.trim());

    final bed = GardenBed.create(
      name: _nameController.text.trim(),
      type: _bedType,
      lengthCm: lengthCm,
      widthCm: widthCm,
      sunExposure: _sunExposure,
      windExposure: _windExposure,
      notes: _notesController.text.trim(),
    );

    await const GardenBedRepository().addGardenBed(bed);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add garden bed'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Example: Front raised bed',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a bed name.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _bedTypeOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_formatValue(option)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() => _bedType = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Length cm',
                      border: OutlineInputBorder(),
                    ),
                    validator: _optionalPositiveNumberValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Width cm',
                      border: OutlineInputBorder(),
                    ),
                    validator: _optionalPositiveNumberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sunExposure,
              decoration: const InputDecoration(
                labelText: 'Sun exposure',
                border: OutlineInputBorder(),
              ),
              items: _sunExposureOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_formatValue(option)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() => _sunExposure = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _windExposure,
              decoration: const InputDecoration(
                labelText: 'Wind exposure',
                border: OutlineInputBorder(),
              ),
              items: _windExposureOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_formatValue(option)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() => _windExposure = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Example: Best for leafy greens in winter.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveGardenBed,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save garden bed'),
            ),
          ],
        ),
      ),
    );
  }

  String? _optionalPositiveNumberValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final number = int.tryParse(trimmed);
    if (number == null || number <= 0) {
      return 'Enter a positive number.';
    }

    return null;
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
