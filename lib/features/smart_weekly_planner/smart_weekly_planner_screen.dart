import 'package:flutter/material.dart';

/// A polished, self-contained Smart Weekly Planner module.
///
/// This screen is dependency-light so it can be mounted from the existing app
/// shell without changing persistence, repositories, routing, or app state.
class SmartWeeklyPlannerScreen extends StatefulWidget {
  const SmartWeeklyPlannerScreen({super.key});

  @override
  State<SmartWeeklyPlannerScreen> createState() => _SmartWeeklyPlannerScreenState();
}

class _SmartWeeklyPlannerScreenState extends State<SmartWeeklyPlannerScreen> {
  PlannerTab _selectedTab = PlannerTab.today;
  final Set<String> _completedTaskIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final tasks = PlannerSeedData.tasks;
    final completedCount = _completedTaskIds.length;

    return Scaffold(
      backgroundColor: GardenPlannerColors.canvas,
      body: Stack(
        children: <Widget>[
          const _DecorativeBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: _HeroPlannerCard(
                      completedCount: completedCount,
                      totalCount: tasks.length,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PlannerTabBarDelegate(
                    selectedTab: _selectedTab,
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                  sliver: _buildTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case PlannerTab.today:
        return _TodayPlannerSliver(
          tasks: PlannerSeedData.tasks,
          completedTaskIds: _completedTaskIds,
          onToggleTask: _toggleTask,
        );
      case PlannerTab.calendar:
        return _CalendarPlannerSliver(windows: PlannerSeedData.plantingWindows);
      case PlannerTab.garden:
        return _GardenPlannerSliver(zones: PlannerSeedData.gardenZones);
      case PlannerTab.plants:
        return _PlantsPlannerSliver(windows: PlannerSeedData.plantingWindows);
    }
  }

  void _toggleTask(String taskId) {
    setState(() {
      if (_completedTaskIds.contains(taskId)) {
        _completedTaskIds.remove(taskId);
      } else {
        _completedTaskIds.add(taskId);
      }
    });
  }
}

enum PlannerTab { today, calendar, garden, plants }

enum GardenTaskType { sow, transplant, feed, pestCheck, water, harvest, protect }

enum GardenTaskPriority { low, normal, high, urgent }

class GardenPlannerColors {
  static const Color canvas = Color(0xFFF8F3E8);
  static const Color card = Color(0xFFFFFCF5);
  static const Color ink = Color(0xFF172D22);
  static const Color muted = Color(0xFF69746B);
  static const Color leaf = Color(0xFF2F724B);
  static const Color moss = Color(0xFF8BA766);
  static const Color mint = Color(0xFFE7F0DB);
  static const Color clay = Color(0xFFC4793D);
  static const Color sun = Color(0xFFF4C86A);
  static const Color berry = Color(0xFFB35642);
  static const Color border = Color(0xFFE7DFCE);
}

class GardenTask {
  const GardenTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.plantName,
    required this.type,
    required this.priority,
    required this.dueLabel,
    required this.estimatedMinutes,
  });

  final String id;
  final String title;
  final String subtitle;
  final String plantName;
  final GardenTaskType type;
  final GardenTaskPriority priority;
  final String dueLabel;
  final int estimatedMinutes;
}

class PlantingWindow {
  const PlantingWindow({
    required this.plantName,
    required this.action,
    required this.windowLabel,
    required this.regionFit,
    required this.sunRequirement,
    required this.spacingLabel,
  });

  final String plantName;
  final String action;
  final String windowLabel;
  final String regionFit;
  final String sunRequirement;
  final String spacingLabel;
}

class GardenZone {
  const GardenZone({
    required this.name,
    required this.description,
    required this.healthLabel,
    required this.nextTask,
    required this.plants,
    required this.progress,
  });

