import 'package:flutter/material.dart';

/// Shared visual language for the garden app.
///
/// Use `GardenVisualTheme.light()` in MaterialApp to give the whole app a
/// softer, warmer, more polished garden-focused appearance.
class GardenVisualTheme {
  const GardenVisualTheme._();

  static const Color canvas = Color(0xFFF8F3E8);
  static const Color surface = Color(0xFFFFFCF5);
  static const Color surfaceSoft = Color(0xFFF1E8D6);
  static const Color ink = Color(0xFF172D22);
  static const Color muted = Color(0xFF66736A);
  static const Color leaf = Color(0xFF2F724B);
  static const Color leafDark = Color(0xFF17452F);
  static const Color moss = Color(0xFF8BA766);
  static const Color mint = Color(0xFFE7F0DB);
  static const Color clay = Color(0xFFC4793D);
  static const Color sun = Color(0xFFF4C86A);
  static const Color berry = Color(0xFFB35642);
  static const Color border = Color(0xFFE7DFCE);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: leaf,
      brightness: Brightness.light,
      primary: leaf,
      secondary: clay,
      surface: surface,
      error: berry,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: leaf,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: leaf,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: leaf,
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: leaf, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: mint,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? leaf : muted,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? leaf : muted);
        }),
      ),
    );
  }
}

class GardenShadows {
  const GardenShadows._();

  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> hero = <BoxShadow>[
    BoxShadow(color: Color(0x24172D22), blurRadius: 32, offset: Offset(0, 18)),
  ];
}

class GardenGradients {
  const GardenGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      GardenVisualTheme.leafDark,
      GardenVisualTheme.leaf,
      GardenVisualTheme.moss,
    ],
  );

  static const LinearGradient plantBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      GardenVisualTheme.mint,
      Color(0xFFD4E5BE),
    ],
  );

  static const LinearGradient sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFFE8A3),
      Color(0xFFF4C86A),
      Color(0xFFD9904E),
    ],
  );
}
