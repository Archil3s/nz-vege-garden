import 'package:flutter/material.dart';

import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_bed_repository.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';
import 'add_bed_planting_screen.dart';
import 'add_garden_bed_screen.dart';
import 'edit_bed_planting_screen.dart';
import 'edit_garden_bed_screen.dart';

class GardenBedsScreen extends StatefulWidget {
  const GardenBedsScreen({super.key});

  @override
  State<GardenBedsScreen> createState() => _GardenBedsScreenState();
}

class _GardenBedsScreenState extends State<GardenBedsScreen> {
  final _bedRepository = const GardenBedRepository();
  final _plantingRepository = const GardenBedPlantingRepository();
  late Future<_GardenBedsData> _gardenBedsFuture;

  @override
  void initState() {
    super.initState();
    _gardenBedsFuture = _loadGardenBedsData();
  }

  Future<_GardenBedsData> _loadGardenBedsData() async {
    final beds = await _bedRepository.loadGardenBeds();
    final plantings = await _plantingRepository.loadPlantings();

    return _GardenBedsData(beds: beds, plantings: plantings);
  }

  void _reloadGardenBeds() {
    setState(() {
      _gardenBedsFuture = _loadGardenBedsData();
    });
  }

  Future<void> _openAddGardenBedScreen() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddGardenBedScreen(),
      ),
    );

    if (saved == true) {
      _reloadGardenBeds();
    }
  }

  Future<void> _openEditGardenBedScreen(GardenBed bed) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditGardenBedScreen(bed: bed),
      ),
    );

    if (saved == true) {
      _reloadGardenBeds();
    }
  }

  Future<void> _openAddPlantingScreen(GardenBed bed) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddBedPlantingScreen(bed: bed),
      ),
    );

    if (saved == true) {
      _reloadGardenBeds();
    }
  }

  Future<void> _openEditPlantingScreen({
    required GardenBed bed,
    required GardenBedPlanting planting,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditBedPlantingScreen(
          bed: bed,
          planting: planting,
        ),
      ),
    );

    if (saved == true) {
      _reloadGardenBeds();
    }
  }

  Future<void> _deleteGardenBed(GardenBed bed) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete garden bed?'),
        content: Text(
          'This will delete ${bed.name} and any crops saved in this bed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await _bedRepository.deleteGardenBed(bed.id);
    await _plantingRepository.deletePlantingsForBed(bed.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${bed.name}.')),
    );

    _reloadGardenBeds();
  }

  Future<void> _deletePlanting(GardenBedPlanting planting) async {
    await _plantingRepository.deletePlanting(planting.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${planting.cropName}.')),
    );

    _reloadGardenBeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My garden beds'),
      ),
      body: FutureBuilder<_GardenBedsData>(
        future: _gardenBedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load garden beds: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          final beds = data?.beds ?? const <GardenBed>[];
          final plantings = data?.plantings ?? const <GardenBedPlanting>[];

          if (beds.isEmpty) {
            return _EmptyGardenBedsState(
              onAddPressed: _openAddGardenBedScreen,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: beds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bed = beds[index];
              final bedPlantings = plantings
                  .where((planting) => planting.bedId == bed.id)
                  .toList(growable: false);

              return _GardenBedCard(
                bed: bed,
                plantings: bedPlantings,
                onAddCropPressed: () => _openAddPlantingScreen(bed),
                onEditPressed: () => _openEditGardenBedScreen(bed),
                onDeletePressed: () => _deleteGardenBed(bed),
                onDeletePlantingPressed: _deletePlanting,
                onEditPlantingPressed: (planting) => _openEditPlantingScreen(
                  bed: bed,
                  planting: planting,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGardenBedScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add bed'),
      ),
    );
  }
}

class _EmptyGardenBedsState extends StatelessWidget {
  const _EmptyGardenBedsState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.yard_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No garden beds yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create raised beds, pots, greenhouse areas, or open garden beds to start planning your home vegetable garden.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add first bed'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenBedCard extends StatelessWidget {
  const _GardenBedCard({
    required this.bed,
    required this.plantings,
    required this.onAddCropPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.onDeletePlantingPressed,
    required this.onEditPlantingPressed,
  });

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;
  final VoidCallback onAddCropPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final ValueChanged<GardenBedPlanting> onDeletePlantingPressed;
  final ValueChanged<GardenBedPlanting> onEditPlantingPressed;

  @override
  Widget build(BuildContext context) {
    final area = bed.areaSquareMeters;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.yard_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bed.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(_formatValue(bed.type)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit bed',
                  onPressed: onEditPressed,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete bed',
                  onPressed: onDeletePressed,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.wb_sunny_outlined,
                  label: _formatValue(bed.sunExposure),
                ),
                _InfoChip(
                  icon: Icons.air_outlined,
                  label: _formatValue(bed.windExposure),
                ),
                if (bed.lengthCm != null && bed.widthCm != null)
                  _InfoChip(
                    icon: Icons.straighten_outlined,
                    label: '${bed.lengthCm} × ${bed.widthCm} cm',
                  ),
                if (area != null)
                  _InfoChip(
                    icon: Icons.square_foot_outlined,
                    label: '${area.toStringAsFixed(2)} m²',
                  ),
              ],
            ),
            if (bed.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(bed.notes),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Crops in this bed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddCropPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Add crop'),
                ),
              ],
            ),
            if (plantings.isEmpty)
              const Text('No crops added yet.')
            else
              ...plantings.map(
                (planting) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.eco_outlined),
                  title: Text(planting.cropName),
                  subtitle: Text(_plantingSubtitle(planting)),
                  onTap: () => onEditPlantingPressed(planting),
                  trailing: IconButton(
                    tooltip: 'Remove crop',
                    onPressed: () => onDeletePlantingPressed(planting),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _plantingSubtitle(GardenBedPlanting planting) {
    final parts = <String>[
      _formatValue(planting.status),
      'Planted ${_formatDate(planting.plantedDate)}',
    ];

    if (planting.expectedHarvestStartDate != null &&
        planting.expectedHarvestEndDate != null) {
      parts.add(
        'Harvest ${_formatDate(planting.expectedHarvestStartDate!)} to ${_formatDate(planting.expectedHarvestEndDate!)}',
      );
    }

    return parts.join(' • ');
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _GardenBedsData {
  const _GardenBedsData({
    required this.beds,
    required this.plantings,
  });

  final List<GardenBed> beds;
  final List<GardenBedPlanting> plantings;
}
