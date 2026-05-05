# NZ Vege Garden

A zero-cost, offline-first Flutter app for New Zealand home vegetable gardeners.

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

## Data validation

The project includes a Python data validator for the bundled offline JSON data.

Run from the repository root:

```bash
python tools/validate_data.py
```

This checks crop, region, planting-rule, pest/problem, and task-rule data before running the Flutter app.

## Project status

Current build phase:

```text
MVP app features are being built with offline bundled data, local device storage, and lightweight validation tooling.
```

Progress tracker:

- [Project progress log](docs/progress_log.md)
- [MVP scope](docs/mvp_scope.md)
- [Data model](docs/data_model.md)
- [NZ growing regions](docs/nz_regions.md)
- [Initial crop list](docs/crop_list.md)
- [Tools](tools/README.md)

## What has been added so far

```text
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
- Bottom navigation
- Local JSON crop, region, planting-rule, pest/problem, and task-rule data
- Python data validation tooling
- Home dashboard with upcoming harvests
- Searchable/filterable crop guide and crop detail screens
- Garden bed planner with local bed creation and storage
- Crop-to-bed planting with estimated harvest windows
- Weekly task recommendations generated from local rules
- Offline pest/problem guide
- Editable local settings
- Basic smoke test

## Purpose

This app helps home growers answer practical questions:

- What can I plant now in my region?
- What garden jobs should I do this week?
- What is growing in each bed?
- When should I harvest?
- How do I deal with common pests and crop problems?

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

Out of scope for the first version:

- Commercial horticulture
- Ornamental gardening
- Lawns
- Cloud accounts
- Paid APIs
- Server-side AI
- Paid hosting
- Required web deployment

## Technical direction

Planned stack:

- Flutter
- Dart
- Python for local data tooling
- Drift / SQLite later if needed
- Bundled JSON seed data
- Local notifications
- Local device storage

## MVP

The first version should include:

1. Region setup
2. What to plant now
3. Crop guide
4. Garden beds
5. Weekly tasks
6. Pest/problem guide
7. Settings
