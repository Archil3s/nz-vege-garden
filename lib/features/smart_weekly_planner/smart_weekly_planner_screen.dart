import 'package:flutter/material.dart';

/// A self-contained Smart Weekly Planner module.
///
/// This screen is intentionally dependency-light so it can be dropped into the
/// existing app navigation without changing persistence or repository layers.
/// Wire it from the app shell with:
///
/// ```dart
/// const SmartWeeklyPlannerScreen()
/// ```
class SmartWeeklyPlannerScreen extends StatefulWidget {
  const SmartWeeklyPlannerScreen({super.key});

  @override
  State<SmartWeeklyPlannerScreen> createState() => _SmartWeeklyPlannerScreenState();
}

class _SmartWeeklyPlannerScreenState extends State<SmartWeeklyPlannerScreen> {
  PlannerTab _selectedTab = PlannerTab.today;
  final Set<String> _completedTaskIds = <String>{};
  final List<GardenTask> _tasks = PlannerSeedData.tasks;
  final List<PlantingWindow> _windows = PlannerSeedData.plantingWindows;
  final List<GardenZone> _zones = PlannerSeedData.gardenZones;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _PlannerHeader(
                completedCount: _completedTaskIds.length,
                totalCount: _tasks.length,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PlannerTabBarDelegate(
                selectedTab: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
                backgroundColor: const Color(0xFFF7F4EC),
                activeColor: colorScheme.primary,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case PlannerTab.today:
        return _TodayPlannerSliver(
          tasks: _tasks,
          completedTaskIds: _completedTaskIds,
          onToggleTask: _toggleTask,
        );
      case PlannerTab.calendar:
        return _CalendarPlannerSliver(windows: _windows);
      case PlannerTab.garden:
        return _GardenPlannerSliver(zones: _zones);
      case PlannerTab.plants:
        return _PlantsPlannerSliver(windows: _windows);
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
      title: 'Sow carrots in a shallow drill',
      subtitle: 'Best window this week. Keep soil evenly moist until germination.',
      plantName: 'Carrot',
      type: GardenTaskType.sow,
      priority: GardenTaskPriority.high,
      dueLabel: 'Best before Friday',
      estimatedMinutes: 12,
    ),
    GardenTask(
      id: 'check-brassicas',
      title: 'Check brassicas for caterpillars',
      subtitle: 'Look under leaves and remove eggs before damage spreads.',
      plantName: 'Brassicas',
      type: GardenTaskType.pestCheck,
      priority: GardenTaskPriority.normal,
      dueLabel: 'Today',
      estimatedMinutes: 5,
    ),
    GardenTask(
      id: 'feed-tomatoes',
      title: 'Feed tomatoes lightly',
      subtitle: 'Use a tomato feed once flowers begin forming.',
      plantName: 'Tomato',
      type: GardenTaskType.feed,
      priority: GardenTaskPriority.normal,
      dueLabel: 'This week',
      estimatedMinutes: 8,
    ),
    GardenTask(
      id: 'protect-basil',
      title: 'Keep basil sheltered overnight',
      subtitle: 'Basil dislikes cold nights. Move pots beside a warm wall.',
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

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({required this.completedCount, required this.totalCount});

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Smart Weekly Planner',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF173A2A),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auckland · Early spring · Low frost risk',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF647067),
                          ),
                    ),
                  ],
                ),
              ),
              const _PlannerAvatar(),
            ],
          ),
          const SizedBox(height: 18),
          _WeeklySummaryCard(progress: progress, completedCount: completedCount, totalCount: totalCount),
        ],
      ),
    );
  }
}

