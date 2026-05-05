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

class FriendlyHomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('NZ Veg Garden'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: canvas)),
          Positioned(top: -120, right: -120, child: _Blob(color: mint.withOpacity(.95), size: 270)),
          Positioned(bottom: -140, left: -120, child: _Blob(color: const Color(0xFFF4C86A).withOpacity(.22), size: 290)),
          FutureBuilder<_HomeData>(
            future: _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Could not load garden data.')));
              }

              final data = snapshot.data;
              if (data == null) return const Center(child: Text('No garden data found.'));

              final firstCrop = data.plantableCrops.isEmpty ? null : data.plantableCrops.first;
              final regionName = data.selectedRegion?.name ?? 'Your region';
              final cards = <Widget>[
                _TodayPage(regionName: regionName, settings: data.settings, firstCrop: firstCrop),
                _SowPage(crops: data.plantableCrops.take(8).toList()),
                const _PrunePage(),
                const _ToolsPage(),
                _PickPage(crops: data.recommendedCrops),
              ];

              return PageView.builder(
                padEnds: false,
                controller: PageController(viewportFraction: .88),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      index == 0 ? 16 : 8,
                      MediaQuery.paddingOf(context).top + 72,
                      index == cards.length - 1 ? 16 : 8,
                      118,
                    ),
                    child: cards[index],
                  );
                },
              );
            },
          ),
        ],
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

class _TodayPage extends StatelessWidget {
  const _TodayPage({required this.regionName, required this.settings, required this.firstCrop});

  final String regionName;
  final AppSettings settings;
  final Crop? firstCrop;

  @override
  Widget build(BuildContext context) {
    return _HeroPanel(
      title: 'Swipe your\ngarden',
      subtitle: 'Quick actions, no scrolling down.',
      iconAsset: 'assets/icons/seedling.svg',
      chips: [regionName, _format(settings.frostRisk), _format(settings.windExposure)],
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
              _openCrop(context, firstCrop!);
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionRow(
          iconAsset: 'assets/icons/pruning_shears.svg',
          title: 'Prune',
          subtitle: 'Trees, shrubs, hedges',
          color: FriendlyHomeScreen.clay,
          onTap: () => _openScreen(context, const PruningGuideScreen()),
        ),
      ],
    );
  }
}

class _SowPage extends StatelessWidget {
  const _SowPage({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Sow now',
      label: '${crops.length} crops',
      iconAsset: 'assets/icons/seedling.svg',
      child: crops.isEmpty
          ? const Text('No sowing picks this month.', style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700))
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: crops.map((crop) => _CropChip(crop: crop)).toList(),
            ),
    );
  }
}

class _PrunePage extends StatelessWidget {
  const _PrunePage();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Pruning',
      label: 'guide',
      iconAsset: 'assets/icons/pruning_shears.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trees, shrubs, bushes, hedges, berries and vines.', style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 18),
          _ActionRow(
            iconAsset: 'assets/icons/pruning_shears.svg',
            title: 'Open pruning guide',
            subtitle: 'Season cards + categories',
            color: FriendlyHomeScreen.clay,
            onTap: () => _openScreen(context, const PruningGuideScreen()),
          ),
        ],
      ),
    );
  }
}

class _ToolsPage extends StatelessWidget {
  const _ToolsPage();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Tools',
      label: 'quick access',
      iconAsset: 'assets/icons/crop_guide.svg',
      child: Column(
        children: [
          _ToolButton(asset: 'assets/icons/crop_guide.svg', label: 'Crop guide', onTap: () => _openScreen(context, const CropGuideScreen())),
          const SizedBox(height: 10),
          _ToolButton(asset: 'assets/icons/calendar_leaf.svg', label: 'Calendar', onTap: () => _openScreen(context, const CropCalendarScreen())),
          const SizedBox(height: 10),
          _ToolButton(asset: 'assets/icons/task_sprout.svg', label: 'Tasks', onTap: () => _openScreen(context, const WeeklyTasksScreen())),
        ],
      ),
    );
  }
}

