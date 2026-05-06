import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WateringPlannerScreen extends StatefulWidget {
  const WateringPlannerScreen({super.key});

  @override
  State<WateringPlannerScreen> createState() => _WateringPlannerScreenState();
}

class _WateringPlannerScreenState extends State<WateringPlannerScreen> {
  static const _soilKey = 'watering_planner_soil_v1';
  static const _mulchKey = 'watering_planner_mulch_v1';
  static const _containerKey = 'watering_planner_container_v1';

  final _temperatureController = TextEditingController(text: '22');
  final _rainController = TextEditingController(text: '0');

  String _soilType = _soilTypes.first;
  String _wind = _windOptions[1];
  String _sun = _sunOptions[1];
  bool _mulched = true;
  bool _container = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soilType = prefs.getString(_soilKey) ?? _soilTypes.first;
      _mulched = prefs.getBool(_mulchKey) ?? true;
      _container = prefs.getBool(_containerKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soilKey, _soilType);
    await prefs.setBool(_mulchKey, _mulched);
    await prefs.setBool(_containerKey, _container);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Soil watering profile saved on this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _WaterEstimate.fromInputs(
      temperatureC: double.tryParse(_temperatureController.text.trim()) ?? 0,
      rainMm: double.tryParse(_rainController.text.trim()) ?? 0,
      soilType: _soilType,
      wind: _wind,
      sun: _sun,
      mulched: _mulched,
      container: _container,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Water & soil planner')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _EstimateCard(estimate: estimate),
                const SizedBox(height: 12),
                _InputCard(
                  title: 'Weather inputs',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _temperatureController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Temp °C',
                              helperText: 'Afternoon high',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _rainController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Rain mm',
                              helperText: 'Last 24h / expected',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _wind,
                      decoration: const InputDecoration(labelText: 'Wind'),
                      items: _windOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _wind = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _sun,
                      decoration: const InputDecoration(labelText: 'Sun exposure'),
                      items: _sunOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _sun = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InputCard(
                  title: 'Soil profile',
                  children: [
                    DropdownButtonFormField<String>(
                      value: _soilType,
                      decoration: const InputDecoration(labelText: 'Soil type'),
                      items: _soilTypes.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _soilType = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mulched bed'),
                      subtitle: const Text('Mulch reduces surface evaporation.'),
                      value: _mulched,
                      onChanged: (value) => setState(() => _mulched = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Container or raised pot'),
                      subtitle: const Text('Containers dry out faster than beds.'),
                      value: _container,
                      onChanged: (value) => setState(() => _container = value),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save soil profile'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _GuidanceCard(estimate: estimate),
              ],
            ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate});

  final _WaterEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(context, estimate.risk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text('Watering estimate', style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              estimate.risk,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              estimate.headline,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: estimate.score / 100),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.opacity_outlined, size: 18),
                  label: Text('${estimate.netLossMm.toStringAsFixed(1)} mm net loss'),
                ),
                Chip(
                  avatar: const Icon(Icons.grass_outlined, size: 18),
                  label: Text(estimate.soilType),
                ),
                if (estimate.container)
                  const Chip(
                    avatar: Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text('Container'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.estimate});

  final _WaterEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soil check steps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...estimate.steps.map(_StepRow.new),
            const Divider(height: 24),
            const Text(
              'This is a practical garden estimate, not a sensor reading. Confirm by checking the top 2–3 cm of soil before watering.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35))),
        ],
      ),
    );
  }
}

class _WaterEstimate {
  const _WaterEstimate({
    required this.risk,
    required this.score,
    required this.netLossMm,
    required this.soilType,
    required this.container,
    required this.headline,
    required this.steps,
  });

  final String risk;
  final double score;
  final double netLossMm;
  final String soilType;
  final bool container;
  final String headline;
  final List<String> steps;

  factory _WaterEstimate.fromInputs({
    required double temperatureC,
    required double rainMm,
    required String soilType,
    required String wind,
    required String sun,
    required bool mulched,
    required bool container,
  }) {
    final tempLoss = temperatureC <= 12
        ? 1.0
        : temperatureC <= 18
            ? 2.0
            : temperatureC <= 24
                ? 3.2
                : temperatureC <= 30
                    ? 4.8
                    : 6.2;

    final windFactor = switch (wind) {
      'Still' => .8,
      'Light' => 1.0,
      'Breezy' => 1.25,
      'Windy' => 1.55,
      _ => 1.0,
    };

    final sunFactor = switch (sun) {
      'Shade' => .7,
      'Part sun' => 1.0,
      'Full sun' => 1.25,
      _ => 1.0,
    };

    final soilFactor = switch (soilType) {
      'Sandy / free draining' => 1.25,
      'Loam / balanced' => 1.0,
      'Clay / holds water' => .78,
      'Compost-rich bed' => .88,
      _ => 1.0,
    };

    final mulchFactor = mulched ? .72 : 1.0;
    final containerFactor = container ? 1.35 : 1.0;
    final rawLoss = tempLoss * windFactor * sunFactor * soilFactor * mulchFactor * containerFactor;
    final netLoss = math.max(0, rawLoss - rainMm);
    final score = (netLoss * 14).clamp(0, 100).toDouble();

    final risk = score >= 70
        ? 'High dry-out risk'
        : score >= 38
            ? 'Moderate dry-out risk'
            : 'Low dry-out risk';

    final headline = score >= 70
        ? 'Water-sensitive crops and containers may need attention today.'
        : score >= 38
            ? 'Check soil before watering; some beds may still be fine.'
            : 'Watering can probably wait unless seedlings or pots are drying out.';

    final steps = <String>[
      'Check the top 2–3 cm of soil with your finger before watering.',
      if (container) 'Check containers first; they lose moisture faster than in-ground beds.',
      if (soilType == 'Sandy / free draining') 'Sandy soil may need smaller, more frequent watering.',
      if (soilType == 'Clay / holds water') 'Clay soil can look dry on top while still wet below; avoid overwatering.',
      if (!mulched) 'Add mulch to reduce evaporation and slow surface drying.',
      if (rainMm >= 5) 'Recent rain is included, but sheltered pots may still be dry.',
      'Water at the base in the morning or evening to reduce evaporation.',
    ];

    return _WaterEstimate(
      risk: risk,
      score: score,
      netLossMm: netLoss.toDouble(),
      soilType: soilType,
      container: container,
      headline: headline,
      steps: steps,
    );
  }
}

Color _riskColor(BuildContext context, String risk) {
  if (risk.startsWith('High')) return Theme.of(context).colorScheme.error;
  if (risk.startsWith('Moderate')) return const Color(0xFFC4793D);
  return Theme.of(context).colorScheme.primary;
}

const _soilTypes = [
  'Loam / balanced',
  'Sandy / free draining',
  'Clay / holds water',
  'Compost-rich bed',
];

const _windOptions = ['Still', 'Light', 'Breezy', 'Windy'];
const _sunOptions = ['Shade', 'Part sun', 'Full sun'];
