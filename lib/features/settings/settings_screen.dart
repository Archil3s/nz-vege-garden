import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/nz_region.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<List<NzRegion>>(
        future: const GardenDataRepository().loadRegions(),
        builder: (context, snapshot) {
          final regions = snapshot.data ?? const <NzRegion>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: ListTile(
                  leading: Icon(Icons.place_outlined),
                  title: Text('Default region'),
                  subtitle: Text('Canterbury. Editable setup will be added next.'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Available NZ regions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else
                ...regions.map(
                  (region) => Card(
                    child: ListTile(
                      title: Text(region.name),
                      subtitle: Text(region.climateSummary),
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
