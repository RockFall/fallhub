"""Export Things/Building/Furniture → living_habitat_assets/v0/furniture/.

Convention:
  assets/v0/furniture/<def_id>/<facing>.png
  assets/v0/furniture/<def_id>/south_mask.png  (bed bedding overlays, optional)

Facing keys: south | east | north  (west = flip east at runtime).
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image
from psd_tools import PSDImage

SRC = Path(
    r"c:\dev\fallhub\docs\produto\assets\reference\game_art_source"
    r"\Things\Building\Furniture"
)
DST = Path(
    r"c:\dev\fallhub\packages\living_habitat_assets\assets\v0\furniture"
)
MANIFEST = Path(
    r"c:\dev\fallhub\packages\living_habitat_assets"
    r"\assets\v0\furniture\MANIFEST.txt"
)

# (def_id, relative_src_without_ext, facing, is_mask)
# facing: south|east|north|single
EXPORTS: list[tuple[str, str, str, bool]] = [
    # Seats
    ("armchair", "Armchair_south", "south", False),
    ("armchair", "Armchair_east", "east", False),
    ("armchair", "Armchair_north", "north", False),
    ("dining_chair", "DiningChair_south", "south", False),
    ("dining_chair", "DiningChair_east", "east", False),
    ("dining_chair", "DiningChair_north", "north", False),
    ("stool", "Stool_east", "east", False),
    ("stool", "Stool_north", "north", False),
    ("couch", "Couch_south", "south", False),
    ("couch", "Couch_east", "east", False),
    ("couch", "Couch_north", "north", False),
    # Beds (base + mask)
    ("bed", "Bed/Bed_south", "south", False),
    ("bed", "Bed/Bed_east", "east", False),
    ("bed", "Bed/Bed_north", "north", False),
    ("bed", "Bed/Bed_southm", "south_mask", False),
    ("bed", "Bed/Bed_eastm", "east_mask", False),
    ("bed", "Bed/Bed_northm", "north_mask", False),
    ("double_bed", "Bed/DoubleBed_south", "south", False),
    ("double_bed", "Bed/DoubleBed_east", "east", False),
    ("double_bed", "Bed/DoubleBed_north", "north", False),
    ("double_bed", "Bed/DoubleBed_southm", "south_mask", False),
    ("double_bed", "Bed/DoubleBed_eastm", "east_mask", False),
    ("double_bed", "Bed/DoubleBed_northm", "north_mask", False),
    ("royal_bed", "Bed/RoyalBed_south", "south", False),
    ("royal_bed", "Bed/RoyalBed_east", "east", False),
    ("royal_bed", "Bed/RoyalBed_north", "north", False),
    ("royal_bed", "Bed/RoyalBed_southm", "south_mask", False),
    ("royal_bed", "Bed/RoyalBed_eastm", "east_mask", False),
    ("royal_bed", "Bed/RoyalBed_northm", "north_mask", False),
    ("hospital_bed", "Bed/HospitalBed_south", "south", False),
    ("hospital_bed", "Bed/HospitalBed_east", "east", False),
    ("hospital_bed", "Bed/HospitalBed_north", "north", False),
    ("hospital_bed", "Bed/HospitalBed_southm", "south_mask", False),
    ("hospital_bed", "Bed/HospitalBed_eastm", "east_mask", False),
    ("hospital_bed", "Bed/HospitalBed_northm", "north_mask", False),
    ("bedroll", "Bed/Bedroll_south", "south", False),
    ("bedroll", "Bed/Bedroll_east", "east", False),
    ("bedroll", "Bed/Bedroll_north", "north", False),
    ("bedroll", "Bed/Bedroll_southm", "south_mask", False),
    ("bedroll", "Bed/Bedroll_eastm", "east_mask", False),
    ("bedroll", "Bed/Bedroll_northm", "north_mask", False),
    ("bedroll_double", "Bed/BedrollDouble_south", "south", False),
    ("bedroll_double", "Bed/BedrollDouble_east", "east", False),
    ("bedroll_double", "Bed/BedrollDouble_north", "north", False),
    ("bedroll_double", "Bed/BedrollDouble_southm", "south_mask", False),
    ("bedroll_double", "Bed/BedrollDouble_eastm", "east_mask", False),
    ("bedroll_double", "Bed/BedrollDouble_northm", "north_mask", False),
    ("sleep_spot", "Bed/SleepSpot_south", "south", False),
    ("sleep_spot", "Bed/SleepSpot_east", "east", False),
    ("sleep_spot", "Bed/SleepSpot_north", "north", False),
    ("double_sleep_spot", "Bed/DoubleSleepSpot_south", "south", False),
    ("double_sleep_spot", "Bed/DoubleSleepSpot_east", "east", False),
    ("double_sleep_spot", "Bed/DoubleSleepSpot_north", "north", False),
    # Tables
    ("table_1x2", "Table1x2_east", "east", False),
    ("table_1x2", "Table1x2_north", "north", False),
    ("table_2x2", "Table2x2_north", "north", False),
    ("table_2x4", "Table2x4_east", "east", False),
    ("table_2x4", "Table2x4_north", "north", False),
    ("table_3x3", "Table3x3_north", "north", False),
    ("end_table", "EndTable_south", "south", False),
    ("end_table", "EndTable_east", "east", False),
    ("end_table", "EndTable_north", "north", False),
    # Storage
    ("dresser", "Dresser_south", "south", False),
    ("dresser", "Dresser_east", "east", False),
    ("dresser", "Dresser_north", "north", False),
    ("shelf", "Shelf_south", "south", False),
    ("shelf", "Shelf_east", "east", False),
    ("shelf", "Shelf_north", "north", False),
    ("shelf_small", "ShelfSmall_south", "south", False),
    ("shelf_small", "ShelfSmall_east", "east", False),
    ("shelf_small", "ShelfSmall_north", "north", False),
    ("bookcase", "Bookcase/Bookcase_south", "south", False),
    ("bookcase", "Bookcase/Bookcase_east", "east", False),
    ("bookcase", "Bookcase/Bookcase_north", "north", False),
    ("bookcase", "Bookcase/Bookcase_Bookend_east", "east_bookend", False),
    ("bookcase", "Bookcase/Bookcase_Bookend_north", "north_bookend", False),
    ("bookcase_small", "Bookcase/BookcaseSmall_south", "south", False),
    ("bookcase_small", "Bookcase/BookcaseSmall_east", "east", False),
    ("bookcase_small", "Bookcase/BookcaseSmall_north", "north", False),
    ("bookcase_small", "Bookcase/BookcaseSmall_Bookend_east", "east_bookend", False),
    ("bookcase_small", "Bookcase/BookcaseSmall_Bookend_north", "north_bookend", False),
    # Light
    ("lamp_standing", "LampStanding", "south", False),
    ("flood_light", "FloodLight", "south", False),
    ("wall_lamp", "WallLamp/WallLamp_south", "south", False),
    ("wall_lamp", "WallLamp/WallLamp_east", "east", False),
    ("wall_lamp", "WallLamp/WallLamp_north", "north", False),
    # Decor
    ("plant_pot", "PlantPot", "south", False),
    ("column", "Column", "south", False),
    ("grand_stele", "GrandStele", "south", False),
    ("pen_marker", "PenMarker", "south", False),
    ("large_stele_a", "SteleLarge/LargeSteleA", "south", False),
    ("large_stele_b", "SteleLarge/LargeSteleB", "south", False),
    ("large_stele_c", "SteleLarge/LargeSteleC", "south", False),
    ("large_stele_d", "SteleLarge/LargeSteleD", "south", False),
    ("large_stele_e", "SteleLarge/LargeSteleE", "south", False),
    ("large_stele_f", "SteleLarge/LargeSteleF", "south", False),
]


def load_image(path_no_ext: Path) -> Image.Image:
    png = path_no_ext.with_suffix(".png")
    psd = path_no_ext.with_suffix(".psd")
    # Prefer PSD so we can skip black matte layers (cleaner AA than flat PNG).
    # Do NOT defringe globally — RimWorld sprites use intentional black outlines.
    if psd.exists():
        img = composite_psd_skip_mattes(PSDImage.open(psd))
        img = punch_black_background(img)
    elif png.exists():
        img = Image.open(png)
        if img.mode != "RGBA":
            img = img.convert("RGBA")
        img = punch_black_background(img)
    else:
        raise FileNotFoundError(path_no_ext)
    return trim_transparent(img)


def is_solid_black_matte(layer, canvas_w: int, canvas_h: int) -> bool:
    """Full-canvas opaque black layer used as PSD backdrop (kills edge AA)."""
    bbox = getattr(layer, "bbox", None)
    if not bbox:
        return False
    left, top, right, bottom = bbox
    if (right - left) < canvas_w * 0.9 or (bottom - top) < canvas_h * 0.9:
        return False
    try:
        li = layer.topil()
    except Exception:
        return False
    if li is None:
        return False
    li = li.convert("RGBA")
    step_x = max(1, li.width // 8)
    step_y = max(1, li.height // 8)
    dark = 0
    n = 0
    for y in range(0, li.height, step_y):
        for x in range(0, li.width, step_x):
            r, g, b, a = li.getpixel((x, y))
            n += 1
            if a > 200 and r <= 8 and g <= 8 and b <= 8:
                dark += 1
    return n > 0 and dark / n >= 0.9


def composite_psd_skip_mattes(psd: PSDImage) -> Image.Image:
    """Compose visible layers onto transparent — skip solid black mattes.

    Flattening onto black bakes anti-alias into dark RGB fringes (ugly lamp edges).
    """
    canvas = Image.new("RGBA", (psd.width, psd.height), (0, 0, 0, 0))
    used = 0
    for layer in psd:
        visible = getattr(layer, "visible", True)
        if not visible:
            continue
        if is_solid_black_matte(layer, psd.width, psd.height):
            continue
        try:
            li = layer.topil()
        except Exception:
            continue
        if li is None:
            continue
        li = li.convert("RGBA")
        left, top, right, bottom = layer.bbox
        # Guard against oversized paste.
        if left >= psd.width or top >= psd.height:
            continue
        canvas.alpha_composite(li, dest=(int(left), int(top)))
        used += 1
    if used == 0:
        fallback = psd.composite()
        if fallback.mode != "RGBA":
            fallback = fallback.convert("RGBA")
        return fallback
    return canvas


def trim_transparent(img: Image.Image, pad: int = 1) -> Image.Image:
    """Crop to opaque content so canvas aspect matches the art (avoids stretch squash)."""
    img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)
    return img.crop((left, top, right, bottom))


def punch_black_background(img: Image.Image, threshold: int = 12) -> Image.Image:
    """Remove opaque black canvas left by RGB PSD composites.

    Flood-fills from the border so interior near-black art (shadows) is kept.
    """
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()

    def is_bg(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        if a == 0:
            return False
        return r <= threshold and g <= threshold and b <= threshold

    # Only run if corners look like a solid black matte.
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    if sum(1 for x, y in corners if is_bg(x, y)) < 2:
        return img

    from collections import deque

    q: deque[tuple[int, int]] = deque()
    seen = [[False] * w for _ in range(h)]
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        if not is_bg(x, y):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return img


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    ok = 0
    fail = 0
    wrote_south: set[str] = set()
    for def_id, rel, facing, _ in EXPORTS:
        src = SRC / rel
        try:
            img = load_image(src)
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {def_id}/{facing}: {e}")
            fail += 1
            continue
        out_dir = DST / def_id
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / f"{facing}.png"
        img.save(out)
        lines.append(
            f"{def_id}/{facing}.png\t{img.size[0]}x{img.size[1]}\t{out.stat().st_size}"
        )
        print(f"OK {out.relative_to(DST)} {img.size} mode={img.mode}")
        ok += 1
        if facing == "south":
            wrote_south.add(def_id)

    # Derived south for defs that only ship east/north in the dump.
    for def_id in {d for d, _, _, _ in EXPORTS} - wrote_south:
        out_dir = DST / def_id
        north = out_dir / "north.png"
        east = out_dir / "east.png"
        src = north if north.exists() else east
        if src.exists():
            shutil.copy(src, out_dir / "south.png")
            print(f"DERIVE {def_id}/south.png <- {src.name}")

    # Legacy flat aliases used by older HabitatAssets constants
    aliases = {
        "bed_south.png": DST / "bed" / "south.png",
        "chair_south.png": DST / "dining_chair" / "south.png",
        "table_south.png": DST / "table_2x2" / "south.png",
        "lamp.png": DST / "lamp_standing" / "south.png",
    }
    for name, src in aliases.items():
        if src.exists():
            shutil.copy(src, DST / name)
            print(f"ALIAS {name} <- {src.relative_to(DST)}")

    MANIFEST.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nDone: {ok} ok, {fail} fail -> {DST}")


if __name__ == "__main__":
    main()
