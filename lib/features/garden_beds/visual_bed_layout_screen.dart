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
  _BedDesignStyle _designStyle = _BedDesignStyle.ordered;

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              _LayoutHeroCard(bed: widget.bed),
              const SizedBox(height: 16),
              _PeopleSelectorCard(
                peopleToFeed: _peopleToFeed,
                onChanged: (value) => setState(() => _peopleToFeed = value),
              ),
              const SizedBox(height: 16),
              _DesignStyleCard(
                selectedStyle: _designStyle,
                onChanged: (value) => setState(() => _designStyle = value),
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
                designStyle: _designStyle,
                title: usingGenerated ? 'Suggested garden design' : 'Current garden design',
                description: usingGenerated
                    ? 'Generated plants are shown as individual SVG crop icons with a layout style you can change.'
                    : 'Saved plant counts are shown as individual SVG crop icons, styled into an engaging bed design.',
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
                      'Garden bed design canvas',
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
                'Preview individual plants with SVG crop icons, bed texture, paths, and selectable layout styles.',
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.straighten_outlined, size: 18),
                    label: Text(dimensions),
                    backgroundColor: scheme.surface.withOpacity(0.72),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('Designable'),
                    backgroundColor: scheme.surface.withOpacity(0.72),
                    side: BorderSide.none,
                  ),
                ],
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

class _DesignStyleCard extends StatelessWidget {
  const _DesignStyleCard({required this.selectedStyle, required this.onChanged});

