import 'app_settings_repository.dart';
import 'garden_data_repository.dart';
import 'models/task_rule.dart';

class WeeklyTaskService {
  const WeeklyTaskService({
    this.settingsRepository = const AppSettingsRepository(),
    this.dataRepository = const GardenDataRepository(),
  });

  final AppSettingsRepository settingsRepository;
  final GardenDataRepository dataRepository;

  Future<List<TaskRule>> generateTasks({DateTime? now}) async {
    final date = now ?? DateTime.now();
    final settings = await settingsRepository.loadSettings();
    final rules = await dataRepository.loadTaskRules();
    final successionRules = await dataRepository.loadSuccessionRules();

    final matchingRules = rules
        .where((rule) => rule.appliesToMonth(date.month))
        .where((rule) => rule.appliesToRegion(settings.regionId))
        .where((rule) => rule.appliesToGardenType(settings.gardenType))
        .where((rule) => rule.appliesToFrostRisk(settings.frostRisk))
        .where((rule) => rule.appliesToWindExposure(settings.windExposure))
        .toList(growable: true);

    final matchingSuccessionRules = successionRules
        .where((rule) => rule.appliesToMonth(date.month))
        .where((rule) => rule.appliesToGardenType(settings.gardenType))
        .where((rule) => rule.appliesToFrostRisk(settings.frostRisk))
        .where((rule) => rule.appliesToWindExposure(settings.windExposure))
        .map(
          (rule) => TaskRule.generated(
            id: 'succession:${rule.id}:${_weekKey(date)}',
            title: rule.title,
            description:
                '${rule.description}\nRepeat every ${rule.intervalDays} days while conditions suit.',
            taskType: 'succession',
            startMonth: rule.startMonth,
            endMonth: rule.endMonth,
            cropIds: [rule.cropId],
            priority: rule.priority,
          ),
        );

    matchingRules.addAll(matchingSuccessionRules);

    return _sortByPriorityThenTitle(matchingRules);
  }

  List<TaskRule> _sortByPriorityThenTitle(List<TaskRule> rules) {
    final sortedRules = [...rules];

    sortedRules.sort((a, b) {
      final priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      return a.title.compareTo(b.title);
    });

    return sortedRules;
  }

  String _weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));

    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
