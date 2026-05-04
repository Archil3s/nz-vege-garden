import 'package:flutter/material.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';

class CropGuideScreen extends StatelessWidget {
  const CropGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop guide'),
      ),
      body: FutureBuilder<List<Crop>>(
        future: const GardenDataRepository().loadCrops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load crops: ${snapshot.error}'));
          }

          final crops = snapshot.data ?? const <Crop>[];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: crops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final crop = crops[index];

              return Card(
                child: ListTile(
                  title: Text(crop.commonName),
                  subtitle: Text(
                    '${crop.summary}\nSpacing: ${crop.spacingCm} cm • Harvest: ${crop.daysToHarvestMin}-${crop.daysToHarvestMax} days',
                  ),
                  isThreeLine: true,
                  trailing: crop.containerFriendly
                      ? const Icon(Icons.inventory_2_outlined)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
