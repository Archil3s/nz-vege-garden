import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PruningGuideScreen extends StatelessWidget {
  const PruningGuideScreen({super.key});

  static const _canvas = Color(0xFFF8F3E8);
  static const _surface = Color(0xFFFFFCF5);
  static const _ink = Color(0xFF172D22);
  static const _muted = Color(0xFF66736A);
  static const _leaf = Color(0xFF2F724B);
  static const _leafDark = Color(0xFF17452F);
  static const _mint = Color(0xFFE7F0DB);
  static const _clay = Color(0xFFC4793D);
  static const _border = Color(0xFFE7DFCE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(title: const Text('Pruning Guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: const [
          _HeroCard(),
          SizedBox(height: 16),
          _SeasonStrip(),
          SizedBox(height: 16),
          _CategoryGrid(),
          SizedBox(height: 16),
          _SafetyCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PruningGuideScreen._leafDark, PruningGuideScreen._leaf, Color(0xFF8BA766)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.20)),
                          ),
                          child: const Text(
                            'Trees · shrubs · vines',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Prune with\nconfidence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 0.96,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset('assets/icons/pruning_shears.svg', width: 82, height: 82),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonStrip extends StatelessWidget {
  const _SeasonStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _SeasonCard(label: 'Winter', icon: Icons.ac_unit_outlined, note: 'Main prune'),
          SizedBox(width: 10),
          _SeasonCard(label: 'Spring', icon: Icons.eco_outlined, note: 'Light tidy'),
          SizedBox(width: 10),
          _SeasonCard(label: 'Summer', icon: Icons.wb_sunny_outlined, note: 'Shape'),
          SizedBox(width: 10),
          _SeasonCard(label: 'Autumn', icon: Icons.spa_outlined, note: 'Avoid hard cuts'),
        ],
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.label, required this.icon, required this.note});

  final String label;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PruningGuideScreen._leaf),
          const Spacer(),
          Text(label, style: const TextStyle(color: PruningGuideScreen._ink, fontWeight: FontWeight.w900)),
          Text(note, style: const TextStyle(color: PruningGuideScreen._muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const items = [
    _PruningCategory('Fruit trees', Icons.park_outlined, 'Open centre', 'Winter'),
    _PruningCategory('Citrus', Icons.sunny, 'Light only', 'After frost'),
    _PruningCategory('Hedges', Icons.dashboard_customize_outlined, 'Shape sides', 'Spring'),
    _PruningCategory('Roses', Icons.local_florist_outlined, 'Hard prune', 'Winter'),
    _PruningCategory('Berries', Icons.grain_outlined, 'Old canes out', 'After fruit'),
    _PruningCategory('Grapes', Icons.alt_route, 'Spur prune', 'Winter'),
    _PruningCategory('Natives', Icons.forest_outlined, 'Tip prune', 'After flowering'),
    _PruningCategory('Shrubs', Icons.yard_outlined, 'Thin inside', 'After bloom'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.12,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items.map((item) => _CategoryTile(item: item)).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item});

  final _PruningCategory item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => _PruningSheet(item: item),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PruningGuideScreen._mint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item.icon, color: PruningGuideScreen._leaf),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PruningGuideScreen._ink, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              _Pill(label: item.season),
            ],
          ),
        ),
      ),
    );
  }
}

class _PruningSheet extends StatelessWidget {
  const _PruningSheet({required this.item});

  final _PruningCategory item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/pruning_shears.svg', width: 64, height: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: item.season),
              _Pill(label: item.action, color: PruningGuideScreen._clay),
              const _Pill(label: 'Clean tools'),
              const _Pill(label: 'Angle cuts'),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Remove dead, damaged, crossing, or crowded growth first. Step back often and keep the natural shape.',
            style: TextStyle(color: PruningGuideScreen._muted, height: 1.4, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: PruningGuideScreen._clay),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avoid heavy pruning during frost, heatwaves, or active flowering unless the plant is damaged.',
              style: TextStyle(color: PruningGuideScreen._muted, fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = PruningGuideScreen._leaf});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _PruningCategory {
  const _PruningCategory(this.title, this.icon, this.action, this.season);

  final String title;
  final IconData icon;
  final String action;
  final String season;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: PruningGuideScreen._surface,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: PruningGuideScreen._border),
    boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))],
  );
}
