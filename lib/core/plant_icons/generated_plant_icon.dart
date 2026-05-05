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

  static const _customPlantSvgs = <String, String>{
    'potato': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="50" cy="56" rx="31" ry="23" fill="#A9825A"/>
      <path d="M23 56 C22 41 38 28 53 30 C69 32 81 45 77 60 C74 73 58 81 41 76 C30 73 24 66 23 56 Z" fill="#B58B63"/>
      <circle cx="36" cy="45" r="3" fill="#6D4C41"/>
      <circle cx="59" cy="38" r="2.8" fill="#6D4C41"/>
      <circle cx="51" cy="68" r="2.5" fill="#6D4C41"/>
      <ellipse cx="38" cy="39" rx="8" ry="4" fill="#FFF7E6" opacity="0.18" transform="rotate(-28 38 39)"/>
    </svg>''',
    'spinach': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M50 83 C49 68 49 55 50 40" stroke="#2E7D32" stroke-width="5" stroke-linecap="round"/>
      <path d="M49 43 C28 37 18 24 22 13 C39 13 50 25 52 43 Z" fill="#4CAF50"/>
      <path d="M52 44 C70 32 86 32 91 45 C78 58 63 57 52 44 Z" fill="#66BB6A"/>
      <path d="M49 57 C28 54 14 66 18 80 C37 84 49 72 49 57 Z" fill="#43A047"/>
      <path d="M52 58 C72 54 88 64 86 79 C68 84 54 73 52 58 Z" fill="#81C784"/>
      <path d="M31 24 C39 31 45 36 50 42 M70 44 C62 45 56 45 52 44 M31 73 C39 67 44 62 49 58 M72 73 C64 67 58 62 52 58" stroke="#1B5E20" stroke-width="2" opacity="0.45"/>
    </svg>''',
    'cabbage': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="52" r="34" fill="#A5D6A7"/>
      <path d="M50 18 C36 28 31 42 38 54 C26 55 18 62 17 76 C36 79 46 70 50 57 C54 70 65 79 83 76 C82 62 74 55 62 54 C69 42 64 28 50 18 Z" fill="#66BB6A"/>
      <path d="M50 28 C40 35 39 46 50 53 C61 46 60 35 50 28 Z" fill="#C8E6C9"/>
      <path d="M39 54 C44 48 47 44 50 30 M61 54 C56 48 53 44 50 30 M22 72 C34 70 43 64 50 55 M78 72 C66 70 57 64 50 55" stroke="#2E7D32" stroke-width="2.2" opacity="0.55"/>
    </svg>''',
    'broad_beans': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M34 83 C31 60 36 40 49 20" stroke="#2E7D32" stroke-width="5" stroke-linecap="round"/>
      <path d="M52 20 C70 28 79 48 73 70 C68 87 46 83 42 67 C38 50 41 31 52 20 Z" fill="#43A047"/>
      <ellipse cx="55" cy="36" rx="8" ry="11" fill="#A5D6A7" transform="rotate(-14 55 36)"/>
      <ellipse cx="56" cy="55" rx="8" ry="11" fill="#A5D6A7" transform="rotate(-4 56 55)"/>
      <ellipse cx="52" cy="72" rx="7" ry="9" fill="#A5D6A7" transform="rotate(11 52 72)"/>
      <path d="M52 23 C50 42 49 60 51 79" stroke="#1B5E20" stroke-width="2" opacity="0.45"/>
    </svg>''',
    'peas': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M22 76 C42 40 62 27 85 23" stroke="#2E7D32" stroke-width="5" stroke-linecap="round"/>
      <path d="M32 68 C47 54 64 49 78 55 C70 75 48 82 32 68 Z" fill="#66BB6A"/>
      <circle cx="48" cy="66" r="7" fill="#C5E1A5"/>
      <circle cx="61" cy="62" r="7" fill="#C5E1A5"/>
      <circle cx="72" cy="57" r="6" fill="#C5E1A5"/>
      <path d="M38 25 C49 20 58 27 59 37 C48 39 39 34 38 25 Z" fill="#81C784"/>
      <path d="M69 21 C79 16 88 21 91 31 C80 35 71 31 69 21 Z" fill="#81C784"/>
    </svg>''',
    'cucumber': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M19 61 C27 36 49 22 71 24 C87 26 92 40 84 53 C72 72 39 82 20 70 C17 68 17 65 19 61 Z" fill="#2E7D32"/>
      <path d="M25 63 C38 48 56 39 79 37" stroke="#81C784" stroke-width="4" stroke-linecap="round" opacity="0.75"/>
      <circle cx="42" cy="55" r="2" fill="#C8E6C9"/><circle cx="57" cy="47" r="2" fill="#C8E6C9"/><circle cx="70" cy="41" r="2" fill="#C8E6C9"/>
      <path d="M73 25 C79 17 90 19 93 27 C84 31 78 30 73 25 Z" fill="#66BB6A"/>
    </svg>''',
    'tomato': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="56" r="30" fill="#E53935"/>
      <path d="M50 25 L56 39 L72 32 L62 45 L78 50 L61 52 L66 68 L52 57 L39 70 L43 53 L25 50 L40 45 L29 32 L45 39 Z" fill="#2E7D32"/>
      <circle cx="39" cy="47" r="7" fill="#FFCDD2" opacity="0.28"/>
      <path d="M50 34 C62 41 70 52 68 67" stroke="#B71C1C" stroke-width="2" opacity="0.25"/>
    </svg>''',
    'carrot': r'''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <path d="M51 27 C59 47 57 70 43 91 C34 67 35 44 51 27 Z" fill="#F57C00"/>
      <path d="M49 29 C59 37 64 42 69 50" stroke="#EF6C00" stroke-width="3" opacity="0.45"/>
      <path d="M48 29 C37 22 34 10 40 5 C49 13 51 21 48 29 Z" fill="#43A047"/>
      <path d="M51 29 C55 16 64 8 73 9 C71 23 62 29 51 29 Z" fill="#66BB6A"/>
      <path d="M50 28 C45 17 49 8 57 4 C62 16 58 24 50 28 Z" fill="#81C784"/>
    </svg>''',
  };

  @override
  Widget build(BuildContext context) {
    final key = _iconKeyForCrop(cropName);
    final rawSvg = _customPlantSvgs[key] ?? generatedPlantSvgs[key];

    if (rawSvg == null) {
      return _fallbackIcon(context);
    }

    final svg = _normaliseSvg(rawSvg);

    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _fallbackIcon(context),
      errorBuilder: (_, __, ___) => _fallbackIcon(context),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Icon(
      Icons.local_florist,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  String _normaliseSvg(String svg) {
    return svg.replaceAll(r'\"', '"').trim();
  }

  String _iconKeyForCrop(String value) {
    final name = value.trim().toLowerCase();
    final exact = name
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (_customPlantSvgs.containsKey(exact)) {
      return exact;
    }

    if (generatedPlantSvgs.containsKey(exact)) {
      return exact;
    }

    const aliases = {
      'potatoes': 'potato',
      'silverbeet': 'spinach',
      'spinach': 'spinach',
      'kale': 'cabbage',
      'cabbage': 'cabbage',
      'broccoli': 'cabbage',
      'cauliflower': 'cabbage',
      'broad_beans': 'broad_beans',
      'broad_bean': 'broad_beans',
      'dwarf_beans': 'broad_beans',
      'beans': 'broad_beans',
      'peas': 'peas',
      'pea': 'peas',
      'courgette': 'cucumber',
      'zucchini': 'cucumber',
      'cucumber': 'cucumber',
      'carrot': 'carrot',
      'carrots': 'carrot',
      'tomato': 'tomato',
      'tomatoes': 'tomato',
      'capsicum': 'capsicum',
      'pepper': 'capsicum',
      'bell_pepper': 'bell_pepper',
      'chilli': 'chilli',
      'spring_onion': 'chives',
      'onion': 'chives',
      'leek': 'chives',
    };

    final alias = aliases[exact];
    if (alias != null) {
      if (_customPlantSvgs.containsKey(alias) || generatedPlantSvgs.containsKey(alias)) {
        return alias;
      }
    }

    for (final key in {..._customPlantSvgs.keys, ...generatedPlantSvgs.keys}) {
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
