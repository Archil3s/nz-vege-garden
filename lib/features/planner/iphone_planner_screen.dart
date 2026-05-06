import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IphonePlannerScreen extends StatefulWidget {
  const IphonePlannerScreen({super.key});

  @override
  State<IphonePlannerScreen> createState() => _IphonePlannerScreenState();
}

class _IphonePlannerScreenState extends State<IphonePlannerScreen> {
  _PlannerSection _section = _PlannerSection.today;
  final Set<String> _doneTasks = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UxColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: _HeroCard(doneCount: _doneTasks.length, totalCount: _PlannerData.tasks.length),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StablePlannerHeaderDelegate(
                section: _section,
                onChanged: (section) {
                  HapticFeedback.selectionClick();
                  setState(() => _section = section);
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
              sliver: _buildSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case _PlannerSection.today:
        return SliverList.separated(
          itemCount: _PlannerData.tasks.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _SectionIntro(
                title: 'Today',
                subtitle: 'Your best garden actions in one thumb-scroll.',
              );
            }
            final task = _PlannerData.tasks[index - 1];
            return _TaskCard(
              task: task,
              done: _doneTasks.contains(task.id),
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_doneTasks.contains(task.id)) {
                    _doneTasks.remove(task.id);
                  } else {
                    _doneTasks.add(task.id);
                  }
                });
              },
            );
          },
        );
      case _PlannerSection.calendar:
        return SliverList.separated(
          itemCount: _PlannerData.windows.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _SectionIntro(
                title: 'Calendar',
                subtitle: 'Planting windows without sideways tab scrolling.',
              );
            }
            return _WindowCard(window: _PlannerData.windows[index - 1]);
          },
        );
      case _PlannerSection.garden:
        return SliverList.separated(
          itemCount: _PlannerData.zones.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _SectionIntro(
                title: 'Garden',
                subtitle: 'Bed and pot status cards with clear next steps.',
              );
            }
            return _ZoneCard(zone: _PlannerData.zones[index - 1]);
          },
        );
      case _PlannerSection.plants:
        return SliverGrid.builder(
          itemCount: _PlannerData.plants.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .92,
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _PlantIntroCard();
            }
            return _PlantCard(plant: _PlannerData.plants[index - 1]);
          },
        );
    }
  }
}

enum _PlannerSection { today, calendar, garden, plants }

