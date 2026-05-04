import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
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
          final crops = data?.crops ?? const <Crop>[];
          final regionName = data?.selectedRegion?.name ?? 'Unknown region';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'What to plant now',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Region: $regionName'),
              if (data != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Frost: ${_formatValue(data.settings.frostRisk)} • '
                  'Wind: ${_formatValue(data.settings.windExposure)} • '
                  'Garden: ${_formatValue(data.settings.gardenType)}',
                ),
              ],
              const SizedBox(height: 16),
              if (crops.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matching crops found for this month.'),
                  ),
                )
              else
                ...crops.map(
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

    final settings = await settingsRepository.loadSettings();
    final regions = await dataRepository.loadRegions();
    final crops = await dataRepository.cropsForMonthAndRegion(
      month: DateTime.now().month,
      regionId: settings.regionId,
    );

    final selectedRegion = regions.where((region) => region.id == settings.regionId).firstOrNull;

    return _HomeData(
      settings: settings,
      selectedRegion: selectedRegion,
      crops: crops,
    );
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _HomeData {
  const _HomeData({
    required this.settings,
    required this.selectedRegion,
    required this.crops,
  });

  final AppSettings settings;
  final NzRegion? selectedRegion;
  final List<Crop> crops;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
