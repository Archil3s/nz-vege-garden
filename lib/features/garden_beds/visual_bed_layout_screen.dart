import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/plant_icons/generated_plant_icon.dart';
import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';
import '../../data/models/planting_rule.dart';

class VisualBedLayoutScreen extends StatefulWidget {
  const VisualBedLayoutScreen({
    required this.bed,
    required this.plantings,
    super.key,
  });

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;

  @override
  State<VisualBedLayoutScreen> createState() => _VisualBedLayoutScreenState();
}

class _VisualBedLayoutScreenState extends State<VisualBedLayoutScreen> {
  final _dataRepository = const GardenDataRepository();
  final _settingsRepository = const AppSettingsRepository();
  late Future<_LayoutData> _layoutFuture;
  int _peopleToFeed = 2;

  @override
  void initState() {
    super.initState();
    _layoutFuture = _loadLayoutData();
  }

  Future<_LayoutData> _loadLayoutData() async {
    final settings = await _settingsRepository.loadSettings();
    final crops = await _dataRepository.loadCrops();
    final rules = await _dataRepository.loadPlantingRules();

    return _LayoutData(
      regionId: settings.regionId,
      crops: crops,
      plantingRules: rules,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.bed.name} layout')),
      body: FutureBuilder<_LayoutData>(
        future: _layoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load layout data: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No layout data found.'));
          }

          final cropById = {for (final crop in data.crops) crop.id: crop};
          final activeZones = widget.plantings
              .where((planting) => planting.status != 'finished' && planting.status != 'failed')
              .map((planting) {
                final crop = cropById[planting.cropId];
                return _LayoutZone(
                  title: planting.cropName,
                  subtitle: _formatValue(planting.status),
                  cropName: planting.cropName,
                  spacingCm: crop?.spacingCm ?? 30,
                  plantCount: planting.plantCount,
                );
              })
              .toList(growable: false);

          final generatedPlan = _generatePlan(data: data, peopleToFeed: _peopleToFeed);
          final usingGenerated = activeZones.isEmpty;
          final displayZones = usingGenerated ? generatedPlan.zones : activeZones;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LayoutHeroCard(bed: widget.bed),
              const SizedBox(height: 16),
              _PeopleSelectorCard(
                peopleToFeed: _peopleToFeed,
                onChanged: (value) => setState(() => _peopleToFeed = value),
              ),
              const SizedBox(height: 16),
              _GeneratedPlanCard(
                plan: generatedPlan,
                showingSavedPlantings: !usingGenerated,
              ),
              const SizedBox(height: 16),
              _VisualBedCard(
                bed: widget.bed,
                zones: displayZones,
                title: usingGenerated ? 'Suggested garden design' : 'Current garden design',
                description: usingGenerated
                    ? 'Generated plants are shown as scaled SVG crop icons based on spacing and bed density.'
                    : 'Saved plant counts are shown as individual scaled SVG crop icons.',
              ),
              const SizedBox(height: 16),
              _SpacingGuideCard(zones: displayZones),
              const SizedBox(height: 16),
              const _DesignNoteCard(),
            ],
          );
        },
      ),
    );
  }

  _GeneratedBedPlan _generatePlan({
    required _LayoutData data,
    required int peopleToFeed,
  }) {
    final now = DateTime.now();
    final cropById = {for (final crop in data.crops) crop.id: crop};
    final seasonalRules = data.plantingRules
        .where((rule) => rule.appliesToMonth(now.month))
        .where((rule) => rule.appliesToRegion(data.regionId))
        .where((rule) => cropById.containsKey(rule.cropId))
        .toList(growable: false);

    final scored = seasonalRules.map((rule) {
      final crop = cropById[rule.cropId]!;
      return _ScoredSeasonalCrop(
        crop: crop,
        rule: rule,
        score: _scoreCrop(crop: crop, rule: rule),
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        return scoreComparison == 0
            ? a.crop.commonName.compareTo(b.crop.commonName)
            : scoreComparison;
      });

    final targetZones = peopleToFeed <= 2
        ? 3
        : peopleToFeed <= 4
            ? 4
            : 5;
    final selected = scored.take(targetZones).toList(growable: false);
    final zoneArea = _zoneAreaSquareMeters(selected.length);
    final zones = selected.map((item) {
      return _LayoutZone(
        title: item.crop.commonName,
        subtitle: _formatMethod(item.rule.method),
        cropName: item.crop.commonName,
        spacingCm: item.crop.spacingCm,
        plantCount: _estimatedPlantCount(item.crop, zoneArea, peopleToFeed),
      );
    }).toList(growable: false);

    return _GeneratedBedPlan(
      monthName: _monthName(now.month),
      zones: zones,
    );
  }

  double? _zoneAreaSquareMeters(int zoneCount) {
    final area = widget.bed.areaSquareMeters;
    if (area == null || area <= 0 || zoneCount <= 0) return null;
    return area / zoneCount;
  }

  int _estimatedPlantCount(Crop crop, double? zoneAreaSquareMeters, int peopleToFeed) {
    if (zoneAreaSquareMeters == null || crop.spacingCm <= 0) {
      return math.max(1, peopleToFeed);
    }
    final spacingMeters = crop.spacingCm / 100;
    final fitCount = (zoneAreaSquareMeters / (spacingMeters * spacingMeters)).floor();
    return fitCount.clamp(1, 60);
  }

  int _scoreCrop({required Crop crop, required PlantingRule rule}) {
    var score = 0;
    if (crop.beginnerFriendly) score += 3;
    if (crop.containerFriendly && widget.bed.type == 'container') score += 3;
    if (rule.method == 'direct_sow') score += 2;
    if (!crop.frostTender) score += 1;
    if (crop.daysToHarvestMax <= 60) score += 2;
    if (crop.category == 'herb') score += 1;
    return score;
  }

  String _formatMethod(String value) {
    return switch (value) {
      'direct_sow' => 'Sow direct',
      'transplant' => 'Transplant',
      _ => _formatValue(value),
    };
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _LayoutHeroCard extends StatelessWidget {
  const _LayoutHeroCard({required this.bed});

  final GardenBed bed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dimensions = bed.lengthCm == null || bed.widthCm == null
        ? 'No dimensions set'
        : '${bed.lengthCm} × ${bed.widthCm} cm';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.surface.withOpacity(0.82),
                    child: Icon(Icons.dashboard_customize_outlined, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Garden bed design assistant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Preview individual plants using scaled SVG crop icons.',
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 14),
              Chip(
                avatar: const Icon(Icons.straighten_outlined, size: 18),
                label: Text(dimensions),
                backgroundColor: scheme.surface.withOpacity(0.72),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleSelectorCard extends StatelessWidget {
  const _PeopleSelectorCard({required this.peopleToFeed, required this.onChanged});

  final int peopleToFeed;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Design target', style: Theme.of(context).textTheme.titleLarge),
                ),
                Badge(label: Text('$peopleToFeed'), child: const Icon(Icons.person_outline)),
              ],
            ),
            Slider(
              value: peopleToFeed.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              label: peopleToFeed.toString(),
              onChanged: (value) => onChanged(value.round()),
            ),
            Text(
              'Generated plans estimate plant counts from bed area and crop spacing.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPlanCard extends StatelessWidget {
  const _GeneratedPlanCard({required this.plan, required this.showingSavedPlantings});

  final _GeneratedBedPlan plan;
  final bool showingSavedPlantings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.monthName} seasonal design idea',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (plan.zones.isEmpty)
              const Text('No seasonal crop suggestions found for this month and region yet.')
            else
              ...plan.zones.map((zone) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: GeneratedPlantIcon(cropName: zone.cropName, size: 28),
                    ),
                    title: Text('${zone.title} × ${zone.plantCount}'),
                    subtitle: Text('${zone.subtitle} • ${zone.spacingCm} cm spacing'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VisualBedCard extends StatelessWidget {
  const _VisualBedCard({
    required this.bed,
    required this.zones,
    required this.title,
    required this.description,
  });

  final GardenBed bed;
  final List<_LayoutZone> zones;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _aspectRatioForBed(bed);
    final scheme = Theme.of(context).colorScheme;
    final markers = _buildMarkers(zones);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BedBackgroundPainter(colorScheme: scheme),
                          ),
                        ),
                        ...markers.map(
                          (marker) => Positioned(
                            left: marker.xFraction * constraints.maxWidth - marker.iconSize / 2,
                            top: marker.yFraction * constraints.maxHeight - marker.iconSize / 2,
                            width: marker.iconSize,
                            height: marker.iconSize,
                            child: Tooltip(
                              message: marker.title,
                              child: GeneratedPlantIcon(
                                cropName: marker.cropName,
                                size: marker.iconSize,
                              ),
                            ),
                          ),
                        ),
                        if (markers.isEmpty) const Center(child: Text('No crops yet')),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (zones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: zones
                    .map((zone) => Chip(
                          avatar: GeneratedPlantIcon(cropName: zone.cropName, size: 20),
                          label: Text('${zone.title} × ${zone.plantCount}'),
                        ))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_PlantMarkerData> _buildMarkers(List<_LayoutZone> zones) {
    if (zones.isEmpty) return const [];

    final markers = <_PlantMarkerData>[];
    final columns = zones.length == 1 ? 1 : math.min(2, zones.length);
    final rows = (zones.length / columns).ceil();
    final totalPlants = zones.fold<int>(0, (sum, zone) => sum + zone.plantCount.clamp(1, 120));
    final densityScale = totalPlants > 90
        ? 0.58
        : totalPlants > 60
            ? 0.68
            : totalPlants > 35
                ? 0.78
                : totalPlants > 18
                    ? 0.88
                    : 1.0;

    for (var zoneIndex = 0; zoneIndex < zones.length; zoneIndex++) {
      final zone = zones[zoneIndex];
      final column = zoneIndex % columns;
      final row = zoneIndex ~/ columns;
      final zoneLeft = column / columns;
      final zoneTop = row / rows;
      final zoneWidth = 1 / columns;
      final zoneHeight = 1 / rows;
      final count = zone.plantCount.clamp(1, 120);
      final gridColumns = math.max(1, math.sqrt(count * zoneWidth / zoneHeight).ceil());
      final gridRows = (count / gridColumns).ceil();
      final spacingSize = (zone.spacingCm / 45 * 22).clamp(10.0, 26.0).toDouble();
      final iconSize = (spacingSize * densityScale).clamp(8.0, 24.0).toDouble();

      for (var i = 0; i < count; i++) {
        final markerColumn = i % gridColumns;
        final markerRow = i ~/ gridColumns;
        markers.add(_PlantMarkerData(
          cropName: zone.cropName,
          title: zone.title,
          xFraction: (zoneLeft + ((markerColumn + 1) / (gridColumns + 1)) * zoneWidth).clamp(0.05, 0.95),
          yFraction: (zoneTop + ((markerRow + 1) / (gridRows + 1)) * zoneHeight).clamp(0.07, 0.93),
          iconSize: iconSize,
        ));
      }
    }

    return markers;
  }

  double _aspectRatioForBed(GardenBed bed) {
    final length = bed.lengthCm;
    final width = bed.widthCm;
    if (length == null || width == null || length <= 0 || width <= 0) return 1.6;
    return (length / width).clamp(0.75, 2.4).toDouble();
  }
}

class _BedBackgroundPainter extends CustomPainter {
  const _BedBackgroundPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final roundedBed = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final soilPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.secondaryContainer.withOpacity(0.55),
          colorScheme.surface,
        ],
      ).createShader(rect);

    canvas.drawRRect(roundedBed, soilPaint);

    final linePaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.22)
      ..strokeWidth = 1;
    for (var y = 22.0; y < size.height; y += 22.0) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), linePaint);
    }

    canvas.drawRRect(
      roundedBed.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colorScheme.outline,
    );
  }

  @override
  bool shouldRepaint(covariant _BedBackgroundPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}

