"""Enable Android core library desugaring for generated Flutter projects.

The repository does not currently commit the generated Android platform folder.
After `flutter create --platforms=android .` runs locally or in CI, this script
patches the generated Android app Gradle file so plugins such as
flutter_local_notifications can compile.
"""

from __future__ import annotations

from pathlib import Path

DESUGAR_DEPENDENCY = "com.android.tools:desugar_jdk_libs:2.1.4"


def _find_matching_brace(text: str, open_brace_index: int) -> int:
    depth = 0
    for index in range(open_brace_index, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("Could not find matching closing brace.")


def _find_block(text: str, block_name: str) -> tuple[int, int, int]:
    marker = f"{block_name} {{"
    start = text.find(marker)
    if start == -1:
        raise ValueError(f"Could not find `{marker}` block.")
    open_brace = text.find("{", start)
    close_brace = _find_matching_brace(text, open_brace)
    return start, open_brace, close_brace


def _insert_before_block_close(text: str, block_name: str, line: str) -> str:
    _, _, close_brace = _find_block(text, block_name)
    indent = "    "
    return text[:close_brace] + f"{indent}{line}\n" + text[close_brace:]


def _ensure_dependencies_block(text: str, dependency_line: str) -> str:
    if dependency_line in text:
        return text

    if "dependencies {" in text:
        start, open_brace, _ = _find_block(text, "dependencies")
        insert_at = open_brace + 1
        return text[:insert_at] + f"\n    {dependency_line}" + text[insert_at:]

    return text.rstrip() + f"\n\ndependencies {{\n    {dependency_line}\n}}\n"


def _patch_groovy(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "coreLibraryDesugaringEnabled true" not in text:
        text = _insert_before_block_close(
            text,
            "compileOptions",
            "coreLibraryDesugaringEnabled true",
        )

    text = _ensure_dependencies_block(
        text,
        f"coreLibraryDesugaring '{DESUGAR_DEPENDENCY}'",
    )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def _patch_kotlin(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "isCoreLibraryDesugaringEnabled = true" not in text:
        text = _insert_before_block_close(
            text,
            "compileOptions",
            "isCoreLibraryDesugaringEnabled = true",
        )

    text = _ensure_dependencies_block(
        text,
        f"coreLibraryDesugaring(\"{DESUGAR_DEPENDENCY}\")",
    )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def _verify(path: Path, is_kotlin: bool) -> None:
    text = path.read_text(encoding="utf-8")
    enabled_marker = (
        "isCoreLibraryDesugaringEnabled = true"
        if is_kotlin
        else "coreLibraryDesugaringEnabled true"
    )
    dependency_marker = (
        f"coreLibraryDesugaring(\"{DESUGAR_DEPENDENCY}\")"
        if is_kotlin
        else f"coreLibraryDesugaring '{DESUGAR_DEPENDENCY}'"
    )

    missing = [
        marker
        for marker in (enabled_marker, dependency_marker)
        if marker not in text
    ]
    if missing:
        raise ValueError(
            "Android desugaring patch verification failed. Missing: "
            + ", ".join(missing)
        )


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    groovy_path = root / "android" / "app" / "build.gradle"
    kotlin_path = root / "android" / "app" / "build.gradle.kts"

    if kotlin_path.exists():
        changed = _patch_kotlin(kotlin_path)
        _verify(kotlin_path, is_kotlin=True)
        print(
            f"Android desugaring {'enabled' if changed else 'already enabled'} in "
            f"{kotlin_path.relative_to(root)}"
        )
        return 0

    if groovy_path.exists():
        changed = _patch_groovy(groovy_path)
        _verify(groovy_path, is_kotlin=False)
        print(
            f"Android desugaring {'enabled' if changed else 'already enabled'} in "
            f"{groovy_path.relative_to(root)}"
        )
        return 0

    print(
        "No Android Gradle app file found. Run "
        "`flutter create --platforms=android --project-name nz_vege_garden .` first."
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
