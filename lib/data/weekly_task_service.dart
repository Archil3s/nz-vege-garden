import 'app_settings_repository.dart';
import 'garden_data_repository.dart';
import 'models/app_settings.dart';
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

    final matchingRules = rules
        .where((rule) => rule.appliesToMonth(date.month))
        .where((rule) => rule.appliesToRegion(settings.regionId))
        .where((rule) => rule.appliesToGardenType(settings.gardenType))
        .where((rule) => rule.appliesToFrostRisk(settings.frostRisk))
        .where((rule) => rule.appliesToWindExposure(settings.windExposure))
        .toList(growable: false);

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
}
