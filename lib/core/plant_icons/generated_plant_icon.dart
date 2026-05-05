import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'generated_plant_svgs.dart';

class GeneratedPlantIcon extends StatelessWidget {
  const GeneratedPlantIcon({
    required this.cropName,
    this.size = 24,
    super.key,
  });

  final String cropName;
  final double size;

  static const _potatoSvg = r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path d="M50 75 C34 75 22 67 20 56 C18 45 26 32 38 26 C44 23 50 22 56 24 C68 28 80 40 78 55 C76 68 64 75 50 75 Z" fill="#A1887F"/>
  <circle cx="34" cy="38" r="3" fill="#795548"/>
  <circle cx="62" cy="30" r="2.5" fill="#795548"/>
  <circle cx="46" cy="70" r="2.5" fill="#795548"/>
  <ellipse cx="36" cy="36" rx="6" ry="4" fill="white" opacity="0.14" transform="rotate(-30 36 36)"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    final key = _iconKeyForCrop(cropName);
    final svg = key == 'potato' ? _potatoSvg : generatedPlantSvgs[key];

    if (svg == null) {
      return Icon(
        Icons.local_florist,
        size: size,
      );
    }

    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  String _iconKeyForCrop(String value) {
    final name = value.trim().toLowerCase();
    final exact = name
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (exact == 'potato' || exact == 'potatoes') {
      return 'potato';
    }

    if (generatedPlantSvgs.containsKey(exact)) {
      return exact;
    }

    const aliases = {
      'silverbeet': 'lettuce',
      'spinach': 'lettuce',
      'kale': 'lettuce',
      'cabbage': 'lettuce',
      'capsicum': 'capsicum',
      'pepper': 'capsicum',
      'bell_pepper': 'bell_pepper',
      'chilli': 'chilli',
      'courgette': 'cucumber',
      'zucchini': 'cucumber',
      'spring_onion': 'chives',
      'onion': 'chives',
      'leek': 'chives',
      'broad_beans': 'lettuce',
      'dwarf_beans': 'lettuce',
    };

    final alias = aliases[exact];
    if (alias != null && generatedPlantSvgs.containsKey(alias)) {
      return alias;
    }

    for (final key in generatedPlantSvgs.keys) {
      final normalizedKey = key.replaceAll('_', ' ');

      if (name == normalizedKey ||
          name.contains(normalizedKey) ||
          normalizedKey.contains(name)) {
        return key;
      }
    }

    return exact;
  }
}
