# MVP Scope

## Product

NZ Vege Garden is an offline-first Flutter app for New Zealand home vegetable gardeners.

The first version should help users make practical weekly gardening decisions without requiring a backend, account, paid API, or cloud database.

## Target user

A home grower in New Zealand using one or more of:

- Raised beds
- Backyard garden beds
- Pots and containers
- Small greenhouses
- Seed trays
- Frost cloth, cloches, or tunnel covers

## Core user questions

The MVP should answer:

1. What can I plant now?
2. What should I do this week?
3. What is growing in each bed?
4. When should I expect to harvest?
5. What common pest or crop problem am I seeing?

## MVP screens

1. Setup
2. Home / What to plant now
3. Crop guide
4. Crop detail
5. My garden beds
6. Bed detail
7. Weekly tasks
8. Pest and problem guide
9. Settings

## MVP features

### Setup

- Select NZ region
- Select garden type
- Select frost risk
- Select shelter/wind exposure
- Select whether the user has season-extension tools

### What to plant now

- Show crops suitable for the current month and region
- Separate direct sowing, transplanting, and sowing undercover
- Warn when crops are frost tender
- Show wait-until-later crops when relevant

### Crop guide

- Search and browse vegetables and herbs
- View crop profiles
- Show sowing, transplanting, spacing, watering, feeding, and harvest guidance

### Garden beds

- Create beds or containers
- Add crops to beds
- Store sowing/transplant dates
- Estimate harvest windows
- Add notes

### Weekly tasks

- Generate local tasks from month, region, and active crops
- Support local reminders

### Pest and problem guide

- Browse common home vegetable issues
- Filter by crop
- Show practical non-commercial actions

## Explicitly out of scope for MVP

- User accounts
- Cloud sync
- Paid APIs
- Server backend
- Server push notifications
- AI image diagnosis
- Commercial horticulture
- Ornamentals
- Lawns
- Complex marketplace/social features

## Zero-cost requirement

The app must remain usable with:

- No hosted backend
- No paid API calls
- No required internet connection
- No account system

Optional static update files may be hosted through GitHub Pages later.
