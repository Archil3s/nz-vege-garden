import 'package:shared_preferences/shared_preferences.dart';

import 'models/garden_quick_log.dart';

class GardenQuickLogRepository {
  const GardenQuickLogRepository();

  static const _logsKey = 'gardenQuickLogs.v1';

  Future<List<GardenQuickLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_logsKey) ?? const <String>[];

    return values
        .map((value) {
          try {
            return GardenQuickLog.fromStorageString(value);
          } catch (_) {
            return null;
          }
        })
        .whereType<GardenQuickLog>()
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addLog(GardenQuickLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await loadLogs();

    final nextLogs = [
      log,
      ...logs,
    ].take(40).map((item) => item.toStorageString()).toList(growable: false);

    await prefs.setStringList(_logsKey, nextLogs);
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
  }
}
