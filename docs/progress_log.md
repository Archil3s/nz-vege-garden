# Progress Log

This file tracks project progress in plain English so the current state is visible from GitHub without needing to inspect every commit.

## Current status

The repo now contains the planning documents, bundled seed data, a Flutter scaffold, a local JSON data layer, placeholder app screens, and the start of local user settings.

## Completed

### Repository setup

- Created repository: `Archil3s/nz-vege-garden`
- Initialized the repository with `README.md`
- Confirmed GitHub write access through the ChatGPT connector

### Planning documents

Added:

```text
docs/mvp_scope.md
docs/data_model.md
docs/nz_regions.md
docs/crop_list.md
```

These define:

- MVP scope
- Target user
- Zero-cost/offline-first constraints
- Suggested local data model
- Broad NZ growing regions
- Initial crop list

### Seed data

Added:

```text
assets/data/nz_regions.json
assets/data/crops.json
assets/data/planting_rules.json
```

Initial data includes:

- 11 broad NZ regions
- Initial vegetable/herb crop profiles
- Basic planting rules for crop, month, method, and region

### Flutter scaffold

Added:

```text
pubspec.yaml
analysis_options.yaml
lib/main.dart
lib/app/app.dart
lib/app/app_theme.dart
```

The app currently uses:

- Flutter
- Material 3
- Bottom navigation
- Bundled JSON assets
- A green garden-themed app style

### Local data layer

Added:

```text
lib/data/garden_data_repository.dart
lib/data/models/crop.dart
lib/data/models/nz_region.dart
lib/data/models/planting_rule.dart
```

The data layer can:

- Load crop seed data
- Load NZ region seed data
- Load planting rules
- Filter crops by selected month and region

### Initial screens

Added:

```text
lib/features/home/home_screen.dart
lib/features/crops/crop_guide_screen.dart
lib/features/garden_beds/garden_beds_screen.dart
lib/features/tasks/weekly_tasks_screen.dart
lib/features/pests/pest_guide_screen.dart
lib/features/settings/settings_screen.dart
```

Current screens:

- Home: shows crops plantable now
- Crops: lists crop guide entries
- Beds: placeholder for garden bed planner
- Tasks: placeholder weekly tasks
- Pests: placeholder pest/problem guide
- Settings: lists available NZ regions

### Settings work started

Added:

```text
lib/data/models/app_settings.dart
```

This defines default local app settings for:

- Region
- Frost risk
- Wind exposure
- Garden type

## In progress

### Editable setup flow

Goal:

- Persist user settings with `shared_preferences`
- Let users choose their NZ region
- Use the saved region on the Home screen
- Show selected region on Settings screen

## Next planned work

1. Add `AppSettingsRepository`
2. Update Home screen to use saved region
3. Update Settings screen with editable region selector
4. Add frost/wind/garden-type selectors
5. Add a basic garden bed model
6. Add local garden bed creation
7. Add crop detail screen
8. Expand seed crop data
9. Add pest/problem seed data
10. Add app tests once the first workflow is stable

## GitHub issues created

- `#2` MVP: Define Flutter app structure
- `#3` MVP: Build local crop and region data layer
- `#4` MVP: Add editable setup flow
