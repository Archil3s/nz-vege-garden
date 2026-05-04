import 'package:flutter/material.dart';

class GardenBedsScreen extends StatelessWidget {
  const GardenBedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My garden beds'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.yard_outlined),
              title: Text('Garden bed planner'),
              subtitle: Text(
                'Create beds, containers, and greenhouse spaces in the next build step.',
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.add),
        label: const Text('Add bed'),
      ),
    );
  }
}
