import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/pest_problem.dart';
import '../../data/models/planting_rule.dart';

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

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({
    required this.crop,
    super.key,
  });

  final Crop crop;

  Future<_CropDetailData> _loadDetailData() async {
    const dataRepository = GardenDataRepository();
    const settingsRepository = AppSettingsRepository();

    final settings = await settingsRepository.loadSettings();
    final rules = await dataRepository.loadPlantingRules();
    final pests = await dataRepository.loadPestProblems();

    final cropRules = rules
        .where((rule) => rule.cropId == crop.id)
        .where((rule) => rule.appliesToRegion(settings.regionId))
        .toList(growable: false)
      ..sort((a, b) => a.startMonth.compareTo(b.startMonth));

    final cropPests = pests
        .where((problem) => problem.commonCrops.contains(crop.id))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    return _CropDetailData(
      settings: settings,
      rules: cropRules,
      pests: cropPests,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: Text(crop.commonName),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<_CropDetailData>(
        future: _loadDetailData(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CropHeroCard(
                  crop: crop,
                  data: null,
                ),
                const SizedBox(height: 14),
                _InfoPanel(
                  title: 'Could not load full crop profile',
                  subtitle:
                      'The core crop data is available, but linked planting or pest data did not load.',
                  icon: Icons.warning_amber_outlined,
                  color: _clay,
                  children: [
                    Text('${snapshot.error}'),
                  ],
                ),
              ],
            );
          }

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
                  _CropHeroCard(
                    crop: crop,
                    data: data,
                  ),
                  const SizedBox(height: 14),
                  _QuickStatsGrid(crop: crop),
                  const SizedBox(height: 14),
                  _DecisionCard(
                    crop: crop,
                    data: data,
                  ),
                  const SizedBox(height: 14),
                  _PlantingWindowsCard(
                    crop: crop,
                    data: data,
                  ),
                  const SizedBox(height: 14),
                  _HowToGrowCard(crop: crop),
                  const SizedBox(height: 14),
                  _WeeklyChecklistCard(
                    crop: crop,
                    data: data,
                  ),
                  const SizedBox(height: 14),
                  _CommonMistakesCard(crop: crop),
                  const SizedBox(height: 14),
                  _PestAndProblemsCard(
                    crop: crop,
                    data: data,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CropHeroCard extends StatelessWidget {
  const _CropHeroCard({
    required this.crop,
    required this.data,
  });

  final Crop crop;
  final _CropDetailData? data;

  @override
  Widget build(BuildContext context) {
    final verdict = _verdictForCrop(crop, data?.settings);
    final regionLabel = data == null
        ? 'Offline profile'
        : _formatValue(data!.settings.regionId);

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
            right: -26,
            bottom: -36,
            child: Icon(
              _iconForCrop(crop),
              color: Colors.white.withValues(alpha: .12),
              size: 160,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassPill(
                  label: '${_formatValue(crop.category)} · $regionLabel'),
              const SizedBox(height: 20),
              Text(
                crop.commonName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                crop.summary,
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(verdict.reason)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(verdict.icon, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            verdict.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.info_outline, color: Colors.white),
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

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        icon: Icons.straighten_outlined,
        label: 'Spacing',
        value: '${crop.spacingCm} cm',
        color: _leaf,
      ),
      _StatData(
        icon: Icons.timer_outlined,
        label: 'Harvest',
        value: '${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
        color: _clay,
      ),
      _StatData(
        icon: Icons.wb_sunny_outlined,
        label: 'Light',
        value: _formatValue(crop.sunRequirement),
        color: _sun,
      ),
      _StatData(
        icon: Icons.water_drop_outlined,
        label: 'Water',
        value: _formatValue(crop.waterRequirement),
        color: _moss,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        return _StatCard(data: stats[index]);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.crop,
    required this.data,
  });

  final Crop crop;
  final _CropDetailData? data;

  @override
  Widget build(BuildContext context) {
    final settings = data?.settings;
    final verdict = _verdictForCrop(crop, settings);

    return _InfoPanel(
      title: 'Should I grow this?',
      subtitle: verdict.reason,
      icon: verdict.icon,
      color: verdict.color,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (crop.beginnerFriendly)
              const _Tag(label: 'Good for beginners', color: _leaf),
            if (crop.containerFriendly)
              const _Tag(label: 'Container friendly', color: _moss),
            if (crop.frostTender)
              const _Tag(label: 'Needs frost protection', color: _clay)
            else
              const _Tag(label: 'Handles cool conditions', color: _leafDark),
            if (settings?.gardenType == 'container' && !crop.containerFriendly)
              const _Tag(label: 'Not ideal for containers', color: _berry),
            if (settings?.frostRisk == 'high' && crop.frostTender)
              const _Tag(label: 'Risky in frost areas', color: _berry),
          ],
        ),
      ],
    );
  }
}

