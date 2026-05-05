import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';

class VisualBedLayoutScreen extends StatelessWidget {
  const VisualBedLayoutScreen({
    required this.bed,
    required this.plantings,
    super.key,
  });

  final GardenBed bed;
  final List<GardenBedPlanting> plantings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${bed.name} layout'),
      ),
      body: FutureBuilder<List<Crop>>(
        future: const GardenDataRepository().loadCrops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load crop spacing data: ${snapshot.error}'),
              ),
            );
          }

          final cropById = {
            for (final crop in snapshot.data ?? const <Crop>[]) crop.id: crop,
          };
          final layoutItems = plantings
              .where((planting) => planting.status != 'finished' && planting.status != 'failed')
              .map(
                (planting) => _LayoutPlanting(
                  planting: planting,
                  crop: cropById[planting.cropId],
                ),
              )
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LayoutIntroCard(bed: bed),
              const SizedBox(height: 16),
              if (layoutItems.isEmpty)
                const _EmptyLayoutCard()
              else
                _VisualBedCard(
                  bed: bed,
                  items: layoutItems,
                ),
              const SizedBox(height: 16),
              _SpacingGuideCard(items: layoutItems),
              const SizedBox(height: 16),
              const _DesignNoteCard(),
            ],
          );
        },
      ),
    );
  }
}

class _LayoutIntroCard extends StatelessWidget {
  const _LayoutIntroCard({required this.bed});

  final GardenBed bed;

  @override
  Widget build(BuildContext context) {
    final dimensions = bed.lengthCm == null || bed.widthCm == null
        ? 'No dimensions set'
        : '${bed.lengthCm} × ${bed.widthCm} cm';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_customize_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visual spacing preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A conceptual layout that uses bed dimensions, planted crops, and crop spacing to show how crowded the bed may be.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.straighten_outlined, size: 18),
                  label: Text(dimensions),
                ),
                Chip(
                  avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                  label: Text(_formatValue(bed.sunExposure)),
                ),
                Chip(
                  avatar: const Icon(Icons.air_outlined, size: 18),
                  label: Text(_formatValue(bed.windExposure)),
                ),
              ],
            ),
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

class _VisualBedCard extends StatelessWidget {
  const _VisualBedCard({
    required this.bed,
    required this.items,
  });

  final GardenBed bed;
  final List<_LayoutPlanting> items;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _aspectRatioForBed(bed);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bed map',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Each crop is arranged into a simple zone. Dots estimate possible plant positions from spacing data.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _BedLayoutPainter(
                      items: items,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
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
    required this.items,
    required this.colorScheme,
  });

  final List<_LayoutPlanting> items;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bedPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.outline;
    final bedRect = Offset.zero & size;

    canvas.drawRect(bedRect, bedPaint);
    canvas.drawRect(bedRect.deflate(1), borderPaint);

    if (items.isEmpty) {
      return;
    }

    final columns = items.length == 1 ? 1 : math.min(2, items.length);
    final rows = (items.length / columns).ceil();
    final zoneWidth = size.width / columns;
    final zoneHeight = size.height / rows;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final column = index % columns;
      final row = index ~/ columns;
      final rect = Rect.fromLTWH(
        column * zoneWidth,
        row * zoneHeight,
        zoneWidth,
        zoneHeight,
      ).deflate(8);
      final color = _colorForIndex(index);
      _paintZone(canvas, rect, item, color);
    }
  }

  void _paintZone(
    Canvas canvas,
    Rect rect,
    _LayoutPlanting item,
    Color color,
  ) {
    final zonePaint = Paint()..color = color.withOpacity(0.16);
    final zoneBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.65);

    final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(rounded, zonePaint);
    canvas.drawRRect(rounded, zoneBorderPaint);

    final spacing = item.crop?.spacingCm ?? 30;
    final estimatedColumns = math.max(1, (rect.width / math.max(22, spacing * 0.7)).floor());
    final estimatedRows = math.max(1, (rect.height / math.max(22, spacing * 0.7)).floor());
    final maxDots = math.min(estimatedColumns * estimatedRows, 24);
    final dotPaint = Paint()..color = color;

    for (var dot = 0; dot < maxDots; dot++) {
      final dotColumn = dot % estimatedColumns;
      final dotRow = dot ~/ estimatedColumns;
      final x = rect.left + ((dotColumn + 1) * rect.width / (estimatedColumns + 1));
      final y = rect.top + ((dotRow + 1) * rect.height / (estimatedRows + 1));
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: item.planting.cropName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 12);

    final labelBackground = Paint()
      ..color = colorScheme.surface.withOpacity(0.86);
    final labelRect = Rect.fromLTWH(
      rect.left + 6,
      rect.top + 6,
      textPainter.width + 12,
      textPainter.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(999)),
      labelBackground,
    );
    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 3));
  }

  Color _colorForIndex(int index) {
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
      colorScheme.primary.withBlue(180),
      colorScheme.tertiary.withGreen(140),
    ];

    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant _BedLayoutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.colorScheme != colorScheme;
  }
}

class _SpacingGuideCard extends StatelessWidget {
  const _SpacingGuideCard({required this.items});

  final List<_LayoutPlanting> items;

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
            if (items.isEmpty)
              const Text('Add crops to this bed to see spacing guidance.')
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.straighten_outlined),
                  title: Text(item.planting.cropName),
                  subtitle: Text(
                    item.crop == null
                        ? 'No crop spacing data found.'
                        : 'Recommended spacing: ${item.crop!.spacingCm} cm between plants.',
                  ),
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
          'This is a performance-safe visual planner. It does not store exact plant coordinates yet. A later version can add manual placement, drag handles, crop family warnings, paths, companion planting, and rotation overlays after the basic layout has been tested on real devices.',
        ),
      ),
    );
  }
}

class _EmptyLayoutCard extends StatelessWidget {
  const _EmptyLayoutCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No active crops in this bed yet. Add a crop to see a visual spacing preview.',
        ),
      ),
    );
  }
}

class _LayoutPlanting {
  const _LayoutPlanting({
    required this.planting,
    required this.crop,
  });

  final GardenBedPlanting planting;
  final Crop? crop;
}