  final String name;
  final String description;
  final String healthLabel;
  final String nextTask;
  final List<String> plants;
  final double progress;
}

class PlannerSeedData {
  static const List<GardenTask> tasks = <GardenTask>[
    GardenTask(
      id: 'sow-carrots',
      title: 'Sow carrots',
      subtitle: 'Best window this week. Keep soil evenly moist until germination.',
      plantName: 'Carrot',
      type: GardenTaskType.sow,
      priority: GardenTaskPriority.high,
      dueLabel: 'Best before Friday',
      estimatedMinutes: 12,
    ),
    GardenTask(
      id: 'check-brassicas',
      title: 'Check brassicas',
      subtitle: 'Look under leaves and remove eggs before damage spreads.',
      plantName: 'Brassicas',
      type: GardenTaskType.pestCheck,
      priority: GardenTaskPriority.normal,
      dueLabel: 'Today',
      estimatedMinutes: 5,
    ),
    GardenTask(
      id: 'feed-tomatoes',
      title: 'Feed tomatoes',
      subtitle: 'Use a tomato feed once flowers begin forming.',
      plantName: 'Tomato',
      type: GardenTaskType.feed,
      priority: GardenTaskPriority.normal,
      dueLabel: 'This week',
      estimatedMinutes: 8,
    ),
    GardenTask(
      id: 'protect-basil',
      title: 'Shelter basil overnight',
      subtitle: 'Move pots beside a warm wall while nights are still cold.',
      plantName: 'Basil',
      type: GardenTaskType.protect,
      priority: GardenTaskPriority.urgent,
      dueLabel: 'Tonight',
      estimatedMinutes: 4,
    ),
  ];

  static const List<PlantingWindow> plantingWindows = <PlantingWindow>[
    PlantingWindow(
      plantName: 'Lettuce',
      action: 'Sow direct or transplant seedlings',
      windowLabel: 'Good now',
      regionFit: 'Excellent for mild NZ regions',
      sunRequirement: 'Part sun',
      spacingLabel: '25 cm',
    ),
    PlantingWindow(
      plantName: 'Carrot',
      action: 'Direct sow only',
      windowLabel: 'Good now',
      regionFit: 'Avoid heavy wet soil',
      sunRequirement: 'Full sun',
      spacingLabel: '5 cm',
    ),
    PlantingWindow(
      plantName: 'Tomato',
      action: 'Start indoors or transplant after cold nights',
      windowLabel: 'Almost ready',
      regionFit: 'Wait in frosty areas',
      sunRequirement: 'Full sun',
      spacingLabel: '50 cm',
    ),
    PlantingWindow(
      plantName: 'Parsley',
      action: 'Sow or transplant',
      windowLabel: 'Good now',
      regionFit: 'Reliable in containers',
      sunRequirement: 'Part sun',
      spacingLabel: '20 cm',
    ),
  ];

  static const List<GardenZone> gardenZones = <GardenZone>[
    GardenZone(
      name: 'Raised Bed 1',
      description: 'Leafy greens and spring root crops',
      healthLabel: 'Good',
      nextTask: 'Sow carrots before Friday',
      plants: <String>['Lettuce', 'Carrot', 'Spring onion'],
      progress: 0.72,
    ),
    GardenZone(
      name: 'Patio Pots',
      description: 'Kitchen herbs close to the house',
      healthLabel: 'Needs water',
      nextTask: 'Water parsley tomorrow morning',
      plants: <String>['Basil', 'Parsley', 'Chives'],
      progress: 0.48,
    ),
  ];
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -100,
            child: _SoftBlob(color: GardenPlannerColors.mint.withOpacity(0.95), size: 260),
          ),
          Positioned(
            top: 180,
            left: -140,
            child: _SoftBlob(color: GardenPlannerColors.sun.withOpacity(0.20), size: 260),
          ),
          Positioned(
            bottom: -160,
            right: -100,
            child: _SoftBlob(color: GardenPlannerColors.moss.withOpacity(0.18), size: 320),
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroPlannerCard extends StatelessWidget {
  const _HeroPlannerCard({required this.completedCount, required this.totalCount});

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF17452F), Color(0xFF2F724B), Color(0xFF9EAD68)],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _BotanicalHeroPainter())),
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
                            _GlassPill(
                              icon: Icons.place_outlined,
                              label: 'Auckland · Early spring',
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your garden\nthis week',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                height: 0.98,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SunBadge(),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _HeroMetricStrip(completedCount: completedCount, totalCount: totalCount, progress: progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotanicalHeroPainter extends CustomPainter {
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

class _SunBadge extends StatelessWidget {
  const _SunBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.17),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFE7A1), size: 34),
    );
  }
}

