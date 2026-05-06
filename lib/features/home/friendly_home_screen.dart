import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/garden_profile_repository.dart';
import '../../data/garden_quick_log_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_profile.dart';
import '../../data/models/garden_quick_log.dart';
import '../../data/models/nz_region.dart';
import '../../data/models/planting_rule.dart';
import '../calendar/crop_calendar_screen.dart';
import '../crops/crop_detail_screen.dart';
import '../crops/crop_guide_screen.dart';
import '../pests/pest_guide_screen.dart';
import '../profile/garden_profile_screen.dart';
import '../tasks/weekly_tasks_screen.dart';
import '../water/watering_planner_screen.dart';

const _canvas = Color(0xFFF8F3E8);
const _surface = Color(0xFFFFFCF5);
const _ink = Color(0xFF172D22);
const _muted = Color(0xFF66736A);
const _leaf = Color(0xFF2F724B);
const _leafDark = Color(0xFF17452F);
const _moss = Color(0xFF8BA766);
const _mint = Color(0xFFE7F0DB);
const _clay = Color(0xFFC4793D);
const _berry = Color(0xFFB35642);
const _border = Color(0xFFE7DFCE);
const _sun = Color(0xFFF4C86A);

class FriendlyHomeScreen extends StatefulWidget {
  const FriendlyHomeScreen({super.key});

  @override
  State<FriendlyHomeScreen> createState() => _FriendlyHomeScreenState();
}

class _FriendlyHomeScreenState extends State<FriendlyHomeScreen> {
  final _settingsRepository = const AppSettingsRepository();
  final _profileRepository = const GardenProfileRepository();
  final _dataRepository = const GardenDataRepository();
  final _logRepository = const GardenQuickLogRepository();

  late Future<_TodayData> _todayFuture;

  @override
  void initState() {
    super.initState();
    _todayFuture = _loadToday();
  }

  Future<_TodayData> _loadToday() async {
    final now = DateTime.now();

    final settings = await _settingsRepository.loadSettings();
    final profile = await _profileRepository.loadProfile();
    final crops = await _dataRepository.loadCrops();
    final rules = await _dataRepository.loadPlantingRules();
    final regions = await _dataRepository.loadRegions();
    final logs = await _logRepository.loadLogs();

    final cropById = {for (final crop in crops) crop.id: crop};
    final region = _findRegion(regions, settings.regionId);

    final actions = _buildActions(
      month: now.month,
      settings: settings,
      profile: profile,
      crops: crops,
      cropById: cropById,
      rules: rules,
    );

    final myCrops = _cropsForIds(profile.growingCropIds, cropById);
    final wishlistCrops = _cropsForIds(profile.wishlistCropIds, cropById);
    final watchouts = actions
        .where((action) => action.type == _TodayActionType.watch)
        .toList(growable: false);

    final jobs = actions
        .where((action) => action.type != _TodayActionType.watch)
        .toList(growable: false);

    return _TodayData(
      settings: settings,
      profile: profile,
      crops: crops,
      cropById: cropById,
      region: region,
      jobs: jobs,
      watchouts: watchouts,
      myCrops: myCrops,
      wishlistCrops: wishlistCrops,
      logs: logs,
      month: now.month,
    );
  }

  Future<void> _addQuickLog({
    required String type,
    required String label,
  }) async {
    HapticFeedback.selectionClick();

    await _logRepository.addLog(
      GardenQuickLog(
        type: type,
        label: label,
        createdAtIso: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label logged.')),
    );

    setState(() {
      _todayFuture = _loadToday();
    });
  }

  void _openActionSheet(_TodayAction action) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    _IconBubble(
                      icon: action.type.icon,
                      color: action.type.color,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.reason,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...action.steps.map((step) => _StepRow(text: step)),
                if (action.cropId != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final crop = action.cropId == null
                          ? null
                          : action.cropById[action.cropId];

                      if (crop == null) {
                        return;
                      }

                      Navigator.pop(context);
                      _openCrop(crop);
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Open crop details'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCrop(Crop crop) {
    HapticFeedback.selectionClick();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropDetailScreen(crop: crop),
      ),
    );
  }

