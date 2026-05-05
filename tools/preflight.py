#!/usr/bin/env python3
"""Run local preflight checks for NZ Vege Garden.

This script is intended for local PC testing. It runs checks in a practical
order and stops at the first failure.

Run from the repository root:

    python tools/preflight.py

Optional modes:

    python tools/preflight.py --no-flutter
    python tools/preflight.py --skip-build
    python tools/preflight.py --web-build
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class CommandFailed(RuntimeError):
    def __init__(self, command: list[str], return_code: int) -> None:
        self.command = command
        self.return_code = return_code
        super().__init__(f"Command failed with exit code {return_code}: {' '.join(command)}")


def run(command: list[str], *, required: bool = True) -> bool:
    print("\n> " + " ".join(command), flush=True)
    result = subprocess.run(command, cwd=ROOT, check=False)

    if result.returncode == 0:
        return True

    if required:
        raise CommandFailed(command, result.returncode)

    return False


def require_executable(name: str) -> bool:
    if shutil.which(name) is not None:
        return True

    print(f"\nMissing executable: {name}")
    print(f"Install {name} or run with a mode that skips it.")
    return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run local project preflight checks.")
    parser.add_argument(
        "--no-flutter",
        action="store_true",
        help="Only run Python/data checks and skip all Flutter commands.",
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Run Flutter dependency, analyzer, and test checks but skip build checks.",
    )
    parser.add_argument(
        "--web-build",
        action="store_true",
        help="Also run a local Flutter web release build after analysis and tests.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    print("NZ Vege Garden local preflight")
    print(f"Repository: {ROOT}")

    try:
        run([sys.executable, "tools/validate_data.py"])

        if args.no_flutter:
            print("\nPreflight passed for Python/data checks. Flutter checks skipped.")
            return 0

        if not require_executable("flutter"):
            return 1

        run(["flutter", "--version"])
        run(["flutter", "pub", "get"])
        run(["dart", "format", "--output=none", "--set-exit-if-changed", "lib", "test"])
        run(["flutter", "analyze"])
        run(["flutter", "test"])

        if args.web_build and not args.skip_build:
            run(["flutter", "build", "web", "--release"])

    except CommandFailed as error:
        print("\nPreflight failed.")
        print(error)
        print("\nFix the first error shown above, then run this script again.")
        return error.return_code

    print("\nPreflight passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
