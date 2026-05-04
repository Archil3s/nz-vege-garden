import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/notifications/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initialise();

  runApp(const NzVegeGardenApp());
}
