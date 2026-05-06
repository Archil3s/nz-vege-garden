import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_settings_repository.dart';
import '../../data/garden_action_service.dart';
import '../../data/garden_data_repository.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_action.dart';
import '../../data/models/planting_rule.dart';
import '../crops/crop_detail_screen.dart';

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

class GardenCoachScreen extends StatefulWidget {
  const GardenCoachScreen({super.key});

  @override
  State<GardenCoachScreen> createState() => _GardenCoachScreenState();
}

class _GardenCoachScreenState extends State<GardenCoachScreen> {
  final _settingsRepository = const AppSettingsRepository();
  final _dataRepository = const GardenDataRepository();
  final _actionService = const GardenActionService();

  late Future<_CoachData> _coachFuture;
  GardenActionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _coachFuture = _loadCoachData();
  }

  Future<_CoachData> _loadCoachData() async {
    final now = DateTime.now();
    final month = now.month;
    final nextMonth = month == 12 ? 1 : month + 1;

    final settings = await _settingsRepository.loadSettings();
    final crops = await _dataRepository.loadCrops();
    final rules = await _dataRepository.loadPlantingRules();

    final actions = _actionService.buildActions(
      crops: crops,
      rules: rules,
      settings: settings,
      month: month,
    );

    final nextMonthActions = _actionService.buildActions(
      crops: crops,
      rules: rules,
      settings: settings,
      month: nextMonth,
    );

    return _CoachData(
      settings: settings,
      month: month,
      nextMonth: nextMonth,
      cropsById: {for (final crop in crops) crop.id: crop},
      rules: rules,
      actions: actions,
      nextMonthActions: nextMonthActions,
    );
  }

  void _openCrop(Crop crop) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropDetailScreen(crop: crop),
      ),
    );
  }

  void _showActionSheet({
    required GardenAction action,
    required Map<String, Crop> cropsById,
  }) {
    HapticFeedback.heavyImpact();
    final crop = action.cropId == null ? null : cropsById[action.cropId];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _ActionBubble(type: action.type, size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.reason,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...action.steps.map((step) => _ActionStep(text: step)),
                if (crop != null) ...[
                  const SizedBox(height: 10),
                  _SheetButton(
                    icon: Icons.menu_book_outlined,
                    label: 'Open ${crop.commonName} details',
                    color: action.type.color,
                    onTap: () {
                      Navigator.pop(context);
                      _openCrop(crop);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<GardenAction> _filteredActions(List<GardenAction> actions) {
    if (_selectedType == null) {
      return actions;
    }

    return actions
        .where((action) => action.type == _selectedType)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Garden Coach'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh advice',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _coachFuture = _loadCoachData();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_CoachData>(
        future: _coachFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load coach advice: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No coach data found.'));
          }

          final filteredActions = _filteredActions(data.actions);
          final bestAction = data.actions.isEmpty ? null : data.actions.first;
          final nextMonthPreview =
              data.nextMonthActions.take(4).toList(growable: false);

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
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CoachHero(
                        data: data,
                        bestAction: bestAction,
                        onBestAction: bestAction == null
                            ? null
                            : () => _showActionSheet(
                                  action: bestAction,
                                  cropsById: data.cropsById,
                                ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ActionTypePicker(
                        selectedType: _selectedType,
                        onSelected: (type) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedType = type);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CoachSummaryCard(actions: data.actions),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(
                        eyebrow: 'Today',
                        title: _selectedType == null
                            ? 'Best garden actions'
                            : _selectedType!.sectionTitle,
                        subtitle:
                            'Tap a card for practical steps. Long-press for the same quick checklist.',
                      ),
                    ),
                  ),
                  if (filteredActions.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyCoachCard(selectedType: _selectedType),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: filteredActions.length,
                          (context, index) {
                            final action = filteredActions[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GardenActionCard(
                                action: action,
                                onTap: () => _showActionSheet(
                                  action: action,
                                  cropsById: data.cropsById,
                                ),
                                onLongPress: () => _showActionSheet(
                                  action: action,
                                  cropsById: data.cropsById,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _NextMonthCard(
                        month: data.nextMonth,
                        actions: nextMonthPreview,
                        onActionTap: (action) => _showActionSheet(
                          action: action,
                          cropsById: data.cropsById,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
                    sliver: SliverToBoxAdapter(
                      child: _SettingsContextCard(settings: data.settings),
                    ),
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

class _CoachHero extends StatelessWidget {
  const _CoachHero({
    required this.data,
    required this.bestAction,
    required this.onBestAction,
  });

  final _CoachData data;
  final GardenAction? bestAction;
  final VoidCallback? onBestAction;

  @override
  Widget build(BuildContext context) {
    final actionCount = data.actions
        .where((action) => action.type != GardenActionType.watch)
        .length;
    final watchCount = data.actions
        .where((action) => action.type == GardenActionType.watch)
        .length;

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
            bottom: -32,
            child: Icon(
              Icons.eco_outlined,
              size: 156,
              color: Colors.white.withValues(alpha: .11),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassPill(
                  label:
                      '${_monthName(data.month)} · ${_formatValue(data.settings.regionId)}'),
              const SizedBox(height: 20),
              const Text(
                'Today in\nyour garden',
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
                '$actionCount practical jobs and $watchCount watch-outs based on your saved garden setup.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .84),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              if (bestAction == null)
                const _HeroEmptyHint()
              else
                _HeroBestAction(
                  action: bestAction!,
                  onTap: onBestAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBestAction extends StatelessWidget {
  const _HeroBestAction({
    required this.action,
    required this.onTap,
  });

  final GardenAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(action.type.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
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
    );
  }
}

class _HeroEmptyHint extends StatelessWidget {
  const _HeroEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.spa_outlined, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quiet month. Prepare beds and look ahead.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTypePicker extends StatelessWidget {
  const _ActionTypePicker({
    required this.selectedType,
    required this.onSelected,
  });

  final GardenActionType? selectedType;
  final ValueChanged<GardenActionType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ChoiceChip(
        avatar: Icon(
          Icons.grid_view_outlined,
          size: 18,
          color: selectedType == null ? Colors.white : _leaf,
        ),
        label: const Text('All'),
        selected: selectedType == null,
        selectedColor: _leaf,
        backgroundColor: _surface,
        side: BorderSide(color: selectedType == null ? _leaf : _border),
        labelStyle: TextStyle(
          color: selectedType == null ? Colors.white : _ink,
          fontWeight: FontWeight.w900,
        ),
        onSelected: (_) => onSelected(null),
      ),
      ...GardenActionType.values.map(
        (type) {
          final selected = selectedType == type;
          return ChoiceChip(
            avatar: Icon(
              type.icon,
              size: 18,
              color: selected ? Colors.white : type.color,
            ),
            label: Text(type.label),
            selected: selected,
            selectedColor: type.color,
            backgroundColor: _surface,
            side: BorderSide(color: selected ? type.color : _border),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w900,
            ),
            onSelected: (_) => onSelected(type),
          );
        },
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _CoachSummaryCard extends StatelessWidget {
  const _CoachSummaryCard({required this.actions});

  final List<GardenAction> actions;

  @override
  Widget build(BuildContext context) {
    final sow = _count(GardenActionType.sow);
    final transplant = _count(GardenActionType.transplant);
    final plant = _count(GardenActionType.plant);
    final harvest = _count(GardenActionType.harvest);
    final watch = _count(GardenActionType.watch);

    return Container(
      padding: const EdgeInsets.all(16),
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
          const _SmallTag(label: 'Garden readout', color: _leaf),
          const SizedBox(height: 12),
          Text(
            _summaryText(
              sow: sow,
              transplant: transplant,
              plant: plant,
              harvest: harvest,
              watch: watch,
            ),
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountPill(type: GardenActionType.sow, count: sow),
              _CountPill(type: GardenActionType.transplant, count: transplant),
              _CountPill(type: GardenActionType.plant, count: plant),
              _CountPill(type: GardenActionType.harvest, count: harvest),
              _CountPill(type: GardenActionType.watch, count: watch),
            ],
          ),
        ],
      ),
    );
  }

  int _count(GardenActionType type) {
    return actions.where((action) => action.type == type).length;
  }

  String _summaryText({
    required int sow,
    required int transplant,
    required int plant,
    required int harvest,
    required int watch,
  }) {
    final planting = sow + transplant + plant;

    if (planting == 0 && harvest == 0) {
      return 'Quiet month. Focus on soil, compost, supports, watering setup, and planning.';
    }

    if (watch > 0 && planting > 0) {
      return 'Planting is possible, but check the watch-outs before you start.';
    }

    if (sow >= transplant && sow >= plant && sow > 0) {
      return 'Seed-starting month. Small repeat sowings will be more useful than one big batch.';
    }

    if (transplant >= sow && transplant >= plant && transplant > 0) {
      return 'Transplant month. Harden seedlings off and protect them from wind or cold.';
    }

    if (plant > 0) {
      return 'Planting month. Good time for tubers, cloves, crowns, or established plants.';
    }

    return 'Harvest and maintenance month. Pick regularly and prepare for the next sowing window.';
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.type,
    required this.count,
  });

  final GardenActionType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(type.icon, size: 18, color: type.color),
      label: Text('${type.label}: $count'),
      backgroundColor: type.color.withValues(alpha: .10),
      side: BorderSide(color: type.color.withValues(alpha: .18)),
      labelStyle: TextStyle(
        color: type.color,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallTag(label: eyebrow, color: _leaf),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 23,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GardenActionCard extends StatelessWidget {
  const _GardenActionCard({
    required this.action,
    required this.onTap,
    required this.onLongPress,
  });

  final GardenAction action;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: action.type.color.withValues(alpha: .16)),
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
                Row(
                  children: [
                    _ActionBubble(type: action.type, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SmallTag(
                        label: action.type.label, color: action.type.color),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  action.subtitle,
                  style: const TextStyle(
                    color: _ink,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.reason,
                  style: const TextStyle(
                    color: _muted,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: action.tags
                      .take(5)
                      .map(
                        (tag) => _InfoChip(label: tag),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap for steps · hold for checklist',
                        style: TextStyle(
                          color: action.type.color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: action.type.color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextMonthCard extends StatelessWidget {
  const _NextMonthCard({
    required this.month,
    required this.actions,
    required this.onActionTap,
  });

  final int month;
  final List<GardenAction> actions;
  final ValueChanged<GardenAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallTag(label: 'Look ahead', color: _moss),
          const SizedBox(height: 10),
          Text(
            'Coming in ${_monthName(month)}',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (actions.isEmpty)
            const Text(
              'No next-month actions found yet.',
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...actions.map(
              (action) => _MiniActionRow(
                action: action,
                onTap: () => onActionTap(action),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniActionRow extends StatelessWidget {
  const _MiniActionRow({
    required this.action,
    required this.onTap,
  });

  final GardenAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              _ActionBubble(type: action.type, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: action.type.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsContextCard extends StatelessWidget {
  const _SettingsContextCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final items = [
      'Region: ${_formatValue(settings.regionId)}',
      'Frost: ${_formatValue(settings.frostRisk)}',
      'Wind: ${_formatValue(settings.windExposure)}',
      'Garden: ${_formatValue(settings.gardenType)}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mint.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advice is based on',
            style: TextStyle(
              color: _leafDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _InfoChip(label: item))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _EmptyCoachCard extends StatelessWidget {
  const _EmptyCoachCard({required this.selectedType});

  final GardenActionType? selectedType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmallTag(label: 'Nothing urgent', color: _clay),
          const SizedBox(height: 12),
          Text(
            selectedType == null
                ? 'No coach actions found.'
                : 'No ${selectedType!.label.toLowerCase()} actions found.',
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use quiet time to prepare compost, clean trays, check water, sharpen tools, or plan next month.',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStep extends StatelessWidget {
  const _ActionStep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
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
              text,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
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

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({
    required this.type,
    required this.size,
  });

  final GardenActionType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(
        type.icon,
        color: type.color,
        size: size * .48,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: _mint.withValues(alpha: .70),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: _leafDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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

class _CoachData {
  const _CoachData({
    required this.settings,
    required this.month,
    required this.nextMonth,
    required this.cropsById,
    required this.rules,
    required this.actions,
    required this.nextMonthActions,
  });

  final AppSettings settings;
  final int month;
  final int nextMonth;
  final Map<String, Crop> cropsById;
  final List<PlantingRule> rules;
  final List<GardenAction> actions;
  final List<GardenAction> nextMonthActions;
}

extension _GardenActionTypePresentation on GardenActionType {
  String get label {
    return switch (this) {
      GardenActionType.sow => 'Sow',
      GardenActionType.transplant => 'Transplant',
      GardenActionType.plant => 'Plant',
      GardenActionType.harvest => 'Harvest',
      GardenActionType.watch => 'Watch',
      GardenActionType.prep => 'Prep',
    };
  }

  String get sectionTitle {
    return switch (this) {
      GardenActionType.sow => 'Seeds to sow',
      GardenActionType.transplant => 'Seedlings to move',
      GardenActionType.plant => 'Things to plant',
      GardenActionType.harvest => 'Likely harvests',
      GardenActionType.watch => 'Garden watch-outs',
      GardenActionType.prep => 'Preparation jobs',
    };
  }

  IconData get icon {
    return switch (this) {
      GardenActionType.sow => Icons.grass_outlined,
      GardenActionType.transplant => Icons.move_down_outlined,
      GardenActionType.plant => Icons.spa_outlined,
      GardenActionType.harvest => Icons.shopping_basket_outlined,
      GardenActionType.watch => Icons.visibility_outlined,
      GardenActionType.prep => Icons.construction_outlined,
    };
  }

  Color get color {
    return switch (this) {
      GardenActionType.sow => _leaf,
      GardenActionType.transplant => _clay,
      GardenActionType.plant => _moss,
      GardenActionType.harvest => _berry,
      GardenActionType.watch => _leafDark,
      GardenActionType.prep => _muted,
    };
  }
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

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
