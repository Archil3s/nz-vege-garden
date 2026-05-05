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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _canvas = Color(0xFFF8F3E8);
  static const _surface = Color(0xFFFFFCF5);
  static const _ink = Color(0xFF172D22);
  static const _muted = Color(0xFF66736A);
  static const _leaf = Color(0xFF2F724B);
  static const _leafDark = Color(0xFF17452F);
  static const _moss = Color(0xFF8BA766);
  static const _mint = Color(0xFFE7F0DB);
  static const _clay = Color(0xFFC4793D);
  static const _border = Color(0xFFE7DFCE);

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
          const Positioned.fill(child: ColoredBox(color: _canvas)),
          Positioned(
            top: -120,
            right: -120,
            child: RepaintBoundary(
              child: _SoftCircle(color: _mint.withOpacity(0.95), size: 270),
            ),
          ),
          Positioned(
            top: 250,
            left: -150,
            child: RepaintBoundary(
              child: _SoftCircle(color: const Color(0xFFF4C86A).withOpacity(0.22), size: 290),
            ),
          ),
          FutureBuilder<_HomeData>(
            future: _loadHomeData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load home data: ${snapshot.error}'),
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return const Center(child: Text('No home data found.'));
              }

              final regionName = data.selectedRegion?.name ?? 'Unknown region';

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 72,
                  16,
                  118,
                ),
                children: [
                  RepaintBoundary(
                    child: _HeroDashboardCard(
                      regionName: regionName,
                      data: data,
                      formatValue: _formatValue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: _HomeQuickAccessPanel(crops: data.plantableCrops)),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: _SowNowPanel(crops: data.plantableCrops)),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: _SummaryCards(data: data)),
                  const SizedBox(height: 16),
                  const RepaintBoundary(child: _QuickActionsCard()),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: _BestForSetupCard(
                      crops: data.recommendedCrops,
                      settings: data.settings,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'More to plant',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ),
                      _MiniPill(label: '${data.plantableCrops.length} options'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data.plantableCrops.isEmpty)
                    const _PrettyCard(
                      child: Text('No matching crops found for this month.'),
                    )
                  else
                    RepaintBoundary(
                      child: SizedBox(
                        height: 156,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: data.plantableCrops.take(8).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final crop = data.plantableCrops[index];
                            return _CropTapCard(crop: crop);
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<_HomeData> _loadHomeData() async {
    const settingsRepository = AppSettingsRepository();
    const dataRepository = GardenDataRepository();

    final now = DateTime.now();
    final settings = await settingsRepository.loadSettings();
    final regions = await dataRepository.loadRegions();
    final plantableCrops = await dataRepository.cropsForMonthAndRegion(
      month: now.month,
      regionId: settings.regionId,
    );

    final selectedRegion = regions.where((region) => region.id == settings.regionId).firstOrNull;
    final recommendedCrops = _recommendedCropsForSetup(
      crops: plantableCrops,
      settings: settings,
    );

    return _HomeData(
      settings: settings,
      selectedRegion: selectedRegion,
      plantableCrops: plantableCrops,
      recommendedCrops: recommendedCrops,
    );
  }

  List<Crop> _recommendedCropsForSetup({
    required List<Crop> crops,
    required AppSettings settings,
  }) {
    final scored = crops
        .map(
          (crop) => _ScoredCrop(
            crop: crop,
            score: _recommendationScore(crop: crop, settings: settings),
          ),
        )
        .where((item) => item.score > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }

        return a.crop.commonName.compareTo(b.crop.commonName);
      });

    return scored.map((item) => item.crop).take(5).toList(growable: false);
  }

  int _recommendationScore({
    required Crop crop,
    required AppSettings settings,
  }) {
    var score = 0;

    if (crop.beginnerFriendly) {
      score += 2;
    }

    if (settings.gardenType == 'container' && crop.containerFriendly) {
      score += 3;
    }

    if (settings.gardenType != 'container') {
      score += 1;
    }

    if (settings.frostRisk == 'high' && !crop.frostTender) {
      score += 3;
    }

    if (settings.frostRisk != 'high') {
      score += 1;
    }

    if (settings.windExposure == 'exposed' || settings.windExposure == 'coastal') {
      if (crop.category == 'herb' || crop.containerFriendly) {
        score += 1;
      }
    }

    return score;
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

void _openCropBottomSheet(BuildContext context, Crop crop) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _CropBottomSheet(crop: crop),
  );
}

