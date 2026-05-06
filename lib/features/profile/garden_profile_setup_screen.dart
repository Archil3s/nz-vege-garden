import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/garden_profile_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_profile.dart';

const _canvas = Color(0xFFF8F3E8);
const _surface = Color(0xFFFFFCF5);
const _ink = Color(0xFF172D22);
const _muted = Color(0xFF66736A);
const _leaf = Color(0xFF2F724B);
const _leafDark = Color(0xFF17452F);
const _moss = Color(0xFF8BA766);
const _mint = Color(0xFFE7F0DB);
const _clay = Color(0xFFC4793D);
const _berry = Color(0xFFB35642);
const _border = Color(0xFFE7DFCE);
const _sun = Color(0xFFF4C86A);

class GardenProfileSetupScreen extends StatefulWidget {
  const GardenProfileSetupScreen({super.key});

  @override
  State<GardenProfileSetupScreen> createState() =>
      _GardenProfileSetupScreenState();
}

class _GardenProfileSetupScreenState extends State<GardenProfileSetupScreen> {
  final _settingsRepository = const AppSettingsRepository();
  final _profileRepository = const GardenProfileRepository();
  final _dataRepository = const GardenDataRepository();

  late Future<_SetupData> _setupFuture;

  String _regionId = AppSettings.defaultSettings.regionId;
  String _frostRisk = AppSettings.defaultSettings.frostRisk;
  String _windExposure = AppSettings.defaultSettings.windExposure;
  String _gardenType = AppSettings.defaultSettings.gardenType;
  String _experienceLevel = GardenProfile.defaultProfile.experienceLevel;

  final Set<String> _growingCropIds = {};
  final Set<String> _wishlistCropIds = {};
  final Set<String> _avoidedCropIds = {};
  final Set<String> _goalIds = {...GardenProfile.defaultProfile.goalIds};

  @override
  void initState() {
    super.initState();
    _setupFuture = _loadData();
  }

  Future<_SetupData> _loadData() async {
    final settings = await _settingsRepository.loadSettings();
    final profile = await _profileRepository.loadProfile();
    final crops = await _dataRepository.loadCrops();

    _regionId = settings.regionId;
    _frostRisk = settings.frostRisk;
    _windExposure = settings.windExposure;
    _gardenType = settings.gardenType;
    _experienceLevel = profile.experienceLevel;

    _growingCropIds
      ..clear()
      ..addAll(profile.growingCropIds);
    _wishlistCropIds
      ..clear()
      ..addAll(profile.wishlistCropIds);
    _avoidedCropIds
      ..clear()
      ..addAll(profile.avoidedCropIds);
    _goalIds
      ..clear()
      ..addAll(profile.goalIds);

    final sortedCrops = [...crops]
      ..sort((a, b) => a.commonName.compareTo(b.commonName));

    return _SetupData(crops: sortedCrops);
  }