  void _openScreen(Widget screen) {
    HapticFeedback.selectionClick();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh today',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _todayFuture = _loadToday());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_TodayData>(
        future: _todayFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load today: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No garden data found.'));
          }

          final bestJob = data.jobs.isEmpty ? null : data.jobs.first;

          return Stack(
            children: [
              Positioned(
                top: -130,
                right: -120,
                child: _SoftBlob(
                  color: _mint.withValues(alpha: .86),
                  size: 270,
                ),
              ),
              Positioned(
                bottom: -190,
                left: -150,
                child: _SoftBlob(
                  color: _sun.withValues(alpha: .18),
                  size: 340,
                ),
              ),
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                children: [
                  _TodayHero(
                    data: data,
                    bestJob: bestJob,
                    onBestTap: bestJob == null
                        ? () => _openScreen(const CropCalendarScreen())
                        : () => _openActionSheet(bestJob),
                  ),
                  const SizedBox(height: 14),
                  _QuickLogPanel(
                    onLog: _addQuickLog,
                  ),
                  const SizedBox(height: 14),
                  _JobsPanel(
                    jobs: data.jobs,
                    onActionTap: _openActionSheet,
                    onOpenCalendar: () =>
                        _openScreen(const CropCalendarScreen()),
                  ),
                  const SizedBox(height: 14),
                  _MyCropsPanel(
                    crops: data.myCrops,
                    wishlistCrops: data.wishlistCrops,
                    onCropTap: _openCrop,
                    onEditPassport: () =>
                        _openScreen(const GardenProfileScreen()),
                  ),
                  const SizedBox(height: 14),
                  _WatchoutsPanel(
                    watchouts: data.watchouts,
                    onActionTap: _openActionSheet,
                    onOpenPests: () => _openScreen(const PestGuideScreen()),
                  ),
                  const SizedBox(height: 14),
                  _RecentLogsPanel(
                    logs: data.logs,
                    onOpenJournal: () => _openScreen(const WeeklyTasksScreen()),
                  ),
                  const SizedBox(height: 14),
                  _ShortcutPanel(
                    onOpenWater: () =>
                        _openScreen(const WateringPlannerScreen()),
                    onOpenCrops: () => _openScreen(const CropGuideScreen()),
                    onOpenCalendar: () =>
                        _openScreen(const CropCalendarScreen()),
                    onOpenPassport: () =>
                        _openScreen(const GardenProfileScreen()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.data,
    required this.bestJob,
    required this.onBestTap,
  });

  final _TodayData data;
  final _TodayAction? bestJob;
  final VoidCallback onBestTap;

  @override
  Widget build(BuildContext context) {
    final regionName =
        data.region?.name ?? _formatValue(data.settings.regionId);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_leafDark, _leaf, _moss],
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
            right: -24,
            bottom: -34,
            child: Icon(
              Icons.eco_outlined,
              size: 152,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassPill(label: '$regionName · ${_monthName(data.month)}'),
              const SizedBox(height: 20),
              const Text(
                'Today in\nyour garden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.profile.setupComplete
                    ? '${data.myCrops.length} crops in your passport · ${data.jobs.length} useful jobs today.'
                    : 'Create a Garden Passport to make this screen more personal.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .86),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onBestTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          bestJob?.type.icon ?? Icons.calendar_month_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bestJob?.title ?? 'Open planting calendar',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLogPanel extends StatelessWidget {
  const _QuickLogPanel({required this.onLog});

  final Future<void> Function({
    required String type,
    required String label,
  }) onLog;

  @override
  Widget build(BuildContext context) {
    final logs = [
      const _QuickLogButtonData(
        type: 'watered',
        label: 'Watered',
        icon: Icons.water_drop_outlined,
        color: _leaf,
      ),
      const _QuickLogButtonData(
        type: 'sowed',
        label: 'Sowed',
        icon: Icons.grass_outlined,
        color: _moss,
      ),
      const _QuickLogButtonData(
        type: 'transplanted',
        label: 'Transplanted',
        icon: Icons.move_down_outlined,
        color: _clay,
      ),
      const _QuickLogButtonData(
        type: 'harvested',
        label: 'Harvested',
        icon: Icons.shopping_basket_outlined,
        color: _berry,
      ),
      const _QuickLogButtonData(
        type: 'pest_seen',
        label: 'Pest seen',
        icon: Icons.bug_report_outlined,
        color: _leafDark,
      ),
    ];

    return _Panel(
      title: 'Quick log',
      subtitle: 'Tap once to remember what happened today.',
      icon: Icons.add_task_outlined,
      color: _leaf,
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = logs[index];

            return _QuickLogButton(
              data: item,
              onTap: () => onLog(type: item.type, label: item.label),
            );
          },
        ),
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({
    required this.data,
    required this.onTap,
  });

  final _QuickLogButtonData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        color: data.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, color: data.color),
                const Spacer(),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobsPanel extends StatelessWidget {
  const _JobsPanel({
    required this.jobs,
    required this.onActionTap,
    required this.onOpenCalendar,
  });

  final List<_TodayAction> jobs;
  final ValueChanged<_TodayAction> onActionTap;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Best jobs now',
      subtitle:
          'Prioritised from your region, season, passport, and crop rules.',
      icon: Icons.checklist_outlined,
      color: _leaf,
      child: jobs.isEmpty
          ? _EmptyPanelAction(
              text: 'No urgent jobs found. Open the calendar to look ahead.',
              icon: Icons.calendar_month_outlined,
              color: _leaf,
              onTap: onOpenCalendar,
            )
          : Column(
              children: jobs.take(6).map((job) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActionCard(
                    action: job,
                    onTap: () => onActionTap(job),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _MyCropsPanel extends StatelessWidget {
  const _MyCropsPanel({
    required this.crops,
    required this.wishlistCrops,
    required this.onCropTap,
    required this.onEditPassport,
  });

  final List<Crop> crops;
  final List<Crop> wishlistCrops;
  final ValueChanged<Crop> onCropTap;
  final VoidCallback onEditPassport;

  @override
  Widget build(BuildContext context) {
    final shownCrops = crops.isEmpty ? wishlistCrops : crops;

    return _Panel(
      title: crops.isEmpty ? 'Your plant shelf' : 'Your crops this week',
      subtitle: crops.isEmpty
          ? 'Add crops to your Garden Passport to make this screen personal.'
          : 'Your active crops come first.',
      icon: Icons.yard_outlined,
      color: _moss,
      child: shownCrops.isEmpty
          ? _EmptyPanelAction(
              text: 'Create your Garden Passport.',
              icon: Icons.yard_outlined,
              color: _moss,
              onTap: onEditPassport,
            )
          : SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: shownCrops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final crop = shownCrops[index];

                  return _CropMiniCard(
                    crop: crop,
                    onTap: () => onCropTap(crop),
                  );
                },
              ),
            ),
    );
  }
}

class _WatchoutsPanel extends StatelessWidget {
  const _WatchoutsPanel({
    required this.watchouts,
    required this.onActionTap,
    required this.onOpenPests,
  });

  final List<_TodayAction> watchouts;
  final ValueChanged<_TodayAction> onActionTap;
  final VoidCallback onOpenPests;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Watch-outs',
      subtitle: 'Things that can quietly cause trouble.',
      icon: Icons.visibility_outlined,
      color: _berry,
      child: watchouts.isEmpty
          ? _EmptyPanelAction(
              text:
                  'No major watch-outs. Open Plant Doctor if something looks wrong.',
              icon: Icons.bug_report_outlined,
              color: _berry,
              onTap: onOpenPests,
            )
          : Column(
              children: watchouts.take(4).map((watchout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActionCard(
                    action: watchout,
                    onTap: () => onActionTap(watchout),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _RecentLogsPanel extends StatelessWidget {
  const _RecentLogsPanel({
    required this.logs,
    required this.onOpenJournal,
  });

  final List<GardenQuickLog> logs;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent garden memory',
      subtitle: 'Quick logs stay on this device for now.',
      icon: Icons.history_outlined,
      color: _clay,
      child: logs.isEmpty
          ? _EmptyPanelAction(
              text: 'No quick logs yet. Use Quick log above after garden jobs.',
              icon: Icons.add_task_outlined,
              color: _clay,
              onTap: onOpenJournal,
            )
          : Column(
              children: logs.take(5).map((log) {
                return _LogRow(log: log);
              }).toList(growable: false),
            ),
    );
  }
}

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel({
    required this.onOpenWater,
    required this.onOpenCrops,
    required this.onOpenCalendar,
    required this.onOpenPassport,
  });

  final VoidCallback onOpenWater;
  final VoidCallback onOpenCrops;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenPassport;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Open a tool',
      subtitle: 'Fast paths when you already know what you need.',
      icon: Icons.apps_outlined,
      color: _leafDark,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ShortcutChip(
            label: 'Water',
            icon: Icons.water_drop_outlined,
            color: _leaf,
            onTap: onOpenWater,
          ),
          _ShortcutChip(
            label: 'Crops',
            icon: Icons.menu_book_outlined,
            color: _moss,
            onTap: onOpenCrops,
          ),
          _ShortcutChip(
            label: 'Calendar',
            icon: Icons.calendar_month_outlined,
            color: _clay,
            onTap: onOpenCalendar,
          ),
          _ShortcutChip(
            label: 'Passport',
            icon: Icons.yard_outlined,
            color: _berry,
            onTap: onOpenPassport,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
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
          _PanelHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(icon: icon, color: color, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 20,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onTap,
  });

  final _TodayAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.type.color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              _IconBubble(
                icon: action.type.icon,
                color: action.type.color,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: action.type.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropMiniCard extends StatelessWidget {
  const _CropMiniCard({
    required this.crop,
    required this.onTap,
  });

  final Crop crop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: _leaf.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBubble(
                  icon: crop.containerFriendly
                      ? Icons.inventory_2_outlined
                      : Icons.eco_outlined,
                  color: _leaf,
                  size: 42,
                ),
                const Spacer(),
                Text(
                  crop.commonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${crop.spacingCm} cm · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax}d',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPanelAction extends StatelessWidget {
  const _EmptyPanelAction({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final GardenQuickLog log;

  @override
  Widget build(BuildContext context) {
    final color = _colorForLog(log.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          _IconBubble(
            icon: _iconForLog(log.type),
            color: color,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${log.label} · ${_shortDate(log.createdAt)}',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, color: _leaf, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label});

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

class _QuickLogButtonData {
  const _QuickLogButtonData({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String type;
  final String label;
  final IconData icon;
  final Color color;
}

class _TodayData {
  const _TodayData({
    required this.settings,
    required this.profile,
    required this.crops,
    required this.cropById,
    required this.region,
    required this.jobs,
    required this.watchouts,
    required this.myCrops,
    required this.wishlistCrops,
    required this.logs,
    required this.month,
  });

  final AppSettings settings;
  final GardenProfile profile;
  final List<Crop> crops;
  final Map<String, Crop> cropById;
  final NzRegion? region;
  final List<_TodayAction> jobs;
  final List<_TodayAction> watchouts;
  final List<Crop> myCrops;
  final List<Crop> wishlistCrops;
  final List<GardenQuickLog> logs;
  final int month;
}

class _TodayAction {
  const _TodayAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.priority,
    required this.steps,
    required this.cropById,
    this.cropId,
  });

  final _TodayActionType type;
  final String title;
  final String subtitle;
  final String reason;
  final int priority;
  final List<String> steps;
  final Map<String, Crop> cropById;
  final String? cropId;
}

enum _TodayActionType {
  sow,
  transplant,
  plant,
  harvest,
  watch,
  prep,
}

extension _TodayActionTypePresentation on _TodayActionType {
  String get label {
    return switch (this) {
      _TodayActionType.sow => 'Sow',
      _TodayActionType.transplant => 'Transplant',
      _TodayActionType.plant => 'Plant',
      _TodayActionType.harvest => 'Harvest',
      _TodayActionType.watch => 'Watch',
      _TodayActionType.prep => 'Prep',
    };
  }

  IconData get icon {
    return switch (this) {
      _TodayActionType.sow => Icons.grass_outlined,
      _TodayActionType.transplant => Icons.move_down_outlined,
      _TodayActionType.plant => Icons.spa_outlined,
      _TodayActionType.harvest => Icons.shopping_basket_outlined,
      _TodayActionType.watch => Icons.visibility_outlined,
      _TodayActionType.prep => Icons.construction_outlined,
    };
  }

  Color get color {
    return switch (this) {
      _TodayActionType.sow => _leaf,
      _TodayActionType.transplant => _clay,
      _TodayActionType.plant => _moss,
      _TodayActionType.harvest => _berry,
      _TodayActionType.watch => _leafDark,
      _TodayActionType.prep => _muted,
    };
  }
}

List<_TodayAction> _buildActions({
  required int month,
  required AppSettings settings,
  required GardenProfile profile,
  required List<Crop> crops,
  required Map<String, Crop> cropById,
  required List<PlantingRule> rules,
}) {
  final actions = <_TodayAction>[];
  final avoided = profile.avoidedCropIds.toSet();

  final relevantRules = rules
      .where((rule) => rule.appliesToRegion(settings.regionId))
      .where((rule) => rule.appliesToMonth(month))
      .where((rule) => cropById.containsKey(rule.cropId))
      .where((rule) => !avoided.contains(rule.cropId))
      .toList(growable: false);

  for (final rule in relevantRules) {
    final crop = cropById[rule.cropId]!;
    final type = _typeForMethod(rule.method);

    actions.add(
      _TodayAction(
        type: type,
        title: _titleForRule(type, crop),
        subtitle: _subtitleForCrop(crop, settings, profile),
        reason: rule.riskNote,
        priority: _priorityForCropAction(crop, type, settings, profile),
        steps: _stepsForCropAction(crop, type, settings),
        cropId: crop.id,
        cropById: cropById,
      ),
    );
  }

  for (final rule in rules.where((rule) => cropById.containsKey(rule.cropId))) {
    final crop = cropById[rule.cropId]!;
    if (avoided.contains(crop.id)) {
      continue;
    }

    final harvestStart = _offsetMonth(
      rule.startMonth,
      (crop.daysToHarvestMin / 30).floor(),
    );
    final harvestEnd = _offsetMonth(
      rule.endMonth,
      (crop.daysToHarvestMax / 30).ceil(),
    );

    if (!_monthInRange(
        month: month, startMonth: harvestStart, endMonth: harvestEnd)) {
      continue;
    }

    if (!rule.appliesToRegion(settings.regionId)) {
      continue;
    }

    actions.add(
      _TodayAction(
        type: _TodayActionType.harvest,
        title: 'Check ${crop.commonName}',
        subtitle: 'Possible harvest window.',
        reason:
            'Estimated from planting window and ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days to harvest.',
        priority: _priorityForCropAction(
            crop, _TodayActionType.harvest, settings, profile),
        steps: const [
          'Check mature plants before watering or disturbing nearby roots.',
          'Harvest gently and pick regularly for crops that keep producing.',
          'Log the harvest if you want a record of what performed well.',
        ],
        cropId: crop.id,
        cropById: cropById,
      ),
    );
  }

  actions.addAll(_watchoutActions(month, settings, profile, cropById));

  if (actions
      .where((action) => action.type != _TodayActionType.watch)
      .isEmpty) {
    actions.add(
      _TodayAction(
        type: _TodayActionType.prep,
        title: 'Prepare beds',
        subtitle: 'Quiet month. Improve soil and tools.',
        reason: 'Good preparation makes the next planting window easier.',
        priority: 48,
        steps: const [
          'Top up beds or containers with compost.',
          'Clean seed trays, labels, and tools.',
          'Check irrigation, mulch, stakes, and netting.',
          'Look ahead to next month’s sowing windows.',
        ],
        cropById: cropById,
      ),
    );
  }

  actions.sort((a, b) {
    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    return a.title.compareTo(b.title);
  });

  return actions;
}

List<_TodayAction> _watchoutActions(
  int month,
  AppSettings settings,
  GardenProfile profile,
  Map<String, Crop> cropById,
) {
  final actions = <_TodayAction>[];

  if (settings.frostRisk == 'high' && month >= 4 && month <= 9) {
    actions.add(
      _TodayAction(
        type: _TodayActionType.watch,
        title: 'Watch cold nights',
        subtitle: 'Frost risk is high in your settings.',
        reason:
            'Tender seedlings and warm-season crops can be damaged by cold nights.',
        priority: 86,
        steps: const [
          'Check overnight lows before transplanting tender crops.',
          'Use frost cloth, cloches, or move pots under cover.',
          'Avoid heavy watering late in the day before frost.',
        ],
        cropById: cropById,
      ),
    );
  }

  if (month == 12 || month == 1 || month == 2) {
    actions.add(
      _TodayAction(
        type: _TodayActionType.watch,
        title: 'Check dry soil',
        subtitle: 'Containers and seedlings dry fast in warm months.',
        reason:
            'Heat stress and uneven watering can cause bolting, wilting, and poor harvests.',
        priority: 78,
        steps: const [
          'Water early morning or evening.',
          'Check containers before garden beds.',
          'Mulch bare soil to reduce evaporation.',
          'Give leafy greens afternoon shade in hot spells.',
        ],
        cropById: cropById,
      ),
    );
  }

  if (settings.windExposure == 'exposed') {
    actions.add(
      _TodayAction(
        type: _TodayActionType.watch,
        title: 'Shelter seedlings',
        subtitle: 'Your garden is marked as exposed.',
        reason:
            'Wind dries seedlings, damages leaves, and increases transplant shock.',
        priority: 70,
        steps: const [
          'Use temporary wind cloth or shelter around new seedlings.',
          'Water before and after transplanting.',
          'Stake tall crops early.',
        ],
        cropById: cropById,
      ),
    );
  }

  if (profile.goalIds.contains('pest_control')) {
    actions.add(
      _TodayAction(
        type: _TodayActionType.watch,
        title: 'Check leaf undersides',
        subtitle: 'Pest prevention is one of your garden goals.',
        reason: 'Small pest problems are easier to handle before they spread.',
        priority: 66,
        steps: const [
          'Check under leaves for eggs, aphids, whitefly, caterpillars, or mites.',
          'Remove badly affected leaves if needed.',
          'Use netting early for brassicas and vulnerable seedlings.',
        ],
        cropById: cropById,
      ),
    );
  }

  return actions;
}

_TodayActionType _typeForMethod(String method) {
  return switch (method) {
    'transplant' => _TodayActionType.transplant,
    'plant_tubers' => _TodayActionType.plant,
    'plant_crowns' => _TodayActionType.plant,
    _ => _TodayActionType.sow,
  };
}

String _titleForRule(_TodayActionType type, Crop crop) {
  return switch (type) {
    _TodayActionType.sow => 'Sow ${crop.commonName}',
    _TodayActionType.transplant => 'Move ${crop.commonName}',
    _TodayActionType.plant => 'Plant ${crop.commonName}',
    _TodayActionType.harvest => 'Harvest ${crop.commonName}',
    _TodayActionType.watch => 'Watch ${crop.commonName}',
    _TodayActionType.prep => 'Prepare for ${crop.commonName}',
  };
}

String _subtitleForCrop(
  Crop crop,
  AppSettings settings,
  GardenProfile profile,
) {
  if (profile.growingCropIds.contains(crop.id)) {
    return 'In your Garden Passport.';
  }

  if (profile.wishlistCropIds.contains(crop.id)) {
    return 'On your want-to-grow shelf.';
  }

  if (settings.gardenType == 'container' && crop.containerFriendly) {
    return 'Good container option · ${crop.spacingCm} cm.';
  }

  if (crop.beginnerFriendly) {
    return 'Beginner-friendly · ${crop.spacingCm} cm.';
  }

  return '${crop.spacingCm} cm · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days.';
}

int _priorityForCropAction(
  Crop crop,
  _TodayActionType type,
  AppSettings settings,
  GardenProfile profile,
) {
  var score = 40;

  score += switch (type) {
    _TodayActionType.sow => 15,
    _TodayActionType.transplant => 16,
    _TodayActionType.plant => 14,
    _TodayActionType.harvest => 8,
    _TodayActionType.watch => 6,
    _TodayActionType.prep => 2,
  };

  if (profile.growingCropIds.contains(crop.id)) {
    score += 40;
  }

  if (profile.wishlistCropIds.contains(crop.id)) {
    score += 20;
  }

  if (profile.experienceLevel == 'beginner' && crop.beginnerFriendly) {
    score += 14;
  }

  if (settings.gardenType == 'container') {
    score += crop.containerFriendly ? 12 : -10;
  }

  if (settings.frostRisk == 'high' && crop.frostTender) {
    score -= 12;
  }

  if (crop.beginnerFriendly) {
    score += 6;
  }

  return score;
}

List<String> _stepsForCropAction(
  Crop crop,
  _TodayActionType type,
  AppSettings settings,
) {
  return switch (type) {
    _TodayActionType.sow => [
        'Prepare a fine, weed-free seed bed or seed tray.',
        'Sow small batches rather than one large batch.',
        'Aim for ${crop.spacingCm} cm final spacing.',
        'Water gently and keep the surface evenly moist.',
        if (crop.frostTender || settings.frostRisk == 'high')
          'Use cover or wait for warmer nights if frost is possible.',
      ],
    _TodayActionType.transplant => [
        'Harden seedlings off before moving them outside.',
        'Water seedlings and the bed before transplanting.',
        'Plant at about ${crop.spacingCm} cm spacing.',
        'Water in well and shade or shelter for the first day if needed.',
        if (settings.windExposure == 'exposed')
          'Use temporary wind shelter while seedlings settle.',
      ],
    _TodayActionType.plant => [
        'Prepare loose, free-draining soil with compost.',
        'Check spacing before planting: about ${crop.spacingCm} cm.',
        'Plant at the right depth for tubers, cloves, crowns, or divisions.',
        'Water in well, then avoid waterlogging.',
      ],
    _TodayActionType.harvest => [
        'Check mature plants every few days.',
        'Harvest gently to avoid damaging nearby growth.',
        'Pick regularly for crops that keep producing.',
      ],
    _TodayActionType.watch => [
        'Check plants closely before the issue gets worse.',
      ],
    _TodayActionType.prep => [
        'Prepare beds, trays, labels, compost, mulch, and supports.',
      ],
  };
}

List<Crop> _cropsForIds(List<String> ids, Map<String, Crop> cropById) {
  return ids.map((id) => cropById[id]).whereType<Crop>().toList(growable: false)
    ..sort((a, b) => a.commonName.compareTo(b.commonName));
}

NzRegion? _findRegion(List<NzRegion> regions, String regionId) {
  for (final region in regions) {
    if (region.id == regionId) {
      return region;
    }
  }

  return null;
}

IconData _iconForLog(String type) {
  return switch (type) {
    'watered' => Icons.water_drop_outlined,
    'sowed' => Icons.grass_outlined,
    'transplanted' => Icons.move_down_outlined,
    'harvested' => Icons.shopping_basket_outlined,
    'pest_seen' => Icons.bug_report_outlined,
    _ => Icons.edit_note_outlined,
  };
}

Color _colorForLog(String type) {
  return switch (type) {
    'watered' => _leaf,
    'sowed' => _moss,
    'transplanted' => _clay,
    'harvested' => _berry,
    'pest_seen' => _leafDark,
    _ => _muted,
  };
}

int _offsetMonth(int month, int offset) {
  final zeroBased = month - 1 + offset;
  return (zeroBased % 12) + 1;
}

bool _monthInRange({
  required int month,
  required int startMonth,
  required int endMonth,
}) {
  if (startMonth <= endMonth) {
    return month >= startMonth && month <= endMonth;
  }

  return month >= startMonth || month <= endMonth;
}

String _shortDate(DateTime date) {
  return '${date.day} ${_shortMonthName(date.month)}';
}

String _monthName(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

String _shortMonthName(int month) {
  return _monthName(month).substring(0, 3);
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