  final _BedDesignStyle selectedStyle;
  final ValueChanged<_BedDesignStyle> onChanged;

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
                Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Layout style', style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<_BedDesignStyle>(
              selected: {selectedStyle},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onChanged(selection.first),
              segments: const [
                ButtonSegment(
                  value: _BedDesignStyle.ordered,
                  icon: Icon(Icons.grid_view_outlined),
                  label: Text('Rows'),
                ),
                ButtonSegment(
                  value: _BedDesignStyle.companion,
                  icon: Icon(Icons.hub_outlined),
                  label: Text('Mixed'),
                ),
                ButtonSegment(
                  value: _BedDesignStyle.showcase,
                  icon: Icon(Icons.auto_awesome_outlined),
                  label: Text('Show'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _descriptionForStyle(selectedStyle),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _descriptionForStyle(_BedDesignStyle style) {
    return switch (style) {
      _BedDesignStyle.ordered => 'Clean rows for practical planting and spacing checks.',
      _BedDesignStyle.companion => 'Mixed clusters with a central path feel for a more natural bed.',
      _BedDesignStyle.showcase => 'A more decorative display view for making the bed feel alive.',
    };
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
    required this.designStyle,
    required this.title,
    required this.description,
  });

  final GardenBed bed;
  final List<_LayoutZone> zones;
  final _BedDesignStyle designStyle;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _aspectRatioForBed(bed);
    final scheme = Theme.of(context).colorScheme;
    final markers = _buildMarkers(zones, designStyle);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                _StyleBadge(style: designStyle),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RepaintBoundary(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BedBackgroundPainter(
                                  colorScheme: scheme,
                                  style: designStyle,
                                ),
                              ),
                            ),
                            ..._buildZoneBadges(zones, designStyle),
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
                        ),
                      );
                    },
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

  List<Widget> _buildZoneBadges(List<_LayoutZone> zones, _BedDesignStyle style) {
    if (zones.isEmpty || style == _BedDesignStyle.ordered) {
      return const [];
    }

    return zones.take(4).toList(growable: false).asMap().entries.map((entry) {
      final index = entry.key;
      final zone = entry.value;
      final alignment = switch (index) {
        0 => Alignment.topLeft,
        1 => Alignment.topRight,
        2 => Alignment.bottomLeft,
        _ => Alignment.bottomRight,
      };

      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                zone.title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }

  List<_PlantMarkerData> _buildMarkers(List<_LayoutZone> zones, _BedDesignStyle style) {
    if (zones.isEmpty) return const [];

    final markers = <_PlantMarkerData>[];
    final totalPlants = zones.fold<int>(0, (sum, zone) => sum + zone.plantCount.clamp(1, 120));
    final densityScale = totalPlants > 90
        ? 0.76
        : totalPlants > 60
            ? 0.82
            : totalPlants > 35
                ? 0.90
                : 1.0;

    for (var zoneIndex = 0; zoneIndex < zones.length; zoneIndex++) {
      final zone = zones[zoneIndex];
      final count = zone.plantCount.clamp(1, 120);
      final spacingBasedSize = (zone.spacingCm / 45 * 28).clamp(20.0, 34.0).toDouble();
      final iconSize = (spacingBasedSize * densityScale).clamp(18.0, 34.0).toDouble();

      markers.addAll(
        switch (style) {
          _BedDesignStyle.ordered => _orderedMarkers(zone, zoneIndex, zones.length, count, iconSize),
          _BedDesignStyle.companion => _companionMarkers(zone, zoneIndex, zones.length, count, iconSize),
          _BedDesignStyle.showcase => _showcaseMarkers(zone, zoneIndex, zones.length, count, iconSize),
        },
      );
    }

    return markers;
  }

  List<_PlantMarkerData> _orderedMarkers(
    _LayoutZone zone,
    int zoneIndex,
    int zoneCount,
    int count,
    double iconSize,
  ) {
    final markers = <_PlantMarkerData>[];
    final columns = zoneCount == 1 ? 1 : math.min(2, zoneCount);
    final rows = (zoneCount / columns).ceil();
    final column = zoneIndex % columns;
    final row = zoneIndex ~/ columns;
    final zoneLeft = column / columns;
    final zoneTop = row / rows;
    final zoneWidth = 1 / columns;
    final zoneHeight = 1 / rows;
    final gridColumns = math.max(1, math.sqrt(count * zoneWidth / zoneHeight).ceil());
    final gridRows = (count / gridColumns).ceil();

    for (var i = 0; i < count; i++) {
      final markerColumn = i % gridColumns;
      final markerRow = i ~/ gridColumns;
      markers.add(_PlantMarkerData(
        cropName: zone.cropName,
        title: zone.title,
        xFraction: (zoneLeft + ((markerColumn + 1) / (gridColumns + 1)) * zoneWidth).clamp(0.06, 0.94),
        yFraction: (zoneTop + ((markerRow + 1) / (gridRows + 1)) * zoneHeight).clamp(0.08, 0.92),
        iconSize: iconSize,
      ));
    }

    return markers;
  }

  List<_PlantMarkerData> _companionMarkers(
    _LayoutZone zone,
    int zoneIndex,
    int zoneCount,
    int count,
    double iconSize,
  ) {
    final markers = <_PlantMarkerData>[];
    final center = _clusterCenter(zoneIndex, zoneCount, inset: 0.18);
    final radiusX = zoneCount <= 2 ? 0.18 : 0.14;
    final radiusY = zoneCount <= 2 ? 0.22 : 0.16;

    for (var i = 0; i < count; i++) {
      final ring = 1 + (i / 8).floor();
      final angle = (i * 2.399963229728653) + zoneIndex;
      final scale = math.min(1.0, 0.22 + ring * 0.13);
      markers.add(_PlantMarkerData(
        cropName: zone.cropName,
        title: zone.title,
        xFraction: (center.dx + math.cos(angle) * radiusX * scale).clamp(0.07, 0.93),
        yFraction: (center.dy + math.sin(angle) * radiusY * scale).clamp(0.09, 0.91),
        iconSize: iconSize,
      ));
    }

    return markers;
  }

  List<_PlantMarkerData> _showcaseMarkers(
    _LayoutZone zone,
    int zoneIndex,
    int zoneCount,
    int count,
    double iconSize,
  ) {
    final markers = <_PlantMarkerData>[];
    final center = _clusterCenter(zoneIndex, zoneCount, inset: 0.13);
    final rows = math.max(1, math.sqrt(count).ceil());

    for (var i = 0; i < count; i++) {
      final row = i ~/ rows;
      final column = i % rows;
      final curve = math.sin((column / math.max(1, rows - 1)) * math.pi) * 0.035;
      final xOffset = (column - (rows - 1) / 2) * 0.045;
      final yOffset = (row - (count / rows).ceil() / 2) * 0.045 + curve;
      markers.add(_PlantMarkerData(
        cropName: zone.cropName,
        title: zone.title,
        xFraction: (center.dx + xOffset).clamp(0.07, 0.93),
        yFraction: (center.dy + yOffset).clamp(0.09, 0.91),
        iconSize: (iconSize * 1.04).clamp(18.0, 36.0).toDouble(),
      ));
    }

    return markers;
  }

  Offset _clusterCenter(int index, int count, {required double inset}) {
    if (count == 1) return const Offset(0.50, 0.52);

    final positions = [
      Offset(inset + 0.10, inset + 0.14),
      Offset(1 - inset - 0.10, 1 - inset - 0.12),
      Offset(1 - inset - 0.08, inset + 0.15),
      Offset(inset + 0.08, 1 - inset - 0.12),
      const Offset(0.50, 0.52),
    ];

    return positions[index % positions.length];
  }

  double _aspectRatioForBed(GardenBed bed) {
    final length = bed.lengthCm;
    final width = bed.widthCm;
    if (length == null || width == null || length <= 0 || width <= 0) return 1.6;
    return (length / width).clamp(0.75, 2.4).toDouble();
  }
}

class _StyleBadge extends StatelessWidget {
  const _StyleBadge({required this.style});

  final _BedDesignStyle style;

  @override
  Widget build(BuildContext context) {
    final label = switch (style) {
      _BedDesignStyle.ordered => 'Rows',
      _BedDesignStyle.companion => 'Mixed',
      _BedDesignStyle.showcase => 'Show',
    };

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
    );
  }
}

