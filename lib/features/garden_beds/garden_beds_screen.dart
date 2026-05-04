import 'package:flutter/material.dart';

import '../../data/garden_bed_repository.dart';
import '../../data/models/garden_bed.dart';
import 'add_garden_bed_screen.dart';

class GardenBedsScreen extends StatefulWidget {
  const GardenBedsScreen({super.key});

  @override
  State<GardenBedsScreen> createState() => _GardenBedsScreenState();
}

class _GardenBedsScreenState extends State<GardenBedsScreen> {
  final _repository = const GardenBedRepository();
  late Future<List<GardenBed>> _gardenBedsFuture;

  @override
  void initState() {
    super.initState();
    _gardenBedsFuture = _repository.loadGardenBeds();
  }

  void _reloadGardenBeds() {
    setState(() {
      _gardenBedsFuture = _repository.loadGardenBeds();
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

  Future<void> _deleteGardenBed(GardenBed bed) async {
    await _repository.deleteGardenBed(bed.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${bed.name}.')),
    );

    _reloadGardenBeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My garden beds'),
      ),
      body: FutureBuilder<List<GardenBed>>(
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

          final beds = snapshot.data ?? const <GardenBed>[];

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

              return _GardenBedCard(
                bed: bed,
                onDeletePressed: () => _deleteGardenBed(bed),
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
    required this.onDeletePressed,
  });

  final GardenBed bed;
  final VoidCallback onDeletePressed;

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
          ],
        ),
      ),
    );
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