class _PlannerAvatar extends StatelessWidget {
  const _PlannerAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE2EAD9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.eco_outlined, color: Color(0xFF2E6B45)),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF173A2A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F173A2A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'This week in your garden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(label: '$completedCount/$totalCount done', isDark: true),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAED581)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: <Widget>[
              Expanded(child: _SummaryMetric(icon: Icons.task_alt, value: '4', label: 'tasks')),
              Expanded(child: _SummaryMetric(icon: Icons.calendar_month, value: '3', label: 'windows')),
              Expanded(child: _SummaryMetric(icon: Icons.device_thermostat, value: 'Low', label: 'frost')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFFAED581), size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlannerTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PlannerTabBarDelegate({
    required this.selectedTab,
    required this.onSelected,
    required this.backgroundColor,
    required this.activeColor,
  });

  final PlannerTab selectedTab;
  final ValueChanged<PlannerTab> onSelected;
  final Color backgroundColor;
  final Color activeColor;

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlannerTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = PlannerTab.values[index];
          final isSelected = tab == selectedTab;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(_tabLabel(tab)),
            avatar: Icon(_tabIcon(tab), size: 18),
            selectedColor: activeColor.withValues(alpha: 0.14),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF435047),
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: isSelected ? activeColor.withValues(alpha: 0.3) : const Color(0xFFE5E0D3),
            ),
            onSelected: (_) => onSelected(tab),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PlannerTabBarDelegate oldDelegate) {
    return selectedTab != oldDelegate.selectedTab || backgroundColor != oldDelegate.backgroundColor;
  }

  String _tabLabel(PlannerTab tab) {
    switch (tab) {
      case PlannerTab.today:
        return 'Today';
      case PlannerTab.calendar:
        return 'Calendar';
      case PlannerTab.garden:
        return 'My Garden';
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
  const _TodayPlannerSliver({
    required this.tasks,
    required this.completedTaskIds,
    required this.onToggleTask,
  });

  final List<GardenTask> tasks;
  final Set<String> completedTaskIds;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: tasks.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _SectionTitle(
            title: 'Today',
            subtitle: 'Highest-impact actions first',
          );
        }
        final task = tasks[index - 1];
        return _GardenTaskCard(
          task: task,
          isCompleted: completedTaskIds.contains(task.id),
          onToggle: () => onToggleTask(task.id),
        );
      },
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
    final priorityColor = _priorityColor(task.priority);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isCompleted ? 0.58 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6E0D3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_taskIcon(task.type), color: priorityColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: const Color(0xFF1E3026),
                              ),
                        ),
                      ),
                      _StatusPill(label: task.dueLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF687269),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      _MetaChip(icon: Icons.timer_outlined, label: '${task.estimatedMinutes} min'),
                      const SizedBox(width: 8),
                      _MetaChip(icon: Icons.spa_outlined, label: task.plantName),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: onToggle,
                        icon: Icon(isCompleted ? Icons.undo : Icons.check),
                        label: Text(isCompleted ? 'Undo' : 'Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(GardenTaskPriority priority) {
    switch (priority) {
      case GardenTaskPriority.low:
        return const Color(0xFF6E8B5E);
      case GardenTaskPriority.normal:
        return const Color(0xFF2E6B45);
      case GardenTaskPriority.high:
        return const Color(0xFFC27B2C);
      case GardenTaskPriority.urgent:
        return const Color(0xFFB4523B);
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
        const _SectionTitle(title: 'Planting windows', subtitle: 'What fits the current NZ season'),
        const SizedBox(height: 12),
        const _MiniCalendarCard(),
        const SizedBox(height: 16),
        ...windows.map((window) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlantingWindowCard(window: window),
            )),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E0D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'September',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3026)),
                ),
              ),
              _StatusPill(label: '7 smart days'),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 28,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isActive = activeDays.contains(day);
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE2EAD9) : const Color(0xFFF8F6F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isActive ? const Color(0xFF2E6B45) : const Color(0xFF7B817A),
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E0D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  window.plantName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3026)),
                ),
              ),
              _StatusPill(label: window.windowLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(window.action, style: const TextStyle(color: Color(0xFF687269))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaChip(icon: Icons.place_outlined, label: window.regionFit),
              _MetaChip(icon: Icons.wb_sunny_outlined, label: window.sunRequirement),
              _MetaChip(icon: Icons.straighten_outlined, label: window.spacingLabel),
            ],
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _SectionTitle(
            title: 'My Garden',
            subtitle: 'Each area gets its own next best action',
          );
        }
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E0D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3026)),
                ),
              ),
              _StatusPill(label: zone.healthLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(zone.description, style: const TextStyle(color: Color(0xFF687269))),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: zone.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0ECE2),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zone.plants.map((plant) => _MetaChip(icon: Icons.local_florist_outlined, label: plant)).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.next_plan_outlined, color: Color(0xFF2E6B45)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    zone.nextTask,
                    style: const TextStyle(color: Color(0xFF1E3026), fontWeight: FontWeight.w700),
                  ),
                ),
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
        const _SectionTitle(title: 'Recommended plants', subtitle: 'Fast picks for the current season'),
        const SizedBox(height: 12),
        ...windows.map((window) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlantRecommendationCard(window: window),
            )),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E0D3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE2EAD9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_florist_outlined, color: Color(0xFF2E6B45)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  window.plantName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E3026)),
                ),
                const SizedBox(height: 5),
                Text(window.action, style: const TextStyle(color: Color(0xFF687269))),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.add),
            tooltip: 'Add to garden',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1E3026),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF687269)),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.isDark = false});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFE2EAD9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF2E6B45),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF5F6E63)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF5F6E63),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
