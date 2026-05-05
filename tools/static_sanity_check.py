#!/usr/bin/env python3
"""Static sanity checks for the NZ Vege Garden Flutter project.

This is not a Dart compiler. It is a lightweight repository scanner that catches
common project issues before running Flutter locally.

Run from the repository root:

    python tools/static_sanity_check.py
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB_DIR = ROOT / "lib"
TEST_DIR = ROOT / "test"
PUBSPEC = ROOT / "pubspec.yaml"

IMPORT_RE = re.compile(r"^import\s+['\"]([^'\"]+)['\"];", re.MULTILINE)
ROOT_BUNDLE_RE = re.compile(r"rootBundle\.loadString\(['\"]([^'\"]+)['\"]\)")


@dataclass(frozen=True)
class Issue:
    file: str
    message: str

    def format(self) -> str:
        return f"{self.file}: {self.message}"


class StaticSanityChecker:
    def __init__(self) -> None:
        self.issues: list[Issue] = []

    def add_issue(self, path: Path | str, message: str) -> None:
        if isinstance(path, Path):
            file_name = str(path.relative_to(ROOT))
        else:
            file_name = path
        self.issues.append(Issue(file=file_name, message=message))

    def dart_files(self) -> list[Path]:
        files = list(LIB_DIR.rglob("*.dart"))
        if TEST_DIR.exists():
            files.extend(TEST_DIR.rglob("*.dart"))
        return sorted(files)

    def check_relative_imports(self) -> None:
        for path in self.dart_files():
            text = path.read_text(encoding="utf-8")
            for match in IMPORT_RE.finditer(text):
                import_path = match.group(1)
                if import_path.startswith(("dart:", "package:")):
                    continue
                target = (path.parent / import_path).resolve()
                if not target.exists():
                    self.add_issue(path, f"missing relative import target: {import_path}")

    def check_asset_references_registered(self) -> None:
        if not PUBSPEC.exists():
            self.add_issue("pubspec.yaml", "missing pubspec.yaml")
            return

        pubspec_text = PUBSPEC.read_text(encoding="utf-8")
        referenced_assets: set[str] = set()

        for path in self.dart_files():
            text = path.read_text(encoding="utf-8")
            for asset in ROOT_BUNDLE_RE.findall(text):
                referenced_assets.add(asset)
                asset_path = ROOT / asset
                if not asset_path.exists():
                    self.add_issue(path, f"referenced asset does not exist: {asset}")
                if asset not in pubspec_text:
                    self.add_issue(path, f"referenced asset is not registered in pubspec.yaml: {asset}")

    def check_pubspec_asset_files_exist(self) -> None:
        if not PUBSPEC.exists():
            return

        pubspec_text = PUBSPEC.read_text(encoding="utf-8")
        for raw_line in pubspec_text.splitlines():
            stripped = raw_line.strip()
            if not stripped.startswith("- assets/"):
                continue
            asset = stripped.removeprefix("- ").strip()
            if not (ROOT / asset).exists():
                self.add_issue(PUBSPEC, f"registered asset does not exist: {asset}")

    def check_no_known_generated_web_paths_in_source(self) -> None:
        web_index = ROOT / "web" / "index.html"
        if not web_index.exists():
            return

        text = web_index.read_text(encoding="utf-8")
        if "flutter_bootstrap.js" not in text:
            self.add_issue(web_index, "Flutter web index does not reference flutter_bootstrap.js")
        if "$FLUTTER_BASE_HREF" not in text:
            self.add_issue(web_index, "Flutter web index does not include $FLUTTER_BASE_HREF placeholder")

    def check_obvious_todos_for_runtime_blockers(self) -> None:
        blocker_terms = [
            "throw UnimplementedError",
            "TODO: crash",
            "TODO crash",
        ]

        for path in self.dart_files():
            text = path.read_text(encoding="utf-8")
            for term in blocker_terms:
                if term in text:
                    self.add_issue(path, f"possible runtime blocker found: {term}")

    def run(self) -> int:
        self.check_relative_imports()
        self.check_asset_references_registered()
        self.check_pubspec_asset_files_exist()
        self.check_no_known_generated_web_paths_in_source()
        self.check_obvious_todos_for_runtime_blockers()

        if self.issues:
            print("Static sanity check failed:\n")
            for issue in self.issues:
                print(f"- {issue.format()}")
            return 1

        print("Static sanity check passed.")
        print(f"Checked Dart files: {len(self.dart_files())}")
        return 0


def main() -> int:
    return StaticSanityChecker().run()


if __name__ == "__main__":
    sys.exit(main())
