"""Enable Android core library desugaring for generated Flutter projects.

The repository does not commit the generated Android platform folder yet. When
`flutter create --platforms=android .` is run locally or in CI, this script
patches the generated Android Gradle file so plugins such as
flutter_local_notifications can compile.
"""

from __future__ import annotations

from pathlib import Path

DESUGAR_DEPENDENCY = "com.android.tools:desugar_jdk_libs:2.1.4"


def _replace_once(text: str, old: str, new: str) -> str:
    if old not in text:
        raise ValueError(f"Could not find expected Gradle block:\n{old}")
    return text.replace(old, new, 1)


def _patch_groovy(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "coreLibraryDesugaringEnabled true" not in text:
        text = _replace_once(
            text,
            "        sourceCompatibility JavaVersion.VERSION_1_8\n"
            "        targetCompatibility JavaVersion.VERSION_1_8\n"
            "    }",
            "        sourceCompatibility JavaVersion.VERSION_1_8\n"
            "        targetCompatibility JavaVersion.VERSION_1_8\n"
            "        coreLibraryDesugaringEnabled true\n"
            "    }",
        )

    if "coreLibraryDesugaring" not in text:
        if "dependencies {" in text:
            text = _replace_once(
                text,
                "dependencies {",
                f"dependencies {{\n    coreLibraryDesugaring '{DESUGAR_DEPENDENCY}'",
            )
        else:
            text = text.rstrip() + (
                "\n\ndependencies {\n"
                f"    coreLibraryDesugaring '{DESUGAR_DEPENDENCY}'\n"
                "}\n"
            )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def _patch_kotlin(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "isCoreLibraryDesugaringEnabled = true" not in text:
        text = _replace_once(
            text,
            "        sourceCompatibility = JavaVersion.VERSION_1_8\n"
            "        targetCompatibility = JavaVersion.VERSION_1_8\n"
            "    }",
            "        sourceCompatibility = JavaVersion.VERSION_1_8\n"
            "        targetCompatibility = JavaVersion.VERSION_1_8\n"
            "        isCoreLibraryDesugaringEnabled = true\n"
            "    }",
        )

    if "coreLibraryDesugaring(" not in text:
        if "dependencies {" in text:
            text = _replace_once(
                text,
                "dependencies {",
                f"dependencies {{\n    coreLibraryDesugaring(\"{DESUGAR_DEPENDENCY}\")",
            )
        else:
            text = text.rstrip() + (
                "\n\ndependencies {\n"
                f"    coreLibraryDesugaring(\"{DESUGAR_DEPENDENCY}\")\n"
                "}\n"
            )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    groovy_path = root / "android" / "app" / "build.gradle"
    kotlin_path = root / "android" / "app" / "build.gradle.kts"

    if groovy_path.exists():
        changed = _patch_groovy(groovy_path)
        print(
            f"Android desugaring {'enabled' if changed else 'already enabled'} in "
            f"{groovy_path.relative_to(root)}"
        )
        return 0

    if kotlin_path.exists():
        changed = _patch_kotlin(kotlin_path)
        print(
            f"Android desugaring {'enabled' if changed else 'already enabled'} in "
            f"{kotlin_path.relative_to(root)}"
        )
        return 0

    print(
        "No Android Gradle app file found. Run "
        "`flutter create --platforms=android --project-name nz_vege_garden .` first."
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
