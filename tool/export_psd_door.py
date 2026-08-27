"""Export DoorSimple_Mover.psd → PNG for Habitat assets."""

from pathlib import Path

from psd_tools import PSDImage

src = Path(
    r"c:\dev\fallhub\docs\produto\assets\reference\game_art_source"
    r"\Things\Building\Door\DoorSimple_Mover.psd"
)
psd = PSDImage.open(src)
print(f"size: {psd.width}x{psd.height}")
print(f"mode: {psd.color_mode}")
print(f"top layers: {len(list(psd))}")
for i, layer in enumerate(psd):
    w = getattr(layer, "width", None)
    h = getattr(layer, "height", None)
    print(f"  [{i}] {layer.name!r} visible={layer.visible} size={w}x{h}")

img = psd.composite()
print(f"composite: mode={img.mode} size={img.size} bbox={img.getbbox()}")
if img.mode != "RGBA":
    img = img.convert("RGBA")

out = Path(
    r"c:\dev\fallhub\packages\living_habitat_assets"
    r"\assets\v0\furniture\door_simple_mover.png"
)
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out)
print(f"saved: {out} ({out.stat().st_size} bytes)")

preview = Path(
    r"c:\dev\fallhub\docs\produto\assets\generated\habitat"
    r"\door_simple_mover_preview.png"
)
preview.parent.mkdir(parents=True, exist_ok=True)
img.save(preview)
print(f"preview: {preview}")
