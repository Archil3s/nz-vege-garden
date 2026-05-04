# Progress Log

This file tracks project progress in plain English so the current state is visible from GitHub without needing to inspect every commit.

## Current status

The repo now contains the planning documents, bundled seed data, a Flutter scaffold, a local JSON data layer, placeholder app screens, and the first usable local setup flow.

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
- Settings: editable local setup screen

### Local setup flow

Added:

```text
lib/data/models/app_settings.dart
lib/data/app_settings_repository.dart
```

Implemented:

- Default app settings
- Local settings persistence with `shared_preferences`
- Editable NZ region selector
- Editable frost risk selector
- Editable wind exposure selector
- Editable garden type selector
- Home screen now reads saved settings
- What-to-plant-now now uses the saved region instead of a hardcoded region

## In progress

### Garden bed planner

Goal:

- Add a local garden bed model
- Add a simple local garden bed repository
- Let users create named beds or containers
- Show saved beds on the Garden Beds screen

## Next planned work

1. Add a basic garden bed model
2. Add local garden bed storage
3. Add garden bed creation form
4. Add crop detail screen
5. Expand seed crop data
6. Add pest/problem seed data
7. Add task generation rules
8. Add local notifications
9. Add app tests once the first workflow is stable

## GitHub issues created

- `#2` MVP: Define Flutter app structure
- `#3` MVP: Build local crop and region data layer
- `#4` MVP: Add editable setup flow
