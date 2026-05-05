# Progress Log

This file tracks project progress in plain English so the current state is visible from GitHub without needing to inspect every commit.

## Current status

The repo now contains the planning documents, expanded bundled seed data, a Flutter scaffold, a local JSON data layer, the first usable local setup flow, a garden dashboard, a working local garden bed planner UI, crop-to-bed planting with editable planting details and estimated harvest windows, navigable crop detail pages, an offline pest/problem guide, generated weekly task recommendations, and the first local notification foundation.

GitHub Pages preview work has been removed for now. The app will be tested locally on a PC with Flutter tooling.

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

### Local run setup

Updated:

```text
README.md
```

Implemented:

- PC run instructions
- Browser run command with `flutter run -d chrome`
- Android emulator/device run command with `flutter run`
- Removed GitHub Pages preview instructions
- Removed automatic GitHub Pages deployment workflow

### Garden dashboard

Updated:

```text
lib/features/home/home_screen.dart
```

Implemented:

- Home screen dashboard title and garden context
- Local bed count summary
- Local planting count summary
- Upcoming harvest count summary
- Upcoming harvest list from planted crops
- Region-aware what-to-plant-now list remains on the Home screen
- Dashboard uses only bundled data and local device storage

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

### Crop-to-bed planting flow

Added:

```text
lib/data/models/garden_bed_planting.dart
lib/data/garden_bed_planting_repository.dart
lib/features/garden_beds/add_bed_planting_screen.dart
lib/features/garden_beds/edit_bed_planting_screen.dart
```

Updated:

```text
lib/features/garden_beds/garden_beds_screen.dart
```

Implemented:

- Local model for crops planted in a bed
- Local planting storage with `shared_preferences`
- Add crop to a saved bed
- Crop selector using bundled crop data
- Planting status selector
- Planting date picker
- Planting notes
- Estimated harvest start and end dates stored per planting
- Harvest window automatically calculated from crop harvest range
- Estimated harvest window preview while adding a crop
- Bed cards now show planted crops and harvest estimates
- Open planted crop detail/editor from bed cards
- Edit planting status
- Edit planting date
- Edit planting notes
- Recalculate harvest estimate when planting date changes
- Delete planting from detail screen
- Remove planted crop from a bed
- Delete bed also removes plantings for that bed

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

### Local notifications foundation

Added:

```text
lib/services/notifications/local_notification_service.dart
```

Updated:

```text
lib/main.dart
lib/data/models/app_settings.dart
lib/data/app_settings_repository.dart
lib/features/settings/settings_screen.dart
```

Implemented:

- Local notification service wrapper
- App startup notification initialisation
- Notification permission request helper
- Weekly reminder preference stored locally
- Settings toggle for weekly garden reminder
- Preview notification when enabling reminders
- Local cancellation when disabling reminders

Note: this is the foundation for notification testing. A true scheduled weekly reminder may need platform-specific configuration once tested on Android/iOS.

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

- Home: garden dashboard, upcoming harvests, and what-to-plant-now list
- Crops: lists crop guide entries and opens detail pages
- Beds: working garden bed planner with crop planting, harvest estimates, and planting edits
- Tasks: generated weekly task recommendations
- Pests: offline pest/problem guide
- Settings: editable local setup screen with reminder toggle

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

### Testing and platform hardening

Goal:

- Run the app on PC with Flutter tooling
- Fix compile/analyzer errors found locally
- Verify notification behaviour on Android/iOS
- Add more useful tests once the app compiles cleanly on local tooling

## Next planned work

1. Test locally on PC
2. Fix any compile/analyzer issues
3. Harden local notifications after device testing
4. Add dashboard polish if needed after testing
5. Add app tests once the first workflow is stable

## GitHub issues created

- `#2` MVP: Define Flutter app structure
- `#3` MVP: Build local crop and region data layer
- `#4` MVP: Add editable setup flow
