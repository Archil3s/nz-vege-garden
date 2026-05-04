# Progress Log

This file tracks project progress in plain English so the current state is visible from GitHub without needing to inspect every commit.

## Current status

The repo now contains the planning documents, bundled seed data, a Flutter scaffold, a local JSON data layer, the first usable local setup flow, and a working local garden bed planner UI.

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
- Beds: working garden bed planner
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

### Garden bed storage foundation

Added:

```text
lib/data/models/garden_bed.dart
lib/data/garden_bed_repository.dart
```

Implemented:

- Local `GardenBed` model
- JSON serialisation for garden beds
- Optional bed dimensions in centimetres
- Calculated bed area helpers
- Sun exposure and wind exposure fields
- Local garden bed storage with `shared_preferences`
- Add, update, delete, and load methods for garden beds

### Garden bed planner UI

Added:

```text
lib/features/garden_beds/add_garden_bed_screen.dart
```

Updated:

```text
lib/features/garden_beds/garden_beds_screen.dart
```

Implemented:

- Empty state for users with no beds
- Add-bed screen
- Required bed name field
- Bed type selector
- Optional length and width fields
- Sun exposure selector
- Wind exposure selector
- Notes field
- Local save through `GardenBedRepository`
- Saved garden bed list
- Bed cards showing type, exposure, dimensions, area, and notes
- Delete support for saved beds

## In progress

### Crop detail screen

Goal:

- Open crop details from the Crop Guide screen
- Show full crop information
- Surface frost/container/beginner flags clearly
- Prepare for adding sowing, transplanting, and harvest guidance per crop

## Next planned work

1. Add crop detail screen
2. Expand seed crop data
3. Add pest/problem seed data
4. Add task generation rules
5. Add local notifications
6. Add app tests once the first workflow is stable

## GitHub issues created

- `#2` MVP: Define Flutter app structure
- `#3` MVP: Build local crop and region data layer
- `#4` MVP: Add editable setup flow
