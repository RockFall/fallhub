# RimWorld vanilla UI extract (local only)

Extraído da instalação Steam local com AssetStudioModCLI.

**Não commitar o conteúdo de `rimworld_vanilla/`. Não redistribuir.** Pasta listada em `.gitignore` (EULA Ludeon proíbe rip/distribuição de partes do Software).

## Conteúdo típico

- `Texture2D/ButtonBG.png` (+ Mouseover / Click) — atlas 64×64, fill `#6A512E`
- `Texture2D/ButtonSubtleAtlas.png` — fill `#182228`
- `Texture2D/DropShadow.png`, radios, sliders, passion icons, scrollbars
- `Font/Calibri_tiny.ttf`, `Arial_tiny.ttf`, `LiberationSans.ttf`

## Uso no exercício

1. Calibrar golden tests / side-by-side contra estes PNGs.
2. No app, preferir tokens em `colony_design_system` + atlases gerados em `assets/ui/chrome/`.
3. Fontes de produção redistribuíveis: **Arimo** (≈ Arial) e **Carlito** (≈ Calibri), OFL.

## Re-extrair

```powershell
$cli = "tool\assetstudio\cli\AssetStudioModCLI_net8_portable\AssetStudioModCLI.exe"
$src = "${env:ProgramFiles(x86)}\Steam\steamapps\common\RimWorld\RimWorldWin64_Data\resources.assets"
$out = "docs\produto\assets\reference\rimworld_vanilla"
& $cli $src -t tex2d,sprite,font -o $out -g type -r --image-format png `
  --filter-by-name "ButtonBG;ButtonSubtle;DropShadow;RadioBut;Slider;Passion;CloseX;Arial_;Calibri_;Liberation"
```
