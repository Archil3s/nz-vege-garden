import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_bed_planting_repository.dart';
import '../../data/garden_bed_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_bed.dart';
import '../../data/models/garden_bed_planting.dart';
import '../../data/models/nz_region.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Garden dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Region: $regionName'),
              const SizedBox(height: 4),
              Text(
                'Frost: ${_formatValue(data.settings.frostRisk)} • '
                'Wind: ${_formatValue(data.settings.windExposure)} • '
                'Garden: ${_formatValue(data.settings.gardenType)}',
              ),
              const SizedBox(height: 16),
              _SummaryCards(data: data),
              const SizedBox(height: 16),
              _UpcomingHarvestsCard(plantings: data.upcomingHarvests),
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
                ...data.plantableCrops.map(
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
    const bedRepository = GardenBedRepository();
    const plantingRepository = GardenBedPlantingRepository();

    final settings = await settingsRepository.loadSettings();
    final regions = await dataRepository.loadRegions();
    final beds = await bedRepository.loadGardenBeds();
    final plantings = await plantingRepository.loadPlantings();
    final plantableCrops = await dataRepository.cropsForMonthAndRegion(
      month: DateTime.now().month,
      regionId: settings.regionId,
    );

    final selectedRegion = regions.where((region) => region.id == settings.regionId).firstOrNull;
    final upcomingHarvests = plantings
        .where((planting) => planting.expectedHarvestStartDate != null)
        .toList(growable: false)
      ..sort((a, b) => a.expectedHarvestStartDate!.compareTo(b.expectedHarvestStartDate!));

    return _HomeData(
      settings: settings,
      selectedRegion: selectedRegion,
      plantableCrops: plantableCrops,
      beds: beds,
      plantings: plantings,
      upcomingHarvests: upcomingHarvests.take(5).toList(growable: false),
    );
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data});

  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.yard_outlined,
            label: 'Beds',
            value: data.beds.length.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.eco_outlined,
            label: 'Plantings',
            value: data.plantings.length.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.event_available_outlined,
            label: 'Harvests',
            value: data.upcomingHarvests.length.toString(),
          ),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _UpcomingHarvestsCard extends StatelessWidget {
  const _UpcomingHarvestsCard({required this.plantings});

  final List<GardenBedPlanting> plantings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming harvests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (plantings.isEmpty)
              const Text('Add crops to beds to see estimated harvest windows here.')
            else
              ...plantings.map(
                (planting) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(planting.cropName),
                  subtitle: Text(_harvestWindow(planting)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _harvestWindow(GardenBedPlanting planting) {
    final start = planting.expectedHarvestStartDate;
    final end = planting.expectedHarvestEndDate;

    if (start == null || end == null) {
      return 'No estimate available';
    }

    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _HomeData {
  const _HomeData({
    required this.settings,
    required this.selectedRegion,
    required this.plantableCrops,
    required this.beds,
    required this.plantings,
    required this.upcomingHarvests,
  });

  final AppSettings settings;
  final NzRegion? selectedRegion;
  final List<Crop> plantableCrops;
  final List<GardenBed> beds;
  final List<GardenBedPlanting> plantings;
  final List<GardenBedPlanting> upcomingHarvests;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
