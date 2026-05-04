import 'package:flutter/material.dart';

import '../../data/models/task_rule.dart';
import '../../data/weekly_task_service.dart';

class WeeklyTasksScreen extends StatelessWidget {
  const WeeklyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly tasks'),
      ),
      body: FutureBuilder<List<TaskRule>>(
        future: const WeeklyTaskService().generateTasks(),
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

          final tasks = snapshot.data ?? const <TaskRule>[];

          if (tasks.isEmpty) {
            return const _EmptyTasksState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];

              return _TaskCard(task: task);
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final TaskRule task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForTaskType(task.taskType)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(task.description),
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
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text(_formatValue(task.taskType)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
