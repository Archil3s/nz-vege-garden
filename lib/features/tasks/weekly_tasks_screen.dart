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
            padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
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
  });

  final TaskRule task;
  final bool completed;
  final ValueChanged<bool> onCompletedChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = completed ? Theme.of(context).disabledColor : null;
    final isSuccession = task.taskType == 'succession';

    return Card(
      child: InkWell(
        onTap: () => onCompletedChanged(!completed),
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
            ],
          ),
        ),
      ),
    );
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
