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
  static const sun = Color(0xFFF4C86A);

  @override
  State<FriendlyHomeScreen> createState() => _FriendlyHomeScreenState();
}

class _FriendlyHomeScreenState extends State<FriendlyHomeScreen> {
  final PageController _controller = PageController(viewportFraction: .94);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: FriendlyHomeScreen.canvas)),
          Positioned(top: -160, right: -136, child: _Blob(color: FriendlyHomeScreen.mint.withOpacity(.62), size: 300)),
          Positioned(bottom: -170, left: -160, child: _Blob(color: FriendlyHomeScreen.sun.withOpacity(.14), size: 320)),
          FutureBuilder<_HomeData>(
            future: _load(),
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
              final pages = <Widget>[
                _TodayCard(regionName: regionName, settings: data.settings, firstCrop: firstCrop),
                _SowCard(crops: data.plantableCrops.take(6).toList()),
                const _PruneCard(),
                const _ToolsCard(),
                _BestPickCard(crops: data.recommendedCrops),
              ];

              return Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          index == 0 ? 12 : 6,
                          topInset + 68,
                          index == pages.length - 1 ? 12 : 6,
                          122,
                        ),
                        child: pages[index],
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 78,
                    child: _PageDots(count: pages.length, activeIndex: _page),
                  ),
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.regionName, required this.settings, required this.firstCrop});

  final String regionName;
  final AppSettings settings;
  final Crop? firstCrop;

  @override
  Widget build(BuildContext context) {
    return _FramedCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 540;
          return Column(
            children: [
              Flexible(
                flex: compact ? 11 : 12,
                child: _TodayHero(regionName: regionName, settings: settings, compact: compact),
              ),
              SizedBox(height: compact ? 10 : 12),
              Flexible(
                flex: compact ? 8 : 7,
                child: _TodayActionsPanel(firstCrop: firstCrop, compact: compact),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.regionName, required this.settings, required this.compact});

  final String regionName;
  final AppSettings settings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FriendlyHomeScreen.leafDark, FriendlyHomeScreen.leaf, FriendlyHomeScreen.moss],
        ),
        borderRadius: BorderRadius.all(Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x22172D22), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
          Column(
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
                    width: compact ? 62 : 72,
                    height: compact ? 62 : 72,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: FriendlyHomeScreen.surface.withOpacity(.86),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.32)),
                    ),
                    child: SvgPicture.asset('assets/icons/seedling.svg'),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Your garden\ntoday',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 31 : 36,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              SizedBox(height: compact ? 7 : 10),
              Text(
                'Simple actions for right now.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(.82), fontSize: compact ? 13 : 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayActionsPanel extends StatelessWidget {
  const _TodayActionsPanel({required this.firstCrop, required this.compact});

  final Crop? firstCrop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: FriendlyHomeScreen.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, compact ? 6 : 8),
            child: Text(
              'Today’s actions',
              style: TextStyle(color: FriendlyHomeScreen.ink, fontSize: compact ? 15 : 16, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _ActionRow(
                    iconAsset: 'assets/icons/seedling.svg',
                    title: 'Sow now',
                    subtitle: firstCrop?.commonName ?? 'No picks this month',
                    color: FriendlyHomeScreen.leaf,
                    compact: true,
                    onTap: () {
                      if (firstCrop == null) {
                        _snack(context, 'No sowing picks for this month.');
                      } else {
                        _openCrop(context, firstCrop!);
                      }
                    },
                  ),
                ),
                SizedBox(height: compact ? 7 : 9),
                Expanded(
                  child: _ActionRow(
                    iconAsset: 'assets/icons/pruning_shears.svg',
                    title: 'Prune guide',
                    subtitle: 'Trees, shrubs and vines',
                    color: FriendlyHomeScreen.clay,
                    compact: true,
                    onTap: () => _openScreen(context, const PruningGuideScreen()),
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

class _SowCard extends StatelessWidget {
  const _SowCard({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    return _GardenCard(
      iconAsset: 'assets/icons/seedling.svg',
      label: '${crops.length} crops',
      title: 'Sow now',
      footer: 'Tap a crop for details',
      child: crops.isEmpty
          ? const _EmptyState(message: 'No sowing picks this month.')
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: crops.map((crop) => _CropChip(crop: crop)).toList(),
            ),
    );
  }
}

class _PruneCard extends StatelessWidget {
  const _PruneCard();

  @override
  Widget build(BuildContext context) {
    return _GardenCard(
      iconAsset: 'assets/icons/pruning_shears.svg',
      label: 'seasonal',
      title: 'Pruning',
      footer: 'Bushes · trees · vines · hedges',
      child: Column(
        children: [
          const _VisualCallout(
            icon: Icons.content_cut_outlined,
            title: 'Quick pruning guide',
            subtitle: 'See what to prune and when.',
            color: FriendlyHomeScreen.clay,
          ),
          const SizedBox(height: 14),
          _ActionRow(
            iconAsset: 'assets/icons/pruning_shears.svg',
            title: 'Open guide',
            subtitle: 'Season cards + categories',
            color: FriendlyHomeScreen.clay,
            onTap: () => _openScreen(context, const PruningGuideScreen()),
          ),
        ],
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    return _GardenCard(
      iconAsset: 'assets/icons/crop_guide.svg',
      label: 'shortcuts',
      title: 'Tools',
      footer: 'Fast access',
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

class _BestPickCard extends StatelessWidget {
  const _BestPickCard({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final best = crops.isEmpty ? null : crops.first;
    return _GardenCard(
      iconAsset: 'assets/icons/weather_frost.svg',
      label: 'easy start',
      title: 'Best pick',
      footer: 'Swipe back anytime',
      child: best == null
          ? const _EmptyState(message: 'Check sowing picks.')
          : Column(
              children: [
                _ActionRow(
                  iconAsset: 'assets/icons/seedling.svg',
                  title: best.commonName,
                  subtitle: 'Good beginner crop',
                  color: FriendlyHomeScreen.leaf,
                  onTap: () => _openCrop(context, best),
                ),
                const SizedBox(height: 14),
                const _VisualCallout(
                  icon: Icons.swipe_outlined,
                  title: 'Swipe cards',
                  subtitle: 'Home is card-first and horizontal.',
                  color: FriendlyHomeScreen.leaf,
                ),
              ],
            ),
    );
  }
}

class _FramedCard extends StatelessWidget {
  const _FramedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FriendlyHomeScreen.surface.withOpacity(.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: FriendlyHomeScreen.border),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class _GardenCard extends StatelessWidget {
  const _GardenCard({required this.iconAsset, required this.label, required this.title, required this.child, required this.footer});

  final String iconAsset;
  final String label;
  final String title;
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FriendlyHomeScreen.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: FriendlyHomeScreen.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Pill(label: label),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(color: FriendlyHomeScreen.ink, fontSize: 36, height: .96, fontWeight: FontWeight.w900, letterSpacing: -1.15)),
            ])),
            Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: FriendlyHomeScreen.mint.withOpacity(.72), borderRadius: BorderRadius.circular(24)),
              child: SvgPicture.asset(iconAsset),
            ),
          ]),
          const SizedBox(height: 24),
          child,
          const Spacer(),
          Row(children: [
            Expanded(child: Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w800))),
            const _Pill(label: 'swipe →'),
          ]),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.iconAsset, required this.title, required this.subtitle, required this.color, required this.onTap, this.compact = false});

  final String iconAsset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 38.0 : 48.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 7 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.96),
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            border: Border.all(color: color.withOpacity(.18)),
          ),
          child: Row(children: [
            Container(
              width: iconSize,
              height: iconSize,
              padding: EdgeInsets.all(compact ? 7 : 8),
              decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(compact ? 13 : 16)),
              child: SvgPicture.asset(iconAsset),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w900, fontSize: compact ? 15 : 17)),
              SizedBox(height: compact ? 1 : 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700, fontSize: compact ? 12 : 14)),
            ])),
            Icon(Icons.chevron_right, color: color, size: compact ? 24 : 28),
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
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(crop.commonName.characters.first.toUpperCase(), style: const TextStyle(color: FriendlyHomeScreen.leaf, fontWeight: FontWeight.w900)),
            ),
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

class _VisualCallout extends StatelessWidget {
  const _VisualCallout({required this.icon, required this.title, required this.subtitle, required this.color});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _VisualCallout(icon: Icons.info_outline, title: 'Nothing urgent', subtitle: message, color: FriendlyHomeScreen.leaf);
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? FriendlyHomeScreen.leaf : FriendlyHomeScreen.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
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

void _showReleaseSummary(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline update TL;DR',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Latest pushed version for the iPhone web/offline preview.',
              style: TextStyle(color: FriendlyHomeScreen.muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const _ReleaseBullet('Home screen card spacing tightened for iPhone.'),
            const _ReleaseBullet('Today’s actions no longer overlap inside the card.'),
            const _ReleaseBullet('Bottom navigation is framed and easier to tap.'),
            const _ReleaseBullet('iPhone web app metadata and safe-area support were added.'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ReleaseBullet extends StatelessWidget {
  const _ReleaseBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle, color: FriendlyHomeScreen.leaf, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: FriendlyHomeScreen.ink, fontWeight: FontWeight.w800, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
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
