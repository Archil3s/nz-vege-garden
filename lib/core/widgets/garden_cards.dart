import 'package:flutter/material.dart';

import '../theme/garden_visual_theme.dart';

class GardenPrettyCard extends StatelessWidget {
  const GardenPrettyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GardenVisualTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GardenVisualTheme.border),
        boxShadow: GardenShadows.soft,
      ),
      child: child,
    );
  }
}

class GardenStatusPill extends StatelessWidget {
  const GardenStatusPill({
    super.key,
    required this.label,
    this.color = GardenVisualTheme.leaf,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class GardenPlantBadge extends StatelessWidget {
  const GardenPlantBadge({
    super.key,
    required this.label,
    this.size = 64,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.isEmpty ? '?' : label.characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: GardenGradients.plantBadge,
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: GardenVisualTheme.leaf,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
