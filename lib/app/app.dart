import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/calendar/crop_calendar_screen.dart';
import '../features/crops/crop_guide_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/pests/pest_guide_screen.dart';
import '../features/pruning/pruning_guide_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/weekly_tasks_screen.dart';
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
        const HomeScreen(),
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
      body: RepaintBoundary(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({required this.onOpenSection});

  final ValueChanged<Widget> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'More garden tools',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Extra tools are grouped here so the main phone navigation stays readable and easy to tap.',
          ),
          const SizedBox(height: 16),
          _MoreSectionCard(
            title: 'Planning',
            children: [
              _MoreSectionTile(
                icon: Icons.menu_book_outlined,
                title: 'Crop guide',
                description: 'Search crops, spacing, harvest timing, and growing notes.',
                onTap: () => onOpenSection(const CropGuideScreen()),
              ),
              _MoreSectionTile(
                icon: Icons.calendar_month_outlined,
                title: 'Crop calendar',
                description: 'Sow, transplant, and harvest timing by month.',
                onTap: () => onOpenSection(const CropCalendarScreen()),
              ),
              _MoreSectionTile(
                icon: Icons.checklist_outlined,
                title: 'Weekly tasks',
                description: 'Local task suggestions, reminders, and succession actions.',
                onTap: () => onOpenSection(const WeeklyTasksScreen()),
              ),
              _MoreSectionTile(
                icon: Icons.content_cut_outlined,
                title: 'Pruning guide',
                description: 'Bushes, trees, hedges, berries, vines, and shrubs.',
                onTap: () => onOpenSection(const PruningGuideScreen()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoreSectionCard(
            title: 'Reference',
            children: [
              _MoreSectionTile(
                icon: Icons.bug_report_outlined,
                title: 'Pest guide',
                description: 'Offline help for common pests and crop problems.',
                onTap: () => onOpenSection(const PestGuideScreen()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoreSectionCard(
            title: 'App',
            children: [
              _MoreSectionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                description: 'Region, garden type, frost risk, wind exposure, and preferences.',
                onTap: () => onOpenSection(const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreSectionCard extends StatelessWidget {
  const _MoreSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MoreSectionTile extends StatelessWidget {
  const _MoreSectionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
