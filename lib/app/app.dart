import 'package:flutter/material.dart';

import '../features/pests/pest_guide_screen.dart';
import 'app_theme.dart';

class NzVegeGardenApp extends StatelessWidget {
  const NzVegeGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pest Tracker',
      theme: buildAppTheme(),
      home: const PestTrackerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
