from pathlib import Path

# Keep the iPhone web preview deterministic while the main UI is iterating.
# This replaces the horizontal home PageView with a vertical, scrollable home page
# so Safari gesture handling cannot trap users on the first card.

Path('lib/features/tasks/weekly_tasks_screen.dart').write_text(
    Path('lib/features/tasks/weekly_tasks_screen.dart').read_text().replace(
        'FontWeight.w650', 'FontWeight.w600'
    )
)

Path('lib/features/home/friendly_home_screen.dart').write_text(r'''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/nz_region.dart';
import '../calendar/crop_calendar_screen.dart';
import '../crops/crop_guide_screen.dart';
import '../pruning/pruning_guide_screen.dart';
import '../tasks/weekly_tasks_screen.dart';

class FriendlyHomeScreen extends StatefulWidget {
  const FriendlyHomeScreen({super.key});

  static const canvas = Color(0xFFF8F3E8);
  static const surface = Color(0xFFFFFCF5);
  static const ink = Color(0xFF172D22);
  static const muted = Color(0xFF66736A);
  static const leaf = Color(0xFF2F724B);
  static const leafDark = Color(0xFF17452F);
  static const moss = Color(0xFF8BA766);
  static const mint = Color(0xFFE7F0DB);
  static const clay = Color(0xFFC4793D);
  static const border = Color(0xFFE7DFCE);

  @override
  State<FriendlyHomeScreen> createState() => _FriendlyHomeScreenState();
}

class _FriendlyHomeScreenState extends State<FriendlyHomeScreen> {
  late final Future<_HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FriendlyHomeScreen.canvas,
      appBar: AppBar(
        title: const Text('NZ Veg Garden'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: FriendlyHomeScreen.leafDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 40),
                shape: const StadiumBorder(),
              ),
              onPressed: () => _showReleaseSummary(context),
              child: const Text('TL;DR', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load garden data.'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) return const Center(child: Text('No garden data found.'));

          final firstCrop = data.plantableCrops.isEmpty ? null : data.plantableCrops.first;
          final regionName = data.selectedRegion?.name ?? 'Your region';

          return ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 104),
            children: [
              _HeroCard(regionName: regionName, settings: data.settings),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Today’s actions',
                subtitle: 'Tap an action. No swiping required.',
                children: [
                  _ActionRow(
                    iconAsset: 'assets/icons/seedling.svg',
                    title: 'Sow now',
                    subtitle: firstCrop?.commonName ?? 'No picks this month',
                    color: FriendlyHomeScreen.leaf,
                    onTap: () {
                      if (firstCrop == null) {
                        _snack(context, 'No sowing picks for this month.');
                      } else {
                        _openCrop(context, firstCrop);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionRow(
                    iconAsset: 'assets/icons/pruning_shears.svg',
                    title: 'Prune guide',
                    subtitle: 'Trees, shrubs and vines',
                    color: FriendlyHomeScreen.clay,
                    onTap: () => _openScreen(context, const PruningGuideScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SowNowSection(crops: data.plantableCrops.take(8).toList()),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Tools',
                subtitle: 'Fast access',
                children: [
                  _ActionRow(iconAsset: 'assets/icons/crop_guide.svg', title: 'Crop guide', subtitle: 'Spacing, harvest timing and notes', color: FriendlyHomeScreen.leaf, onTap: () => _openScreen(context, const CropGuideScreen())),
                  const SizedBox(height: 10),
                  _ActionRow(iconAsset: 'assets/icons/calendar_leaf.svg', title: 'Calendar', subtitle: 'Monthly sowing and harvest windows', color: FriendlyHomeScreen.leaf, onTap: () => _openScreen(context, const CropCalendarScreen())),
                  const SizedBox(height: 10),
                  _ActionRow(iconAsset: 'assets/icons/task_sprout.svg', title: 'Weekly tasks', subtitle: 'Quick task details and check-offs', color: FriendlyHomeScreen.leaf, onTap: () => _openScreen(context, const WeeklyTasksScreen())),
                ],
              ),
              const SizedBox(height: 16),
              _BestPickSection(crops: data.recommendedCrops),
            ],
          );
        },
      ),
    );
  }

  static Future<_HomeData> _load() async {
    const settingsRepository = AppSettingsRepository();
    const dataRepository = GardenDataRepository();
    final now = DateTime.now();
    final settings = await settingsRepository.loadSettings();
    final regions = await dataRepository.loadRegions();
    final crops = await dataRepository.cropsForMonthAndRegion(month: now.month, regionId: settings.regionId);
    final selectedRegion = regions.where((region) => region.id == settings.regionId).firstOrNull;
    final recommended = _recommend(crops, settings);
    return _HomeData(settings: settings, selectedRegion: selectedRegion, plantableCrops: crops, recommendedCrops: recommended);
  }

  static List<Crop> _recommend(List<Crop> crops, AppSettings settings) {
    final scored = crops.map((crop) => _ScoredCrop(crop: crop, score: _score(crop, settings))).where((item) => item.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((item) => item.crop).take(5).toList();
  }

  static int _score(Crop crop, AppSettings settings) {
    var score = 0;
    if (crop.beginnerFriendly) score += 2;
    if (settings.gardenType == 'container' && crop.containerFriendly) score += 3;
    if (settings.frostRisk == 'high' && !crop.frostTender) score += 3;
    if (settings.frostRisk != 'high') score += 1;
    return score;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.regionName, required this.settings});

  final String regionName;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [FriendlyHomeScreen.leafDark, FriendlyHomeScreen.leaf, FriendlyHomeScreen.moss]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x22172D22), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GlassPill(label: regionName),
                    _GlassPill(label: _format(settings.frostRisk)),
                    _GlassPill(label: _format(settings.windExposure)),
                  ],
                ),
              ),
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FriendlyHomeScreen.surface.withOpacity(.88), borderRadius: BorderRadius.circular(22)),
                child: SvgPicture.asset('assets/icons/seedling.svg'),
              ),
            ],
          ),
          const SizedBox(height: 52),
          const Text('Your garden\ntoday', style: TextStyle(color: Colors.white, fontSize: 40, height: .94, fontWeight: FontWeight.w900, letterSpacing: -1.3)),
          const SizedBox(height: 10),
          Text('Scroll down for sowing, pruning and tools.', style: TextStyle(color: Colors.white.withOpacity(.84), fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FriendlyHomeScreen.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FriendlyHomeScreen.border),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: FriendlyHomeScreen.ink, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}

class _SowNowSection extends StatelessWidget {
  const _SowNowSection({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sow now',
      subtitle: 'Current crop options for your settings',
      children: crops.isEmpty
          ? [const _EmptyCallout(message: 'No sowing picks this month.')]
          : crops.map((crop) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _CropTile(crop: crop))).toList(),
    );
  }
}

class _BestPickSection extends StatelessWidget {
  const _BestPickSection({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final best = crops.isEmpty ? null : crops.first;
    return _SectionCard(
      title: 'Best pick',
      subtitle: 'Easy crop based on your settings',
      children: [
        if (best == null) const _EmptyCallout(message: 'Check sowing picks.') else _CropTile(crop: best),
      ],
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return _ActionRow(
      iconAsset: 'assets/icons/seedling.svg',
      title: crop.commonName,
      subtitle: '${crop.spacingCm} cm spacing · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
      color: FriendlyHomeScreen.leaf,
      onTap: () => _openCrop(context, crop),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.iconAsset, required this.title, required this.subtitle, required this.color, required this.onTap});

  final String iconAsset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.96), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(.18))),
          child: Row(children: [
            Container(width: 46, height: 46, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(15)), child: SvgPicture.asset(iconAsset)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: FriendlyHomeScreen.ink, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700)),
            ])),
            Icon(Icons.chevron_right, color: color),
          ]),
        ),
      ),
    );
  }
}

class _EmptyCallout extends StatelessWidget {
  const _EmptyCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FriendlyHomeScreen.mint.withOpacity(.72), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const Icon(Icons.info_outline, color: FriendlyHomeScreen.leaf),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: FriendlyHomeScreen.leafDark, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

class _CropSheet extends StatelessWidget {
  const _CropSheet({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SvgPicture.asset('assets/icons/seedling.svg', width: 58, height: 58),
            const SizedBox(width: 14),
            Expanded(child: Text(crop.commonName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Pill(label: '${crop.spacingCm} cm'),
            _Pill(label: '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days'),
            if (crop.containerFriendly) const _Pill(label: 'container'),
            if (crop.beginnerFriendly) const _Pill(label: 'easy'),
            if (crop.frostTender) const _Pill(label: 'protect', color: FriendlyHomeScreen.clay),
          ]),
          const SizedBox(height: 16),
          Text(crop.summary, style: const TextStyle(color: FriendlyHomeScreen.muted, height: 1.4, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { Navigator.pop(context); _snack(context, '${crop.commonName} saved for later'); }, icon: const Icon(Icons.add), label: const Text('Save for later'))),
        ]),
      ),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(.20))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = FriendlyHomeScreen.leaf});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

void _showReleaseSummary(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Offline update TL;DR', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Home now uses vertical scrolling. Sow now is directly below Today’s actions.', style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const _Bullet('Removed horizontal card dependency on iPhone Safari.'),
          const _Bullet('Sow now is a normal scroll section.'),
          const _Bullet('Tools and weekly tasks are still visible lower down.'),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))),
        ]),
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.check_circle, color: FriendlyHomeScreen.leaf, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w800, height: 1.35))),
      ]),
    );
  }
}

void _openCrop(BuildContext context, Crop crop) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true, builder: (_) => _CropSheet(crop: crop));
}

void _openScreen(BuildContext context, Widget screen) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

void _snack(BuildContext context, String message) {
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _format(String value) {
  return value.split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
}

class _HomeData {
  const _HomeData({required this.settings, required this.selectedRegion, required this.plantableCrops, required this.recommendedCrops});
  final AppSettings settings;
  final NzRegion? selectedRegion;
  final List<Crop> plantableCrops;
  final List<Crop> recommendedCrops;
}

class _ScoredCrop {
  const _ScoredCrop({required this.crop, required this.score});
  final Crop crop;
  final int score;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
''')