  Future<void> _save() async {
    HapticFeedback.selectionClick();

    final settings = AppSettings(
      regionId: _regionId,
      frostRisk: _frostRisk,
      windExposure: _windExposure,
      gardenType: _gardenType,
      weeklyReminderEnabled: AppSettings.defaultSettings.weeklyReminderEnabled,
    );

    final profile = GardenProfile(
      growingCropIds: _growingCropIds.toList()..sort(),
      wishlistCropIds: _wishlistCropIds.toList()..sort(),
      avoidedCropIds: _avoidedCropIds.toList()..sort(),
      goalIds: _goalIds.toList()..sort(),
      experienceLevel: _experienceLevel,
      setupComplete: true,
    );

    await _settingsRepository.saveSettings(settings);
    await _profileRepository.saveProfile(profile);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('My Garden profile saved.')),
    );

    Navigator.of(context).pop(true);
  }

  void _toggleCrop(Set<String> target, String cropId) {
    setState(() {
      if (target.contains(cropId)) {
        target.remove(cropId);
      } else {
        target.add(cropId);
      }

      if (target == _growingCropIds) {
        _wishlistCropIds.remove(cropId);
        _avoidedCropIds.remove(cropId);
      } else if (target == _wishlistCropIds) {
        _growingCropIds.remove(cropId);
        _avoidedCropIds.remove(cropId);
      } else if (target == _avoidedCropIds) {
        _growingCropIds.remove(cropId);
        _wishlistCropIds.remove(cropId);
      }
    });
  }

  void _toggleGoal(String goalId) {
    setState(() {
      if (_goalIds.contains(goalId)) {
        _goalIds.remove(goalId);
      } else {
        _goalIds.add(goalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Set up My Garden'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<_SetupData>(
        future: _setupFuture,
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

          final crops = snapshot.data?.crops ?? const <Crop>[];

          return Stack(
            children: [
              Positioned(
                top: -130,
                right: -120,
                child: _SoftBlob(
                  color: _mint.withValues(alpha: .86),
                  size: 270,
                ),
              ),
              Positioned(
                bottom: -190,
                left: -150,
                child: _SoftBlob(
                  color: _sun.withValues(alpha: .18),
                  size: 340,
                ),
              ),
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                children: [
                  _SetupHero(
                    growingCount: _growingCropIds.length,
                    wishlistCount: _wishlistCropIds.length,
                    goalCount: _goalIds.length,
                  ),
                  const SizedBox(height: 14),
                  _SetupPanel(
                    title: '1. Your garden conditions',
                    subtitle:
                        'These settings make advice more local and realistic.',
                    icon: Icons.tune_outlined,
                    color: _leaf,
                    children: [
                      _DropdownField(
                        label: 'NZ region',
                        value: _regionId,
                        items: const {
                          'northland': 'Northland',
                          'auckland': 'Auckland',
                          'waikato': 'Waikato',
                          'bay_of_plenty': 'Bay of Plenty',
                          'gisborne': 'Gisborne',
                          'hawkes_bay': 'Hawkes Bay',
                          'taranaki': 'Taranaki',
                          'manawatu': 'Manawatū',
                          'wellington': 'Wellington',
                          'tasman': 'Tasman',
                          'nelson': 'Nelson',
                          'marlborough': 'Marlborough',
                          'west_coast': 'West Coast',
                          'canterbury': 'Canterbury',
                          'otago': 'Otago',
                          'southland': 'Southland',
                        },
                        onChanged: (value) => setState(() => _regionId = value),
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Garden type',
                        value: _gardenType,
                        items: const {
                          'raised_bed': 'Raised beds',
                          'in_ground': 'In-ground beds',
                          'container': 'Pots and containers',
                          'greenhouse': 'Greenhouse / tunnelhouse',
                          'mixed': 'Mixed garden',
                        },
                        onChanged: (value) =>
                            setState(() => _gardenType = value),
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Frost risk',
                        value: _frostRisk,
                        items: const {
                          'low': 'Low',
                          'moderate': 'Moderate',
                          'high': 'High',
                        },
                        onChanged: (value) =>
                            setState(() => _frostRisk = value),
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Wind exposure',
                        value: _windExposure,
                        items: const {
                          'sheltered': 'Sheltered',
                          'moderate': 'Moderate',
                          'exposed': 'Exposed',
                        },
                        onChanged: (value) =>
                            setState(() => _windExposure = value),
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Experience',
                        value: _experienceLevel,
                        items: const {
                          'beginner': 'Beginner',
                          'confident': 'Confident',
                          'experienced': 'Experienced',
                        },
                        onChanged: (value) =>
                            setState(() => _experienceLevel = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SetupPanel(
                    title: '2. Your garden goals',
                    subtitle:
                        'The app can prioritise advice around what matters to you.',
                    icon: Icons.flag_outlined,
                    color: _moss,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalOptions.map((goal) {
                          final selected = _goalIds.contains(goal.id);

                          return FilterChip(
                            avatar: Icon(goal.icon, size: 18),
                            label: Text(goal.label),
                            selected: selected,
                            onSelected: (_) => _toggleGoal(goal.id),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CropPickerPanel(
                    title: '3. Crops growing now',
                    subtitle:
                        'These get priority in advice, pest help, and garden jobs.',
                    icon: Icons.eco_outlined,
                    color: _leaf,
                    crops: crops,
                    selectedIds: _growingCropIds,
                    onToggle: (cropId) => _toggleCrop(_growingCropIds, cropId),
                  ),
                  const SizedBox(height: 14),
                  _CropPickerPanel(
                    title: '4. Crops you want to grow',
                    subtitle: 'Useful for planning what to sow next.',
                    icon: Icons.favorite_border,
                    color: _clay,
                    crops: crops,
                    selectedIds: _wishlistCropIds,
                    onToggle: (cropId) => _toggleCrop(_wishlistCropIds, cropId),
                  ),
                  const SizedBox(height: 14),
                  _CropPickerPanel(
                    title: '5. Crops to avoid',
                    subtitle:
                        'Use this for crops you do not want the app to push.',
                    icon: Icons.block_outlined,
                    color: _berry,
                    crops: crops,
                    selectedIds: _avoidedCropIds,
                    onToggle: (cropId) => _toggleCrop(_avoidedCropIds, cropId),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save My Garden profile'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({
    required this.growingCount,
    required this.wishlistCount,
    required this.goalCount,
  });

  final int growingCount;
  final int wishlistCount;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_leafDark, _leaf, _moss],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22172D22),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -34,
            child: Icon(
              Icons.yard_outlined,
              size: 152,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassPill(label: 'My Garden setup'),
              const SizedBox(height: 20),
              const Text(
                'Make the app\nabout your garden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$growingCount growing now · $wishlistCount want to grow · $goalCount goals selected.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .86),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _CropPickerPanel extends StatelessWidget {
  const _CropPickerPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.crops,
    required this.selectedIds,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Crop> crops;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SetupPanel(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      children: [
        if (selectedIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedIds.take(8).map((id) {
              final crop = crops.where((item) => item.id == id).firstOrNull;
              return _SmallTag(
                label: crop?.commonName ?? _formatValue(id),
                color: color,
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: crops.map((crop) {
            final selected = selectedIds.contains(crop.id);

            return FilterChip(
              avatar: Icon(
                crop.containerFriendly
                    ? Icons.inventory_2_outlined
                    : Icons.eco_outlined,
                size: 18,
              ),
              label: Text(crop.commonName),
              selected: selected,
              onSelected: (_) => onToggle(crop.id),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(icon: icon, color: color, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 20,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _SetupData {
  const _SetupData({required this.crops});

  final List<Crop> crops;
}

const _goalOptions = [
  _GoalOption(
    id: 'food_production',
    label: 'Grow more food',
    icon: Icons.restaurant_outlined,
  ),
  _GoalOption(
    id: 'beginner_friendly',
    label: 'Beginner friendly',
    icon: Icons.sentiment_satisfied_alt_outlined,
  ),
  _GoalOption(
    id: 'containers',
    label: 'Containers',
    icon: Icons.inventory_2_outlined,
  ),
  _GoalOption(
    id: 'pest_control',
    label: 'Pest control',
    icon: Icons.bug_report_outlined,
  ),
  _GoalOption(
    id: 'water_saving',
    label: 'Water saving',
    icon: Icons.water_drop_outlined,
  ),
  _GoalOption(
    id: 'year_round',
    label: 'Year-round harvests',
    icon: Icons.calendar_month_outlined,
  ),
];

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }
}
