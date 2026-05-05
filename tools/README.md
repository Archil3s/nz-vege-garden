# Tools

This folder contains development tools for maintaining the offline app data.

## Validate bundled data

Run from the repository root:

```bash
python tools/validate_data.py
```

The validator checks:

- `assets/data/crops.json`
- `assets/data/nz_regions.json`
- `assets/data/planting_rules.json`
- `assets/data/pests.json`
- `assets/data/task_rules.json`

It verifies:

- required fields exist
- IDs are unique
- month values are between 1 and 12
- harvest ranges are valid
- booleans are booleans
- crop references point to real crop IDs
- region references point to real region IDs or `all`

The script uses only Python's standard library. No packages need to be installed.