class _PlantingWindowsCard extends StatelessWidget {
  const _PlantingWindowsCard({
    required this.crop,
    required this.data,
  });

  final Crop crop;
  final _CropDetailData? data;

  @override
  Widget build(BuildContext context) {
    final rules = data?.rules ?? const <PlantingRule>[];

    if (rules.isEmpty) {
      return _InfoPanel(
        title: 'Planting windows',
        subtitle: 'No linked planting window yet for your saved region.',
        icon: Icons.calendar_month_outlined,
        color: _clay,
        children: const [
          Text(
            'This crop is in the offline crop database, but it does not yet have a region-specific planting rule. Add a planting rule to make it appear in the calendar and Garden Coach.',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      );
    }

    return _InfoPanel(
      title: 'When to sow, plant, or transplant',
      subtitle: 'Windows use your saved region and the offline planting rules.',
      icon: Icons.calendar_month_outlined,
      color: _leaf,
      children: [
        ...rules.map(
          (rule) => _PlantingWindowRow(rule: rule),
        ),
      ],
    );
  }
}

class _PlantingWindowRow extends StatelessWidget {
  const _PlantingWindowRow({required this.rule});

  final PlantingRule rule;

  @override
  Widget build(BuildContext context) {
    final activity = _activityForMethod(rule.method);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: activity.color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activity.color.withValues(alpha: .16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(activity.icon, color: activity.color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activity.label} · ${_monthRange(rule.startMonth, rule.endMonth)}',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.riskNote,
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
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

class _HowToGrowCard extends StatelessWidget {
  const _HowToGrowCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'How to grow it well',
      subtitle: 'Practical growing advice based on this crop profile.',
      icon: Icons.eco_outlined,
      color: _leaf,
      children: [
        _Checklist(items: _howToGrowSteps(crop)),
      ],
    );
  }
}

class _WeeklyChecklistCard extends StatelessWidget {
  const _WeeklyChecklistCard({
    required this.crop,
    required this.data,
  });

  final Crop crop;
  final _CropDetailData? data;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'This week’s checklist',
      subtitle:
          'Use this after sowing, planting, or checking an existing crop.',
      icon: Icons.checklist_outlined,
      color: _moss,
      children: [
        _Checklist(items: _weeklyChecklist(crop, data?.settings)),
      ],
    );
  }
}

class _CommonMistakesCard extends StatelessWidget {
  const _CommonMistakesCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'Common mistakes to avoid',
      subtitle:
          'The small things that usually cause weak plants or poor harvests.',
      icon: Icons.warning_amber_outlined,
      color: _clay,
      children: [
        _Checklist(items: _commonMistakes(crop)),
      ],
    );
  }
}

class _PestAndProblemsCard extends StatelessWidget {
  const _PestAndProblemsCard({
    required this.crop,
    required this.data,
  });

  final Crop crop;
  final _CropDetailData? data;