class _SpacingGuideCard extends StatelessWidget {
  const _SpacingGuideCard({required this.zones});

  final List<_LayoutZone> zones;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spacing guide', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (zones.isEmpty)
              const Text('Add crops or use a generated plan to see spacing guidance.')
            else
              ...zones.map((zone) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: GeneratedPlantIcon(cropName: zone.cropName, size: 28),
                    ),
                    title: Text('${zone.title} × ${zone.plantCount}'),
                    subtitle: Text('${zone.subtitle} • ${zone.spacingCm} cm between plants'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _DesignNoteCard extends StatelessWidget {
  const _DesignNoteCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'The visual map uses individual SVG crop icons. Tightly spaced or high-density plantings are drawn smaller so the bed is not visually overrepresented.',
        ),
      ),
    );
  }
}

class _LayoutData {
  const _LayoutData({required this.regionId, required this.crops, required this.plantingRules});

  final String regionId;
  final List<Crop> crops;
  final List<PlantingRule> plantingRules;
}

class _GeneratedBedPlan {
  const _GeneratedBedPlan({required this.monthName, required this.zones});

  final String monthName;
  final List<_LayoutZone> zones;
}

class _ScoredSeasonalCrop {
  const _ScoredSeasonalCrop({required this.crop, required this.rule, required this.score});

  final Crop crop;
  final PlantingRule rule;
  final int score;
}

class _LayoutZone {
  const _LayoutZone({
    required this.title,
    required this.subtitle,
    required this.cropName,
    required this.spacingCm,
    required this.plantCount,
  });

  final String title;
  final String subtitle;
  final String cropName;
  final int spacingCm;
  final int plantCount;
}

class _PlantMarkerData {
  const _PlantMarkerData({
    required this.cropName,
    required this.title,
    required this.xFraction,
    required this.yFraction,
    required this.iconSize,
  });

  final String cropName;
  final String title;
  final double xFraction;
  final double yFraction;
  final double iconSize;
}

String _monthName(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