class _HeroDashboardCard extends StatelessWidget {
  const _HeroDashboardCard({
    required this.regionName,
    required this.data,
    required this.formatValue,
  });

  final String regionName;
  final _HomeData data;
  final String Function(String) formatValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HomeScreen._leafDark, HomeScreen._leaf, HomeScreen._moss],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _LeafPatternPainter())),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GlassPill(icon: Icons.place_outlined, label: regionName),
                            const SizedBox(height: 18),
                            const Text(
                              'Sow, grow\nand prune',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                height: 0.96,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SvgIconBox(asset: 'assets/icons/seedling.svg', size: 74),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassPill(icon: Icons.ac_unit_outlined, label: 'Frost ${formatValue(data.settings.frostRisk)}'),
                      _GlassPill(icon: Icons.air_outlined, label: 'Wind ${formatValue(data.settings.windExposure)}'),
                      _GlassPill(icon: Icons.yard_outlined, label: formatValue(data.settings.gardenType)),
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
}

class _HomeQuickAccessPanel extends StatelessWidget {
  const _HomeQuickAccessPanel({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final firstCrop = crops.isEmpty ? null : crops.first;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _PriorityAccessCard(
          asset: 'assets/icons/seedling.svg',
          title: 'Sow now',
          subtitle: firstCrop?.commonName ?? 'Open picks',
          color: HomeScreen._leaf,
          onTap: () {
            if (firstCrop == null) {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No sowing picks for this month.')),
              );
              return;
            }

            _openCropBottomSheet(context, firstCrop);
          },
        ),
        _PriorityAccessCard(
          asset: 'assets/icons/pruning_shears.svg',
          title: 'Pruning',
          subtitle: 'Trees & shrubs',
          color: HomeScreen._clay,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PruningGuideScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _PriorityAccessCard extends StatelessWidget {
  const _PriorityAccessCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

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
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HomeScreen._surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.28), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(asset, width: 58, height: 58),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: HomeScreen._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              _MiniPill(label: subtitle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SowNowPanel extends StatelessWidget {
  const _SowNowPanel({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    final sowNow = crops.take(4).toList(growable: false);

    return _PrettyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/seedling.svg', width: 48, height: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sow now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                ),
              ),
              _MiniPill(label: '${sowNow.length} picks'),
            ],
          ),
          const SizedBox(height: 14),
          if (sowNow.isEmpty)
            const Text('No sowing picks for this month.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sowNow.map((crop) => _SowNowButton(crop: crop)).toList(),
            ),
        ],
      ),
    );
  }
}