  @override
  Widget build(BuildContext context) {
    final problems = data?.pests ?? const <PestProblem>[];

    if (problems.isEmpty) {
      return _InfoPanel(
        title: 'Likely pests and problems',
        subtitle: 'No linked pest or problem entries yet.',
        icon: Icons.bug_report_outlined,
        color: _berry,
        children: const [
          Text(
            'This will improve as the offline pest database expands. For now, check leaves, stems, soil moisture, and new growth regularly.',
            style: TextStyle(
              color: _muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return _InfoPanel(
      title: 'Likely pests and problems',
      subtitle: 'Signs to watch for and practical actions to take.',
      icon: Icons.bug_report_outlined,
      color: _berry,
      children: [
        ...problems.map(
          (problem) => _ProblemCard(problem: problem),
        ),
      ],
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.problem});

  final PestProblem problem;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      leading: Icon(_iconForProblem(problem), color: _berry),
      title: Text(
        problem.name,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(_formatValue(problem.category)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            problem.summary,
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _MiniList(title: 'Signs', items: problem.signs),
        _MiniList(title: 'What to do', items: problem.actions),
        _MiniList(title: 'Prevention', items: problem.prevention),
        if (problem.seasonNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            problem.seasonNotes,
            style: const TextStyle(
              color: _muted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
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
                  letterSpacing: -.2,
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

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, color: _leaf, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MiniList extends StatelessWidget {
  const _MiniList({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          ...items.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                            color: _leaf, fontWeight: FontWeight.w900),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: _muted,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
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
      side: BorderSide(color: color.withValues(alpha: .16)),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
      ),
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

class _CropDetailData {
  const _CropDetailData({
    required this.settings,
    required this.rules,
    required this.pests,
  });

  final AppSettings settings;
  final List<PlantingRule> rules;
  final List<PestProblem> pests;
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _Verdict {
  const _Verdict({
    required this.title,
    required this.reason,
    required this.icon,
    required this.color,
  });

  final String title;
  final String reason;
  final IconData icon;
  final Color color;
}

class _ActivityData {
  const _ActivityData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_Verdict _verdictForCrop(Crop crop, AppSettings? settings) {
  if (settings?.gardenType == 'container' && !crop.containerFriendly) {
    return const _Verdict(
      title: 'Better in a garden bed',
      reason:
          'This crop usually needs more root room or space than a normal container gives.',
      icon: Icons.yard_outlined,
      color: _clay,
    );
  }

  if (settings?.frostRisk == 'high' && crop.frostTender) {
    return const _Verdict(
      title: 'Grow with frost protection',
      reason:
          'This crop is frost tender and your saved settings show high frost risk.',
      icon: Icons.ac_unit_outlined,
      color: _berry,
    );
  }

  if (crop.beginnerFriendly && crop.containerFriendly) {
    return const _Verdict(
      title: 'Strong home-garden pick',
      reason:
          'This crop is beginner-friendly and can work in containers or smaller spaces.',
      icon: Icons.thumb_up_alt_outlined,
      color: _leaf,
    );
  }

  if (crop.beginnerFriendly) {
    return const _Verdict(
      title: 'Good beginner crop',
      reason:
          'This crop is marked as beginner-friendly in the offline crop database.',
      icon: Icons.sentiment_satisfied_alt_outlined,
      color: _leaf,
    );
  }

  return const _Verdict(
    title: 'Worth growing with care',
    reason:
        'This crop can be useful, but it needs more attention to timing, water, spacing, or protection.',
    icon: Icons.eco_outlined,
    color: _moss,
  );
}

List<String> _howToGrowSteps(Crop crop) {
  final steps = <String>[
    crop.sunRequirement == 'full_sun'
        ? 'Choose a sunny position with good airflow.'
        : 'Use sun or part shade, especially during hotter months.',
    'Allow about ${crop.spacingCm} cm between plants so roots and leaves have room.',
  ];

  if (crop.waterRequirement == 'regular') {
    steps.add(
        'Keep soil evenly moist, especially while seeds or seedlings establish.');
  } else if (crop.waterRequirement == 'high') {
    steps.add(
        'Keep moisture steady; this crop struggles if it dries out repeatedly.');
  } else {
    steps.add('Water deeply, then let the soil settle before watering again.');
  }

  if (crop.containerFriendly) {
    steps.add(
        'Use a container with drainage holes and refresh nutrients during the season.');
  }

  if (crop.frostTender) {
    steps.add(
        'Avoid frost. Start under cover or wait until nights are reliably warm.');
  } else {
    steps.add(
        'This crop can handle cooler conditions better than tender summer crops.');
  }

  steps.add(
      'Expect harvest around ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days, depending on weather and growth.');

  return steps;
}

List<String> _weeklyChecklist(Crop crop, AppSettings? settings) {
  return [
    'Check soil moisture around the root zone, not only the surface.',
    'Look under leaves for pests, eggs, chewing damage, or yellowing.',
    'Remove weeds while small so they do not compete for water and nutrients.',
    if (crop.waterRequirement == 'regular' || crop.waterRequirement == 'high')
      'Keep watering consistent to avoid stress, splitting, bolting, or poor growth.',
    if (crop.containerFriendly || settings?.gardenType == 'container')
      'Check containers more often than garden beds because they dry out faster.',
    if (crop.frostTender || settings?.frostRisk == 'high')
      'Keep frost cloth, cloches, or shelter ready for cold nights.',
  ];
}

List<String> _commonMistakes(Crop crop) {
  final mistakes = <String>[
    'Planting too close. Use the spacing guide so plants can breathe and crop properly.',
    'Letting seedlings dry out while young.',
    'Forgetting to label sowing dates, which makes harvest timing harder to judge.',
  ];

  if (crop.frostTender) {
    mistakes
        .add('Planting outside too early before cold nights have finished.');
  }

  if (crop.containerFriendly) {
    mistakes.add(
        'Using a small pot without enough drainage, compost, or regular feeding.');
  }

  if (crop.waterRequirement == 'regular' || crop.waterRequirement == 'high') {
    mistakes.add(
        'Watering irregularly, which can stress roots and reduce harvest quality.');
  }

  if (crop.sunRequirement == 'full_sun') {
    mistakes.add(
        'Putting it in too much shade, which can slow growth and reduce harvest.');
  }

  return mistakes;
}

_ActivityData _activityForMethod(String method) {
  return switch (method) {
    'transplant' => const _ActivityData(
        label: 'Transplant',
        icon: Icons.move_down_outlined,
        color: _clay,
      ),
    'plant_tubers' => const _ActivityData(
        label: 'Plant tubers',
        icon: Icons.spa_outlined,
        color: _moss,
      ),
    'plant_crowns' => const _ActivityData(
        label: 'Plant crowns',
        icon: Icons.spa_outlined,
        color: _moss,
      ),
    _ => const _ActivityData(
        label: 'Sow',
        icon: Icons.grass_outlined,
        color: _leaf,
      ),
  };
}

IconData _iconForCrop(Crop crop) {
  if (crop.category == 'herb') {
    return Icons.local_florist_outlined;
  }

  if (crop.frostTender) {
    return Icons.wb_sunny_outlined;
  }

  if (crop.containerFriendly) {
    return Icons.inventory_2_outlined;
  }

  return Icons.eco_outlined;
}

IconData _iconForProblem(PestProblem problem) {
  return switch (problem.category) {
    'pest' => Icons.bug_report_outlined,
    'disease' => Icons.coronavirus_outlined,
    'crop_problem' => Icons.warning_amber_outlined,
    _ => Icons.info_outline,
  };
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _monthName(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

String _shortMonthName(int month) {
  return _monthName(month).substring(0, 3);
}

String _monthRange(int startMonth, int endMonth) {
  if (startMonth == endMonth) {
    return _monthName(startMonth);
  }

  return '${_shortMonthName(startMonth)}–${_shortMonthName(endMonth)}';
}
