# NZ Vege Garden

A zero-cost, offline-first Flutter app for New Zealand home vegetable gardeners.

## Web preview

A GitHub Pages preview is deployed from the `main` branch when the deployment workflow succeeds:

```text
https://archil3s.github.io/nz-vege-garden/
```

The preview is for visual testing only. The app remains offline-first and does not require a backend, paid API, cloud account system, or paid hosting.

## Local run instructions

When testing on a PC with Flutter installed:

```bash
git clone https://github.com/Archil3s/nz-vege-garden.git
cd nz-vege-garden
flutter pub get
flutter run
```

For a browser test on PC:

```bash
flutter run -d chrome
```

For an Android emulator or connected Android device:

```bash
flutter run
```

## Preflight checks

Before running the app locally:

```bash
python tools/validate_data.py
python tools/static_sanity_check.py
flutter pub get
flutter analyze
flutter test
```

A fuller local testing checklist is available here:

- [Local testing checklist](docs/local_testing_checklist.md)

## Data validation

The project includes a Python data validator for the bundled offline JSON data.

Run from the repository root:

```bash
python tools/validate_data.py
```

This checks crop, region, planting-rule, pest/problem, task-rule, and succession-rule data before running the Flutter app.

## Project status

Current build phase:

```text
MVP app features are being built with offline bundled data, local device storage, GitHub Pages visual preview, and lightweight validation tooling.
```

Current MVP coverage:

- First-run setup collects region, frost risk, wind exposure, and garden type.
- Setup and settings are stored locally with `shared_preferences`.
- The default app shell is planner-first for iPhone use.
- Local JSON assets power crops, NZ regions, planting rules, pests, tasks, and succession rules.
- Planting recommendations can be filtered by region, month, and planting method.
- GitHub Pages preview is designed for iPhone visual checks and fallback diagnostics.

Progress tracker:

- [Project progress log](docs/progress_log.md)
- [Local testing checklist](docs/local_testing_checklist.md)
- [UX and performance guidelines](docs/ux_performance_guidelines.md)
- [MVP scope](docs/mvp_scope.md)
- [Data model](docs/data_model.md)
- [NZ growing regions](docs/nz_regions.md)
- [Initial crop list](docs/crop_list.md)
- [Tools](tools/README.md)

## What has been added so far

```text
.github/workflows/
docs/
assets/data/
lib/main.dart
lib/app/
lib/data/
lib/features/
tools/
web/
test/
pubspec.yaml
analysis_options.yaml
```

The app currently has:

- Flutter project scaffold
- Material 3 app shell
- Planner-first bottom navigation for iPhone
- First-run setup flow
- GitHub Pages Flutter web preview workflow
- Local JSON crop, region, planting-rule, pest/problem, task-rule, and succession-rule data
- Python data validation tooling
- Static sanity checker and local preflight runner
- Home dashboard with setup-aware recommendations and harvest sections
- Searchable/filterable crop guide and crop detail screens
- Crop calendar with sow, transplant, and harvest views
- Garden bed planner with local bed creation, editing, and storage
- Crop-to-bed planting with estimated harvest windows and quick status actions
- Weekly task checklist with completion tracking and succession reminders
- Searchable/filterable offline pest/problem guide
- Editable local settings
- Basic smoke test

## Purpose

This app helps home growers answer practical questions:

- What can I plant now in my region?
- What garden jobs should I do this week?
- What is growing in each bed?
- When should I harvest?
- How do I deal with common pests and crop problems?
- When should I sow, transplant, resow, and harvest?

## Product focus

This project is focused on backyard and small-space vegetable gardening in New Zealand.

Initial scope:

- Vegetables
- Herbs
- Raised beds
- Containers
- Small greenhouses
- Regional planting windows
- Frost-aware advice
- Local notifications
- Offline crop guide
- Crop calendar
- Succession planting reminders

Out of scope for the first version:

- Commercial horticulture
- Ornamental gardening
- Lawns
- Cloud accounts
- Paid APIs
- Server-side AI
- Paid hosting
- Required account-based web deployment

## Technical direction

Planned stack:

- Flutter
- Dart
- Python for local data tooling
- Drift / SQLite later if needed
- Bundled JSON seed data
- Local notifications
- Local device storage
- GitHub Pages preview for visual testing

## MVP

The first version should include:

1. Region setup
2. What to plant now
3. Crop guide
4. Crop calendar
5. Garden beds
6. Weekly tasks and succession reminders
7. Pest/problem guide
8. Settings
