import 'package:flutter/material.dart';

import '../theme/garden_visual_theme.dart';

class GardenScreenBackground extends StatelessWidget {
  const GardenScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: ColoredBox(color: GardenVisualTheme.canvas)),
        const Positioned(top: -120, right: -100, child: _SoftBlob(color: GardenVisualTheme.mint, size: 260)),
        Positioned(
          top: 180,
          left: -140,
          child: _SoftBlob(color: GardenVisualTheme.sun.withOpacity(0.20), size: 260),
        ),
        Positioned(
          bottom: -160,
          right: -100,
          child: _SoftBlob(color: GardenVisualTheme.moss.withOpacity(0.18), size: 320),
        ),
        child,
      ],
    );
  }
}

class GardenHeroCard extends StatelessWidget {
  const GardenHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: GardenShadows.hero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: GardenGradients.hero),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: GardenBotanicalPainter())),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            GardenGlassPill(icon: Icons.place_outlined, label: eyebrow),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                height: 0.98,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  if (footer != null) ...<Widget>[
                    const SizedBox(height: 24),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GardenGlassPill extends StatelessWidget {
  const GardenGlassPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class GardenBotanicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = Colors.white.withOpacity(0.10);
    final stemPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final baseX = size.width * 0.68;
    final baseY = size.height * 0.98;

    for (var i = 0; i < 6; i++) {
      final dx = baseX + (i - 2.5) * 24;
      final height = 86.0 + i * 10;
      final path = Path()
        ..moveTo(dx, baseY)
        ..quadraticBezierTo(dx - 20, baseY - height * 0.45, dx + 4, baseY - height);
      canvas.drawPath(path, stemPaint);

      canvas.save();
      canvas.translate(dx + 2, baseY - height * 0.70);
      canvas.rotate(-0.55 + i * 0.18);
      canvas.drawOval(const Rect.fromLTWH(-8, -18, 18, 36), leafPaint);
      canvas.restore();
    }

    final circlePaint = Paint()..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), 72, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
