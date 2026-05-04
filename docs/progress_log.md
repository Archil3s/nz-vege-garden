# Progress Log

This file tracks project progress in plain English so the current state is visible from GitHub without needing to inspect every commit.

## Current status

The repo now contains the planning documents, expanded bundled seed data, a Flutter scaffold, a local JSON data layer, the first usable local setup flow, a working local garden bed planner UI, navigable crop detail pages, an offline pest/problem guide, and generated weekly task recommendations.

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
assets/data/pests.json
assets/data/task_rules.json
```

Initial data includes:

- 11 broad NZ regions
- Expanded vegetable/herb crop profiles
- Basic planting rules for crop, month, method, and region
- Pest, disease, and crop problem guidance
- Weekly task generation rules

### Expanded crop database

Updated:

```text
assets/data/crops.json
```

Added or expanded crops including:

```text
potato
kumara
kale
cabbage
cauliflower
broad_beans
dwarf_beans
courgette
cucumber
pumpkin
capsicum
chilli
onion
leek
spring_onion
sweetcorn
parsley
coriander
chives
```

The crop guide now has broader MVP coverage for common New Zealand home vegetable gardens.

### Pest/problem guide data

Added:

```text
assets/data/pests.json
lib/data/models/pest_problem.dart
```

Updated:

```text
pubspec.yaml
lib/data/garden_data_repository.dart
lib/features/pests/pest_guide_screen.dart
```

Implemented:

- Offline pest/problem seed data
- PestProblem model
- Asset registration for pest data
- Data repository loading for pest/problem entries
- Data-driven Pests screen
- Expandable pest/problem cards
- Signs, actions, prevention notes, and seasonal notes
- Category icons for pests, diseases, and crop problems

### Weekly task generation

Added:

```text
assets/data/task_rules.json
lib/data/models/task_rule.dart
lib/data/weekly_task_service.dart
```

Updated:

```text
pubspec.yaml
lib/data/garden_data_repository.dart
lib/features/tasks/weekly_tasks_screen.dart
```

Implemented:

- Offline weekly task rule seed data
- TaskRule model
- Asset registration for task rules
- Data repository loading for task rules
- WeeklyTaskService for generated recommendations
- Filtering by month, region, garden type, frost risk, and wind exposure
- Priority-based task sorting
- Data-driven Weekly Tasks screen
- Task cards with task type icons, title, description, priority, and type
- Empty state when no task rules match

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
- Load pest/problem seed data
- Load task rule seed data
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
- Crops: lists crop guide entries and opens detail pages
- Beds: working garden bed planner
- Tasks: generated weekly task recommendations
- Pests: offline pest/problem guide
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

### Crop detail pages

Added:

```text
lib/features/crops/crop_detail_screen.dart
```

Updated:

```text
lib/features/crops/crop_guide_screen.dart
```

Implemented:

- Tappable crop guide cards
- Crop detail navigation
- Crop name and summary
- Category, sun, water, frost, container, and beginner chips
- Plant spacing section
- Harvest timing section
- Generated growing notes from existing seed data
- MVP data note for future richer crop guidance

## In progress

### Local notifications

Goal:

- Initialise local notifications
- Let users enable a weekly gardening reminder
- Keep reminders local on-device
- Avoid server push notifications and backend cost

## Next planned work

1. Add local notification service
2. Add notification setting toggle
3. Add app tests once the first workflow is stable

## GitHub issues created

- `#2` MVP: Define Flutter app structure
- `#3` MVP: Build local crop and region data layer
- `#4` MVP: Add editable setup flow