class _SowNowButton extends StatelessWidget {
  const _SowNowButton({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _openCropBottomSheet(context, crop),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(color: HomeScreen._leaf, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text(
                  crop.commonName.characters.first.toUpperCase(),
                  style: const TextStyle(color: HomeScreen._leaf, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Text(crop.commonName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data});

  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _SummaryCard(asset: 'assets/icons/seedling.svg', label: 'Sow now', value: data.plantableCrops.length.toString()),
        const _PruneSummaryCard(),
      ],
    );
  }
}

class _PruneSummaryCard extends StatelessWidget {
  const _PruneSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PruningGuideScreen()));
        },
        child: _PrettyCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/pruning_shears.svg', width: 50, height: 50),
              const SizedBox(height: 8),
              Text('8', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: HomeScreen._ink)),
              Text('Prune guide', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HomeScreen._muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.asset, required this.label, required this.value});

  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _PrettyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(asset, width: 50, height: 50),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: HomeScreen._ink)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HomeScreen._muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Pick a path', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.4))),
            const _MiniPill(label: 'tap cards'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 146,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ActionTile(asset: 'assets/icons/seedling.svg', label: 'Sow', onTap: () {}),
              const SizedBox(width: 12),
              _ActionTile(asset: 'assets/icons/crop_guide.svg', label: 'Crops', onTap: () => _open(context, const CropGuideScreen())),
              const SizedBox(width: 12),
              _ActionTile(asset: 'assets/icons/calendar_leaf.svg', label: 'Calendar', onTap: () => _open(context, const CropCalendarScreen())),
              const SizedBox(width: 12),
              _ActionTile(asset: 'assets/icons/task_sprout.svg', label: 'Tasks', onTap: () => _open(context, const WeeklyTasksScreen())),
              const SizedBox(width: 12),
              _ActionTile(asset: 'assets/icons/pruning_shears.svg', label: 'Prune', onTap: () => _open(context, const PruningGuideScreen())),
            ],
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.asset, required this.label, required this.onTap});

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Ink(
            width: 132,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: HomeScreen._surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: HomeScreen._border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.asset(asset, width: 66, height: 66),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(color: HomeScreen._ink, fontSize: 17, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BestForSetupCard extends StatelessWidget {
  const _BestForSetupCard({required this.crops, required this.settings});

  final List<Crop> crops;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return _PrettyCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SvgPicture.asset('assets/icons/seedling.svg', width: 44, height: 44),
          const SizedBox(width: 12),
          Expanded(child: Text('Best picks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.4))),
        ]),
        const SizedBox(height: 12),
        if (crops.isEmpty) const Text('No strong recommendations found for this month.') else Wrap(spacing: 8, runSpacing: 8, children: crops.map((crop) => _CropChip(crop: crop)).toList()),
      ]),
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
        onTap: () => _openCropBottomSheet(context, crop),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(color: HomeScreen._mint, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PlantBadge(label: crop.commonName, size: 30),
            const SizedBox(width: 7),
            Text(crop.commonName, style: const TextStyle(color: HomeScreen._leafDark, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _CropTapCard extends StatelessWidget {
  const _CropTapCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openCropBottomSheet(context, crop),
          child: Ink(
            width: 132,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: HomeScreen._surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: HomeScreen._border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _SvgIconBox(asset: 'assets/icons/seedling.svg', size: 58),
              const SizedBox(height: 10),
              Text(crop.commonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: HomeScreen._ink, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 7),
              if (crop.frostTender) const _MiniPill(label: 'frost', color: HomeScreen._clay) else const _MiniPill(label: 'hardy'),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CropBottomSheet extends StatelessWidget {
  const _CropBottomSheet({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _SvgIconBox(asset: 'assets/icons/seedling.svg', size: 64),
          const SizedBox(width: 14),
          Expanded(child: Text(crop.commonName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 14),
        Text(crop.summary),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniPill(label: '${crop.spacingCm}cm'),
          _MiniPill(label: '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days'),
          if (crop.containerFriendly) const _MiniPill(label: 'container'),
          if (crop.beginnerFriendly) const _MiniPill(label: 'easy'),
          if (crop.frostTender) const _MiniPill(label: 'frost tender', color: HomeScreen._clay),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); }, icon: const Icon(Icons.add), label: const Text('Add later'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); }, icon: const Icon(Icons.close), label: const Text('Close'))),
        ]),
      ]),
    );
  }
}

class _PrettyCard extends StatelessWidget {
  const _PrettyCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: HomeScreen._surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: HomeScreen._border), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))]),
      child: child,
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.color = HomeScreen._leaf});

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

class _PlantBadge extends StatelessWidget {
  const _PlantBadge({required this.label, this.size = 56});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.isEmpty ? '?' : label.characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [HomeScreen._mint, Color(0xFFD4E5BE)]), borderRadius: BorderRadius.circular(size * 0.36)),
      child: Text(initial, style: TextStyle(color: HomeScreen._leaf, fontSize: size * 0.38, fontWeight: FontWeight.w900)),
    );
  }
}

class _SvgIconBox extends StatelessWidget {
  const _SvgIconBox({required this.asset, this.size = 64});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(0.20))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}

class _LeafPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = Colors.white.withOpacity(0.10);
    final stemPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final baseX = size.width * 0.70;
    final baseY = size.height * 0.98;

    for (var i = 0; i < 6; i++) {
      final dx = baseX + (i - 2.5) * 23;
      final height = 82.0 + i * 9;
      final path = Path()
        ..moveTo(dx, baseY)
        ..quadraticBezierTo(dx - 18, baseY - height * 0.45, dx + 4, baseY - height);
      canvas.drawPath(path, stemPaint);
      canvas.save();
      canvas.translate(dx + 2, baseY - height * 0.70);
      canvas.rotate(-0.55 + i * 0.18);
      canvas.drawOval(const Rect.fromLTWH(-8, -18, 18, 36), leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
