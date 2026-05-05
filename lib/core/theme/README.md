# Garden visual theme

Reusable visual polish for the app.

## Apply app-wide

In the app entry point:

```dart
import 'package:nz_vege_garden/core/theme/garden_visual_theme.dart';

MaterialApp(
  theme: GardenVisualTheme.light(),
  home: const YourHomeScreen(),
);
```

## Reusable visual components

```dart
import 'package:nz_vege_garden/core/widgets/garden_cards.dart';
import 'package:nz_vege_garden/core/widgets/garden_hero.dart';
```

Available components:

- `GardenScreenBackground`
- `GardenHeroCard`
- `GardenGlassPill`
- `GardenPrettyCard`
- `GardenStatusPill`
- `GardenPlantBadge`
- `GardenBotanicalPainter`

## Design direction

The visual style is designed to make the app feel warmer and more premium:

- soft off-white canvas
- rounded cards
- botanical green palette
- warmer clay and sun accents
- subtle shadows
- gradient hero surfaces
- decorative plant shapes without image assets
- Material 3 controls
