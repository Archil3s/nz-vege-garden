import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/garden_data_repository.dart';
import '../../data/garden_memory_service.dart';
import '../../data/garden_profile_repository.dart';
import '../../data/garden_quick_log_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/garden_memory.dart';
import '../../data/models/garden_profile.dart';
import '../../data/models/garden_quick_log.dart';
import '../crops/crop_detail_screen.dart';
import '../profile/garden_profile_screen.dart';

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

class GardenMemoryScreen extends StatefulWidget {
  const GardenMemoryScreen({super.key});

  @override
  State<GardenMemoryScreen> createState() => _GardenMemoryScreenState();
}

class _GardenMemoryScreenState extends State<GardenMemoryScreen> {
  final _dataRepository = const GardenDataRepository();
  final _profileRepository = const GardenProfileRepository();
  final _logRepository = const GardenQuickLogRepository();
  final _memoryService = const GardenMemoryService();

  late Future<_GardenMemoryData> _memoryFuture;

  @override
  void initState() {
    super.initState();
    _memoryFuture = _loadMemory();
  }

  Future<_GardenMemoryData> _loadMemory() async {
    final profile = await _profileRepository.loadProfile();
    final crops = await _dataRepository.loadCrops();
    final logs = await _logRepository.loadLogs();
    final cropById = {for (final crop in crops) crop.id: crop};

    final summary = _memoryService.buildSummary(
      profile: profile,
      cropById: cropById,
      logs: logs,
      now: DateTime.now(),
    );

    return _GardenMemoryData(
      profile: profile,
      crops: crops,
      cropById: cropById,
      logs: logs,
      summary: summary,
    );
  }

  Future<void> _addLog(GardenQuickLog log) async {
    await _logRepository.addLog(log);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${log.label} saved.')),
    );

    setState(() => _memoryFuture = _loadMemory());
  }

  Future<void> _openLogSheet(_GardenMemoryData data) async {
    HapticFeedback.selectionClick();

    final log = await showModalBottomSheet<GardenQuickLog>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _surface,
      builder: (context) {
        return _SmartLogSheet(data: data);
      },
    );

    if (log != null) {
      await _addLog(log);
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

  Future<void> _openPassport() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GardenProfileScreen(),
      ),
    );

    if (mounted) {
      setState(() => _memoryFuture = _loadMemory());
    }
  }

  Future<void> _clearLogs() async {
    HapticFeedback.selectionClick();

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear garden memory?'),
          content: const Text(
            'This clears quick logs stored on this device. Your Garden Passport crops stay saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear logs'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    await _logRepository.clearLogs();

    if (mounted) {
      setState(() => _memoryFuture = _loadMemory());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Garden Memory'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => _memoryFuture = _loadMemory()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_GardenMemoryData>(
        future: _memoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load garden memory: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No memory data found.'));
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
                  _MemoryHero(
                    data: data,
                    onAddLog: () => _openLogSheet(data),
                  ),
                  const SizedBox(height: 14),
                  _NudgesPanel(
                    nudges: data.summary.nudges,
                    cropById: data.cropById,
                    onCropTap: _openCrop,
                    onOpenPassport: _openPassport,
                  ),
                  const SizedBox(height: 14),
                  _CropMemoryPanel(
                    memories: data.summary.cropMemories,
                    onCropTap: _openCrop,
                    onOpenPassport: _openPassport,
                  ),
                  const SizedBox(height: 14),
                  _TimelinePanel(
                    logs: data.summary.recentLogs,
                    cropById: data.cropById,
                    onAddLog: () => _openLogSheet(data),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<_GardenMemoryData>(
        future: _memoryFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          return FloatingActionButton.extended(
            onPressed: data == null ? null : () => _openLogSheet(data),
            icon: const Icon(Icons.add_task_outlined),
            label: const Text('Log'),
          );
        },
      ),
    );
  }
}

class _MemoryHero extends StatelessWidget {
  const _MemoryHero({
    required this.data,
    required this.onAddLog,
  });

