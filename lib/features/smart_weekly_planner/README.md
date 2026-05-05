# Smart Weekly Planner

Self-contained UI module for a more visual, action-led NZ garden planning experience.

## Entry point

```dart
import 'package:nz_vege_garden/features/smart_weekly_planner/smart_weekly_planner_screen.dart';

const SmartWeeklyPlannerScreen();
```

## Current scope

- UI-first weekly planner screen
- Today, Calendar, My Garden, and Plants tabs
- Task completion state
- Seasonal planting window cards
- Garden zone cards
- Recommendation cards
- Seed data only; no persistence dependency yet

## Intended next wiring

1. Add `SmartWeeklyPlannerScreen` to the app shell or home navigation.
2. Replace `PlannerSeedData` with existing plant and garden repositories.
3. Persist completed tasks.
4. Connect region selection to user settings.
5. Connect weather/frost warnings when a weather provider is added.

## Design intent

The screen avoids large text blocks and uses cards, chips, progress indicators, and clear actions so the app feels more like a daily garden dashboard than a static planting calendar.
