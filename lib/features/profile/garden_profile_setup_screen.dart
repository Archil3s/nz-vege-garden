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
  final _searchController = TextEditingController();

  late Future<List<Crop>> _cropsFuture;

  int _step = 0;
  String _shelfMode = 'growing';
  String _search = '';

  String _regionId = AppSettings.defaultSettings.regionId;
  String _frostRisk = AppSettings.defaultSettings.frostRisk;
  String _windExposure = AppSettings.defaultSettings.windExposure;
  String _gardenType = AppSettings.defaultSettings.gardenType;
  String _experienceLevel = GardenProfile.defaultProfile.experienceLevel;
  bool _weeklyReminderEnabled =
      AppSettings.defaultSettings.weeklyReminderEnabled;

  final Set<String> _growingCropIds = {};
  final Set<String> _wishlistCropIds = {};
  final Set<String> _avoidedCropIds = {};
  final Set<String> _goalIds = {...GardenProfile.defaultProfile.goalIds};

  @override
  void initState() {
    super.initState();
    _cropsFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Crop>> _loadData() async {
    final settings = await _settingsRepository.loadSettings();
    final profile = await _profileRepository.loadProfile();
    final crops = await _dataRepository.loadCrops();

    _regionId = settings.regionId;
    _frostRisk = settings.frostRisk;
    _windExposure = settings.windExposure;
    _gardenType = settings.gardenType;
    _weeklyReminderEnabled = settings.weeklyReminderEnabled;
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

    return [...crops]..sort((a, b) => a.commonName.compareTo(b.commonName));
  }

  Future<void> _save() async {
    HapticFeedback.selectionClick();

    await _settingsRepository.saveSettings(
      AppSettings(
        regionId: _regionId,
        frostRisk: _frostRisk,
        windExposure: _windExposure,
        gardenType: _gardenType,
        weeklyReminderEnabled: _weeklyReminderEnabled,
      ),
    );

    await _profileRepository.saveProfile(
      GardenProfile(
        growingCropIds: _growingCropIds.toList()..sort(),
        wishlistCropIds: _wishlistCropIds.toList()..sort(),
        avoidedCropIds: _avoidedCropIds.toList()..sort(),
        goalIds: _goalIds.toList()..sort(),
        experienceLevel: _experienceLevel,
        setupComplete: true,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Garden Passport saved.')),
    );

    Navigator.of(context).pop(true);
  }

  void _next() {
    HapticFeedback.selectionClick();

    if (_step == 2) {
      _save();
      return;
    }

    setState(() => _step += 1);
  }

  void _back() {
    HapticFeedback.selectionClick();

    if (_step == 0) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _step -= 1);
  }

  Set<String> get _activeShelf {
    return switch (_shelfMode) {
      'want' => _wishlistCropIds,
      'avoid' => _avoidedCropIds,
      _ => _growingCropIds,
    };
  }

  Color get _activeShelfColor {
    return switch (_shelfMode) {
      'want' => _clay,
      'avoid' => _berry,
      _ => _leaf,
    };
  }

  String get _activeShelfLabel {
    return switch (_shelfMode) {
      'want' => 'Want to grow',
      'avoid' => 'Skip for now',
      _ => 'Growing now',
    };
  }

  void _toggleCrop(String cropId) {
    setState(() {
      final active = _activeShelf;

      if (active.contains(cropId)) {
        active.remove(cropId);
        return;
      }

      _growingCropIds.remove(cropId);
      _wishlistCropIds.remove(cropId);
      _avoidedCropIds.remove(cropId);

      active.add(cropId);
    });
  }

  void _applyPack(List<String> cropIds, List<Crop> allCrops) {
    HapticFeedback.selectionClick();

    final availableIds = allCrops.map((crop) => crop.id).toSet();

    setState(() {
      for (final cropId in cropIds.where(availableIds.contains)) {
        _growingCropIds.remove(cropId);
        _wishlistCropIds.remove(cropId);
        _avoidedCropIds.remove(cropId);
        _activeShelf.add(cropId);
      }
    });
  }

  List<Crop> _visibleCrops(List<Crop> crops) {
    final query = _search.trim().toLowerCase();

    final filtered = crops.where((crop) {
      if (query.isEmpty) {
        return true;
      }

      return [
        crop.commonName,
        crop.category,
        crop.summary,
        crop.sunRequirement,
        crop.waterRequirement,
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);

    filtered.sort((a, b) {
      final scoreCompare = _cropScore(b).compareTo(_cropScore(a));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return a.commonName.compareTo(b.commonName);
    });

    return query.isEmpty
        ? filtered.take(28).toList(growable: false)
        : filtered.take(80).toList(growable: false);
  }

  int _cropScore(Crop crop) {
    var score = 0;

    if (crop.beginnerFriendly) {
      score += 20;
    }

    if (crop.containerFriendly) {
      score += 12;
    }

    if (!crop.frostTender) {
      score += 6;
    }

    if (crop.waterRequirement == 'regular') {
      score += 4;
    }

    if (_activeShelf.contains(crop.id)) {
      score += 40;
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Garden Passport'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Crop>>(
        future: _cropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load setup: ${snapshot.error}'),
              ),
            );
          }

          final crops = snapshot.data ?? const <Crop>[];

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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 126),
                children: [
                  _PassportHero(
                    step: _step,
                    growingCount: _growingCropIds.length,
                    wantCount: _wishlistCropIds.length,
                    goalCount: _goalIds.length,
                  ),
                  const SizedBox(height: 14),
                  _StepDots(step: _step),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (_step) {
                      0 => _buildGardenStyleStep(),
                      1 => _buildGoalStep(),
                      _ => _buildPlantShelfStep(crops),
                    },
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _back,
                          icon:
                              Icon(_step == 0 ? Icons.close : Icons.arrow_back),
                          label: Text(_step == 0 ? 'Cancel' : 'Back'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _next,
                          icon: Icon(_step == 2
                              ? Icons.save_outlined
                              : Icons.arrow_forward),
                          label: Text(_step == 2 ? 'Save' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGardenStyleStep() {
    return Column(
      key: const ValueKey('style'),
      children: [
        _Panel(
          title: 'Pick your garden style',
          subtitle: 'One choice is enough. You can change it later.',
          icon: Icons.yard_outlined,
          color: _leaf,
          children: [
            _BigChoiceGrid(
              selectedValue: _gardenType,
              choices: const [
                _ChoiceData(
                  value: 'raised_bed',
                  title: 'Raised beds',
                  subtitle: 'Easy access, tidy rows',
                  icon: Icons.crop_square_outlined,
                  color: _leaf,
                ),
                _ChoiceData(
                  value: 'container',
                  title: 'Pots',
                  subtitle: 'Balcony, patio, small space',
                  icon: Icons.inventory_2_outlined,
                  color: _clay,
                ),
                _ChoiceData(
                  value: 'in_ground',
                  title: 'In-ground',
                  subtitle: 'Traditional garden beds',
                  icon: Icons.grass_outlined,
                  color: _moss,
                ),
                _ChoiceData(
                  value: 'greenhouse',
                  title: 'Greenhouse',
                  subtitle: 'Sheltered warm growing',
                  icon: Icons.foundation_outlined,
                  color: _leafDark,
                ),
                _ChoiceData(
                  value: 'mixed',
                  title: 'Mixed',
                  subtitle: 'A bit of everything',
                  icon: Icons.auto_awesome_mosaic_outlined,
                  color: _berry,
                ),
              ],
              onSelected: (value) => setState(() => _gardenType = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          title: 'Conditions',
          subtitle: 'Keep this simple. Use your best guess.',
          icon: Icons.tune_outlined,
          color: _moss,
          children: [
            _DropdownField(
              label: 'Region',
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
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'Frost',
                    value: _frostRisk,
                    items: const {
                      'low': 'Low',
                      'moderate': 'Moderate',
                      'high': 'High',
                    },
                    onChanged: (value) => setState(() => _frostRisk = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownField(
                    label: 'Wind',
                    value: _windExposure,
                    items: const {
                      'sheltered': 'Sheltered',
                      'moderate': 'Moderate',
                      'exposed': 'Exposed',
                    },
                    onChanged: (value) => setState(() => _windExposure = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      key: const ValueKey('goals'),
      children: [
        _Panel(
          title: 'Choose your garden vibe',
          subtitle: 'Pick only what matters. This keeps advice focused.',
          icon: Icons.flag_outlined,
          color: _leaf,
          children: [
            _BigChoiceGrid(
              selectedValue: _experienceLevel,
              choices: const [
                _ChoiceData(
                  value: 'beginner',
                  title: 'Beginner',
                  subtitle: 'Tell me what to do',
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  color: _leaf,
                ),
                _ChoiceData(
                  value: 'confident',
                  title: 'Confident',
                  subtitle: 'I know the basics',
                  icon: Icons.psychology_alt_outlined,
                  color: _clay,
                ),
                _ChoiceData(
                  value: 'experienced',
                  title: 'Experienced',
                  subtitle: 'Give me shortcuts',
                  icon: Icons.bolt_outlined,
                  color: _berry,
                ),
              ],
              onSelected: (value) => setState(() => _experienceLevel = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          title: 'What should the app care about?',
          subtitle: 'These become your advice filters.',
          icon: Icons.auto_awesome_outlined,
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
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected) {
                        _goalIds.remove(goal.id);
                      } else {
                        _goalIds.add(goal.id);
                      }
                    });
                  },
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantShelfStep(List<Crop> crops) {
    final visibleCrops = _visibleCrops(crops);

    return Column(
      key: const ValueKey('plants'),
      children: [
        _Panel(
          title: 'Build your Plant Shelf',
          subtitle:
              'Only use one shelf at a time. Search if the crop is not shown.',
          icon: Icons.local_florist_outlined,
          color: _activeShelfColor,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShelfChip(
                  value: 'growing',
                  label: 'Growing',
                  icon: Icons.eco_outlined,
                  color: _leaf,
                  selectedValue: _shelfMode,
                  onSelected: (value) => setState(() => _shelfMode = value),
                ),
                _ShelfChip(
                  value: 'want',
                  label: 'Want',
                  icon: Icons.favorite_border,
                  color: _clay,
                  selectedValue: _shelfMode,
                  onSelected: (value) => setState(() => _shelfMode = value),
                ),
                _ShelfChip(
                  value: 'avoid',
                  label: 'Avoid',
                  icon: Icons.block_outlined,
                  color: _berry,
                  selectedValue: _shelfMode,
                  onSelected: (value) => setState(() => _shelfMode = value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Find a crop',
                hintText: 'Tomato, garlic, lettuce...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 14),
            _StarterPacks(
              shelfLabel: _activeShelfLabel,
              color: _activeShelfColor,
              onPackSelected: (ids) => _applyPack(ids, crops),
            ),
            const SizedBox(height: 14),
            Text(
              _search.isEmpty
                  ? 'Showing the easiest picks first. Search to find more.'
                  : '${visibleCrops.length} matching crops.',
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleCrops.map((crop) {
                final selected = _activeShelf.contains(crop.id);

                return FilterChip(
                  avatar: Icon(
                    crop.containerFriendly
                        ? Icons.inventory_2_outlined
                        : Icons.eco_outlined,
                    size: 18,
                  ),
                  label: Text(crop.commonName),
                  selected: selected,
                  onSelected: (_) => _toggleCrop(crop.id),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ],
    );
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.step,
    required this.growingCount,
    required this.wantCount,
    required this.goalCount,
  });

  final int step;
  final int growingCount;
  final int wantCount;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => 'Your garden\npassport',
      1 => 'Your garden\nstyle',
      _ => 'Your plant\nshelf',
    };

    final subtitle = switch (step) {
      0 => 'Start with the basics. No pressure to be exact.',
      1 => '$goalCount goals selected. Pick only what matters.',
      _ => '$growingCount growing · $wantCount want to grow.',
    };

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
              const _GlassPill(label: '3 quick steps'),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
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

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index == step;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 8,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: active ? _leaf : _border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
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

class _BigChoiceGrid extends StatelessWidget {
  const _BigChoiceGrid({
    required this.selectedValue,
    required this.choices,
    required this.onSelected,
  });

  final String selectedValue;
  final List<_ChoiceData> choices;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: choices.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.16,
      ),
      itemBuilder: (context, index) {
        final choice = choices[index];
        final selected = selectedValue == choice.value;

        return Material(
          color: selected ? choice.color : Colors.white.withValues(alpha: .74),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(choice.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? choice.color : _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    choice.icon,
                    color: selected ? Colors.white : choice.color,
                  ),
                  const Spacer(),
                  Text(
                    choice.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    choice.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: .84)
                          : _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _ShelfChip extends StatelessWidget {
  const _ShelfChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.selectedValue,
    required this.onSelected,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : color,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: color,
      backgroundColor: _surface,
      side: BorderSide(color: selected ? color : _border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontWeight: FontWeight.w900,
      ),
      onSelected: (_) => onSelected(value),
    );
  }
}

class _StarterPacks extends StatelessWidget {
  const _StarterPacks({
    required this.shelfLabel,
    required this.color,
    required this.onPackSelected,
  });

  final String shelfLabel;
  final Color color;
  final ValueChanged<List<String>> onPackSelected;

  @override
  Widget build(BuildContext context) {
    final packs = [
      const _PackData(
        title: 'Easy salad',
        cropIds: ['lettuce', 'rocket', 'radish', 'spring_onion', 'parsley'],
      ),
      const _PackData(
        title: 'Container picks',
        cropIds: [
          'lettuce',
          'chilli',
          'tomato',
          'spring_onion',
          'basil',
          'parsley'
        ],
      ),
      const _PackData(
        title: 'Winter hardy',
        cropIds: ['kale', 'silverbeet', 'broad_beans', 'garlic', 'peas'],
      ),
      const _PackData(
        title: 'Summer food',
        cropIds: ['tomato', 'courgette', 'cucumber', 'dwarf_beans', 'basil'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$shelfLabel starter packs',
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packs.map((pack) {
            return ActionChip(
              avatar: Icon(Icons.auto_awesome_outlined, color: color, size: 18),
              label: Text(pack.title),
              onPressed: () => onPackSelected(pack.cropIds),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ChoiceData {
  const _ChoiceData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _PackData {
  const _PackData({
    required this.title,
    required this.cropIds,
  });

  final String title;
  final List<String> cropIds;
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

const _goalOptions = [
  _GoalOption(
    id: 'food_production',
    label: 'Grow more food',
    icon: Icons.restaurant_outlined,
  ),
  _GoalOption(
    id: 'beginner_friendly',
    label: 'Keep it easy',
    icon: Icons.sentiment_satisfied_alt_outlined,
  ),
  _GoalOption(
    id: 'containers',
    label: 'Small spaces',
    icon: Icons.inventory_2_outlined,
  ),
  _GoalOption(
    id: 'pest_control',
    label: 'Fewer pests',
    icon: Icons.bug_report_outlined,
  ),
  _GoalOption(
    id: 'water_saving',
    label: 'Save water',
    icon: Icons.water_drop_outlined,
  ),
  _GoalOption(
    id: 'year_round',
    label: 'Year-round food',
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
