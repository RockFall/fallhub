# living_habitat_assets

Subset de sprites do Living Habitat (V0+) usado pelo renderer Flame.

## Origem

- Pawn / tiles: `docs/produto/assets/reference/living_pawn/` (gitignored)
- Furniture RW dump: `docs/produto/assets/reference/game_art_source/Things/Building/Furniture/` (gitignored)

Export furniture:

```bash
python tool/export_furniture_assets.py
```

## Layout

```text
assets/v0/
  furniture/
    <def_id>/south.png|east.png|north.png
    <def_id>/south_mask.png   # bedding overlay (beds)
    door_simple_mover.png
    tv_south.png
  pawn/...
  tiles/...
```

Blueprints e tags: `lib/features/habitat/flame/furniture/` no app (`FurnitureRegistry`).
