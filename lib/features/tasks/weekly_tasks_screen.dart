import 'package:flutter/material.dart';

class WeeklyTasksScreen extends StatelessWidget {
  const WeeklyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly tasks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: CheckboxListTile(
              value: false,
              onChanged: null,
              title: Text('Check seedlings for slugs and snails'),
              subtitle: Text('Placeholder seasonal task'),
            ),
          ),
          Card(
            child: CheckboxListTile(
              value: false,
              onChanged: null,
              title: Text('Water containers if dry'),
              subtitle: Text('Placeholder garden task'),
            ),
          ),
        ],
      ),
    );
  }
}
