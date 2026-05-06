import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/garden_profile_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_profile.dart';
import '../crops/crop_detail_screen.dart';
import 'garden_profile_setup_screen.dart';

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

class GardenProfileScreen extends StatefulWidget {
  const GardenProfileScreen({super.key});

  @override
  State<GardenProfileScreen> createState() => _GardenProfileScreenState();
}

class _GardenProfileScreenState extends State<GardenProfileScreen> {
  final _settingsRepository = const AppSettingsRepository();
  final _profileRepository = const GardenProfileRepository();
  final _dataRepository = const GardenDataRepository();

  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadData();
  }

  Future<_ProfileData> _loadData() async {
    final settings = await _settingsRepository.loadSettings();
    final profile = await _profileRepository.loadProfile();
    final crops = await _dataRepository.loadCrops();

    return _ProfileData(
      settings: settings,
      profile: profile,
      crops: crops,
      cropById: {for (final crop in crops) crop.id: crop},
    );
  }

  Future<void> _openSetup() async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const GardenProfileSetupScreen(),
      ),
    );

    if (changed == true && mounted) {
      setState(() => _profileFuture = _loadData());
    }
  }

  void _openCrop(Crop crop) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropDetailScreen(crop: crop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('My Garden'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Edit passport',
            onPressed: _openSetup,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load My Garden: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No profile data found.'));
          }

          final growing =
              _cropsForIds(data.profile.growingCropIds, data.cropById);
          final want =
              _cropsForIds(data.profile.wishlistCropIds, data.cropById);
          final avoid =
              _cropsForIds(data.profile.avoidedCropIds, data.cropById);
          final recommended = _recommendedCrops(data);

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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                children: [
                  _PassportHero(
                    settings: data.settings,
                    profile: data.profile,
                    growingCount: growing.length,
                    wantCount: want.length,
                    onEdit: _openSetup,
                  ),
                  const SizedBox(height: 14),
                  if (!data.profile.setupComplete)
                    _StartCard(onTap: _openSetup)
                  else ...[
                    _FocusCard(data: data),
                    const SizedBox(height: 14),
                    _PlantShelf(
                      title: 'Growing now',
                      subtitle: 'Your active crops.',
                      icon: Icons.eco_outlined,
                      color: _leaf,
                      crops: growing,
                      emptyText: 'Add what is already in your garden.',
                      onCropTap: _openCrop,
                      onAddTap: _openSetup,
                    ),
                    const SizedBox(height: 14),
                    _PlantShelf(
                      title: 'Want to grow',
                      subtitle: 'Your planning shortlist.',
                      icon: Icons.favorite_border,
                      color: _clay,
                      crops: want,
                      emptyText: 'Add crops you are thinking about.',
                      onCropTap: _openCrop,
                      onAddTap: _openSetup,
                    ),
                    const SizedBox(height: 14),
                    _PlantShelf(
                      title: 'Good next picks',
                      subtitle: 'Simple suggestions from your garden passport.',
                      icon: Icons.auto_awesome_outlined,
                      color: _moss,
                      crops: recommended,
                      emptyText: 'Add your goals to improve suggestions.',
                      onCropTap: _openCrop,
                      onAddTap: _openSetup,
                    ),
                    if (avoid.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _PlantShelf(
                        title: 'Skip for now',
                        subtitle: 'The app should avoid pushing these.',
                        icon: Icons.block_outlined,
                        color: _berry,
                        crops: avoid,
                        emptyText: '',
                        onCropTap: _openCrop,
                        onAddTap: _openSetup,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Crop> _cropsForIds(List<String> ids, Map<String, Crop> cropById) {
    return ids
        .map((id) => cropById[id])
        .whereType<Crop>()
        .toList(growable: false)
      ..sort((a, b) => a.commonName.compareTo(b.commonName));
  }

  List<Crop> _recommendedCrops(_ProfileData data) {
    final excluded = {
      ...data.profile.growingCropIds,
      ...data.profile.wishlistCropIds,
      ...data.profile.avoidedCropIds,
    };

    final wantsContainers = data.settings.gardenType == 'container' ||
        data.profile.goalIds.contains('containers');
    final wantsBeginner = data.profile.experienceLevel == 'beginner' ||
        data.profile.goalIds.contains('beginner_friendly');

    final candidates = data.crops
        .where((crop) => !excluded.contains(crop.id))
        .toList(growable: false);

    candidates.sort((a, b) {
      final scoreCompare =
          _scoreCrop(b, wantsContainers, wantsBeginner).compareTo(
        _scoreCrop(a, wantsContainers, wantsBeginner),
      );

      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return a.commonName.compareTo(b.commonName);
    });

    return candidates.take(8).toList(growable: false);
  }

  int _scoreCrop(Crop crop, bool wantsContainers, bool wantsBeginner) {
    var score = 0;

    if (wantsContainers && crop.containerFriendly) {
      score += 20;
    }

    if (wantsBeginner && crop.beginnerFriendly) {
      score += 18;
    }

    if (!crop.frostTender) {
      score += 5;
    }

    if (crop.waterRequirement == 'regular') {
      score += 3;
    }

    return score;
  }
}

class _PassportHero extends StatelessWidget {
  const _PassportHero({
    required this.settings,
    required this.profile,
    required this.growingCount,
    required this.wantCount,
    required this.onEdit,
  });

  final AppSettings settings;
  final GardenProfile profile;
  final int growingCount;
  final int wantCount;
  final VoidCallback onEdit;

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
              _GlassPill(
                  label:
                      '${_formatValue(settings.regionId)} · ${_formatValue(settings.gardenType)}'),
              const SizedBox(height: 20),
              const Text(
                'Garden\nPassport',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.setupComplete
                    ? '$growingCount growing · $wantCount planned · ${profile.goalIds.length} goals.'
                    : 'A lighter way to tell the app what your garden is like.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .86),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profile.setupComplete
                                ? 'Tune my passport'
                                : 'Create passport',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Start small',
      subtitle:
          'Choose a garden style, a few goals, and a few crops. Skip anything you are unsure about.',
      icon: Icons.rocket_launch_outlined,
      color: _leaf,
      children: [
        FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.yard_outlined),
          label: const Text('Create Garden Passport'),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    final focus = _focusText(data);

    return _Panel(
      title: 'Your garden focus',
      subtitle: focus,
      icon: Icons.center_focus_strong_outlined,
      color: _leaf,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SmallTag(
                label: _formatValue(data.settings.gardenType), color: _leaf),
            _SmallTag(
                label: '${_formatValue(data.settings.frostRisk)} frost',
                color: _clay),
            _SmallTag(
                label: '${_formatValue(data.settings.windExposure)} wind',
                color: _leafDark),
            _SmallTag(
                label: _formatValue(data.profile.experienceLevel),
                color: _moss),
            ...data.profile.goalIds.take(4).map(
                  (goalId) =>
                      _SmallTag(label: _formatValue(goalId), color: _berry),
                ),
          ],
        ),
      ],
    );
  }

  String _focusText(_ProfileData data) {
    if (data.profile.goalIds.contains('containers') ||
        data.settings.gardenType == 'container') {
      return 'Prioritise container-friendly crops and regular watering checks.';
    }

    if (data.profile.goalIds.contains('beginner_friendly') ||
        data.profile.experienceLevel == 'beginner') {
      return 'Prioritise easy crops, simple jobs, and clear next steps.';
    }

    if (data.profile.goalIds.contains('pest_control')) {
      return 'Prioritise pest watch-outs and prevention before problems spread.';
    }

    if (data.profile.goalIds.contains('year_round')) {
      return 'Prioritise succession sowing and crops that keep the garden producing.';
    }

    return 'Keep advice focused on your saved crops and local conditions.';
  }
}

class _PlantShelf extends StatelessWidget {
  const _PlantShelf({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.crops,
    required this.emptyText,
    required this.onCropTap,
    required this.onAddTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Crop> crops;
  final String emptyText;
  final ValueChanged<Crop> onCropTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      children: [
        if (crops.isEmpty)
          _EmptyShelf(
            text: emptyText,
            color: color,
            onTap: onAddTap,
          )
        else
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: crops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final crop = crops[index];

                return _CropCard(
                  crop: crop,
                  color: color,
                  onTap: () => onCropTap(crop),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({
    required this.crop,
    required this.color,
    required this.onTap,
  });

  final Crop crop;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Material(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBubble(
                  icon: crop.containerFriendly
                      ? Icons.inventory_2_outlined
                      : Icons.eco_outlined,
                  color: color,
                  size: 42,
                ),
                const Spacer(),
                Text(
                  crop.commonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${crop.spacingCm} cm · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax}d',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

class _ProfileData {
  const _ProfileData({
    required this.settings,
    required this.profile,
    required this.crops,
    required this.cropById,
  });

  final AppSettings settings;
  final GardenProfile profile;
  final List<Crop> crops;
  final Map<String, Crop> cropById;
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
