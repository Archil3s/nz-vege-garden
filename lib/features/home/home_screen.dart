import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/nz_region.dart';
import '../calendar/crop_calendar_screen.dart';
import '../crops/crop_guide_screen.dart';
import '../tasks/weekly_tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NZ Vege Garden'),
      ),
      body: FutureBuilder<_HomeData>(
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Text(
                'Garden dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SetupChip(
                    icon: Icons.place_outlined,
                    label: regionName,
                  ),
                  _SetupChip(
                    icon: Icons.ac_unit_outlined,
                    label: 'Frost: ${_formatValue(data.settings.frostRisk)}',
                  ),
                  _SetupChip(
                    icon: Icons.air_outlined,
                    label: 'Wind: ${_formatValue(data.settings.windExposure)}',
                  ),
                  _SetupChip(
                    icon: Icons.yard_outlined,
                    label: _formatValue(data.settings.gardenType),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SummaryCards(data: data),
              const SizedBox(height: 16),
              const _QuickActionsCard(),
              const SizedBox(height: 16),
              _BestForSetupCard(
                crops: data.recommendedCrops,
                settings: data.settings,
              ),
              const SizedBox(height: 16),
              Text(
                'What to plant now',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.plantableCrops.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matching crops found for this month.'),
                  ),
                )
              else
                ...data.plantableCrops.take(8).map(
                  (crop) => Card(
                    child: ListTile(
                      title: Text(crop.commonName),
                      subtitle: Text(crop.summary),
                      trailing: crop.frostTender
                          ? const Icon(Icons.ac_unit, semanticLabel: 'Frost tender')
                          : null,
                    ),
                  ),
                ),
            ],
          );
        },
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

class _SetupChip extends StatelessWidget {
  const _SetupChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
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
      childAspectRatio: 1.7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _SummaryCard(
          icon: Icons.eco_outlined,
          label: 'Plant now',
          value: data.plantableCrops.length.toString(),
        ),
        _SummaryCard(
          icon: Icons.recommend_outlined,
          label: 'Best fit',
          value: data.recommendedCrops.length.toString(),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.45,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _QuickActionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'Crop guide',
                  onTap: () => _open(context, const CropGuideScreen()),
                ),
                _QuickActionButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  onTap: () => _open(context, const CropCalendarScreen()),
                ),
                _QuickActionButton(
                  icon: Icons.checklist_outlined,
                  label: 'Tasks',
                  onTap: () => _open(context, const WeeklyTasksScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _BestForSetupCard extends StatelessWidget {
  const _BestForSetupCard({
    required this.crops,
    required this.settings,
  });

  final List<Crop> crops;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Best fit for your setup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (crops.isEmpty)
              const Text(
                'No strong recommendations found for this month. Check the full planting list below.',
              )
            else
              ...crops.map(
                (crop) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.eco_outlined),
                  title: Text(crop.commonName),
                  subtitle: Text(_reasonForCrop(crop)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _reasonForCrop(Crop crop) {
    final reasons = <String>[];

    if (crop.beginnerFriendly) {
      reasons.add('beginner friendly');
    }

    if (settings.gardenType == 'container' && crop.containerFriendly) {
      reasons.add('suits containers');
    }

    if (settings.frostRisk == 'high' && !crop.frostTender) {
      reasons.add('better for frost-prone gardens');
    }

    if ((settings.windExposure == 'exposed' || settings.windExposure == 'coastal') &&
        crop.containerFriendly) {
      reasons.add('can be moved or sheltered');
    }

    if (reasons.isEmpty) {
      return crop.summary;
    }

    return '${crop.summary}\nWhy: ${reasons.join(', ')}.';
  }
}

class _HomeData {
  const _HomeData({
    required this.settings,
    required this.selectedRegion,
    required this.plantableCrops,
    required this.recommendedCrops,
  });

  final AppSettings settings;
  final NzRegion? selectedRegion;
  final List<Crop> plantableCrops;
  final List<Crop> recommendedCrops;
}

class _ScoredCrop {
  const _ScoredCrop({
    required this.crop,
    required this.score,
  });

  final Crop crop;
  final int score;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
