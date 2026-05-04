import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _weeklyReminderId = 1001;

  Future<void> initialise() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
  }

  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    final macosGranted = await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    final androidGranted = await android?.requestNotificationsPermission() ?? true;

    return iosGranted && macosGranted && androidGranted;
  }

  Future<void> showWeeklyReminderPreview() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_garden_reminders',
        'Weekly garden reminders',
        channelDescription: 'Local reminders to check weekly garden tasks.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      _weeklyReminderId,
      'Check your garden tasks',
      'Open NZ Vege Garden to review this week\'s jobs.',
      details,
    );
  }

  Future<void> cancelWeeklyReminder() async {
    await _plugin.cancel(_weeklyReminderId);
  }
}
