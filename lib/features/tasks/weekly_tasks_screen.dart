import 'package:flutter/material.dart';

import '../../data/models/task_rule.dart';
import '../../data/task_completion_repository.dart';
import '../../data/weekly_task_service.dart';

class WeeklyTasksScreen extends StatefulWidget {
  const WeeklyTasksScreen({super.key});

  @override
  State<WeeklyTasksScreen> createState() => _WeeklyTasksScreenState();
}

class _WeeklyTasksScreenState extends State<WeeklyTasksScreen> {
  final _taskService = const WeeklyTaskService();
  final _completionRepository = const TaskCompletionRepository();

  late Future<_WeeklyTasksData> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasksData();
  }

  Future<_WeeklyTasksData> _loadTasksData() async {
    final tasks = await _taskService.generateTasks();
    final completedTaskIds = await _completionRepository.loadCompletedTaskIds();

    return _WeeklyTasksData(
      tasks: tasks,
      completedTaskIds: completedTaskIds,
      weekKey: _completionRepository.weekKey(),
    );
  }

  void _reloadTasks() {
    setState(() {
      _tasksFuture = _loadTasksData();
    });
  }

  Future<void> _setTaskCompleted(TaskRule task, bool completed) async {
    await _completionRepository.setTaskCompleted(
      taskId: task.id,
      completed: completed,
    );

    _reloadTasks();
  }

  Future<void> _clearWeek() async {
    await _completionRepository.clearCompletedTasksForWeek();
    _reloadTasks();
  }

  void _openTaskDetails(TaskRule task, bool completed) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _TaskDetailSheet(
          task: task,
          completed: completed,
          onCompletedChanged: (value) async {
            Navigator.pop(context);
            await _setTaskCompleted(task, value);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly tasks'),
      ),
      body: FutureBuilder<_WeeklyTasksData>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load weekly tasks: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          final tasks = data?.tasks ?? const <TaskRule>[];

          if (tasks.isEmpty) {
            return const _EmptyTasksState();
          }

          final completedCount = data!.tasks
              .where((task) => data.completedTaskIds.contains(task.id))
              .length;
          final successionCount = tasks
              .where((task) => task.taskType == 'succession')
              .length;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: tasks.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TaskProgressCard(
                  completedCount: completedCount,
                  totalCount: tasks.length,
                  successionCount: successionCount,
                  weekKey: data.weekKey,
                  onClearPressed: completedCount == 0 ? null : _clearWeek,
                );
              }

              final task = tasks[index - 1];
              final completed = data.completedTaskIds.contains(task.id);

              return _TaskCard(
                task: task,
                completed: completed,
                onCompletedChanged: (value) => _setTaskCompleted(task, value),
                onOpenDetails: () => _openTaskDetails(task, completed),
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskProgressCard extends StatelessWidget {
  const _TaskProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.successionCount,
    required this.weekKey,
    required this.onClearPressed,
  });

  final int completedCount;
  final int totalCount;
  final int successionCount;
  final String weekKey;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This week',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: onClearPressed,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$completedCount of $totalCount tasks completed'),
            const SizedBox(height: 6),
            const Text(
              'Tap a task for quick steps before marking it done.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.repeat_outlined, size: 18),
                  label: Text('Succession: $successionCount'),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('Week $weekKey'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.completed,
    required this.onCompletedChanged,
    required this.onOpenDetails,
  });

  final TaskRule task;
  final bool completed;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textColor = completed ? Theme.of(context).disabledColor : null;
    final isSuccession = task.taskType == 'succession';

    return Card(
      child: InkWell(
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: completed,
                onChanged: (value) => onCompletedChanged(value ?? false),
              ),
              const SizedBox(width: 8),
              Icon(_iconForTaskType(task.taskType), color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSuccession) ...[
                      const _SuccessionBadge(),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: textColor,
                            decoration: completed ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.flag_outlined, size: 18),
                          label: Text('Priority ${task.priority}'),
                        ),
                        Chip(
                          avatar: Icon(_iconForTaskType(task.taskType), size: 18),
                          label: Text(_formatValue(task.taskType)),
                        ),
                        if (completed)
                          const Chip(
                            avatar: Icon(Icons.check_circle_outline, size: 18),
                            label: Text('Done'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.task,
    required this.completed,
    required this.onCompletedChanged,
  });

  final TaskRule task;
  final bool completed;
  final ValueChanged<bool> onCompletedChanged;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForTaskType(task.taskType);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Icon(_iconForTaskType(task.taskType)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatValue(task.taskType),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              task.description,
              style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.flag_outlined, size: 18),
                  label: Text('Priority ${task.priority}'),
                ),
                if (task.taskType == 'succession') const _SuccessionBadge(),
                if (completed)
                  const Chip(
                    avatar: Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Marked done'),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Quick steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            ...steps.map(_TaskStep.new),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onCompletedChanged(!completed),
                icon: Icon(completed ? Icons.undo_outlined : Icons.check_circle_outline),
                label: Text(completed ? 'Mark as not done' : 'Mark as done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStep extends StatelessWidget {
  const _TaskStep(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35, fontWeight: FontWeight.w650),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessionBadge extends StatelessWidget {
  const _SuccessionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          'Succession planting',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No weekly tasks found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Task rules will expand as the local gardening database grows. Check Settings to confirm your region, frost risk, wind exposure, and garden type.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTasksData {
  const _WeeklyTasksData({
    required this.tasks,
    required this.completedTaskIds,
    required this.weekKey,
  });

  final List<TaskRule> tasks;
  final Set<String> completedTaskIds;
  final String weekKey;
}

IconData _iconForTaskType(String taskType) {
  return switch (taskType) {
    'water' => Icons.water_drop_outlined,
    'check_pests' => Icons.bug_report_outlined,
    'protect' => Icons.health_and_safety_outlined,
    'support' => Icons.signpost_outlined,
    'mulch' => Icons.grass_outlined,
    'prepare_bed' => Icons.yard_outlined,
    'succession' => Icons.repeat_outlined,
    _ => Icons.check_circle_outline,
  };
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

List<String> _stepsForTaskType(String taskType) {
  return switch (taskType) {
    'water' => const [
        'Check the top 2–3 cm of soil before watering.',
        'Water slowly at the base of the plant, not over the leaves.',
        'Skip watering if the soil is still cool and damp.',
      ],
    'check_pests' => const [
        'Inspect leaf undersides and new growth first.',
        'Remove obvious pests by hand where practical.',
        'Check again in two days if damage is fresh.',
      ],
    'protect' => const [
        'Check the overnight forecast before dusk.',
        'Cover frost-tender crops or move pots under shelter.',
        'Remove covers in the morning once temperatures lift.',
      ],
    'support' => const [
        'Look for leaning stems or heavy growth.',
        'Tie plants loosely so stems can still move.',
        'Keep supports clear of roots when pushing stakes in.',
      ],
    'mulch' => const [
        'Clear weeds before adding mulch.',
        'Keep mulch a few centimetres away from stems.',
        'Top up thin areas after rain or wind.',
      ],
    'prepare_bed' => const [
        'Remove weeds and old crop debris.',
        'Loosen the surface without disturbing soil too deeply.',
        'Add compost before the next sowing window.',
      ],
    'succession' => const [
        'Check whether you still have harvest space available.',
        'Sow a small batch rather than a full bed.',
        'Repeat only while the weather still suits this crop.',
      ],
    _ => const [
        'Check the task conditions in your garden.',
        'Do the smallest useful action first.',
        'Mark it done when the garden is up to date.',
      ],
  };
}
