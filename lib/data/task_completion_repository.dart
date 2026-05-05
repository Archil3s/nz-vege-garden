import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TaskCompletionRepository {
  const TaskCompletionRepository();

  static const _completedTasksKey = 'weeklyTasks.completedByWeek';

  Future<Set<String>> loadCompletedTaskIds({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = this.weekKey(now: now);
    final encoded = prefs.getString(_completedTasksKey);

    if (encoded == null || encoded.isEmpty) {
      return <String>{};
    }

    final data = jsonDecode(encoded) as Map<String, dynamic>;
    final completedForWeek = data[weekKey];

    if (completedForWeek is! List<dynamic>) {
      return <String>{};
    }

    return completedForWeek.whereType<String>().toSet();
  }

  Future<void> setTaskCompleted({
    required String taskId,
    required bool completed,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = this.weekKey(now: now);
    final encoded = prefs.getString(_completedTasksKey);
    final data = encoded == null || encoded.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(encoded) as Map<String, dynamic>;

    final completedIds = await loadCompletedTaskIds(now: now);

    if (completed) {
      completedIds.add(taskId);
    } else {
      completedIds.remove(taskId);
    }

    data[weekKey] = completedIds.toList(growable: false)..sort();

    await prefs.setString(_completedTasksKey, jsonEncode(data));
  }

  Future<void> clearCompletedTasksForWeek({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = this.weekKey(now: now);
    final encoded = prefs.getString(_completedTasksKey);

    if (encoded == null || encoded.isEmpty) {
      return;
    }

    final data = jsonDecode(encoded) as Map<String, dynamic>;
    data.remove(weekKey);

    await prefs.setString(_completedTasksKey, jsonEncode(data));
  }

  String weekKey({DateTime? now}) {
    final date = now ?? DateTime.now();
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));

    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
