#!/usr/bin/env python3
"""Instantiates the Android/iOS platform folders from the official
Flutter `flutter create` templates (checked out sparse at /tmp/fl).

Placeholders are substituted with this project's identifiers. Run once;
the generated folders are committed to the repo.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path

TEMPLATES = Path("/tmp/fl/packages/flutter_tools/templates/app")
ROOT = Path(__file__).resolve().parent.parent

# These must match the Flutter SDK template the folders are generated from
# (packages/flutter_tools/lib/src/android/gradle_utils.dart). The values below are the
# Flutter 3.47 template defaults: AGP 9.1.0 + Gradle 9.3.1 + KGP 2.4.0. Flutter's
# Gradle plugin rejects anything below Gradle 8.14.0 / AGP 8.11.1 / KGP 2.2.20.
VALUES = {
    "projectName": "isosha_esosheni",
    "titleCaseProjectName": "Isosha Esosheni",
    "androidIdentifier": "com.trsh.isoshaesosheni",
    "iosIdentifier": "com.trsh.isoshaesosheni",
    "iosDevelopmentTeam": "",
    "agpVersion": "9.1.0",
    "androidSdkVersion": "36",
    "gradleVersion": "9.3.1",
    "kotlinVersion": "2.4.0",
}


def fill(text: str) -> str:
    for key, value in VALUES.items():
        text = text.replace("{{%s}}" % key, value)
    return text


def copy_tree(src: Path, dst: Path, remap: dict[str, str] | None = None) -> None:
    for path in sorted(src.rglob("*")):
        rel = path.relative_to(src).as_posix()
        if remap:
            for old, new in remap.items():
                rel = rel.replace(old, new)
        rel = rel.replace("androidIdentifier", "com/trsh/isoshaesosheni")
        if rel.endswith(".tmpl"):
            rel = rel[: -len(".tmpl")]
        target = dst / rel
        if path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.suffix in {".png", ".jar"}:
                shutil.copyfile(path, target)
            else:
                target.write_text(fill(path.read_text()))


def main() -> None:
    android = ROOT / "android"
    ios = ROOT / "ios"
    android.mkdir(exist_ok=True)
    ios.mkdir(exist_ok=True)

    copy_tree(TEMPLATES / "android.tmpl", android)
    copy_tree(TEMPLATES / "android-kotlin.tmpl", android)
    copy_tree(TEMPLATES / "ios.tmpl", ios)
    print("Platform folders written.")


if __name__ == "__main__":
    main()
