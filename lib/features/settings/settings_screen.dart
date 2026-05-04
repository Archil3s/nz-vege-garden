import 'package:flutter/material.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/nz_region.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _frostRiskOptions = ['low', 'moderate', 'high'];
  static const _windExposureOptions = ['sheltered', 'moderate', 'exposed', 'coastal'];
  static const _gardenTypeOptions = [
    'open_bed',
    'raised_bed',
    'container',
    'greenhouse',
    'seed_tray_indoor',
  ];

  final _settingsRepository = const AppSettingsRepository();
  final _dataRepository = const GardenDataRepository();

  late Future<_SettingsData> _settingsDataFuture;

  @override
  void initState() {
    super.initState();
    _settingsDataFuture = _loadSettingsData();
  }

  Future<_SettingsData> _loadSettingsData() async {
    final settings = await _settingsRepository.loadSettings();
    final regions = await _dataRepository.loadRegions();

    return _SettingsData(settings: settings, regions: regions);
  }

  Future<void> _saveSettings(AppSettings settings) async {
    await _settingsRepository.saveSettings(settings);
    setState(() {
      _settingsDataFuture = _loadSettingsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<_SettingsData>(
        future: _settingsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load settings: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No settings found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Garden setup',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'These settings are stored locally on your device and used to personalise planting advice.',
              ),
              const SizedBox(height: 16),
              _DropdownCard<String>(
                icon: Icons.place_outlined,
                title: 'NZ region',
                value: data.settings.regionId,
                items: data.regions
                    .map(
                      (region) => DropdownMenuItem(
                        value: region.id,
                        child: Text(region.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  _saveSettings(data.settings.copyWith(regionId: value));
                },
              ),
              _DropdownCard<String>(
                icon: Icons.ac_unit_outlined,
                title: 'Frost risk',
                value: data.settings.frostRisk,
                items: _frostRiskOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_formatValue(option)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  _saveSettings(data.settings.copyWith(frostRisk: value));
                },
              ),
              _DropdownCard<String>(
                icon: Icons.air_outlined,
                title: 'Wind exposure',
                value: data.settings.windExposure,
                items: _windExposureOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_formatValue(option)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  _saveSettings(data.settings.copyWith(windExposure: value));
                },
              ),
              _DropdownCard<String>(
                icon: Icons.yard_outlined,
                title: 'Garden type',
                value: data.settings.gardenType,
                items: _gardenTypeOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_formatValue(option)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  _saveSettings(data.settings.copyWith(gardenType: value));
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Available NZ regions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...data.regions.map(
                (region) => Card(
                  child: ListTile(
                    title: Text(region.name),
                    subtitle: Text(region.climateSummary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<T>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
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

class _SettingsData {
  const _SettingsData({
    required this.settings,
    required this.regions,
  });

  final AppSettings settings;
  final List<NzRegion> regions;
}
