# NZ Vege Garden

A zero-cost, offline-first Flutter app for New Zealand home vegetable gardeners.

## Project status

Current build phase:

```text
MVP scaffold and local data layer are in progress.
```

Progress tracker:

- [Project progress log](docs/progress_log.md)
- [MVP scope](docs/mvp_scope.md)
- [Data model](docs/data_model.md)
- [NZ growing regions](docs/nz_regions.md)
- [Initial crop list](docs/crop_list.md)

## What has been added so far

```text
docs/
assets/data/
lib/main.dart
lib/app/
lib/data/
lib/features/
pubspec.yaml
analysis_options.yaml
```

The app currently has:

- Flutter project scaffold
- Material 3 app shell
- Bottom navigation
- Local JSON crop, region, and planting-rule data
- Home screen showing what to plant now
- Crop guide screen
- Placeholder screens for beds, tasks, pests, and settings
- Initial settings model

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

## Technical direction

Planned stack:

- Flutter
- Dart
- Drift / SQLite
- Bundled JSON seed data
- Local notifications
- Optional static updates through GitHub Pages

## MVP

The first version should include:

1. Region setup
2. What to plant now
3. Crop guide
4. Garden beds
5. Weekly tasks
6. Pest/problem guide
7. Settings
