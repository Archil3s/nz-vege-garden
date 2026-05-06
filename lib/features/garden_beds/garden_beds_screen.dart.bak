import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/plant_icons/generated_plant_icon.dart';
import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_bed_repository.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';
import 'add_bed_planting_screen.dart';
import 'add_garden_bed_screen.dart';
import 'edit_bed_planting_screen.dart';
import 'edit_garden_bed_screen.dart';
import 'generate_garden_bed_screen.dart';
import 'visual_bed_layout_screen.dart';

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

  Future<void> _openGenerateGardenBedScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const GenerateGardenBedScreen(),
      ),
    );

    _reloadGardenBeds();
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

  Future<void> _openVisualLayoutScreen({
    required GardenBed bed,
    required List<GardenBedPlanting> plantings,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VisualBedLayoutScreen(
          bed: bed,
          plantings: plantings,
        ),
      ),
    );

    _reloadGardenBeds();
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

  Future<void> _updatePlantingStatus({
    required GardenBedPlanting planting,
    required String status,
  }) async {
    final updatedPlanting = planting.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    await _plantingRepository.updatePlanting(updatedPlanting);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${planting.cropName} marked as ${_formatValue(status)}.'),
      ),
    );

    _reloadGardenBeds();
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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
              onGeneratePressed: _openGenerateGardenBedScreen,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemCount: beds.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GenerateBedPromptCard(onGeneratePressed: _openGenerateGardenBedScreen);
              }

              final bed = beds[index - 1];
              final bedPlantings = plantings
                  .where((planting) => planting.bedId == bed.id)
                  .toList(growable: false);

              return _GardenBedCard(
                bed: bed,
                plantings: bedPlantings,
                onAddCropPressed: () => _openAddPlantingScreen(bed),
                onEditPressed: () => _openEditGardenBedScreen(bed),
                onLayoutPressed: () => _openVisualLayoutScreen(
                  bed: bed,
                  plantings: bedPlantings,
                ),
                onDeletePressed: () => _deleteGardenBed(bed),
                onDeletePlantingPressed: _deletePlanting,
                onEditPlantingPressed: (planting) => _openEditPlantingScreen(
                  bed: bed,
                  planting: planting,
                ),
                onStatusChanged: (planting, status) => _updatePlantingStatus(
                  planting: planting,
                  status: status,
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
  const _EmptyGardenBedsState({
    required this.onAddPressed,
    required this.onGeneratePressed,
  });

  final VoidCallback onAddPressed;
  final VoidCallback onGeneratePressed;

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
              'Create a bed manually or generate a seasonal bed design from your local planting data.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGeneratePressed,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generate starter bed'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add bed manually'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateBedPromptCard extends StatelessWidget {
  const _GenerateBedPromptCard({required this.onGeneratePressed});

  final VoidCallback onGeneratePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate a seasonal bed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick a goal, size, and style. The app creates crops, counts, and opens the visual design canvas.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onGeneratePressed,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Generate bed'),
                  ),
                ],
              ),
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
    required this.onLayoutPressed,
    required this.onDeletePressed,
    required this.onDeletePlantingPressed,
    required this.onEditPlantingPressed,
    required this.onStatusChanged,
  });

  static const _statusOptions = [
    'planned',
    'sown',
    'transplanted',
    'growing',
    'harvesting',
    'finished',
    'failed',
  ];

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;
  final VoidCallback onAddCropPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onLayoutPressed;
  final VoidCallback onDeletePressed;
  final ValueChanged<GardenBedPlanting> onDeletePlantingPressed;
  final ValueChanged<GardenBedPlanting> onEditPlantingPressed;
  final void Function(GardenBedPlanting planting, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final area = bed.areaSquareMeters;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onLayoutPressed,
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
                  _InfoChip(
                    icon: Icons.palette_outlined,
                    label: _formatValue(bed.layoutStyle),
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
              _EmbeddedBedPlannerPreview(
                bed: bed,
                plantings: plantings,
                onTap: onLayoutPressed,
              ),
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
                    onPressed: onLayoutPressed,
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Open planner'),
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
                    leading: Icon(_statusIcon(planting.status)),
                    title: Text(planting.cropName),
                    subtitle: Text(_plantingSubtitle(planting)),
                    onTap: () => onEditPlantingPressed(planting),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Planting actions',
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEditPlantingPressed(planting);
                          return;
                        }

                        if (value == 'remove') {
                          onDeletePlantingPressed(planting);
                          return;
                        }

                        onStatusChanged(planting, value);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit details'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        ..._statusOptions.map(
                          (status) => PopupMenuItem(
                            value: status,
                            enabled: status != planting.status,
                            child: ListTile(
                              leading: Icon(_statusIcon(status)),
                              title: Text(_formatValue(status)),
                              trailing: status == planting.status
                                  ? const Icon(Icons.check)
                                  : null,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'remove',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Remove crop'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _plantingSubtitle(GardenBedPlanting planting) {
    final parts = <String>[
      _formatValue(planting.status),
      '${planting.plantCount} plants',
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

  IconData _statusIcon(String status) {
    return switch (status) {
      'planned' => Icons.event_note_outlined,
      'sown' => Icons.grass_outlined,
      'transplanted' => Icons.move_down_outlined,
      'growing' => Icons.eco_outlined,
      'harvesting' => Icons.shopping_basket_outlined,
      'finished' => Icons.check_circle_outline,
      'failed' => Icons.cancel_outlined,
      _ => Icons.eco_outlined,
    };
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

class _EmbeddedBedPlannerPreview extends StatelessWidget {
  const _EmbeddedBedPlannerPreview({
    required this.bed,
    required this.plantings,
    required this.onTap,
  });

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activePlantings = plantings
        .where((planting) => planting.status != 'finished' && planting.status != 'failed')
        .toList(growable: false);
    final markers = _buildMarkers(activePlantings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bed planner preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_full_outlined),
              label: const Text('Design'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: _aspectRatioForBed(bed),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MiniBedPainter(
                        colorScheme: scheme,
                        style: bed.layoutStyle,
                      ),
                    ),
                  ),
                  ...markers.map(
                    (marker) => Positioned(
                      left: marker.xFraction * 1000,
                      top: marker.yFraction * 1000,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            ...markers.map(
                              (marker) => Positioned(
                                left: marker.xFraction * constraints.maxWidth - marker.size / 2,
                                top: marker.yFraction * constraints.maxHeight - marker.size / 2,
                                width: marker.size,
                                height: marker.size,
                                child: GeneratedPlantIcon(
                                  cropName: marker.cropName,
                                  size: marker.size,
                                ),
                              ),
                            ),
                            if (markers.isEmpty)
                              Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: scheme.surface.withOpacity(0.76),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Text('Tap to design this bed'),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.spa_outlined,
              label: '${activePlantings.fold<int>(0, (sum, planting) => sum + planting.plantCount)} plants',
            ),
            _InfoChip(
              icon: Icons.layers_outlined,
              label: '${activePlantings.length} crops',
            ),
            _InfoChip(
              icon: Icons.touch_app_outlined,
              label: 'Tap to edit layout',
            ),
          ],
        ),
      ],
    );
  }

  List<_MiniPlantMarker> _buildMarkers(List<GardenBedPlanting> plantings) {
    if (plantings.isEmpty) {
      return const [];
    }

    final markers = <_MiniPlantMarker>[];
    final style = bed.layoutStyle;
    final totalPlants = plantings.fold<int>(
      0,
      (sum, planting) => sum + planting.plantCount.clamp(1, 80),
    );
    final size = totalPlants > 60
        ? 16.0
        : totalPlants > 35
            ? 18.0
            : 22.0;

    for (var cropIndex = 0; cropIndex < plantings.length; cropIndex++) {
      final planting = plantings[cropIndex];
      final count = planting.plantCount.clamp(1, 80);

      if (style == 'companion') {
        markers.addAll(_clusterMarkers(planting, cropIndex, plantings.length, count, size));
      } else if (style == 'showcase') {
        markers.addAll(_showcaseMarkers(planting, cropIndex, plantings.length, count, size));
      } else {
        markers.addAll(_rowMarkers(planting, cropIndex, plantings.length, count, size));
      }
    }

    return markers.take(120).toList(growable: false);
  }

  List<_MiniPlantMarker> _rowMarkers(
    GardenBedPlanting planting,
    int cropIndex,
    int cropCount,
    int count,
    double size,
  ) {
    final markers = <_MiniPlantMarker>[];
    final columns = cropCount == 1 ? 1 : math.min(2, cropCount);
    final rows = (cropCount / columns).ceil();
    final zoneColumn = cropIndex % columns;
    final zoneRow = cropIndex ~/ columns;
    final zoneLeft = zoneColumn / columns;
    final zoneTop = zoneRow / rows;
    final zoneWidth = 1 / columns;
    final zoneHeight = 1 / rows;
    final gridColumns = math.max(1, math.sqrt(count * zoneWidth / zoneHeight).ceil());
    final gridRows = (count / gridColumns).ceil();

    for (var i = 0; i < count; i++) {
      final markerColumn = i % gridColumns;
      final markerRow = i ~/ gridColumns;
      markers.add(_MiniPlantMarker(
        cropName: planting.cropName,
        xFraction: (zoneLeft + ((markerColumn + 1) / (gridColumns + 1)) * zoneWidth).clamp(0.06, 0.94),
        yFraction: (zoneTop + ((markerRow + 1) / (gridRows + 1)) * zoneHeight).clamp(0.08, 0.92),
        size: size,
      ));
    }

    return markers;
  }

  List<_MiniPlantMarker> _clusterMarkers(
    GardenBedPlanting planting,
    int cropIndex,
    int cropCount,
    int count,
    double size,
  ) {
    final center = _clusterCenter(cropIndex, cropCount);
    final markers = <_MiniPlantMarker>[];

    for (var i = 0; i < count; i++) {
      final ring = 1 + (i / 8).floor();
      final angle = (i * 2.399963229728653) + cropIndex;
      final scale = math.min(1.0, 0.22 + ring * 0.13);
      markers.add(_MiniPlantMarker(
        cropName: planting.cropName,
        xFraction: (center.dx + math.cos(angle) * 0.16 * scale).clamp(0.07, 0.93),
        yFraction: (center.dy + math.sin(angle) * 0.18 * scale).clamp(0.09, 0.91),
        size: size,
      ));
    }

    return markers;
  }

  List<_MiniPlantMarker> _showcaseMarkers(
    GardenBedPlanting planting,
    int cropIndex,
    int cropCount,
    int count,
    double size,
  ) {
    final center = _clusterCenter(cropIndex, cropCount);
    final columns = math.max(1, math.sqrt(count).ceil());
    final rows = (count / columns).ceil();
    final markers = <_MiniPlantMarker>[];

    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      final column = i % columns;
      final curve = math.sin((column / math.max(1, columns - 1)) * math.pi) * 0.035;
      markers.add(_MiniPlantMarker(
        cropName: planting.cropName,
        xFraction: (center.dx + (column - (columns - 1) / 2) * 0.045).clamp(0.07, 0.93),
        yFraction: (center.dy + (row - (rows - 1) / 2) * 0.045 + curve).clamp(0.09, 0.91),
        size: size,
      ));
    }

    return markers;
  }

  Offset _clusterCenter(int index, int count) {
    if (count == 1) return const Offset(0.50, 0.52);

    final positions = [
      const Offset(0.25, 0.27),
      const Offset(0.75, 0.73),
      const Offset(0.74, 0.28),
      const Offset(0.26, 0.72),
      const Offset(0.50, 0.52),
    ];

    return positions[index % positions.length];
  }

  double _aspectRatioForBed(GardenBed bed) {
    final length = bed.lengthCm;
    final width = bed.widthCm;
    if (length == null || width == null || length <= 0 || width <= 0) return 1.6;
    return (length / width).clamp(0.85, 2.2).toDouble();
  }
}

