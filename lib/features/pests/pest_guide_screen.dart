import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/pest_problem.dart';

class PestGuideScreen extends StatelessWidget {
  const PestGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pests and problems'),
      ),
      body: FutureBuilder<List<PestProblem>>(
        future: const GardenDataRepository().loadPestProblems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load pest guide: ${snapshot.error}'),
              ),
            );
          }

          final problems = snapshot.data ?? const <PestProblem>[];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: problems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final problem = problems[index];

              return Card(
                child: ExpansionTile(
                  leading: Icon(_iconForCategory(problem.category)),
                  title: Text(problem.name),
                  subtitle: Text(problem.summary),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _Section(
                      title: 'Signs',
                      items: problem.signs,
                    ),
                    _Section(
                      title: 'Actions',
                      items: problem.actions,
                    ),
                    _Section(
                      title: 'Prevention',
                      items: problem.prevention,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Chip(
                          avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: Text(problem.seasonNotes),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'pest' => Icons.bug_report_outlined,
      'disease' => Icons.coronavirus_outlined,
      'crop_problem' => Icons.warning_amber_outlined,
      _ => Icons.info_outline,
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
