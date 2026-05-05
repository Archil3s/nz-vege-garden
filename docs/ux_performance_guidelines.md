# UX and Performance Guidelines

The app should feel practical, visual, and responsive on normal phones. Visual features should help users understand their garden quickly, but they should not cause slow tab changes, janky scrolling, delayed taps, or crashes.

## Product goal

Build a visual garden-planning app that remains:

- offline-first
- low memory
- fast to open
- fast to move between tabs
- stable on older Android devices
- useful without images, maps, servers, paid APIs, or live network calls

## Visual design principles

### Prefer lightweight visual language

Use:

- Material icons
- chips
- cards
- progress bars
- simple month grids
- simple status indicators
- small illustrations made from icons and layout

Avoid by default:

- large image-heavy screens
- auto-playing animations
- complex custom painters
- deeply nested animated widgets
- unnecessary shadows and clipping in long lists
- loading remote images

### Make visual meaning consistent

Use the same visual language across the app:

- sow/direct sow: seedling/grass icon
- transplant: move/transplant icon
- growing: eco icon
- harvest: basket icon
- warning/problem: warning icon
- pest: bug icon
- disease: disease icon
- done: check icon
- failed: cancel icon

When colours are used, they should support meaning rather than decoration.

### Make beginners comfortable

Screens should answer:

- What can I do now?
- Why is this recommended?
- What should I watch for?
- What happens next?

Avoid dumping dense technical data without a short explanation.

### Keep experienced users efficient

Experienced users should be able to:

- scan many crops quickly
- filter lists
- jump between crop, pest, calendar, and bed information
- mark statuses quickly
- avoid unnecessary setup screens after first use

## Performance principles

### Do not do heavy work in build methods

Avoid:

- decoding JSON repeatedly inside item builders
- sorting large lists inside row builders
- recalculating expensive data every frame
- creating new futures repeatedly in widgets that rebuild often

Prefer:

- load once in `initState` for stateful screens
- prepare lookup maps before rendering lists
- derive screen data once before building repeated cards

### Keep list rendering efficient

Use `ListView.builder` or `ListView.separated` for long lists.

Use direct child lists only when the data set is small and bounded.

Current small bounded lists are acceptable for MVP, but if crop/pest data grows substantially, convert long guide screens to builders.

### Keep tab switching light

Tabs should not trigger unnecessary expensive reloads. As the app grows, consider:

- caching loaded static JSON data in repository memory
- keeping tab state alive where useful
- avoiding expensive screen startup work
- splitting very large screens into smaller sections

### Prefer local JSON now, SQLite later only if needed

Bundled JSON is fine while data is modest.

Move to SQLite/Drift only when the app needs:

- many user-created records
- complex filtering
- search over large data sets
- reliable relational links
- migration support

Do not add database complexity before it is needed.

### Avoid animation unless it improves clarity

Use subtle animation only for:

- progress changes
- expanding/collapsing information
- simple screen transitions handled by Flutter

Avoid decorative animation until the app has been profiled on a device.

## Screen-specific guidance

### Home dashboard

Should stay highly scannable.

Use:

- summary cards
- short recommendation cards
- harvest-ready section
- later harvest section

Avoid:

- too many cards before the user sees useful action
- large charts on the first version
- auto-refresh loops

### Crop calendar

The calendar should be visual but simple.

Good MVP design:

- month chips
- activity filters
- colour-coded activity chips
- grouped list entries
- clear icons for sow, transplant, harvest

Later enhancement:

- compact 12-month crop row view
- colour-coded month bars
- family filters
- region selector shortcut

Avoid:

- rendering a large custom grid with complex painting before device testing
- overloading each month cell with too much text

### Crop guide

Should remain searchable and fast.

Prefer:

- search field
- filter chips
- readable cards
- detail screen links

If crop data grows large:

- switch to `ListView.builder`
- precompute searchable strings
- avoid filtering on every keystroke without debouncing if performance drops

### Pest/problem guide

Should support quick diagnosis.

Prefer:

- search by symptoms
- category filters
- affected crop filters
- expandable cards
- crop detail links

Avoid:

- showing every sign/action expanded by default

### Garden beds

Should focus on action speed.

Prefer:

- quick status actions
- clear planted crop summaries
- detail editor only when needed
- confirmation before destructive actions

Avoid:

- large visual bed-layout rendering until data model is ready
- drag-and-drop before basic workflows are stable

### Weekly tasks

Should feel like a checklist.

Prefer:

- progress summary
- checkboxes
- reset current week
- short task descriptions

Avoid:

- generating too many tasks at once
- hiding high-priority tasks below long informational text

## Implementation guardrails

### Use const where practical

Use `const` constructors where possible to reduce rebuild work.

### Keep widgets small

Split complex screens into private widgets such as:

```dart
_SummaryCard
_HarvestReadyCard
_CalendarEntryCard
```

This improves readability and reduces accidental rebuild complexity.

### Keep data transformation outside repeated widgets

Do sorting, filtering, and lookup construction once per load, not inside each row.

### Add fallback states

Every data-driven screen should handle:

- loading
- error
- empty state
- normal data state

### Use local-first interaction design

Do not design screens that depend on:

- internet access
- paid APIs
- accounts
- background servers
- external image services

## Testing guidance

When testing on PC or phone, check:

- app launch time
- tab switch delay
- scrolling smoothness in Crop Guide, Calendar, Pests, and Beds
- whether tapping cards feels immediate
- whether expanding pest/problem cards is smooth
- whether adding/editing beds and plantings feels responsive
- whether the Home dashboard loads without visible lag

If a screen feels slow, inspect:

1. repeated JSON loading
2. repeated sorting/filtering in build
3. too many expanded widgets
4. unnecessary nested scroll views
5. unnecessary animations
6. excessive card shadows/clipping

## Near-term performance-safe visual roadmap

Recommended next visual upgrades:

1. Improve Crop Calendar with grouped activity sections.
2. Add compact 12-month crop timeline rows.
3. Add succession planting reminders as lightweight task cards.
4. Add crop rotation warnings using simple family chips.
5. Add harvest log summaries using simple counts and lists.

Avoid until after device testing:

- drag-and-drop bed layouts
- image/photo-heavy journal
- animated garden maps
- custom charting libraries
- large offline databases without pagination/search planning