class _MiniBedPainter extends CustomPainter {
  const _MiniBedPainter({required this.colorScheme, required this.style});

  final ColorScheme colorScheme;
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bed = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final soil = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.secondaryContainer.withOpacity(0.58),
          colorScheme.surface,
        ],
      ).createShader(rect);

    canvas.drawRRect(bed, soil);

    final texture = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.18)
      ..strokeWidth = 1;
    for (var y = 18.0; y < size.height; y += 18.0) {
      canvas.drawLine(
        Offset(12, y + math.sin(y * 0.16) * 1.4),
        Offset(size.width - 12, y + math.cos(y * 0.13) * 1.4),
        texture,
      );
    }

    if (style == 'companion') {
      final path = Path()
        ..moveTo(size.width * 0.50, 10)
        ..cubicTo(
          size.width * 0.38,
          size.height * 0.28,
          size.width * 0.62,
          size.height * 0.62,
          size.width * 0.50,
          size.height - 10,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = colorScheme.surface.withOpacity(0.34),
      );
    } else if (style == 'showcase') {
      final rings = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = colorScheme.tertiary.withOpacity(0.24);
      final center = Offset(size.width / 2, size.height / 2);
      for (var radius = 22.0; radius < math.min(size.width, size.height) / 2; radius += 28) {
        canvas.drawCircle(center, radius, rings);
      }
    } else {
      final guides = Paint()
        ..color = colorScheme.primary.withOpacity(0.12)
        ..strokeWidth = 1;
      for (var x = size.width / 4; x < size.width; x += size.width / 4) {
        canvas.drawLine(Offset(x, 14), Offset(x, size.height - 14), guides);
      }
    }

    canvas.drawRRect(
      bed.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colorScheme.outline.withOpacity(0.54),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniBedPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme || oldDelegate.style != style;
  }
}

class _MiniPlantMarker {
  const _MiniPlantMarker({
    required this.cropName,
    required this.xFraction,
    required this.yFraction,
    required this.size,
  });

  final String cropName;
  final double xFraction;
  final double yFraction;
  final double size;
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
