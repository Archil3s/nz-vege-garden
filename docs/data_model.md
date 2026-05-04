# Data Model

This app should use local-first data. The initial app can load bundled JSON into a local SQLite database, then query SQLite for app screens.

## Core entities

## crops

Represents a vegetable, herb, or small edible crop.

Suggested fields:

```text
id
common_name
botanical_name
category
summary
sun_requirement
water_requirement
soil_preference
spacing_cm
row_spacing_cm
days_to_harvest_min
days_to_harvest_max
frost_tender
perennial
container_friendly
beginner_friendly
notes
```

## regions

Represents broad New Zealand growing regions.

Suggested fields:

```text
id
name
island
climate_summary
frost_risk_default
wind_risk_default
notes
```

## planting_rules

Region-specific planting windows by crop and method.

Suggested fields:

```text
id
crop_id
region_id
method
start_month
end_month
risk_note
```

Methods:

```text
direct_sow
sow_undercover
transplant
harvest
```

## garden_beds

User-created local garden areas.

Suggested fields:

```text
id
name
type
length_cm
width_cm
sun_exposure
wind_exposure
notes
created_at
updated_at
```

## garden_bed_crops

Crops currently or previously grown in a bed.

Suggested fields:

```text
id
bed_id
crop_id
status
sown_date
transplanted_date
expected_harvest_start
expected_harvest_end
actual_harvest_date
notes
created_at
updated_at
```

Statuses:

```text
planned
sown
transplanted
growing
harvesting
finished
failed
```

## tasks

User tasks and generated seasonal tasks.

Suggested fields:

```text
id
title
description
due_date
completed
crop_id
bed_id
task_type
created_at
updated_at
```

Task types:

```text
sow
transplant
water
feed
weed
check_pests
harvest
clear_bed
prepare_bed
custom
```

## pests

Common vegetable garden pests.

Suggested fields:

```text
id
name
summary
signs
common_crops
actions
prevention
season_notes
```

## crop_problems

Common non-pest crop issues.

Suggested fields:

```text
id
name
summary
symptoms
likely_causes
actions
prevention
```

## Storage approach

Recommended app flow:

1. Bundle JSON data in `assets/data`.
2. On first app launch, load seed data into SQLite.
3. Store user garden data only on device.
4. Allow export/import later as JSON.

## Offline rule

All core app logic must work without internet access.
