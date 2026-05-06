import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/nz_region.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
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

  late Future<List<NzRegion>> _regionsFuture;
  AppSettings _draft = AppSettings.defaultSettings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _regionsFuture = _dataRepository.loadRegions();
    _loadExistingSettings();
  }

  Future<void> _loadExistingSettings() async {
    final settings = await _settingsRepository.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() => _draft = settings);
  }

  Future<void> _completeSetup() async {
    if (_saving) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _saving = true);

    await _settingsRepository.completeSetup(_draft);

    if (!mounted) {
      return;
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),
      body: SafeArea(
        child: FutureBuilder<List<NzRegion>>(
          future: _regionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load setup data: ${snapshot.error}'),
                ),
              );
            }

            final regions = snapshot.data ?? const <NzRegion>[];
            final regionIds = regions.map((region) => region.id).toSet();
            final regionValue = regionIds.contains(_draft.regionId)
                ? _draft.regionId
                : regions.isEmpty
                    ? _draft.regionId
                    : regions.first.id;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _SetupHero(settings: _draft, regionName: _regionName(regions, regionValue)),
                const SizedBox(height: 18),
                Text(
                  'Garden setup',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your local conditions once. The app stores this on-device and uses it for offline planting advice.',
                  style: TextStyle(color: Color(0xFF66736A), height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                _DropdownCard<String>(
                  icon: Icons.place_outlined,
                  title: 'NZ region',
                  value: regionValue,
                  items: regions
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
                    setState(() => _draft = _draft.copyWith(regionId: value));
                  },
                ),
                _DropdownCard<String>(
                  icon: Icons.ac_unit_outlined,
                  title: 'Frost risk',
                  value: _draft.frostRisk,
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
                    setState(() => _draft = _draft.copyWith(frostRisk: value));
                  },
                ),
                _DropdownCard<String>(
                  icon: Icons.air_outlined,
                  title: 'Wind exposure',
                  value: _draft.windExposure,
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
                    setState(() => _draft = _draft.copyWith(windExposure: value));
                  },
                ),
                _DropdownCard<String>(
                  icon: Icons.yard_outlined,
                  title: 'Garden type',
                  value: _draft.gardenType,
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
                    setState(() => _draft = _draft.copyWith(gardenType: value));
                  },
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _completeSetup,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving setup' : 'Start planning offline'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _regionName(List<NzRegion> regions, String regionId) {
    for (final region in regions) {
      if (region.id == regionId) {
        return region.name;
      }
    }
    return 'Canterbury';
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({required this.settings, required this.regionName});

  final AppSettings settings;
  final String regionName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17452F), Color(0xFF2F724B), Color(0xFF8BA766)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x24172D22), blurRadius: 30, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GlassPill(icon: Icons.place_outlined, label: regionName),
              _GlassPill(icon: Icons.ac_unit_outlined, label: _format(settings.frostRisk)),
              _GlassPill(icon: Icons.air_outlined, label: _format(settings.windExposure)),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Set up your\ngarden once',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: .96,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_format(settings.gardenType)} advice, saved locally.',
            style: TextStyle(color: Colors.white.withOpacity(.82), fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  String _format(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
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
