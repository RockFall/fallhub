"""Audit furniture PNG aspect vs FurnitureRegistry footprints.

Fails (exit 1) when south sprite aspect is far from footprint aspect —
the classic square-atlas-into-1x2-bed squash.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(r"c:\dev\fallhub\packages\living_habitat_assets\assets\v0\furniture")

# Keep in sync with FurnitureRegistry footprints (south-facing).
FOOTPRINTS: dict[str, tuple[int, int]] = {
    "armchair": (1, 1),
    "dining_chair": (1, 1),
    "stool": (1, 1),
    "couch": (2, 1),
    "bed": (1, 2),
    "double_bed": (2, 2),
    "royal_bed": (2, 2),
    "hospital_bed": (1, 2),
    "bedroll": (1, 2),
    "bedroll_double": (2, 2),
    "sleep_spot": (1, 2),
    "double_sleep_spot": (2, 2),
    "table_1x2": (1, 2),
    "table_2x2": (2, 2),
    "table_2x4": (2, 4),
    "table_3x3": (3, 3),
    "end_table": (1, 1),
    "dresser": (2, 1),
    "shelf": (2, 1),
    "shelf_small": (1, 1),
    "bookcase": (2, 1),
    "bookcase_small": (1, 1),
    "lamp_standing": (1, 1),
    "flood_light": (1, 1),
    "wall_lamp": (1, 1),
    "plant_pot": (1, 1),
    "column": (1, 1),
    "grand_stele": (2, 2),
    "pen_marker": (1, 1),
}

# Match ratio below this on non-square footprints → warn.
# (Square footprints are skipped — tall lamps/chairs in 1×1 are fine with fit-cover.)
MIN_MATCH = 0.72


def match(foot: tuple[int, int], sprite_aspect: float) -> float:
    fw, fh = foot
    foot_aspect = fw / fh
    lo, hi = sorted((foot_aspect, sprite_aspect))
    return lo / hi


def main() -> int:
    bad: list[str] = []
    ok_n = 0
    skipped = 0
    for def_id, foot in sorted(FOOTPRINTS.items()):
        path = ROOT / def_id / "south.png"
        if not path.exists():
            bad.append(f"{def_id}: missing south.png")
            continue
        im = Image.open(path).convert("RGBA")
        w, h = im.size
        if h == 0:
            bad.append(f"{def_id}: zero height")
            continue
        aspect = w / h
        # Square collision cells: aspect mismatch is aesthetic overflow, not squash.
        if foot[0] == foot[1]:
            skipped += 1
            print(f"SKIP {def_id}: sprite={w}x{h} foot={foot[0]}x{foot[1]} (square cell)")
            continue
        m = match(foot, aspect)
        line = (
            f"{def_id}: sprite={w}x{h} aspect={aspect:.3f} "
            f"foot={foot[0]}x{foot[1]} match={m:.3f}"
        )
        if m < MIN_MATCH:
            bad.append(line + "  <-- SQUASH RISK")
            print("BAD ", line)
        else:
            ok_n += 1
            print("OK  ", line)

    print(f"\n{ok_n} ok, {skipped} square-skipped, {len(bad)} bad (min match {MIN_MATCH})")
    if bad:
        print("\nFix: re-run export with trim, or fix footprint in FurnitureRegistry.")
        for b in bad:
            print(" -", b)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
