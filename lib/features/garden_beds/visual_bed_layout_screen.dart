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
                  source: _LayoutZoneSource.saved,
                  icon: _iconForStatus(planting.status),
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
                    ? 'This generated layout draws the estimated number of individual plants that fit by spacing.'
                    : 'This map draws the saved plant count for each active crop in this bed.',
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
        if (scoreComparison != 0) return scoreComparison;
        return a.crop.commonName.compareTo(b.crop.commonName);
      });

    final targetZones = peopleToFeed <= 2
        ? 3
        : peopleToFeed <= 4
            ? 4
            : 5;
    final selected = scored.take(targetZones).toList(growable: false);
    final zoneArea = _zoneAreaSquareMeters(selected.length);

    final zones = selected.map((item) {
      final plantCount = _estimatedPlantCount(
        crop: item.crop,
        zoneAreaSquareMeters: zoneArea,
        peopleToFeed: peopleToFeed,
      );

      return _LayoutZone(
        title: item.crop.commonName,
        subtitle: _formatMethod(item.rule.method),
        cropName: item.crop.commonName,
        spacingCm: item.crop.spacingCm,
        plantCount: plantCount,
        source: _LayoutZoneSource.generated,
        icon: item.rule.method == 'transplant' ? Icons.move_down_outlined : Icons.grass_outlined,
      );
    }).toList(growable: false);

    return _GeneratedBedPlan(
      monthName: _monthName(now.month),
      zones: zones,
      suggestions: selected,
    );
  }

  double? _zoneAreaSquareMeters(int zoneCount) {
    final area = widget.bed.areaSquareMeters;
    if (area == null || area <= 0 || zoneCount <= 0) return null;
    return area / zoneCount;
  }

  int _estimatedPlantCount({
    required Crop crop,
    required double? zoneAreaSquareMeters,
    required int peopleToFeed,
  }) {
    if (zoneAreaSquareMeters == null || crop.spacingCm <= 0) {
      return math.max(1, peopleToFeed);
    }

    final spacingMeters = crop.spacingCm / 100;
    final plantArea = spacingMeters * spacingMeters;
    final fitCount = (zoneAreaSquareMeters / plantArea).floor();
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

  IconData _iconForStatus(String status) {
    return switch (status) {
      'planned' => Icons.event_note_outlined,
      'sown' => Icons.grass_outlined,
      'transplanted' => Icons.move_down_outlined,
      'growing' => Icons.eco_outlined,
      'harvesting' => Icons.shopping_basket_outlined,
      _ => Icons.eco_outlined,
    };
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
                'Preview a literal plant-count layout using SVG crop icons and spacing data.',
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(icon: Icons.straighten_outlined, label: dimensions),
                  _HeroChip(icon: Icons.wb_sunny_outlined, label: _formatValue(bed.sunExposure)),
                  _HeroChip(icon: Icons.air_outlined, label: _formatValue(bed.windExposure)),
                ],
              ),
            ],
          ),
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: scheme.surface.withOpacity(0.72),
      side: BorderSide.none,
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
            const SizedBox(height: 8),
            Text('Plan this bed for $peopleToFeed ${peopleToFeed == 1 ? 'person' : 'people'}.'),
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
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${plan.monthName} seasonal design idea',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan.zones.isEmpty)
              const Text('No seasonal crop suggestions found for this month and region yet.')
            else ...[
              Text(
                showingSavedPlantings
                    ? 'Your map shows saved crops. These are extra ideas for another bed.'
                    : 'Your bed has no active crops, so the map below uses this generated design.',
              ),
              const SizedBox(height: 12),
              ...plan.zones.map((zone) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: GeneratedPlantIcon(cropName: zone.cropName, size: 28),
                    ),
                    title: Text('${zone.title} × ${zone.plantCount}'),
                    subtitle: Text('${zone.subtitle} • ${zone.spacingCm} cm spacing'),
                  )),
            ],
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
            Row(
              children: [
                Icon(Icons.map_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.surfaceContainerHighest, scheme.surface],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _BedBackgroundPainter(colorScheme: scheme))),
                        ...markers.map((marker) => Positioned(
                              left: marker.xFraction * 1000,
                              top: marker.yFraction * 1000,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, -0.5),
                                child: _PlantMarker(marker: marker),
                              ),
                            )),
                        if (markers.isEmpty)
                          const Center(child: Text('No crops yet')),
                      ],
                    ),
                  ),
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

      for (var i = 0; i < count; i++) {
        final markerColumn = i % gridColumns;
        final markerRow = i ~/ gridColumns;
        final x = zoneLeft + ((markerColumn + 1) / (gridColumns + 1)) * zoneWidth;
        final y = zoneTop + ((markerRow + 1) / (gridRows + 1)) * zoneHeight;
        markers.add(_PlantMarkerData(
          cropName: zone.cropName,
          title: zone.title,
          xFraction: x.clamp(0.06, 0.94),
          yFraction: y.clamp(0.08, 0.92),
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

class _PlantMarker extends StatelessWidget {
  const _PlantMarker({required this.marker});

  final _PlantMarkerData marker;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: marker.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: GeneratedPlantIcon(cropName: marker.cropName, size: 24),
        ),
      ),
    );
  }
}

class _BedBackgroundPainter extends CustomPainter {
  const _BedBackgroundPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bedRect = Offset.zero & size;
    final roundedBed = RRect.fromRectAndRadius(bedRect, const Radius.circular(18));
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.secondaryContainer.withOpacity(0.55),
          colorScheme.surface,
        ],
      ).createShader(bedRect);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.outline;

    canvas.drawRRect(roundedBed, soilPaint);

    final linePaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.22)
      ..strokeWidth = 1;
    for (var y = 22.0; y < size.height; y += 22.0) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y + math.sin(y) * 1.6), linePaint);
    }

    canvas.drawRRect(roundedBed.deflate(1), borderPaint);
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
          'The visual map now represents individual plants, not only crop zones. A later version can add exact drag placement and save coordinates, but this version already respects saved plant counts and generated spacing estimates.',
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
  const _GeneratedBedPlan({required this.monthName, required this.zones, required this.suggestions});

  final String monthName;
  final List<_LayoutZone> zones;
  final List<_ScoredSeasonalCrop> suggestions;
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
    required this.source,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String cropName;
  final int spacingCm;
  final int plantCount;
  final _LayoutZoneSource source;
  final IconData icon;
}

class _PlantMarkerData {
  const _PlantMarkerData({
    required this.cropName,
    required this.title,
    required this.xFraction,
    required this.yFraction,
  });

  final String cropName;
  final String title;
  final double xFraction;
  final double yFraction;
}

enum _LayoutZoneSource { saved, generated }

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
