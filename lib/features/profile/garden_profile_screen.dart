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

    final cropById = {for (final crop in crops) crop.id: crop};

    return _ProfileData(
      settings: settings,
      profile: profile,
      crops: crops,
      cropById: cropById,
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
      setState(() {
        _profileFuture = _loadData();
      });
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
            tooltip: 'Edit My Garden',
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

          final growingCrops =
              _cropsForIds(data.profile.growingCropIds, data.cropById);
          final wishlistCrops =
              _cropsForIds(data.profile.wishlistCropIds, data.cropById);
          final avoidedCrops =
              _cropsForIds(data.profile.avoidedCropIds, data.cropById);
          final recommendedCrops = _recommendedCrops(data);

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
                  _ProfileHero(
                    settings: data.settings,
                    profile: data.profile,
                    growingCount: growingCrops.length,
                    wishlistCount: wishlistCrops.length,
                    onEdit: _openSetup,
                  ),
                  const SizedBox(height: 14),
                  if (!data.profile.setupComplete)
                    _GetStartedCard(onTap: _openSetup)
                  else ...[
                    _GardenReadoutCard(
                      settings: data.settings,
                      profile: data.profile,
                    ),
                    const SizedBox(height: 14),
                    _CropSection(
                      title: 'Growing now',
                      subtitle:
                          'These crops should get priority in advice and checks.',
                      icon: Icons.eco_outlined,
                      color: _leaf,
                      crops: growingCrops,
                      emptyText: 'No crops marked as growing yet.',
                      onCropTap: _openCrop,
                    ),
                    const SizedBox(height: 14),
                    _CropSection(
                      title: 'Want to grow',
                      subtitle: 'Use this as your planning shortlist.',
                      icon: Icons.favorite_border,
                      color: _clay,
                      crops: wishlistCrops,
                      emptyText: 'No wishlist crops selected yet.',
                      onCropTap: _openCrop,
                    ),
                    const SizedBox(height: 14),
                    _CropSection(
                      title: 'Recommended next',
                      subtitle:
                          'Based on your goals, garden type, and current selections.',
                      icon: Icons.auto_awesome_outlined,
                      color: _moss,
                      crops: recommendedCrops,
                      emptyText:
                          'Add goals and crops to improve recommendations.',
                      onCropTap: _openCrop,
                    ),
                    if (avoidedCrops.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _CropSection(
                        title: 'Avoid for now',
                        subtitle: 'The app should avoid pushing these crops.',
                        icon: Icons.block_outlined,
                        color: _berry,
                        crops: avoidedCrops,
                        emptyText: 'No avoided crops selected.',
                        onCropTap: _openCrop,
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
      final aScore = _cropScore(a,
          wantsContainers: wantsContainers, wantsBeginner: wantsBeginner);
      final bScore = _cropScore(b,
          wantsContainers: wantsContainers, wantsBeginner: wantsBeginner);
      final scoreCompare = bScore.compareTo(aScore);

      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return a.commonName.compareTo(b.commonName);
    });

    return candidates.take(6).toList(growable: false);
  }

  int _cropScore(
    Crop crop, {
    required bool wantsContainers,
    required bool wantsBeginner,
  }) {
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.settings,
    required this.profile,
    required this.growingCount,
    required this.wishlistCount,
    required this.onEdit,
  });

  final AppSettings settings;
  final GardenProfile profile;
  final int growingCount;
  final int wishlistCount;
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
                'My Garden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 39,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.setupComplete
                    ? '$growingCount growing now · $wishlistCount want to grow · ${profile.goalIds.length} garden goals.'
                    : 'Set up your garden once so the app can prioritise the crops, jobs, and risks that matter.',
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
                                ? 'Edit My Garden profile'
                                : 'Set up My Garden',
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

class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Start with your real garden',
      subtitle:
          'Pick your crops, goals, frost risk, and garden type. This makes the app much more useful.',
      icon: Icons.rocket_launch_outlined,
      color: _leaf,
      children: [
        FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.yard_outlined),
          label: const Text('Set up My Garden'),
        ),
      ],
    );
  }
}

class _GardenReadoutCard extends StatelessWidget {
  const _GardenReadoutCard({
    required this.settings,
    required this.profile,
  });

  final AppSettings settings;
  final GardenProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Garden readout',
      subtitle:
          'This is the context the app can use to make advice more personal.',
      icon: Icons.tune_outlined,
      color: _leaf,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SmallTag(
                label: 'Region: ${_formatValue(settings.regionId)}',
                color: _leaf),
            _SmallTag(
                label: 'Garden: ${_formatValue(settings.gardenType)}',
                color: _moss),
            _SmallTag(
                label: 'Frost: ${_formatValue(settings.frostRisk)}',
                color: _clay),
            _SmallTag(
                label: 'Wind: ${_formatValue(settings.windExposure)}',
                color: _leafDark),
            _SmallTag(
                label: 'Level: ${_formatValue(profile.experienceLevel)}',
                color: _berry),
            ...profile.goalIds.map(
              (goalId) => _SmallTag(label: _formatValue(goalId), color: _leaf),
            ),
          ],
        ),
      ],
    );
  }
}

class _CropSection extends StatelessWidget {
  const _CropSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.crops,
    required this.emptyText,
    required this.onCropTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Crop> crops;
  final String emptyText;
  final ValueChanged<Crop> onCropTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      children: [
        if (crops.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(
              color: _muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...crops.map(
            (crop) => _CropRow(
              crop: crop,
              color: color,
              onTap: () => onCropTap(crop),
            ),
          ),
      ],
    );
  }
}

class _CropRow extends StatelessWidget {
  const _CropRow({
    required this.crop,
    required this.color,
    required this.onTap,
  });

  final Crop crop;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _IconBubble(
                icon: crop.containerFriendly
                    ? Icons.inventory_2_outlined
                    : Icons.eco_outlined,
                color: color,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.commonName,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${crop.spacingCm} cm · ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
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
