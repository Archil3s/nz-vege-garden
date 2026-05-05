import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import 'crop_detail_screen.dart';

class CropGuideScreen extends StatefulWidget {
  const CropGuideScreen({super.key});

  @override
  State<CropGuideScreen> createState() => _CropGuideScreenState();
}

class _CropGuideScreenState extends State<CropGuideScreen> {
  final _searchController = TextEditingController();
  final _repository = const GardenDataRepository();

  String _query = '';
  String _category = 'all';
  bool _beginnerOnly = false;
  bool _containerOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Crop> _filterCrops(List<Crop> crops) {
    final normalizedQuery = _query.trim().toLowerCase();

    return crops.where((crop) {
      final matchesQuery = normalizedQuery.isEmpty ||
          crop.commonName.toLowerCase().contains(normalizedQuery) ||
          crop.summary.toLowerCase().contains(normalizedQuery);
      final matchesCategory = _category == 'all' || crop.category == _category;
      final matchesBeginner = !_beginnerOnly || crop.beginnerFriendly;
      final matchesContainer = !_containerOnly || crop.containerFriendly;

      return matchesQuery && matchesCategory && matchesBeginner && matchesContainer;
    }).toList(growable: false);
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _category = 'all';
      _beginnerOnly = false;
      _containerOnly = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop guide'),
      ),
      body: FutureBuilder<List<Crop>>(
        future: _repository.loadCrops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load crops: ${snapshot.error}'));
          }

          final crops = snapshot.data ?? const <Crop>[];
          final filteredCrops = _filterCrops(crops);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search crops',
                  hintText: 'Example: tomato, brassica, herb',
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
                    label: const Text('Vegetables'),
                    selected: _category == 'vegetable',
                    onSelected: (_) => setState(() => _category = 'vegetable'),
                  ),
                  ChoiceChip(
                    label: const Text('Herbs'),
                    selected: _category == 'herb',
                    onSelected: (_) => setState(() => _category = 'herb'),
                  ),
                  FilterChip(
                    label: const Text('Beginner friendly'),
                    selected: _beginnerOnly,
                    onSelected: (selected) => setState(() => _beginnerOnly = selected),
                  ),
                  FilterChip(
                    label: const Text('Container friendly'),
                    selected: _containerOnly,
                    onSelected: (selected) => setState(() => _containerOnly = selected),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${filteredCrops.length} of ${crops.length} crops',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (filteredCrops.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No crops match these filters.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Try clearing the search or disabling one of the filters.'),
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
                ...filteredCrops.map(
                  (crop) => Card(
                    child: ListTile(
                      title: Text(crop.commonName),
                      subtitle: Text(
                        '${crop.summary}\nSpacing: ${crop.spacingCm} cm • Harvest: ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CropDetailScreen(crop: crop),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
