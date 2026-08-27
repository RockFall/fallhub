"""Find furniture PNGs with opaque black backgrounds (bad PSD composite)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(r"c:\dev\fallhub\packages\living_habitat_assets\assets\v0\furniture")


def analyze(path: Path) -> dict:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    total = w * h
    transparent = 0
    nearly_black_opaque = 0
    corner = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    border_black = 0
    border_n = 0
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            border_n += 1
            if a > 200 and r < 20 and g < 20 and b < 20:
                border_black += 1
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = px[x, y]
            border_n += 1
            if a > 200 and r < 20 and g < 20 and b < 20:
                border_black += 1
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                transparent += 1
            elif r < 12 and g < 12 and b < 12 and a > 200:
                nearly_black_opaque += 1
    tr = transparent / total
    br = border_black / max(border_n, 1)
    corners_bad = sum(
        1 for r, g, b, a in corner if a > 200 and r < 25 and g < 25 and b < 25
    )
    return {
        "tr": round(tr, 3),
        "black_pct": round(nearly_black_opaque / total, 3),
        "corners_bad": corners_bad,
        "border_black_pct": round(br, 3),
        "corner0": corner[0],
    }


def is_suspect(info: dict) -> bool:
    return (
        info["corners_bad"] >= 2
        or info["border_black_pct"] > 0.35
        or (info["tr"] < 0.05 and info["black_pct"] > 0.2)
        or (
            info["tr"] < 0.15
            and info["corners_bad"] >= 1
            and info["black_pct"] > 0.1
        )
    )


def main() -> None:
    suspects = []
    ok = []
    for p in sorted(ROOT.rglob("*.png")):
        if p.name.endswith("_mask.png") or "bookend" in p.name:
            continue
        info = analyze(p)
        rel = str(p.relative_to(ROOT)).replace("\\", "/")
        (suspects if is_suspect(info) else ok).append((rel, info))

    print("=== SUSPECTS (likely black bg) ===")
    for rel, info in suspects:
        print(
            f"{rel}: tr={info['tr']} black%={info['black_pct']} "
            f"corners_bad={info['corners_bad']} border_blk={info['border_black_pct']} "
            f"c0={info['corner0']}"
        )
    print(f"\nSuspects: {len(suspects)} / {len(suspects) + len(ok)}")
    print("\n=== Sample OK ===")
    for rel, info in ok[:12]:
        print(f"{rel}: tr={info['tr']} c0={info['corner0']}")


if __name__ == "__main__":
    main()
