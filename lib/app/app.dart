import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/calendar/crop_calendar_screen.dart';
import '../features/coach/garden_coach_screen.dart';
import '../features/crops/crop_guide_screen.dart';
import '../features/harvest/harvest_tracker_screen.dart';
import '../features/home/friendly_home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/journal/garden_journal_screen.dart';
import '../features/pests/pest_guide_screen.dart';
import '../features/pruning/pruning_guide_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/weekly_tasks_screen.dart';
import '../features/water/watering_planner_screen.dart';
import 'app_theme.dart';

class NzVegeGardenApp extends StatelessWidget {
  const NzVegeGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NZ Vege Garden',
      theme: buildAppTheme(),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        const FriendlyHomeScreen(),
        const GardenCoachScreen(),
        const InsightsScreen(),
        _MoreScreen(onOpenSection: _openSection),
      ];

  void _openSection(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: RepaintBoundary(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF5).withValues(alpha: .96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE7DFCE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              elevation: 0,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                if (index == _selectedIndex) {
                  HapticFeedback.selectionClick();
                  return;
                }

                HapticFeedback.selectionClick();
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.eco_outlined),
                  selectedIcon: Icon(Icons.eco),
                  label: 'Coach',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_outlined),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({required this.onOpenSection});

  static const canvas = Color(0xFFF8F3E8);
  static const surface = Color(0xFFFFFCF5);
  static const ink = Color(0xFF172D22);
  static const muted = Color(0xFF66736A);
  static const leaf = Color(0xFF2F724B);
  static const leafDark = Color(0xFF17452F);
  static const moss = Color(0xFF8BA766);
  static const mint = Color(0xFFE7F0DB);
  static const clay = Color(0xFFC4793D);
  static const berry = Color(0xFFB35642);
  static const border = Color(0xFFE7DFCE);
  static const sun = Color(0xFFF4C86A);

  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final planningTools = [
      const _MoreTool(
        icon: Icons.water_drop_outlined,
        title: 'Water & soil',
        description: 'Estimate dry-out risk before watering.',
        tag: 'Today',
        color: leaf,
        screen: WateringPlannerScreen(),
      ),
      const _MoreTool(
        icon: Icons.shopping_basket_outlined,
        title: 'Harvest tracker',
        description: 'Track weights, notes, and crop leaders.',
        tag: 'Log',
        color: clay,
        screen: HarvestTrackerScreen(),
      ),
      const _MoreTool(
        icon: Icons.edit_note_outlined,
        title: 'Garden journal',
        description: 'Save observations, ideas, and pest notes.',
        tag: 'Notes',
        color: moss,
        screen: GardenJournalScreen(),
      ),
      const _MoreTool(
        icon: Icons.menu_book_outlined,
        title: 'Crop guide',
        description: 'Spacing, harvest timing, and growing notes.',
        tag: 'Search',
        color: leaf,
        screen: CropGuideScreen(),
      ),
      const _MoreTool(
        icon: Icons.calendar_month_outlined,
        title: 'Crop calendar',
        description: 'Sow, transplant, and harvest by month.',
        tag: 'Plan',
        color: leafDark,
        screen: CropCalendarScreen(),
      ),
      const _MoreTool(
        icon: Icons.checklist_outlined,
        title: 'Weekly tasks',
        description: 'Local task suggestions and reminders.',
        tag: 'Tasks',
        color: moss,
        screen: WeeklyTasksScreen(),
      ),
      const _MoreTool(
        icon: Icons.content_cut_outlined,
        title: 'Pruning guide',
        description: 'Bushes, hedges, berries, vines, and trees.',
        tag: 'Seasonal',
        color: clay,
        screen: PruningGuideScreen(),
      ),
    ];

    final referenceTools = [
      const _MoreTool(
        icon: Icons.bug_report_outlined,
        title: 'Pest guide',
        description: 'Common pests and crop problems offline.',
        tag: 'Help',
        color: berry,
        screen: PestGuideScreen(),
      ),
      const _MoreTool(
        icon: Icons.settings_outlined,
        title: 'Settings',
        description: 'Region, garden type, frost, wind, and reminders.',
        tag: 'App',
        color: leafDark,
        screen: SettingsScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: canvas,
      body: Stack(
        children: [
          Positioned(
            top: -130,
            right: -110,
            child: _SoftBlob(
              color: mint.withValues(alpha: .85),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -170,
            left: -150,
            child: _SoftBlob(
              color: sun.withValues(alpha: .18),
              size: 320,
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _MoreHeroCard(
                      onOpenSection: onOpenSection,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _QuickToolGrid(
                      tools: planningTools.take(4).toList(),
                      onOpenSection: onOpenSection,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _MoreSectionCard(
                      eyebrow: 'Planning',
                      title: 'Keep the garden moving',
                      subtitle:
                          'Fast tools for water, sowing, tasks, harvests, and seasonal care.',
                      tools: planningTools,
                      onOpenSection: onOpenSection,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
                  sliver: SliverToBoxAdapter(
                    child: _MoreSectionCard(
                      eyebrow: 'Reference',
                      title: 'Help and setup',
                      subtitle: 'Guides and app preferences live here.',
                      tools: referenceTools,
                      onOpenSection: onOpenSection,
                    ),
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

class _MoreHeroCard extends StatelessWidget {
  const _MoreHeroCard({required this.onOpenSection});

  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _MoreScreen.leafDark,
            _MoreScreen.leaf,
            _MoreScreen.moss,
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22172D22),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -24,
            child: Icon(
              Icons.local_florist_outlined,
              size: 150,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassLabel(label: 'More garden tools'),
              const SizedBox(height: 20),
              const Text(
                'What do you want\nto do next?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: .96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pick by job, not by menu. The most useful tools are surfaced first.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _HeroActionButton(
                      icon: Icons.water_drop_outlined,
                      label: 'Check water',
                      onTap: () => onOpenSection(const WateringPlannerScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroActionButton(
                      icon: Icons.menu_book_outlined,
                      label: 'Find crop',
                      onTap: () => onOpenSection(const CropGuideScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickToolGrid extends StatelessWidget {
  const _QuickToolGrid({
    required this.tools,
    required this.onOpenSection,
  });

  final List<_MoreTool> tools;
  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: tools.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        return _QuickToolCard(
          tool: tools[index],
          onOpenSection: onOpenSection,
        );
      },
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  const _QuickToolCard({
    required this.tool,
    required this.onOpenSection,
  });

  final _MoreTool tool;
  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MoreScreen.surface,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.selectionClick();
          onOpenSection(tool.screen);
        },
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _MoreScreen.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToolIconBubble(
                icon: tool.icon,
                color: tool.color,
              ),
              const Spacer(),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _MoreScreen.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.tag,
                style: TextStyle(
                  color: tool.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSectionCard extends StatelessWidget {
  const _MoreSectionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.tools,
    required this.onOpenSection,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<_MoreTool> tools;
  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _MoreScreen.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _MoreScreen.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionEyebrow(label: eyebrow),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _MoreScreen.ink,
              fontSize: 22,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _MoreScreen.muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...tools.map(
            (tool) => _MoreToolRow(
              tool: tool,
              onOpenSection: onOpenSection,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreToolRow extends StatelessWidget {
  const _MoreToolRow({
    required this.tool,
    required this.onOpenSection,
  });

  final _MoreTool tool;
  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          onOpenSection(tool.screen);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _ToolIconBubble(
                icon: tool.icon,
                color: tool.color,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: const TextStyle(
                        color: _MoreScreen.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.description,
                      style: const TextStyle(
                        color: _MoreScreen.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SmallTag(
                label: tool.tag,
                color: tool.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolIconBubble extends StatelessWidget {
  const _ToolIconBubble({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _MoreScreen.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _MoreScreen.leafDark,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MoreTool {
  const _MoreTool({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.color,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final Color color;
  final Widget screen;
}
