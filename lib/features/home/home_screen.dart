import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _defaultRegionId = 'canterbury';

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NZ Vege Garden'),
      ),
      body: FutureBuilder<List<Crop>>(
        future: const GardenDataRepository().cropsForMonthAndRegion(
          month: currentMonth,
          regionId: _defaultRegionId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load crop data: ${snapshot.error}'),
              ),
            );
          }

          final crops = snapshot.data ?? const <Crop>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'What to plant now',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Default region: Canterbury. Region setup will be added next.',
              ),
              const SizedBox(height: 16),
              if (crops.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matching crops found for this month.'),
                  ),
                )
              else
                ...crops.map(
                  (crop) => Card(
                    child: ListTile(
                      title: Text(crop.commonName),
                      subtitle: Text(crop.summary),
                      trailing: crop.frostTender
                          ? const Icon(Icons.ac_unit, semanticLabel: 'Frost tender')
                          : null,
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