class _PickPage extends StatelessWidget {
  const _PickPage({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final best = crops.isEmpty ? null : crops.first;
    return _Panel(
      title: 'Best pick',
      label: 'easy start',
      iconAsset: 'assets/icons/weather_frost.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (best == null)
            const Text('Check sowing picks.', style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700))
          else
            _ActionRow(
              iconAsset: 'assets/icons/seedling.svg',
              title: best.commonName,
              subtitle: 'Beginner-friendly pick',
              color: FriendlyHomeScreen.leaf,
              onTap: () => _openCrop(context, best),
            ),
          const SizedBox(height: 18),
          const Text('Swipe left or right to move between Home sections.', style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700, height: 1.35)),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.title, required this.subtitle, required this.iconAsset, required this.chips, required this.children});

  final String title;
  final String subtitle;
  final String iconAsset;
  final List<String> chips;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18))],
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FriendlyHomeScreen.leafDark, FriendlyHomeScreen.leaf, FriendlyHomeScreen.moss]),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Wrap(spacing: 8, runSpacing: 8, children: chips.take(3).map((chip) => _GlassPill(label: chip)).toList())),
              SvgPicture.asset(iconAsset, width: 78, height: 78),
            ]),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 36, height: .96, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.78), fontWeight: FontWeight.w800)),
            const SizedBox(height: 22),
            ...children,
          ]),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.label, required this.iconAsset, required this.child});

  final String title;
  final String label;
  final String iconAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: FriendlyHomeScreen.surface, borderRadius: BorderRadius.circular(34), border: Border.all(color: FriendlyHomeScreen.border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 12))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Pill(label: label),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: FriendlyHomeScreen.ink, fontSize: 34, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
          ])),
          SvgPicture.asset(iconAsset, width: 76, height: 76),
        ]),
        const SizedBox(height: 22),
        child,
        const Spacer(),
        const Align(alignment: Alignment.bottomRight, child: _Pill(label: 'swipe →')),
      ]),
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
        borderRadius: BorderRadius.circular(24),
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(.18))),
          child: Row(children: [
            SvgPicture.asset(iconAsset, width: 46, height: 46),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w900, fontSize: 16)),
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

class _CropChip extends StatelessWidget {
  const _CropChip({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _openCrop(context, crop),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(color: FriendlyHomeScreen.mint, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 32, height: 32, alignment: Alignment.center, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Text(crop.commonName.characters.first.toUpperCase(), style: const TextStyle(color: FriendlyHomeScreen.leaf, fontWeight: FontWeight.w900))),
            const SizedBox(width: 8),
            Text(crop.commonName, style: const TextStyle(color: FriendlyHomeScreen.leafDark, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.asset, required this.label, required this.onTap});

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionRow(iconAsset: asset, title: label, subtitle: 'Open', color: FriendlyHomeScreen.leaf, onTap: onTap);
  }
}

class _CropSheet extends StatelessWidget {
  const _CropSheet({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SvgPicture.asset('assets/icons/seedling.svg', width: 64, height: 64),
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
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); _snack(context, '${crop.commonName} saved for later'); }, icon: const Icon(Icons.add), label: const Text('Save for later'))),
      ]),
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

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)));
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = Colors.white.withOpacity(.10);
    final stemPaint = Paint()..color = Colors.white.withOpacity(.13)..strokeWidth = 2..style = PaintingStyle.stroke;
    final baseX = size.width * .70;
    final baseY = size.height * .98;
    for (var i = 0; i < 6; i++) {
      final dx = baseX + (i - 2.5) * 23;
      final height = 82.0 + i * 9;
      final path = Path()..moveTo(dx, baseY)..quadraticBezierTo(dx - 18, baseY - height * .45, dx + 4, baseY - height);
      canvas.drawPath(path, stemPaint);
      canvas.save();
      canvas.translate(dx + 2, baseY - height * .70);
      canvas.rotate(-.55 + i * .18);
      canvas.drawOval(const Rect.fromLTWH(-8, -18, 18, 36), leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _openCrop(BuildContext context, Crop crop) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => _CropSheet(crop: crop));
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
