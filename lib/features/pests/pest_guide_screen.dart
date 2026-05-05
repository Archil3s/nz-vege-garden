import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/pest_problem.dart';

class PestGuideScreen extends StatefulWidget {
  const PestGuideScreen({super.key});

  @override
  State<PestGuideScreen> createState() => _PestGuideScreenState();
}

class _PestGuideScreenState extends State<PestGuideScreen> {
  final _searchController = TextEditingController();
  final _repository = const GardenDataRepository();

  String _query = '';
  String _category = 'all';
  String _cropId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PestProblem> _filterProblems(List<PestProblem> problems) {
    final normalizedQuery = _query.trim().toLowerCase();

    return problems.where((problem) {
      final searchableText = [
        problem.name,
        problem.category,
        problem.summary,
        problem.seasonNotes,
        ...problem.signs,
        ...problem.actions,
        ...problem.prevention,
      ].join(' ').toLowerCase();

      final matchesQuery = normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory = _category == 'all' || problem.category == _category;
      final matchesCrop = _cropId == 'all' || problem.commonCrops.contains(_cropId);

      return matchesQuery && matchesCategory && matchesCrop;
    }).toList(growable: false);
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _category = 'all';
      _cropId = 'all';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pests and problems'),
      ),
      body: FutureBuilder<_PestGuideData>(
        future: _loadData(),
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

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No pest guide data found.'));
          }

          final filteredProblems = _filterProblems(data.problems);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search pests and problems',
                  hintText: 'Example: aphids, holes, yellowing, watering',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _category == 'all',
                    onSelected: (_) => setState(() => _category = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('Pests'),
                    selected: _category == 'pest',
                    onSelected: (_) => setState(() => _category = 'pest'),
                  ),
                  ChoiceChip(
                    label: const Text('Diseases'),
                    selected: _category == 'disease',
                    onSelected: (_) => setState(() => _category = 'disease'),
                  ),
                  ChoiceChip(
                    label: const Text('Crop problems'),
                    selected: _category == 'crop_problem',
                    onSelected: (_) => setState(() => _category = 'crop_problem'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _cropId,
                decoration: const InputDecoration(
                  labelText: 'Affected crop',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All crops'),
                  ),
                  ...data.crops.map(
                    (crop) => DropdownMenuItem(
                      value: crop.id,
                      child: Text(crop.commonName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() => _cropId = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filteredProblems.length} of ${data.problems.length} entries',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (_query.isNotEmpty || _category != 'all' || _cropId != 'all')
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (filteredProblems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No pests or problems match these filters.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Try clearing the search, changing the crop, or choosing a different category.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredProblems.map(
                  (problem) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PestProblemCard(
                      problem: problem,
                      cropNameById: data.cropNameById,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<_PestGuideData> _loadData() async {
    final problems = await _repository.loadPestProblems();
    final crops = await _repository.loadCrops();
    final affectedCropIds = problems.expand((problem) => problem.commonCrops).toSet();
    final affectedCrops = crops
        .where((crop) => affectedCropIds.contains(crop.id))
        .toList(growable: false)
      ..sort((a, b) => a.commonName.compareTo(b.commonName));
    final cropNameById = {
      for (final crop in crops) crop.id: crop.commonName,
    };

    return _PestGuideData(
      problems: problems,
      crops: affectedCrops,
      cropNameById: cropNameById,
    );
  }
}

class _PestProblemCard extends StatelessWidget {
  const _PestProblemCard({
    required this.problem,
    required this.cropNameById,
  });

  final PestProblem problem;
  final Map<String, String> cropNameById;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(_iconForCategory(problem.category)),
        title: Text(problem.name),
        subtitle: Text(problem.summary),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (problem.commonCrops.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: problem.commonCrops
                    .map(
                      (cropId) => Chip(
                        avatar: const Icon(Icons.eco_outlined, size: 18),
                        label: Text(cropNameById[cropId] ?? _formatValue(cropId)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
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
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'pest' => Icons.bug_report_outlined,
      'disease' => Icons.coronavirus_outlined,
      'crop_problem' => Icons.warning_amber_outlined,
      _ => Icons.info_outline,
    };
  }

  String _formatValue(String value) {
    return value
        .split('_')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
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

class _PestGuideData {
  const _PestGuideData({
    required this.problems,
    required this.crops,
    required this.cropNameById,
  });

  final List<PestProblem> problems;
  final List<Crop> crops;
  final Map<String, String> cropNameById;
}