class _BedBackgroundPainter extends CustomPainter {
  const _BedBackgroundPainter({required this.colorScheme, required this.style});

  final ColorScheme colorScheme;
  final _BedDesignStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final roundedBed = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.secondaryContainer.withOpacity(0.58),
          colorScheme.surface,
        ],
      ).createShader(rect);

    canvas.drawRRect(roundedBed, soilPaint);
    _paintSoilTexture(canvas, size);
    _paintStyleOverlay(canvas, size);
    _paintTimberFrame(canvas, roundedBed);
  }

  void _paintSoilTexture(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.22)
      ..strokeWidth = 1;
    for (var y = 22.0; y < size.height; y += 22.0) {
      canvas.drawLine(
        Offset(14, y + math.sin(y * 0.18) * 1.8),
        Offset(size.width - 14, y + math.cos(y * 0.14) * 1.8),
        linePaint,
      );
    }

    final dotPaint = Paint()..color = colorScheme.onSurfaceVariant.withOpacity(0.10);
    for (var i = 0; i < 56; i++) {
      final x = ((i * 37) % math.max(1, size.width.toInt())).toDouble();
      final y = ((i * 53) % math.max(1, size.height.toInt())).toDouble();
      canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
    }
  }

  void _paintStyleOverlay(Canvas canvas, Size size) {
    switch (style) {
      case _BedDesignStyle.ordered:
        _paintRowGuides(canvas, size);
      case _BedDesignStyle.companion:
        _paintCurvedPath(canvas, size);
      case _BedDesignStyle.showcase:
        _paintShowcasePath(canvas, size);
    }
  }

  void _paintRowGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary.withOpacity(0.13)
      ..strokeWidth = 1.2;
    for (var x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 18), Offset(x, size.height - 18), paint);
    }
  }

  void _paintCurvedPath(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.50, 12)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.28,
        size.width * 0.62,
        size.height * 0.62,
        size.width * 0.50,
        size.height - 12,
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = colorScheme.surface.withOpacity(0.38);
    canvas.drawPath(path, paint);
  }

  void _paintShowcasePath(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.tertiary.withOpacity(0.28);
    final center = Offset(size.width / 2, size.height / 2);
    for (var radius = 28.0; radius < math.min(size.width, size.height) / 2; radius += 34) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintTimberFrame(Canvas canvas, RRect roundedBed) {
    canvas.drawRRect(
      roundedBed.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = colorScheme.outline.withOpacity(0.58),
    );
    canvas.drawRRect(
      roundedBed.deflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = colorScheme.surface.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _BedBackgroundPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme || oldDelegate.style != style;
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
          'This is now a design canvas rather than a plain grid. It keeps the useful plant-count logic, but adds selectable visual styles, SVG crop markers, garden-bed texture, path overlays, and crop labels. A later version can add saved manual placement and drag editing.',
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

enum _BedDesignStyle { ordered, companion, showcase }

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
