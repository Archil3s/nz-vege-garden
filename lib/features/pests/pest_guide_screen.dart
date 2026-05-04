import 'package:flutter/material.dart';

class PestGuideScreen extends StatelessWidget {
  const PestGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pests and problems'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.bug_report_outlined),
              title: Text('Slugs and snails'),
              subtitle: Text('Common issue for seedlings and leafy crops.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.bug_report_outlined),
              title: Text('White butterfly caterpillars'),
              subtitle: Text('Common issue on brassicas such as broccoli and cabbage.'),
            ),
          ),
        ],
      ),
    );
  }
}
