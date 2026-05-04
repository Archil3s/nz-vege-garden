import 'package:flutter/material.dart';

import '../../data/models/crop.dart';

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({
    required this.crop,
    super.key,
  });

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(crop.commonName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            crop.commonName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(crop.summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.category_outlined,
                label: _formatValue(crop.category),
              ),
              _StatusChip(
                icon: Icons.wb_sunny_outlined,
                label: _formatValue(crop.sunRequirement),
              ),
              _StatusChip(
                icon: Icons.water_drop_outlined,
                label: _formatValue(crop.waterRequirement),
              ),
              if (crop.frostTender)
                const _StatusChip(
                  icon: Icons.ac_unit,
                  label: 'Frost tender',
                )
              else
                const _StatusChip(
                  icon: Icons.ac_unit_outlined,
                  label: 'Frost tolerant',
                ),
              if (crop.containerFriendly)
                const _StatusChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'Container friendly',
                ),
              if (crop.beginnerFriendly)
                const _StatusChip(
                  icon: Icons.thumb_up_alt_outlined,
                  label: 'Beginner friendly',
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Spacing',
            icon: Icons.straighten_outlined,
            child: Text('${crop.spacingCm} cm between plants'),
          ),
          _InfoSection(
            title: 'Harvest timing',
            icon: Icons.event_available_outlined,
            child: Text(
              '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days from sowing or transplanting, depending on conditions.',
            ),
          ),
          _InfoSection(
            title: 'Growing notes',
            icon: Icons.eco_outlined,
            child: Text(_buildGrowingNotes(crop)),
          ),
          _InfoSection(
            title: 'MVP data note',
            icon: Icons.info_outline,
            child: const Text(
              'This crop profile uses the first seed data set. More detailed sowing, transplanting, pest, disease, feeding, and harvest guidance will be added as the crop database expands.',
            ),
          ),
        ],
      ),
    );
  }

  String _buildGrowingNotes(Crop crop) {
    final notes = <String>[];

    if (crop.frostTender) {
      notes.add('Avoid outdoor planting until frost risk has passed.');
    } else {
      notes.add('Suitable for cooler periods or mild frost conditions depending on region.');
    }

    if (crop.containerFriendly) {
      notes.add('Can be grown in containers if watering and feeding are managed.');
    }

    if (crop.waterRequirement == 'regular') {
      notes.add('Keep soil moisture consistent, especially while establishing.');
    }

    if (crop.sunRequirement == 'full_sun') {
      notes.add('Best in a sunny position.');
    } else if (crop.sunRequirement == 'sun_or_part_shade') {
      notes.add('Can handle sun or part shade, useful for warmer parts of the season.');
    }

    return notes.join(' ');
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
