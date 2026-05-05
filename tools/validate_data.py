#!/usr/bin/env python3
"""Validate bundled offline data for NZ Vege Garden.

This script uses only Python's standard library so it can run on any PC with
Python installed. It checks the JSON files used by the Flutter app and reports
clear errors before app runtime.

Run from the repository root:

    python tools/validate_data.py
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "assets" / "data"


@dataclass(frozen=True)
class ValidationError:
    file: str
    message: str

    def format(self) -> str:
        return f"{self.file}: {self.message}"


class Validator:
    def __init__(self) -> None:
        self.errors: list[ValidationError] = []

    def add_error(self, file: str, message: str) -> None:
        self.errors.append(ValidationError(file=file, message=message))

    def load_json_list(self, relative_path: str) -> list[dict[str, Any]]:
        path = ROOT / relative_path
        try:
            with path.open("r", encoding="utf-8") as handle:
                data = json.load(handle)
        except FileNotFoundError:
            self.add_error(relative_path, "file is missing")
            return []
        except json.JSONDecodeError as error:
            self.add_error(relative_path, f"invalid JSON: {error}")
            return []

        if not isinstance(data, list):
            self.add_error(relative_path, "top-level JSON value must be a list")
            return []

        rows: list[dict[str, Any]] = []
        for index, item in enumerate(data):
            if not isinstance(item, dict):
                self.add_error(relative_path, f"item {index} must be an object")
                continue
            rows.append(item)

        return rows

    def require_string(self, file: str, row: dict[str, Any], field: str) -> None:
        value = row.get(field)
        if not isinstance(value, str) or not value.strip():
            self.add_error(file, f"{row_label(row)} field '{field}' must be a non-empty string")

    def require_bool(self, file: str, row: dict[str, Any], field: str) -> None:
        if not isinstance(row.get(field), bool):
            self.add_error(file, f"{row_label(row)} field '{field}' must be a boolean")

    def require_int(
        self,
        file: str,
        row: dict[str, Any],
        field: str,
        *,
        minimum: int | None = None,
        maximum: int | None = None,
    ) -> None:
        value = row.get(field)
        if not isinstance(value, int):
            self.add_error(file, f"{row_label(row)} field '{field}' must be an integer")
            return
        if minimum is not None and value < minimum:
            self.add_error(file, f"{row_label(row)} field '{field}' must be >= {minimum}")
        if maximum is not None and value > maximum:
            self.add_error(file, f"{row_label(row)} field '{field}' must be <= {maximum}")

    def require_string_list(self, file: str, row: dict[str, Any], field: str) -> None:
        value = row.get(field)
        if not isinstance(value, list):
            self.add_error(file, f"{row_label(row)} field '{field}' must be a list")
            return
        for index, item in enumerate(value):
            if not isinstance(item, str) or not item.strip():
                self.add_error(
                    file,
                    f"{row_label(row)} field '{field}' item {index} must be a non-empty string",
                )

    def require_unique_ids(self, file: str, rows: list[dict[str, Any]]) -> set[str]:
        seen: set[str] = set()
        ids: set[str] = set()
        for index, row in enumerate(rows):
            value = row.get("id")
            if not isinstance(value, str) or not value.strip():
                self.add_error(file, f"item {index} field 'id' must be a non-empty string")
                continue
            if value in seen:
                self.add_error(file, f"duplicate id '{value}'")
            seen.add(value)
            ids.add(value)
        return ids


def row_label(row: dict[str, Any]) -> str:
    identifier = row.get("id") or row.get("name") or row.get("title") or "unknown item"
    return f"[{identifier}]"


def validate_crops(validator: Validator) -> set[str]:
    file = "assets/data/crops.json"
    rows = validator.load_json_list(file)
    crop_ids = validator.require_unique_ids(file, rows)

    for row in rows:
        for field in [
            "commonName",
            "category",
            "summary",
            "sunRequirement",
            "waterRequirement",
        ]:
            validator.require_string(file, row, field)
        for field in ["spacingCm", "daysToHarvestMin", "daysToHarvestMax"]:
            validator.require_int(file, row, field, minimum=1)
        for field in ["frostTender", "containerFriendly", "beginnerFriendly"]:
            validator.require_bool(file, row, field)

        min_days = row.get("daysToHarvestMin")
        max_days = row.get("daysToHarvestMax")
        if isinstance(min_days, int) and isinstance(max_days, int) and min_days > max_days:
            validator.add_error(file, f"{row_label(row)} daysToHarvestMin must be <= daysToHarvestMax")

    return crop_ids


def validate_regions(validator: Validator) -> set[str]:
    file = "assets/data/nz_regions.json"
    rows = validator.load_json_list(file)
    region_ids = validator.require_unique_ids(file, rows)

    for row in rows:
        for field in [
            "name",
            "island",
            "climateSummary",
            "defaultFrostRisk",
            "defaultWindRisk",
        ]:
            validator.require_string(file, row, field)

    return region_ids


def validate_planting_rules(
    validator: Validator,
    *,
    crop_ids: set[str],
    region_ids: set[str],
) -> None:
    file = "assets/data/planting_rules.json"
    rows = validator.load_json_list(file)

    for row in rows:
        for field in ["cropId", "regionId", "method", "riskNote"]:
            validator.require_string(file, row, field)
        for field in ["startMonth", "endMonth"]:
            validator.require_int(file, row, field, minimum=1, maximum=12)

        crop_id = row.get("cropId")
        region_id = row.get("regionId")
        if isinstance(crop_id, str) and crop_id not in crop_ids:
            validator.add_error(file, f"{row_label(row)} cropId '{crop_id}' is not in crops.json")
        if isinstance(region_id, str) and region_id != "all" and region_id not in region_ids:
            validator.add_error(file, f"{row_label(row)} regionId '{region_id}' is not in nz_regions.json")


def validate_pests(validator: Validator, *, crop_ids: set[str]) -> None:
    file = "assets/data/pests.json"
    rows = validator.load_json_list(file)
    validator.require_unique_ids(file, rows)

    for row in rows:
        for field in ["name", "category", "summary", "seasonNotes"]:
            validator.require_string(file, row, field)
        for field in ["signs", "commonCrops", "actions", "prevention"]:
            validator.require_string_list(file, row, field)

        for crop_id in row.get("commonCrops", []):
            if isinstance(crop_id, str) and crop_id not in crop_ids:
                validator.add_error(file, f"{row_label(row)} commonCrops item '{crop_id}' is not in crops.json")


def validate_task_rules(
    validator: Validator,
    *,
    crop_ids: set[str],
    region_ids: set[str],
) -> None:
    file = "assets/data/task_rules.json"
    rows = validator.load_json_list(file)
    validator.require_unique_ids(file, rows)

    for row in rows:
        for field in ["title", "description", "taskType", "regionId"]:
            validator.require_string(file, row, field)
        for field in ["cropIds", "gardenTypes", "frostRisks", "windExposures"]:
            validator.require_string_list(file, row, field)
        for field in ["startMonth", "endMonth"]:
            validator.require_int(file, row, field, minimum=1, maximum=12)
        validator.require_int(file, row, "priority", minimum=1)

        region_id = row.get("regionId")
        if isinstance(region_id, str) and region_id != "all" and region_id not in region_ids:
            validator.add_error(file, f"{row_label(row)} regionId '{region_id}' is not in nz_regions.json")

        for crop_id in row.get("cropIds", []):
            if isinstance(crop_id, str) and crop_id not in crop_ids:
                validator.add_error(file, f"{row_label(row)} cropIds item '{crop_id}' is not in crops.json")


def main() -> int:
    validator = Validator()

    crop_ids = validate_crops(validator)
    region_ids = validate_regions(validator)
    validate_planting_rules(validator, crop_ids=crop_ids, region_ids=region_ids)
    validate_pests(validator, crop_ids=crop_ids)
    validate_task_rules(validator, crop_ids=crop_ids, region_ids=region_ids)

    if validator.errors:
        print("Data validation failed:\n")
        for error in validator.errors:
            print(f"- {error.format()}")
        return 1

    print("Data validation passed.")
    print(f"Validated data directory: {DATA_DIR.relative_to(ROOT)}")
    print(f"Crops: {len(crop_ids)}")
    print(f"Regions: {len(region_ids)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