class _HeroMetricStrip extends StatelessWidget {
  const _HeroMetricStrip({required this.completedCount, required this.totalCount, required this.progress});

  final int completedCount;
  final int totalCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE7A1)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: _HeroMetric(value: '$completedCount/$totalCount', label: 'done')),
              const _MetricDivider(),
              const Expanded(child: _HeroMetric(value: '3', label: 'windows')),
              const _MetricDivider(),
              const Expanded(child: _HeroMetric(value: 'Low', label: 'frost')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: Colors.white.withOpacity(0.18));
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

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
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PlannerTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PlannerTabBarDelegate({required this.selectedTab, required this.onSelected});

  final PlannerTab selectedTab;
  final ValueChanged<PlannerTab> onSelected;

  @override
  double get minExtent => 74;

  @override
  double get maxExtent => 74;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GardenPlannerColors.canvas.withOpacity(0.96),
        boxShadow: overlapsContent
            ? const <BoxShadow>[BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: PlannerTab.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final tab = PlannerTab.values[index];
            final isSelected = tab == selectedTab;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: ChoiceChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(_tabIcon(tab), size: 18, color: isSelected ? Colors.white : GardenPlannerColors.leaf),
                label: Text(_tabLabel(tab)),
                selectedColor: GardenPlannerColors.leaf,
                backgroundColor: GardenPlannerColors.card,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : GardenPlannerColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(color: isSelected ? GardenPlannerColors.leaf : GardenPlannerColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onSelected: (_) => onSelected(tab),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PlannerTabBarDelegate oldDelegate) => selectedTab != oldDelegate.selectedTab;

  String _tabLabel(PlannerTab tab) {
    switch (tab) {
      case PlannerTab.today:
        return 'Today';
      case PlannerTab.calendar:
        return 'Calendar';
      case PlannerTab.garden:
        return 'Garden';
      case PlannerTab.plants:
        return 'Plants';
    }
  }

  IconData _tabIcon(PlannerTab tab) {
    switch (tab) {
      case PlannerTab.today:
        return Icons.today_outlined;
      case PlannerTab.calendar:
        return Icons.calendar_month_outlined;
      case PlannerTab.garden:
        return Icons.yard_outlined;
      case PlannerTab.plants:
        return Icons.local_florist_outlined;
    }
  }
}

class _TodayPlannerSliver extends StatelessWidget {
  const _TodayPlannerSliver({required this.tasks, required this.completedTaskIds, required this.onToggleTask});

  final List<GardenTask> tasks;
  final Set<String> completedTaskIds;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: tasks.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) return const _SectionHeader(title: 'Today', subtitle: 'Designed as fast, tappable garden actions.');
        if (index == 1) return const _ForecastStrip();
        final task = tasks[index - 2];
        return _GardenTaskCard(
          task: task,
          isCompleted: completedTaskIds.contains(task.id),
          onToggle: () => onToggleTask(task.id),
        );
      },
    );
  }
}