  final _GardenMemoryData data;
  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    final growingCount = data.profile.growingCropIds.length;
    final logCount = data.logs.length;

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
              Icons.history_outlined,
              size: 152,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassPill(label: 'Personal garden memory'),
              const SizedBox(height: 20),
              const Text(
                'Garden\nMemory',
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
                '$growingCount crops tracked · $logCount quick logs saved on this device.',
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
                  onTap: onAddLog,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.add_task_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add a smart garden log',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white),
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

class _NudgesPanel extends StatelessWidget {
  const _NudgesPanel({
    required this.nudges,
    required this.cropById,
    required this.onCropTap,
    required this.onOpenPassport,
  });

  final List<GardenNudge> nudges;
  final Map<String, Crop> cropById;
  final ValueChanged<Crop> onCropTap;
  final VoidCallback onOpenPassport;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Personal nudges',
      subtitle: 'Built from your Garden Passport and recent logs.',
      icon: Icons.auto_awesome_outlined,
      color: _leaf,
      child: nudges.isEmpty
          ? _EmptyAction(
              text: 'Add logs and crops to unlock personal reminders.',
              icon: Icons.yard_outlined,
              color: _leaf,
              onTap: onOpenPassport,
            )
          : Column(
              children: nudges.map((nudge) {
                final crop =
                    nudge.cropId == null ? null : cropById[nudge.cropId];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NudgeCard(
                    nudge: nudge,
                    crop: crop,
                    onTap: crop == null ? null : () => onCropTap(crop),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({
    required this.nudge,
    required this.crop,
    required this.onTap,
  });

  final GardenNudge nudge;
  final Crop? crop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForNudge(nudge.type);

    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              _IconBubble(
                icon: _iconForNudge(nudge.type),
                color: color,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nudge.title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nudge.body,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (crop != null) Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropMemoryPanel extends StatelessWidget {
  const _CropMemoryPanel({
    required this.memories,
    required this.onCropTap,
    required this.onOpenPassport,
  });

  final List<CropMemory> memories;
  final ValueChanged<Crop> onCropTap;
  final VoidCallback onOpenPassport;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Crop memory',
      subtitle: 'What the app remembers for your active crops.',
      icon: Icons.eco_outlined,
      color: _moss,
      child: memories.isEmpty
          ? _EmptyAction(
              text: 'Add crops to your Garden Passport first.',
              icon: Icons.yard_outlined,
              color: _moss,
              onTap: onOpenPassport,
            )
          : Column(
              children: memories.map((memory) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CropMemoryCard(
                    memory: memory,
                    onTap: () => onCropTap(memory.crop),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _CropMemoryCard extends StatelessWidget {
  const _CropMemoryCard({
    required this.memory,
    required this.onTap,
  });

  final CropMemory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final crop = memory.crop;

    return Material(
      color: _moss.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBubble(
                    icon: crop.containerFriendly
                        ? Icons.inventory_2_outlined
                        : Icons.eco_outlined,
                    color: _moss,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      crop.commonName,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _moss),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _MemoryChip(
                    label: _logStatus('Watered', memory.lastWatered),
                    color: _leaf,
                  ),
                  _MemoryChip(
                    label: _logStatus('Sowed', memory.lastSowed),
                    color: _moss,
                  ),
                  _MemoryChip(
                    label: _logStatus('Harvested', memory.lastHarvested),
                    color: _berry,
                  ),
                  if (memory.lastPestSeen != null)
                    _MemoryChip(
                      label: _logStatus('Pest', memory.lastPestSeen),
                      color: _clay,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.logs,
    required this.cropById,
    required this.onAddLog,
  });

  final List<GardenQuickLog> logs;
  final Map<String, Crop> cropById;
  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Garden story',
      subtitle: 'Recent activity from quick logs.',
      icon: Icons.history_outlined,
      color: _clay,
      child: logs.isEmpty
          ? _EmptyAction(
              text: 'No logs yet. Add the first one.',
              icon: Icons.add_task_outlined,
              color: _clay,
              onTap: onAddLog,
            )
          : Column(
              children: logs.map((log) {
                return _TimelineRow(
                  log: log,
                  crop: log.cropId == null ? null : cropById[log.cropId],
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.log,
    required this.crop,
  });

  final GardenQuickLog log;
  final Crop? crop;

  @override
  Widget build(BuildContext context) {
    final color = _colorForLog(log.type);
    final target = crop?.commonName ?? log.scope ?? 'All garden';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          _IconBubble(
            icon: _iconForLog(log.type),
            color: color,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${log.label} · $target · ${_relativeDate(log.createdAt)}',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartLogSheet extends StatefulWidget {
  const _SmartLogSheet({required this.data});

  final _GardenMemoryData data;

  @override
  State<_SmartLogSheet> createState() => _SmartLogSheetState();
}

class _SmartLogSheetState extends State<_SmartLogSheet> {
  String _type = 'watered';
  String _target = 'all';
  String? _cropId;

  @override
  Widget build(BuildContext context) {
    final activeCrops = widget.data.profile.growingCropIds
        .map((id) => widget.data.cropById[id])
        .whereType<Crop>()
        .toList(growable: false)
      ..sort((a, b) => a.commonName.compareTo(b.commonName));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                _IconBubble(
                  icon: _iconForLog(_type),
                  color: _colorForLog(_type),
                  size: 58,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'What happened in the garden?',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: 'Activity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'watered', child: Text('Watered')),
                DropdownMenuItem(value: 'sowed', child: Text('Sowed')),
                DropdownMenuItem(
                  value: 'transplanted',
                  child: Text('Transplanted'),
                ),
                DropdownMenuItem(value: 'harvested', child: Text('Harvested')),
                DropdownMenuItem(value: 'pest_seen', child: Text('Pest seen')),
                DropdownMenuItem(value: 'checked', child: Text('Checked')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _target,
              decoration: InputDecoration(
                labelText: 'Target',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All garden')),
                const DropdownMenuItem(
                  value: 'containers',
                  child: Text('Containers'),
                ),
                const DropdownMenuItem(
                  value: 'growing',
                  child: Text('All growing crops'),
                ),
                if (activeCrops.isNotEmpty)
                  const DropdownMenuItem(
                    value: 'crop',
                    child: Text('Specific crop'),
                  ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _target = value;
                  if (_target != 'crop') {
                    _cropId = null;
                  }
                });
              },
            ),
            if (_target == 'crop') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _cropId,
                decoration: InputDecoration(
                  labelText: 'Crop',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: activeCrops
                    .map(
                      (crop) => DropdownMenuItem(
                        value: crop.id,
                        child: Text(crop.commonName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _cropId = value),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _target == 'crop' && _cropId == null
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        GardenQuickLog(
                          type: _type,
                          label: _labelForLog(_type),
                          createdAtIso: DateTime.now().toIso8601String(),
                          cropId: _target == 'crop' ? _cropId : null,
                          scope: _scopeForTarget(_target),
                        ),
                      );
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save garden log'),
            ),
          ],
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
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

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
          child,
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

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String text;
  final IconData icon;
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
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
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

class _MemoryChip extends StatelessWidget {
  const _MemoryChip({
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
        fontSize: 12,
        fontWeight: FontWeight.w800,
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

class _GardenMemoryData {
  const _GardenMemoryData({
    required this.profile,
    required this.crops,
    required this.cropById,
    required this.logs,
    required this.summary,
  });

  final GardenProfile profile;
  final List<Crop> crops;
  final Map<String, Crop> cropById;
  final List<GardenQuickLog> logs;
  final GardenMemorySummary summary;
}

String _labelForLog(String type) {
  return switch (type) {
    'watered' => 'Watered',
    'sowed' => 'Sowed',
    'transplanted' => 'Transplanted',
    'harvested' => 'Harvested',
    'pest_seen' => 'Pest seen',
    'checked' => 'Checked',
    _ => 'Garden note',
  };
}

String? _scopeForTarget(String target) {
  return switch (target) {
    'containers' => 'Containers',
    'growing' => 'All growing crops',
    'all' => 'All garden',
    _ => null,
  };
}

IconData _iconForLog(String type) {
  return switch (type) {
    'watered' => Icons.water_drop_outlined,
    'sowed' => Icons.grass_outlined,
    'transplanted' => Icons.move_down_outlined,
    'harvested' => Icons.shopping_basket_outlined,
    'pest_seen' => Icons.bug_report_outlined,
    'checked' => Icons.check_circle_outline,
    _ => Icons.edit_note_outlined,
  };
}

Color _colorForLog(String type) {
  return switch (type) {
    'watered' => _leaf,
    'sowed' => _moss,
    'transplanted' => _clay,
    'harvested' => _berry,
    'pest_seen' => _leafDark,
    'checked' => _moss,
    _ => _muted,
  };
}

IconData _iconForNudge(String type) {
  return switch (type) {
    'water' => Icons.water_drop_outlined,
    'pest' => Icons.bug_report_outlined,
    'seedlings' => Icons.grass_outlined,
    'frost' => Icons.ac_unit_outlined,
    'containers' => Icons.inventory_2_outlined,
    'passport' => Icons.yard_outlined,
    _ => Icons.auto_awesome_outlined,
  };
}

Color _colorForNudge(String type) {
  return switch (type) {
    'water' => _leaf,
    'pest' => _berry,
    'seedlings' => _moss,
    'frost' => _leafDark,
    'containers' => _clay,
    'passport' => _leaf,
    _ => _moss,
  };
}

String _logStatus(String label, GardenQuickLog? log) {
  if (log == null) {
    return '$label: never';
  }

  return '$label: ${_relativeDate(log.createdAt)}';
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final days = now.difference(date).inDays;

  if (days <= 0) {
    return 'today';
  }

  if (days == 1) {
    return 'yesterday';
  }

  if (days < 7) {
    return '$days days ago';
  }

  if (days < 14) {
    return 'last week';
  }

  return '${date.day} ${_shortMonthName(date.month)}';
}

String _shortMonthName(int month) {
  return const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
