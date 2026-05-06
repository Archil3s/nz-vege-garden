import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/garden_data_repository.dart';
import '../../data/models/crop.dart';
import '../../data/models/pest_problem.dart';
import '../crops/crop_detail_screen.dart';

const _canvas = Color(0xFFF8F3E8);
const _surface = Color(0xFFFFFCF5);
const _ink = Color(0xFF172D22);
const _muted = Color(0xFF66736A);
const _leaf = Color(0xFF2F724B);
const _leafDark = Color(0xFF17452F);
const _moss = Color(0xFF8BA766);
const _mint = Color(0xFFE7F0DB);
const _clay = Color(0xFFC4793D);
const _berry = Color(0xFFB35642);
const _border = Color(0xFFE7DFCE);
const _sun = Color(0xFFF4C86A);

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
  String _symptomId = 'all';

  static const _symptoms = [
    _SymptomPreset(
      id: 'all',
      label: 'All signs',
      prompt: 'Show everything',
      icon: Icons.grid_view_outlined,
      color: _leaf,
      keywords: [],
    ),
    _SymptomPreset(
      id: 'holes',
      label: 'Holes',
      prompt: 'Leaves are chewed',
      icon: Icons.blur_circular_outlined,
      color: _berry,
      keywords: [
        'hole',
        'holes',
        'chew',
        'chewed',
        'caterpillar',
        'slug',
        'snail',
        'damage'
      ],
    ),
    _SymptomPreset(
      id: 'yellowing',
      label: 'Yellowing',
      prompt: 'Leaves are yellow',
      icon: Icons.warning_amber_outlined,
      color: _clay,
      keywords: [
        'yellow',
        'yellowing',
        'pale',
        'chlorosis',
        'nutrient',
        'water'
      ],
    ),
    _SymptomPreset(
      id: 'sticky',
      label: 'Sticky',
      prompt: 'Sticky leaves or insects',
      icon: Icons.water_drop_outlined,
      color: _moss,
      keywords: ['sticky', 'aphid', 'honeydew', 'whitefly', 'insect', 'sap'],
    ),
    _SymptomPreset(
      id: 'spots',
      label: 'Spots',
      prompt: 'Spots, mould, or rot',
      icon: Icons.coronavirus_outlined,
      color: _berry,
      keywords: [
        'spot',
        'spots',
        'mould',
        'mold',
        'rot',
        'blight',
        'mildew',
        'disease'
      ],
    ),
    _SymptomPreset(
      id: 'wilting',
      label: 'Wilting',
      prompt: 'Wilting or weak growth',
      icon: Icons.local_florist_outlined,
      color: _clay,
      keywords: ['wilt', 'wilting', 'droop', 'weak', 'water', 'dry', 'root'],
    ),
    _SymptomPreset(
      id: 'seedlings',
      label: 'Seedlings',
      prompt: 'Seedlings disappear',
      icon: Icons.grass_outlined,
      color: _leafDark,
      keywords: [
        'seedling',
        'seedlings',
        'cutworm',
        'slug',
        'snail',
        'birds',
        'disappear'
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_PestGuideData> _loadData() async {
    final problems = await _repository.loadPestProblems();
    final crops = await _repository.loadCrops();
    final affectedCropIds =
        problems.expand((problem) => problem.commonCrops).toSet();
    final affectedCrops = crops
        .where((crop) => affectedCropIds.contains(crop.id))
        .toList(growable: false)
      ..sort((a, b) => a.commonName.compareTo(b.commonName));

    return _PestGuideData(
      problems: problems,
      crops: affectedCrops,
      cropById: {for (final crop in crops) crop.id: crop},
    );
  }

  List<PestProblem> _filterProblems(List<PestProblem> problems) {
    final normalizedQuery = _query.trim().toLowerCase();
    final symptom = _symptoms.firstWhere(
      (preset) => preset.id == _symptomId,
      orElse: () => _symptoms.first,
    );

    final filtered = problems.where((problem) {
      final searchableText = [
        problem.name,
        problem.category,
        problem.summary,
        problem.seasonNotes,
        ...problem.signs,
        ...problem.actions,
        ...problem.prevention,
      ].join(' ').toLowerCase();

      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory =
          _category == 'all' || problem.category == _category;
      final matchesCrop =
          _cropId == 'all' || problem.commonCrops.contains(_cropId);
      final matchesSymptom =
          symptom.id == 'all' || symptom.keywords.any(searchableText.contains);

      return matchesQuery && matchesCategory && matchesCrop && matchesSymptom;
    }).toList(growable: false);

    filtered.sort((a, b) {
      final aScore = _problemScore(a);
      final bScore = _problemScore(b);
      final scoreCompare = bScore.compareTo(aScore);

      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  int _problemScore(PestProblem problem) {
    var score = 0;

    if (_category != 'all' && problem.category == _category) {
      score += 10;
    }

    if (_cropId != 'all' && problem.commonCrops.contains(_cropId)) {
      score += 12;
    }

    final symptom = _symptoms.firstWhere(
      (preset) => preset.id == _symptomId,
      orElse: () => _symptoms.first,
    );

    if (symptom.id != 'all') {
      final text = [
        problem.name,
        problem.summary,
        ...problem.signs,
        ...problem.actions,
        ...problem.prevention,
      ].join(' ').toLowerCase();

      if (symptom.keywords.any(text.contains)) {
        score += 20;
      }
    }

    return score;
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _query = '';
      _category = 'all';
      _cropId = 'all';
      _symptomId = 'all';
      _searchController.clear();
    });
  }

  void _showProblemSheet(PestProblem problem, Map<String, Crop> cropById) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    _IconBubble(
                      icon: _iconForCategory(problem.category),
                      color: _colorForCategory(problem.category),
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            problem.name,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            problem.summary,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MiniList(title: 'Signs to check', items: problem.signs),
                _MiniList(title: 'What to do now', items: problem.actions),
                _MiniList(
                    title: 'How to prevent it', items: problem.prevention),
                if (problem.seasonNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SeasonNote(note: problem.seasonNotes),
                ],
                if (problem.commonCrops.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _LinkedCrops(
                    cropIds: problem.commonCrops,
                    cropById: cropById,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Plant Doctor'),
        backgroundColor: Colors.transparent,
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
                child: Text('Could not load plant doctor: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No pest guide data found.'));
          }

          final filteredProblems = _filterProblems(data.problems);
          final selectedSymptom = _symptoms.firstWhere(
            (preset) => preset.id == _symptomId,
            orElse: () => _symptoms.first,
          );

          return Stack(
            children: [
              Positioned(
                top: -130,
                right: -120,
                child: _SoftBlob(
                  color: _mint.withValues(alpha: .86),
                  size: 270,
                ),
              ),
              Positioned(
                bottom: -190,
                left: -150,
                child: _SoftBlob(
                  color: _sun.withValues(alpha: .18),
                  size: 340,
                ),
              ),
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                children: [
                  _DoctorHero(
                    selectedSymptom: selectedSymptom,
                    resultCount: filteredProblems.length,
                    totalCount: data.problems.length,
                  ),
                  const SizedBox(height: 16),
                  _SymptomPicker(
                    symptoms: _symptoms,
                    selectedId: _symptomId,
                    onSelected: (id) {
                      HapticFeedback.selectionClick();
                      setState(() => _symptomId = id);
                    },
                  ),
                  const SizedBox(height: 14),
                  _SearchAndFilters(
                    searchController: _searchController,
                    query: _query,
                    category: _category,
                    cropId: _cropId,
                    crops: data.crops,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onCategoryChanged: (value) =>
                        setState(() => _category = value),
                    onCropChanged: (value) => setState(() => _cropId = value),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 14),
                  _DoctorSummaryCard(
                    selectedSymptom: selectedSymptom,
                    filteredCount: filteredProblems.length,
                    totalCount: data.problems.length,
                    category: _category,
                    cropId: _cropId,
                    cropById: data.cropById,
                  ),
                  const SizedBox(height: 14),
                  if (filteredProblems.isEmpty)
                    _EmptyResultsCard(onClear: _clearFilters)
                  else
                    ...filteredProblems.map(
                      (problem) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProblemCard(
                          problem: problem,
                          cropById: data.cropById,
                          onTap: () =>
                              _showProblemSheet(problem, data.cropById),
                          onLongPress: () =>
                              _showProblemSheet(problem, data.cropById),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoctorHero extends StatelessWidget {
  const _DoctorHero({
    required this.selectedSymptom,
    required this.resultCount,
    required this.totalCount,
  });

  final _SymptomPreset selectedSymptom;
  final int resultCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_leafDark, _leaf, _moss],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22172D22),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -34,
            child: Icon(
              selectedSymptom.icon,
              size: 152,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassPill(label: 'Plant Doctor'),
              const SizedBox(height: 20),
              const Text(
                'What do you\nsee?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                selectedSymptom.id == 'all'
                    ? 'Choose a symptom, crop, or search term to narrow likely causes.'
                    : '${selectedSymptom.prompt}. Showing $resultCount of $totalCount possible issues.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .86),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(selectedSymptom.icon, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedSymptom.prompt,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(Icons.touch_app_outlined, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SymptomPicker extends StatelessWidget {
  const _SymptomPicker({
    required this.symptoms,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_SymptomPreset> symptoms;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: symptoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final symptom = symptoms[index];
          final selected = symptom.id == selectedId;

          return Material(
            color: selected ? symptom.color : _surface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onSelected(symptom.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 118,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: selected ? symptom.color : _border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 18,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      symptom.icon,
                      color: selected ? Colors.white : symptom.color,
                    ),
                    const Spacer(),
                    Text(
                      symptom.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      symptom.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: .82)
                            : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.searchController,
    required this.query,
    required this.category,
    required this.cropId,
    required this.crops,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onCropChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String query;
  final String category;
  final String cropId;
  final List<Crop> crops;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onCropChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters = query.isNotEmpty || category != 'all' || cropId != 'all';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search signs, pests, diseases',
              hintText: 'Example: aphids, holes, yellowing, mould',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(
                label: 'All',
                value: 'all',
                selectedValue: category,
                icon: Icons.grid_view_outlined,
                color: _leaf,
                onSelected: onCategoryChanged,
              ),
              _CategoryChip(
                label: 'Pests',
                value: 'pest',
                selectedValue: category,
                icon: Icons.bug_report_outlined,
                color: _berry,
                onSelected: onCategoryChanged,
              ),
              _CategoryChip(
                label: 'Diseases',
                value: 'disease',
                selectedValue: category,
                icon: Icons.coronavirus_outlined,
                color: _clay,
                onSelected: onCategoryChanged,
              ),
              _CategoryChip(
                label: 'Crop problems',
                value: 'crop_problem',
                selectedValue: category,
                icon: Icons.warning_amber_outlined,
                color: _moss,
                onSelected: onCategoryChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: cropId,
            decoration: InputDecoration(
              labelText: 'Affected crop',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('All crops'),
              ),
              ...crops.map(
                (crop) => DropdownMenuItem(
                  value: crop.id,
                  child: Text(crop.commonName),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onCropChanged(value);
              }
            },
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.icon,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedValue == value;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : color,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: color,
      backgroundColor: _surface,
      side: BorderSide(color: selected ? color : _border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontWeight: FontWeight.w900,
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected(value);
      },
    );
  }
}

class _DoctorSummaryCard extends StatelessWidget {
  const _DoctorSummaryCard({
    required this.selectedSymptom,
    required this.filteredCount,
    required this.totalCount,
    required this.category,
    required this.cropId,
    required this.cropById,
  });

  final _SymptomPreset selectedSymptom;
  final int filteredCount;
  final int totalCount;
  final String category;
  final String cropId;
  final Map<String, Crop> cropById;

  @override
  Widget build(BuildContext context) {
    final cropName = cropById[cropId]?.commonName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallTag(label: 'Likely matches', color: selectedSymptom.color),
          const SizedBox(height: 12),
          Text(
            '$filteredCount of $totalCount entries',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _summaryText(cropName),
            style: const TextStyle(
              color: _muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  label: selectedSymptom.label, color: selectedSymptom.color),
              if (category != 'all')
                _InfoChip(
                    label: _formatValue(category),
                    color: _colorForCategory(category)),
              if (cropName != null) _InfoChip(label: cropName, color: _leaf),
            ],
          ),
        ],
      ),
    );
  }

  String _summaryText(String? cropName) {
    if (filteredCount == 0) {
      return 'No exact match. Clear one filter or choose a broader symptom.';
    }

    if (selectedSymptom.id == 'all' && cropName == null && category == 'all') {
      return 'Choose a symptom or affected crop to make the list more useful.';
    }

    if (cropName != null) {
      return 'Filtered for $cropName. Tap a card for signs, actions, and prevention.';
    }

    return 'Tap a card for a practical checklist. Long-press works too.';
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.problem,
    required this.cropById,
    required this.onTap,
    required this.onLongPress,
  });

  final PestProblem problem;
  final Map<String, Crop> cropById;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(problem.category);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: .16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBubble(
                      icon: _iconForCategory(problem.category),
                      color: color,
                      size: 50,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        problem.name,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SmallTag(
                        label: _formatValue(problem.category), color: color),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  problem.summary,
                  style: const TextStyle(
                    color: _muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    ...problem.signs.take(3).map(
                          (sign) => _InfoChip(label: sign, color: color),
                        ),
                  ],
                ),
                if (problem.commonCrops.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CropPreviewChips(
                    cropIds: problem.commonCrops,
                    cropById: cropById,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap for diagnosis steps',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropPreviewChips extends StatelessWidget {
  const _CropPreviewChips({
    required this.cropIds,
    required this.cropById,
  });

  final List<String> cropIds;
  final Map<String, Crop> cropById;

  @override
  Widget build(BuildContext context) {
    final labels = cropIds
        .take(4)
        .map((id) => cropById[id]?.commonName ?? _formatValue(id))
        .toList();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        ...labels.map(
          (label) => _InfoChip(label: label, color: _leaf),
        ),
        if (cropIds.length > 4)
          _InfoChip(label: '+${cropIds.length - 4} more', color: _leafDark),
      ],
    );
  }
}

class _LinkedCrops extends StatelessWidget {
  const _LinkedCrops({
    required this.cropIds,
    required this.cropById,
  });

  final List<String> cropIds;
  final Map<String, Crop> cropById;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cropIds.map((cropId) {
        final crop = cropById[cropId];
        final label = crop?.commonName ?? _formatValue(cropId);

        return ActionChip(
          avatar: const Icon(Icons.eco_outlined, size: 18),
          label: Text(label),
          onPressed: crop == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CropDetailScreen(crop: crop),
                    ),
                  );
                },
        );
      }).toList(growable: false),
    );
  }
}

class _MiniList extends StatelessWidget {
  const _MiniList({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, color: _leaf, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: _muted,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonNote extends StatelessWidget {
  const _SeasonNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _mint.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: _leafDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                color: _leafDark,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmallTag(label: 'No exact match', color: _clay),
          const SizedBox(height: 12),
          const Text(
            'Try a broader symptom or clear the crop/category filter.',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gardening symptoms can overlap. For example, yellowing can come from water, roots, nutrients, pests, or disease.',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SymptomPreset {
  const _SymptomPreset({
    required this.id,
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  final String id;
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;
  final List<String> keywords;
}

class _PestGuideData {
  const _PestGuideData({
    required this.problems,
    required this.crops,
    required this.cropById,
  });

  final List<PestProblem> problems;
  final List<Crop> crops;
  final Map<String, Crop> cropById;
}

IconData _iconForCategory(String category) {
  return switch (category) {
    'pest' => Icons.bug_report_outlined,
    'disease' => Icons.coronavirus_outlined,
    'crop_problem' => Icons.warning_amber_outlined,
    _ => Icons.info_outline,
  };
}

Color _colorForCategory(String category) {
  return switch (category) {
    'pest' => _berry,
    'disease' => _clay,
    'crop_problem' => _moss,
    _ => _leaf,
  };
}

String _formatValue(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
