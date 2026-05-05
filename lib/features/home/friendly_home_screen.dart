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
          Positioned(top: 250, left: -150, child: _Blob(color: const Color(0xFFF4C86A).withOpacity(.22), size: 290)),
          FutureBuilder<_HomeData>(
            future: _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load garden data.')));
              }

              final data = snapshot.data;
              if (data == null) return const Center(child: Text('No garden data found.'));

              final firstCrop = data.plantableCrops.isEmpty ? null : data.plantableCrops.first;
              final regionName = data.selectedRegion?.name ?? 'Your region';

              return ListView(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 72, 16, 118),
                children: [
                  _Hero(regionName: regionName, settings: data.settings),
                  const SizedBox(height: 18),
                  _SectionHeader(title: 'Today', label: 'start here'),
                  const SizedBox(height: 10),
                  _MainActions(
                    firstCrop: firstCrop,
                    onSow: () {
                      if (firstCrop == null) {
                        _snack(context, 'No sowing picks for this month.');
                      } else {
                        _openCrop(context, firstCrop);
                      }
                    },
                    onPrune: () => _openScreen(context, const PruningGuideScreen()),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(title: 'Sow now', label: '${data.plantableCrops.length} crops'),
                  const SizedBox(height: 10),
                  _SowScroller(crops: data.plantableCrops.take(8).toList()),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: 'Tools', label: 'quick tap'),
                  const SizedBox(height: 10),
                  const _ToolStrip(),
                  const SizedBox(height: 18),
                  _BeginnerPickCard(crops: data.recommendedCrops),
                ],
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

class _Hero extends StatelessWidget {
  const _Hero({required this.regionName, required this.settings});

  final String regionName;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), boxShadow: const [BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FriendlyHomeScreen.leafDark, FriendlyHomeScreen.leaf, FriendlyHomeScreen.moss]),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _GlassPill(icon: Icons.place_outlined, label: regionName),
                      const SizedBox(height: 18),
                      const Text('What should\nI do today?', style: TextStyle(color: Colors.white, fontSize: 34, height: .96, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _GlassPill(icon: Icons.ac_unit_outlined, label: _format(settings.frostRisk)),
                        _GlassPill(icon: Icons.air_outlined, label: _format(settings.windExposure)),
                      ]),
                    ]),
                  ),
                  SvgPicture.asset('assets/icons/seedling.svg', width: 80, height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  const _MainActions({required this.firstCrop, required this.onSow, required this.onPrune});

  final Crop? firstCrop;
  final VoidCallback onSow;
  final VoidCallback onPrune;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.04,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _BigCard(asset: 'assets/icons/seedling.svg', title: 'Sow', subtitle: firstCrop?.commonName ?? 'No picks', color: FriendlyHomeScreen.leaf, onTap: onSow),
        _BigCard(asset: 'assets/icons/pruning_shears.svg', title: 'Prune', subtitle: 'Trees & shrubs', color: FriendlyHomeScreen.clay, onTap: onPrune),
      ],
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.asset, required this.title, required this.subtitle, required this.color, required this.onTap});

  final String asset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: FriendlyHomeScreen.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: color.withOpacity(.28), width: 1.4), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 12))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SvgPicture.asset(asset, width: 62, height: 62),
            const Spacer(),
            Text(title, style: const TextStyle(color: FriendlyHomeScreen.ink, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            const SizedBox(height: 6),
            _Pill(label: subtitle, color: color),
          ]),
        ),
      ),
    );
  }
}

class _SowScroller extends StatelessWidget {
  const _SowScroller({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) return const _Card(child: Text('No sowing picks this month.'));
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: crops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CropCard(crop: crops[index]),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openCrop(context, crop),
        child: Ink(
          width: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: FriendlyHomeScreen.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: FriendlyHomeScreen.border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset('assets/icons/seedling.svg', width: 58, height: 58),
            const SizedBox(height: 10),
            Text(crop.commonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 7),
            if (crop.frostTender) const _Pill(label: 'protect', color: FriendlyHomeScreen.clay) else const _Pill(label: 'hardy'),
          ]),
        ),
      ),
    );
  }
}

class _ToolStrip extends StatelessWidget {
  const _ToolStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        _ToolCard(asset: 'assets/icons/crop_guide.svg', label: 'Crops', onTap: () => _openScreen(context, const CropGuideScreen())),
        const SizedBox(width: 12),
        _ToolCard(asset: 'assets/icons/calendar_leaf.svg', label: 'Calendar', onTap: () => _openScreen(context, const CropCalendarScreen())),
        const SizedBox(width: 12),
        _ToolCard(asset: 'assets/icons/task_sprout.svg', label: 'Tasks', onTap: () => _openScreen(context, const WeeklyTasksScreen())),
        const SizedBox(width: 12),
        _ToolCard(asset: 'assets/icons/pruning_shears.svg', label: 'Prune', onTap: () => _openScreen(context, const PruningGuideScreen())),
      ]),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.asset, required this.label, required this.onTap});

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Ink(
          width: 112,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: FriendlyHomeScreen.surface, borderRadius: BorderRadius.circular(26), border: Border.all(color: FriendlyHomeScreen.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(asset, width: 52, height: 52),
            const SizedBox(height: 9),
            Text(label, style: const TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _BeginnerPickCard extends StatelessWidget {
  const _BeginnerPickCard({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final best = crops.isEmpty ? null : crops.first;
    return _Card(
      child: Row(children: [
        SvgPicture.asset('assets/icons/weather_frost.svg', width: 54, height: 54),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Best beginner pick', style: TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(best?.commonName ?? 'Check sowing picks above', style: const TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.label});

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.3))),
      _Pill(label: label),
    ]);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: FriendlyHomeScreen.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: FriendlyHomeScreen.border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))]),
      child: child,
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
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(.20))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
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