class _ForecastStrip extends StatelessWidget {
  const _ForecastStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          _ForecastCard(day: 'Mon', icon: Icons.cloud_outlined, label: 'Mild', value: '18°'),
          _ForecastCard(day: 'Tue', icon: Icons.water_drop_outlined, label: 'Rain', value: '12mm'),
          _ForecastCard(day: 'Wed', icon: Icons.wb_sunny_outlined, label: 'Sow', value: 'Best'),
          _ForecastCard(day: 'Thu', icon: Icons.air_outlined, label: 'Wind', value: 'Med'),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.day, required this.icon, required this.label, required this.value});

  final String day;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[Text(day, style: const TextStyle(fontWeight: FontWeight.w900, color: GardenPlannerColors.ink)), const Spacer(), Icon(icon, size: 18, color: GardenPlannerColors.leaf)]),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: GardenPlannerColors.ink)),
          Text(label, style: const TextStyle(color: GardenPlannerColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GardenTaskCard extends StatelessWidget {
  const _GardenTaskCard({required this.task, required this.isCompleted, required this.onToggle});

  final GardenTask task;
  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = _priorityColor(task.priority);

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: isCompleted ? 0.985 : 1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isCompleted ? 0.56 : 1,
        child: Container(
          decoration: _cardDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Row(
              children: <Widget>[
                Container(width: 7, height: 152, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _IconTile(icon: _taskIcon(task.type), color: accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    task.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GardenPlannerColors.ink),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(task.plantName, style: const TextStyle(color: GardenPlannerColors.muted, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            _StatusPill(label: task.dueLabel, color: accent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(task.subtitle, style: const TextStyle(color: GardenPlannerColors.muted, height: 1.35)),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            _MetaChip(icon: Icons.timer_outlined, label: '${task.estimatedMinutes} min'),
                            const SizedBox(width: 8),
                            _MetaChip(icon: Icons.bolt_outlined, label: _priorityLabel(task.priority)),
                            const Spacer(),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: isCompleted ? GardenPlannerColors.muted : GardenPlannerColors.leaf,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: onToggle,
                              icon: Icon(isCompleted ? Icons.undo : Icons.check, size: 18),
                              label: Text(isCompleted ? 'Undo' : 'Done'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(GardenTaskPriority priority) {
    switch (priority) {
      case GardenTaskPriority.low:
        return GardenPlannerColors.moss;
      case GardenTaskPriority.normal:
        return GardenPlannerColors.leaf;
      case GardenTaskPriority.high:
        return GardenPlannerColors.clay;
      case GardenTaskPriority.urgent:
        return GardenPlannerColors.berry;
    }
  }

  String _priorityLabel(GardenTaskPriority priority) {
    switch (priority) {
      case GardenTaskPriority.low:
        return 'Low';
      case GardenTaskPriority.normal:
        return 'Normal';
      case GardenTaskPriority.high:
        return 'High';
      case GardenTaskPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _taskIcon(GardenTaskType type) {
    switch (type) {
      case GardenTaskType.sow:
        return Icons.grass_outlined;
      case GardenTaskType.transplant:
        return Icons.move_down_outlined;
      case GardenTaskType.feed:
        return Icons.compost_outlined;
      case GardenTaskType.pestCheck:
        return Icons.bug_report_outlined;
      case GardenTaskType.water:
        return Icons.water_drop_outlined;
      case GardenTaskType.harvest:
        return Icons.shopping_basket_outlined;
      case GardenTaskType.protect:
        return Icons.shield_outlined;
    }
  }
}

class _CalendarPlannerSliver extends StatelessWidget {
  const _CalendarPlannerSliver({required this.windows});

  final List<PlantingWindow> windows;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(<Widget>[
        const _SectionHeader(title: 'Planting windows', subtitle: 'A visual season map for what belongs now.'),
        const SizedBox(height: 14),
        const _MiniCalendarCard(),
        const SizedBox(height: 16),
        ...windows.map((window) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _PlantingWindowCard(window: window))),
      ]),
    );
  }
}

class _MiniCalendarCard extends StatelessWidget {
  const _MiniCalendarCard();

  @override
  Widget build(BuildContext context) {
    const activeDays = <int>{3, 6, 9, 13, 17, 21, 26};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: Text('September', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GardenPlannerColors.ink))),
              _StatusPill(label: '7 smart days'),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 28,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isActive = activeDays.contains(day);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? GardenPlannerColors.leaf : const Color(0xFFF5EFE2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isActive ? const <BoxShadow>[BoxShadow(color: Color(0x252F724B), blurRadius: 10, offset: Offset(0, 5))] : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(color: isActive ? Colors.white : GardenPlannerColors.muted, fontWeight: FontWeight.w900),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlantingWindowCard extends StatelessWidget {
  const _PlantingWindowCard({required this.window});

  final PlantingWindow window;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          _PlantBadge(label: window.plantName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(window.plantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GardenPlannerColors.ink))),
                    _StatusPill(label: window.windowLabel),
                  ],
                ),
                const SizedBox(height: 7),
                Text(window.action, style: const TextStyle(color: GardenPlannerColors.muted, height: 1.3)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetaChip(icon: Icons.wb_sunny_outlined, label: window.sunRequirement),
                    _MetaChip(icon: Icons.straighten_outlined, label: window.spacingLabel),
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

class _GardenPlannerSliver extends StatelessWidget {
  const _GardenPlannerSliver({required this.zones});

  final List<GardenZone> zones;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: zones.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) return const _SectionHeader(title: 'My Garden', subtitle: 'Each area gets its own next best action.');
        return _GardenZoneCard(zone: zones[index - 1]);
      },
    );
  }
}

class _GardenZoneCard extends StatelessWidget {
  const _GardenZoneCard({required this.zone});

  final GardenZone zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(zone.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GardenPlannerColors.ink))),
              _StatusPill(label: zone.healthLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(zone.description, style: const TextStyle(color: GardenPlannerColors.muted)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: zone.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF0E8D8),
              valueColor: const AlwaysStoppedAnimation<Color>(GardenPlannerColors.leaf),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: zone.plants.map((plant) => _MetaChip(icon: Icons.local_florist_outlined, label: plant)).toList()),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: GardenPlannerColors.mint, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: <Widget>[
                const Icon(Icons.next_plan_outlined, color: GardenPlannerColors.leaf),
                const SizedBox(width: 10),
                Expanded(child: Text(zone.nextTask, style: const TextStyle(color: GardenPlannerColors.ink, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantsPlannerSliver extends StatelessWidget {
  const _PlantsPlannerSliver({required this.windows});

  final List<PlantingWindow> windows;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(<Widget>[
        const _SectionHeader(title: 'Recommended plants', subtitle: 'Quick visual picks for the current season.'),
        const SizedBox(height: 14),
        ...windows.map((window) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _PlantRecommendationCard(window: window))),
      ]),
    );
  }
}

class _PlantRecommendationCard extends StatelessWidget {
  const _PlantRecommendationCard({required this.window});

  final PlantingWindow window;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          _PlantBadge(label: window.plantName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(window.plantName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GardenPlannerColors.ink)),
                const SizedBox(height: 5),
                Text(window.regionFit, style: const TextStyle(color: GardenPlannerColors.muted)),
              ],
            ),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: GardenPlannerColors.leaf, foregroundColor: Colors.white),
            onPressed: () {},
            icon: const Icon(Icons.add),
            tooltip: 'Add to garden',
          ),
        ],
      ),
    );
  }
}

class _PlantBadge extends StatelessWidget {
  const _PlantBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[GardenPlannerColors.mint, Color(0xFFD4E5BE)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label.characters.first.toUpperCase(),
        style: const TextStyle(color: GardenPlannerColors.leaf, fontSize: 24, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(color: GardenPlannerColors.ink, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: GardenPlannerColors.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(19)),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.color = GardenPlannerColors.leaf});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF5EFE2), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: GardenPlannerColors.muted),
          const SizedBox(width: 6),
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GardenPlannerColors.muted, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: GardenPlannerColors.card,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: GardenPlannerColors.border),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10)),
    ],
  );
}
