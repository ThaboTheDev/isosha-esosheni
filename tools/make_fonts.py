#!/usr/bin/env python3
"""One-time asset preparation: static font instances.

- Pulls the variable fonts for Figtree and Cormorant Garamond from
  google/fonts (requires network + git) if they are not already vendored
  under /tmp/gfonts.
- Uses fontTools.varLib.mutator to pin the `wght` axis, strips the
  variation tables, and emits the static instances referenced by
  pubspec.yaml (checked into the repo).

Run:  python3 tools/make_fonts.py
Deps: pip install fonttools
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"
VENDOR = Path("/tmp/gfonts")

# (source variable font, [(instance weight, output name), ...])
PLAN = [
    (
        VENDOR / "ofl/figtree/Figtree[wght].ttf",
        [
            (400, "Figtree-Regular.ttf"),
            (500, "Figtree-Medium.ttf"),
            (600, "Figtree-SemiBold.ttf"),
            (700, "Figtree-Bold.ttf"),
        ],
    ),
    (
        VENDOR / "ofl/cormorantgaramond/CormorantGaramond[wght].ttf",
        [
            (600, "CormorantGaramond-SemiBold.ttf"),
            (700, "CormorantGaramond-Bold.ttf"),
        ],
    ),
]


def ensure_vendor() -> None:
    if VENDOR.exists() and (VENDOR / "ofl/figtree").exists():
        return
    print("Cloning google/fonts (sparse)...")
    subprocess.run(
        [
            "git",
            "clone",
            "--depth",
            "1",
            "--filter=blob:none",
            "--sparse",
            "https://github.com/google/fonts.git",
            str(VENDOR),
        ],
        check=True,
    )
    subprocess.run(
        [
            "git",
            "-C",
            str(VENDOR),
            "sparse-checkout",
            "set",
            "ofl/figtree",
            "ofl/cormorantgaramond",
        ],
        check=True,
    )


def main() -> int:
    try:
        from fontTools.varLib import instancer  # type: ignore
    except ImportError:
        print("fonttools is required: pip install fonttools", file=sys.stderr)
        return 1

    ensure_vendor()
    FONTS.mkdir(parents=True, exist_ok=True)

    for src, instances in PLAN:
        if not src.exists():
            print(f"Missing source font: {src}", file=sys.stderr)
            return 1
        for weight, name in instances:
            out = FONTS / name
            print(f"instancing {src.name} wght={weight} -> {name}")
            from fontTools.ttLib import TTFont  # type: ignore

            base = TTFont(str(src))
            font = instancer.instantiateVariableFont(
                base, {"wght": weight}, inplace=False, static=True
            )
            # Strip variation tables so the file is a plain static font.
            for tag in ("fvar", "avar", "HVAR", "MVAR", "STAT", "cvar"):
                if tag in font:
                    del font[tag]
            if "OS/2" in font:
                font["OS/2"].usWeightClass = weight
            font.save(str(out))
    print("Fonts written to", FONTS)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