class _PlannerTask {
  const _PlannerTask({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    required this.badge,
    required this.minutes,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String title;
  final String detail;
  final String badge;
  final int minutes;
  final Color color;
}

class _PlantWindow {
  const _PlantWindow({
    required this.name,
    required this.action,
    required this.badge,
    required this.detail,
    required this.icon,
  });

  final String name;
  final String action;
  final String badge;
  final String detail;
  final IconData icon;
}

class _GardenZone {
  const _GardenZone({
    required this.name,
    required this.status,
    required this.nextTask,
    required this.progress,
    required this.plants,
  });

  final String name;
  final String status;
  final String nextTask;
  final double progress;
  final List<String> plants;
}

class _UxColors {
  static const canvas = Color(0xFFF8F3E8);
  static const card = Color(0xFFFFFCF5);
  static const ink = Color(0xFF172D22);
  static const muted = Color(0xFF66736A);
  static const leaf = Color(0xFF2F724B);
  static const mint = Color(0xFFE7F0DB);
  static const clay = Color(0xFFC4793D);
  static const berry = Color(0xFFB35642);
  static const sun = Color(0xFFF4C86A);
  static const border = Color(0xFFE7DFCE);
}

class _PlannerData {
  static const tasks = <_PlannerTask>[
    _PlannerTask(
      id: 'sow-carrots',
      icon: Icons.grass_outlined,
      title: 'Sow carrots',
      detail: 'Good window now. Keep the seed row damp.',
      badge: 'Best now',
      minutes: 12,
      color: _UxColors.leaf,
    ),
    _PlannerTask(
      id: 'check-brassicas',
      icon: Icons.bug_report_outlined,
      title: 'Check brassicas',
      detail: 'Look under leaves before pest damage spreads.',
      badge: 'Today',
      minutes: 5,
      color: _UxColors.clay,
    ),
    _PlannerTask(
      id: 'water-pots',
      icon: Icons.water_drop_outlined,
      title: 'Water pots',
      detail: 'Containers dry faster in wind and sun.',
      badge: 'Quick',
      minutes: 4,
      color: _UxColors.berry,
    ),
  ];

  static const windows = <_PlantWindow>[
    _PlantWindow(
      name: 'Lettuce',
      action: 'Sow or transplant',
      badge: 'Good now',
      detail: 'Part sun. Reliable in mild NZ conditions.',
      icon: Icons.spa_outlined,
    ),
    _PlantWindow(
      name: 'Carrot',
      action: 'Direct sow',
      badge: 'Good now',
      detail: 'Loose soil. Avoid heavy wet patches.',
      icon: Icons.grass_outlined,
    ),
    _PlantWindow(
      name: 'Parsley',
      action: 'Sow or transplant',
      badge: 'Easy',
      detail: 'Good for pots near the kitchen.',
      icon: Icons.local_florist_outlined,
    ),
  ];

  static const zones = <_GardenZone>[
    _GardenZone(
      name: 'Raised Bed 1',
      status: 'Good',
      nextTask: 'Sow carrots before Friday',
      progress: .72,
      plants: ['Lettuce', 'Carrot', 'Spring onion'],
    ),
    _GardenZone(
      name: 'Patio Pots',
      status: 'Needs water',
      nextTask: 'Water parsley tomorrow morning',
      progress: .48,
      plants: ['Basil', 'Parsley', 'Chives'],
    ),
  ];

  static const plants = <_PlantWindow>[
    _PlantWindow(name: 'Lettuce', action: '25 cm', badge: 'Part sun', detail: 'Fast salad crop', icon: Icons.spa_outlined),
    _PlantWindow(name: 'Carrot', action: '5 cm', badge: 'Full sun', detail: 'Direct sow only', icon: Icons.grass_outlined),
    _PlantWindow(name: 'Parsley', action: '20 cm', badge: 'Pots', detail: 'Reliable herb', icon: Icons.local_florist_outlined),
    _PlantWindow(name: 'Tomato', action: '50 cm', badge: 'Protect', detail: 'Wait for warm nights', icon: Icons.wb_sunny_outlined),
  ];
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.doneCount, required this.totalCount});

  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17452F), _UxColors.leaf, Color(0xFF8BA766)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x24172D22), blurRadius: 28, offset: Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _HeroPill(icon: Icons.offline_bolt_outlined, label: 'Offline iPhone planner'),
              const Spacer(),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: const Icon(Icons.eco_outlined, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Your garden\nthis week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: .96,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(_UxColors.sun),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroStat(value: '$doneCount/$totalCount', label: 'done'),
              const SizedBox(width: 12),
              const _HeroStat(value: '3', label: 'actions'),
              const SizedBox(width: 12),
              const _HeroStat(value: 'Low', label: 'jank'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StablePlannerHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StablePlannerHeaderDelegate({required this.section, required this.onChanged});

  final _PlannerSection section;
  final ValueChanged<_PlannerSection> onChanged;

  @override
  double get minExtent => 142;

  @override
  double get maxExtent => 142;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: _UxColors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _UxColors.card.withOpacity(.98),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _UxColors.border),
            boxShadow: overlapsContent
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.25,
              physics: const NeverScrollableScrollPhysics(),
              children: _PlannerSection.values.map((item) {
                return _SegmentButton(
                  section: item,
                  selected: item == section,
                  onTap: () => onChanged(item),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StablePlannerHeaderDelegate oldDelegate) => section != oldDelegate.section;
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.section, required this.selected, required this.onTap});

  final _PlannerSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: selected ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? _UxColors.leaf : const Color(0xFFF5EFE2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon(section), size: 18, color: selected ? Colors.white : _UxColors.leaf),
              const SizedBox(width: 7),
              Text(
                _label(section),
                style: TextStyle(
                  color: selected ? Colors.white : _UxColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(_PlannerSection section) {
    switch (section) {
      case _PlannerSection.today:
        return 'Today';
      case _PlannerSection.calendar:
        return 'Calendar';
      case _PlannerSection.garden:
        return 'Garden';
      case _PlannerSection.plants:
        return 'Plants';
    }
  }

  IconData _icon(_PlannerSection section) {
    switch (section) {
      case _PlannerSection.today:
        return Icons.today_outlined;
      case _PlannerSection.calendar:
        return Icons.calendar_month_outlined;
      case _PlannerSection.garden:
        return Icons.yard_outlined;
      case _PlannerSection.plants:
        return Icons.local_florist_outlined;
    }
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _UxColors.ink, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.6)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _UxColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.done, required this.onToggle});

  final _PlannerTask task;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Row(
        children: [
          _IconBadge(icon: task.icon, color: task.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(task.title, style: _titleStyle)),
                    _SmallPill(label: task.badge, color: task.color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(task.detail, style: _bodyStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Meta(icon: Icons.timer_outlined, label: '${task.minutes} min'),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: done ? _UxColors.muted : _UxColors.leaf,
                        foregroundColor: Colors.white,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: onToggle,
                      icon: Icon(done ? Icons.undo : Icons.check, size: 18),
                      label: Text(done ? 'Undo' : 'Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.window});

  final _PlantWindow window;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Row(
        children: [
          _IconBadge(icon: window.icon, color: _UxColors.leaf),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(window.name, style: _titleStyle)), _SmallPill(label: window.badge)]),
                const SizedBox(height: 6),
                Text(window.action, style: const TextStyle(color: _UxColors.ink, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(window.detail, style: _bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});

  final _GardenZone zone;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(zone.name, style: _titleStyle)), _SmallPill(label: zone.status)]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: zone.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE6D7),
              valueColor: const AlwaysStoppedAnimation<Color>(_UxColors.leaf),
            ),
          ),
          const SizedBox(height: 12),
          Text(zone.nextTask, style: const TextStyle(color: _UxColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zone.plants.map((plant) => _SmallPill(label: plant, color: _UxColors.clay)).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PlantIntroCard extends StatelessWidget {
  const _PlantIntroCard();

  @override
  Widget build(BuildContext context) {
    return const _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swipe_down_alt_outlined, color: _UxColors.leaf),
          Spacer(),
          Text('Plant picks', style: _titleStyle),
          SizedBox(height: 6),
          Text('Tap-friendly grid. No horizontal tab scroll.', style: _bodyStyle),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({required this.plant});

  final _PlantWindow plant;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: plant.icon, color: _UxColors.leaf),
          const Spacer(),
          Text(plant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStyle),
          const SizedBox(height: 6),
          Text(plant.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: _bodyStyle),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [_SmallPill(label: plant.badge), _SmallPill(label: plant.action, color: _UxColors.clay)]),
        ],
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _UxColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _UxColors.border),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 7),
        const Text('Offline iPhone planner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(.74), fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, this.color = _UxColors.leaf});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 17, color: _UxColors.muted),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _UxColors.muted, fontWeight: FontWeight.w800)),
    ]);
  }
}

const _titleStyle = TextStyle(color: _UxColors.ink, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.2);
const _bodyStyle = TextStyle(color: _UxColors.muted, height: 1.34, fontWeight: FontWeight.w650);
