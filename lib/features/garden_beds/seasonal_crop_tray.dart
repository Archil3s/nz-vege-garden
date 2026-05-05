import 'package:flutter/material.dart';

import '../../core/plant_icons/generated_plant_icon.dart';
import '../../data/models/crop.dart';
import '../../data/models/planting_rule.dart';

class SeasonalCropTray extends StatelessWidget {
  const SeasonalCropTray({
    required this.monthName,
    required this.options,
    required this.onCropSelected,
    this.selectedMethod = SeasonalCropTrayMethod.both,
    this.onMethodChanged,
    super.key,
  });

  final String monthName;
  final List<SeasonalCropTrayOption> options;
  final SeasonalCropTrayMethod selectedMethod;
  final ValueChanged<SeasonalCropTrayMethod>? onMethodChanged;
  final ValueChanged<SeasonalCropTrayOption> onCropSelected;

  @override
  Widget build(BuildContext context) {
    final filteredOptions = options
        .where((option) => selectedMethod.allows(option.method))
        .toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_florist_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What can go in now',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(monthName),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Seasonal options for this month and region. Tap a crop to start placing it into the bed layout.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<SeasonalCropTrayMethod>(
              selected: {selectedMethod},
              showSelectedIcon: false,
              onSelectionChanged: onMethodChanged == null
                  ? null
                  : (selection) => onMethodChanged!(selection.first),
              segments: const [
                ButtonSegment(
                  value: SeasonalCropTrayMethod.both,
                  icon: Icon(Icons.all_inclusive_outlined),
                  label: Text('Both'),
                ),
                ButtonSegment(
                  value: SeasonalCropTrayMethod.directSow,
                  icon: Icon(Icons.grass_outlined),
                  label: Text('Sow'),
                ),
                ButtonSegment(
                  value: SeasonalCropTrayMethod.transplant,
                  icon: Icon(Icons.move_down_outlined),
                  label: Text('Plant'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredOptions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No seasonal crop options found for this filter.'),
              )
            else
              SizedBox(
                height: 156,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index];
                    return _SeasonalCropTile(
                      option: option,
                      onTap: () => onCropSelected(option),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeasonalCropTile extends StatelessWidget {
  const _SeasonalCropTile({required this.option, required this.onTap});

  final SeasonalCropTrayOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 142,
      child: Material(
        color: scheme.surfaceContainerHighest.withOpacity(0.58),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: GeneratedPlantIcon(
                          cropName: option.crop.commonName,
                          size: 34,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(option.methodIcon, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  option.crop.commonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  option.methodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _MiniBadge('${option.crop.spacingCm} cm'),
                    _MiniBadge('${option.crop.daysToHarvestMin}-${option.crop.daysToHarvestMax}d'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class SeasonalCropTrayOption {
  const SeasonalCropTrayOption({
    required this.crop,
    required this.rule,
  });

  final Crop crop;
  final PlantingRule rule;

  String get method => rule.method;

  String get methodLabel {
    return switch (rule.method) {
      'direct_sow' => 'Direct sow now',
      'transplant' => 'Transplant now',
      _ => rule.method,
    };
  }

  IconData get methodIcon {
    return switch (rule.method) {
      'direct_sow' => Icons.grass_outlined,
      'transplant' => Icons.move_down_outlined,
      _ => Icons.eco_outlined,
    };
  }
}

enum SeasonalCropTrayMethod {
  both,
  directSow,
  transplant;

  bool allows(String method) {
    return switch (this) {
      SeasonalCropTrayMethod.both => true,
      SeasonalCropTrayMethod.directSow => method == 'direct_sow',
      SeasonalCropTrayMethod.transplant => method == 'transplant',
    };
  }
}
