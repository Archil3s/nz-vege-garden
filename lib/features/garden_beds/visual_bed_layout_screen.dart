import 'dart:math' as math;

import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: Text('${widget.bed.name} layout'),
      ),
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
          final activePlantingZones = widget.plantings
              .where((planting) => planting.status != 'finished' && planting.status != 'failed')
              .map(
                (planting) {
                  final crop = cropById[planting.cropId];
                  return _LayoutZone(
                    title: planting.cropName,
                    subtitle: _formatValue(planting.status),
                    spacingCm: crop?.spacingCm ?? 30,
                    source: _LayoutZoneSource.saved,
                    icon: _iconForStatus(planting.status),
                  );
                },
              )
              .toList(growable: false);

          final generatedPlan = _generatePlan(
            data: data,
            peopleToFeed: _peopleToFeed,
          );
          final displayZones = activePlantingZones.isEmpty ? generatedPlan.zones : activePlantingZones;
          final showingGeneratedMap = activePlantingZones.isEmpty;

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
                showingSavedPlantings: !showingGeneratedMap,
              ),
              const SizedBox(height: 16),
              _VisualBedCard(
                bed: widget.bed,
                zones: displayZones,
                title: showingGeneratedMap ? 'Suggested garden design' : 'Current garden design',
                description: showingGeneratedMap
                    ? 'A seasonal layout idea based on your saved region, the current month, bed size, crop spacing, and people target.'
                    : 'Your active plantings visualised as crop zones. Finished and failed crops are hidden from this layout.',
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

    final scored = seasonalRules
        .map((rule) {
          final crop = cropById[rule.cropId]!;
          return _ScoredSeasonalCrop(
            crop: crop,
            rule: rule,
            score: _scoreCrop(crop: crop, rule: rule),
          );
        })
        .toList(growable: false)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) {
          return scoreComparison;
        }

        return a.crop.commonName.compareTo(b.crop.commonName);
      });

    final targetZones = peopleToFeed <= 2
        ? 3
        : peopleToFeed <= 4
            ? 4
            : 5;
    final selected = scored.take(targetZones).toList(growable: false);
    final zones = selected
        .map(
          (item) => _LayoutZone(
            title: item.crop.commonName,
            subtitle: _formatMethod(item.rule.method),
            spacingCm: item.crop.spacingCm,
            source: _LayoutZoneSource.generated,
            icon: item.rule.method == 'transplant' ? Icons.move_down_outlined : Icons.grass_outlined,
          ),
        )
        .toList(growable: false);

    return _GeneratedBedPlan(
      monthName: _monthName(now.month),
      zones: zones,
      suggestions: selected,
    );
  }

  int _scoreCrop({
    required Crop crop,
    required PlantingRule rule,
  }) {
    var score = 0;

    if (crop.beginnerFriendly) {
      score += 3;
    }
    if (crop.containerFriendly && widget.bed.type == 'container') {
      score += 3;
    }
    if (rule.method == 'direct_sow') {
      score += 2;
    }
    if (!crop.frostTender) {
      score += 1;
    }
    if (crop.daysToHarvestMax <= 60) {
      score += 2;
    }
    if (crop.category == 'herb') {
      score += 1;
    }

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
            colors: [
              scheme.primaryContainer,
              scheme.tertiaryContainer,
            ],
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
                    child: Icon(
                      Icons.dashboard_customize_outlined,
                      color: scheme.primary,
                    ),
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
                'Preview your current planting or generate a seasonal layout idea before adding crops.',
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
  const _HeroChip({
    required this.icon,
    required this.label,
  });

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
  const _PeopleSelectorCard({
    required this.peopleToFeed,
    required this.onChanged,
  });

  final int peopleToFeed;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Design target',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Badge(
                  label: Text('$peopleToFeed'),
                  child: const Icon(Icons.person_outline),
                ),
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
              'This changes how many crop zones the generated design tries to include.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPlanCard extends StatelessWidget {
  const _GeneratedPlanCard({
    required this.plan,
    required this.showingSavedPlantings,
  });

  final _GeneratedBedPlan plan;
  final bool showingSavedPlantings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: scheme.tertiary),
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
            if (plan.suggestions.isEmpty)
              const Text('No seasonal crop suggestions found for this month and region yet.')
            else ...[
              Text(
                showingSavedPlantings
                    ? 'Your map shows current plantings. These are extra seasonal ideas you could use in another bed.'
                    : 'Your bed has no active crops, so the map below uses this generated design idea.',
              ),
              const SizedBox(height: 12),
              ...plan.suggestions.map(
                (item) => _SuggestionTile(item: item),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.item});

  final _ScoredSeasonalCrop item;

  @override
  Widget build(BuildContext context) {
    final methodIcon = item.rule.method == 'transplant' ? Icons.move_down_outlined : Icons.grass_outlined;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(methodIcon, size: 20),
      ),
      title: Text(item.crop.commonName),
      subtitle: Text(
        '${_formatMethod(item.rule.method)} now • spacing ${item.crop.spacingCm} cm\n${item.rule.riskNote}',
      ),
    );
  }

  String _formatMethod(String value) {
    return switch (value) {
      'direct_sow' => 'Sow direct',
      'transplant' => 'Transplant',
      _ => value,
    };
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surfaceContainerHighest,
                    scheme.surface,
                  ],
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
                    child: CustomPaint(
                      painter: _BedLayoutPainter(
                        zones: zones,
                        colorScheme: scheme,
                      ),
                      child: const SizedBox.expand(),
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
                    .map(
                      (zone) => Chip(
                        avatar: Icon(zone.icon, size: 18),
                        label: Text(zone.title),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _aspectRatioForBed(GardenBed bed) {
    final length = bed.lengthCm;
    final width = bed.widthCm;

    if (length == null || width == null || length <= 0 || width <= 0) {
      return 1.6;
    }

    return (length / width).clamp(0.75, 2.4).toDouble();
  }
}

class _BedLayoutPainter extends CustomPainter {
  const _BedLayoutPainter({
    required this.zones,
    required this.colorScheme,
  });

  final List<_LayoutZone> zones;
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
    _paintSoilTexture(canvas, size);
    canvas.drawRRect(roundedBed.deflate(1), borderPaint);

    if (zones.isEmpty) {
      _paintEmptyBed(canvas, size);
      return;
    }

    final columns = zones.length == 1 ? 1 : math.min(2, zones.length);
    final rows = (zones.length / columns).ceil();
    final zoneWidth = size.width / columns;
    final zoneHeight = size.height / rows;

    for (var index = 0; index < zones.length; index++) {
      final zone = zones[index];
      final column = index % columns;
      final row = index ~/ columns;
      final rect = Rect.fromLTWH(
        column * zoneWidth,
        row * zoneHeight,
        zoneWidth,
        zoneHeight,
      ).deflate(10);
      final color = _colorForIndex(index, zone.source);
      _paintZone(canvas, rect, zone, color);
    }
  }

  void _paintSoilTexture(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.22)
      ..strokeWidth = 1;
    const gap = 22.0;

    for (var y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y + math.sin(y) * 1.6), linePaint);
    }

    final dotPaint = Paint()..color = colorScheme.onSurfaceVariant.withOpacity(0.10);
    for (var i = 0; i < 38; i++) {
      final x = ((i * 37) % math.max(1, size.width.toInt())).toDouble();
      final y = ((i * 53) % math.max(1, size.height.toInt())).toDouble();
      canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
    }
  }

  void _paintEmptyBed(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'No crops yet',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  void _paintZone(Canvas canvas, Rect rect, _LayoutZone zone, Color color) {
    final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final zonePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.24),
          color.withOpacity(0.10),
        ],
      ).createShader(rect);
    final zoneBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withOpacity(0.68);

    canvas.drawRRect(rounded, zonePaint);
    canvas.drawRRect(rounded, zoneBorderPaint);

    final estimatedColumns = math.max(1, (rect.width / math.max(24, zone.spacingCm * 0.68)).floor());
    final estimatedRows = math.max(1, (rect.height / math.max(24, zone.spacingCm * 0.68)).floor());
    final maxDots = math.min(estimatedColumns * estimatedRows, 24);

    for (var dot = 0; dot < maxDots; dot++) {
      final dotColumn = dot % estimatedColumns;
      final dotRow = dot ~/ estimatedColumns;
      final x = rect.left + ((dotColumn + 1) * rect.width / (estimatedColumns + 1));
      final y = rect.top + ((dotRow + 1) * rect.height / (estimatedRows + 1));
      _paintPlantMarker(canvas, Offset(x, y), color);
    }

    _paintZoneLabel(canvas, rect, zone, color);
  }

  void _paintPlantMarker(Canvas canvas, Offset center, Color color) {
    final stemPaint = Paint()
      ..color = color.withOpacity(0.72)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = color;
    final shadowPaint = Paint()..color = colorScheme.shadow.withOpacity(0.08);

    canvas.drawCircle(center.translate(0, 2), 5.8, shadowPaint);
    canvas.drawLine(center.translate(0, 5), center.translate(0, -4), stemPaint);
    canvas.drawOval(Rect.fromCenter(center: center.translate(-3.2, -2.2), width: 7, height: 4.4), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: center.translate(3.2, -2.2), width: 7, height: 4.4), leafPaint);
    canvas.drawCircle(center.translate(0, 2.8), 2.4, Paint()..color = color.withOpacity(0.86));
  }

  void _paintZoneLabel(Canvas canvas, Rect rect, _LayoutZone zone, Color color) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: zone.title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16);
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: zone.subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16);

    final labelWidth = math.max(titlePainter.width, subtitlePainter.width) + 16;
    final labelHeight = titlePainter.height + subtitlePainter.height + 10;
    final labelRect = Rect.fromLTWH(rect.left + 8, rect.top + 8, labelWidth, labelHeight);
    final labelPaint = Paint()..color = colorScheme.surface.withOpacity(0.92);

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(14)),
      labelPaint,
    );
    titlePainter.paint(canvas, Offset(labelRect.left + 8, labelRect.top + 4));
    subtitlePainter.paint(canvas, Offset(labelRect.left + 8, labelRect.top + 4 + titlePainter.height));
  }

  Color _colorForIndex(int index, _LayoutZoneSource source) {
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
      const Color(0xFF4C7F5D),
      const Color(0xFF7C6F3C),
    ];

    final color = colors[index % colors.length];
    return source == _LayoutZoneSource.generated ? color.withOpacity(0.95) : color;
  }

  @override
  bool shouldRepaint(covariant _BedLayoutPainter oldDelegate) {
    return oldDelegate.zones != zones || oldDelegate.colorScheme != colorScheme;
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
            Text(
              'Spacing guide',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (zones.isEmpty)
              const Text('Add crops or use a generated plan to see spacing guidance.')
            else
              ...zones.map(
                (zone) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(zone.icon, size: 20),
                  ),
                  title: Text(zone.title),
                  subtitle: Text('${zone.subtitle} • ${zone.spacingCm} cm between plants'),
                ),
              ),
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
          'This is a designed planning view, not an exact yield guarantee. It uses current season rules and spacing data to create a practical starting point. A later version can save generated plans into the bed, support manual drag placement, add companion planting, and show crop rotation warnings.',
        ),
      ),
    );
  }
}

class _LayoutData {
  const _LayoutData({
    required this.regionId,
    required this.crops,
    required this.plantingRules,
  });

  final String regionId;
  final List<Crop> crops;
  final List<PlantingRule> plantingRules;
}

class _GeneratedBedPlan {
  const _GeneratedBedPlan({
    required this.monthName,
    required this.zones,
    required this.suggestions,
  });

  final String monthName;
  final List<_LayoutZone> zones;
  final List<_ScoredSeasonalCrop> suggestions;
}

class _ScoredSeasonalCrop {
  const _ScoredSeasonalCrop({
    required this.crop,
    required this.rule,
    required this.score,
  });

  final Crop crop;
  final PlantingRule rule;
  final int score;
}

class _LayoutZone {
  const _LayoutZone({
    required this.title,
    required this.subtitle,
    required this.spacingCm,
    required this.source,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final int spacingCm;
  final _LayoutZoneSource source;
  final IconData icon;
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
