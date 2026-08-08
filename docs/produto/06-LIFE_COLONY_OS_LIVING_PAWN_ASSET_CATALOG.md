# Life Colony OS — Living Pawn / Habitat Asset Catalog

**Documento:** inventário de recursos visuais para preparar a implementação de `05-LIFE_COLONY_OS_LIVING_PAWN_SPEC.md`  
**Status:** referência de pré-produção  
**Versão:** 1.0.0  
**Data:** 2026-08-07  
**Pasta local de binários:** `docs/produto/assets/reference/living_pawn/` (**gitignored**)

---

## 0. Objetivo deste catálogo

Capturar e organizar material visual que permita:

1. estudar a **gramática** do pawn top-down (camadas, direções, body types);
2. mapear **estações e objetos** do Habitat → jobs / domínios Life Colony;
3. ter templates e exemplos de modders (CC-BY / MIT) prontos para produção;
4. alimentar o renderer Flame (`LivingPawnComponent`, furniture, tiles) **já no V0**.

> **Regra de uso:** para o exercício / build visual-first, **pode** usar os PNGs vanilla capturados da cópia Steam local e packs de modders com licença compatível — se for o caminho mais direto para paridade RimWorld. Ver `07-LIFE_COLONY_OS_LIVING_PAWN_VISUAL_FIRST_BUILD.md`. Pasta `living_pawn/` permanece gitignored; o app copia um subset para `living_habitat_assets` quando for bundlar.

---

## 1. Mapa mental: do asset ao Habitat

```text
Pawn visual
  body (Naked_*)     → silhueta / body type
  head (*)           → cabeça + formato
  hair (*)           → corte (tintável)
  apparel (*)        → loadouts (trabalho, casual, viagem…)
  hands (mod)        → item em mão / gesto

Habitat scene
  floors / walls     → tiles e limites do cômodo
  bed / chair / table→ sono, refeição, social
  research / stove   → aprendizado, cozinha
  bookcase / TV      → lazer, Atlas Musical (projeção)
  comms / telescope  → relações, exploração, pesquisa
```

Espelhamento com a spec §11–§18 e §58 (camadas):

| Camada Life Colony (alvo) | Referência visual capturada |
|---|---|
| `body` | `vanilla_pawn_body` + templates ISOR3X |
| `head` | `vanilla_pawn_head` |
| `hair` / `beard` | `vanilla_pawn_hair` |
| `apparel_shell` / `apparel_skin` | `vanilla_apparel` + ISOR3X Apparel.ai |
| `held_item` / mãos | Show Me Your Hands (`Hand*.png`) |
| `furniture` / estações | furniture + stations + leisure |
| `structure` | floors / doors / walls samples |

---

## 2. Política de licença (resumo operacional)

| Fonte | Licença / restrição | Pode ir no app? | Uso permitido aqui |
|---|---|---|---|
| Extração Steam RimWorld (`resources.assets`) | EULA Ludeon — cuidado ao redistribuir publicamente | **Uso local / exercício OK**; release público exige revisão | Implementação V0+, calibração, paridade visual |
| Steam Workshop (Vanilla Expanded etc.) | Copyright dos autores VE / Oskar Potocki et al. — **não redistribuir** | Não no bundle público | Cópia local da Workshop instalada → `modder/vanilla_expanded/` |
| [ISOR3X/library-of-templates](https://github.com/ISOR3X/library-of-templates) | **CC BY 4.0** (crédito obrigatório) | Sim, com atribuição | Templates Illustrator + PNGs de referência de corpo/cabeça |
| [emipa606/ShowMeYourHands](https://github.com/emipa606/ShowMeYourHands) | **MIT** | Sim | Texturas de mão / offsets; adaptar ou recriar |
| [NL] Facial Animation (Workshop) | Redistribuição **proibida** pelo autor | Não | Só estudo in-game; não baixar/commitar |
| Art Source oficial Ludeon (fórum / wiki) | Material para modders; não é pack de redistribuição de jogo | Não no bundle | Preferir extração local da cópia comprada |

**Fonte canônica:** só Steam local (jogo + Workshop). Não baixar packs de sites de terceiros.

Binários em `living_pawn/` ficam fora do git. Este markdown **é** versionado.

---

## 3. Inventário local

Raiz: `docs/produto/assets/reference/living_pawn/`

### 3.1 Vanilla — pawn (~163 PNGs)

| Pasta | PNGs | Conteúdo | Uso no Living Pawn |
|---|---:|---|---|
| `vanilla_pawn_body/` | 15 | `Naked_{Male,Female,Thin,Fat,Hulk}_{south,east,north}` | Body types, escala, footprint |
| `vanilla_pawn_head/` | 36 | `Female/Male_{Average,Narrow}_{Normal,Pointy,Wide}_{dir}` | Formatos de cabeça; anchors |
| `vanilla_pawn_hair/` | 52 | Afro, Bob, Burgundy, Firestarter, Mohawk, Spikes, Curl, … | Cortes tintáveis |
| `vanilla_pawn_beard/` | 60 | Beard, Moustache, Goatee, Stubble, Lincoln, Colonial | Camada facial opcional |

**Convenção de direção:** `_south` (frente), `_east`, `_north` — west costuma ser espelho do east.

### 3.2 Vanilla — apparel / loadouts

| Pasta | PNGs | Bases úteis |
|---|---:|---|
| `vanilla_apparel/` | 190 | ShirtBasic, ShirtButton, Pants, Jacket, Parka, Duster, Flak*, PlateArmor, Tribal, Robes, hats/helmets |

| Loadout LC | Assets de referência |
|---|---|
| `casual` | ShirtBasic + Pants |
| `work_desk` | ShirtButton + Pants |
| `outdoor` / viagem | Parka / Jacket / Duster |
| `focus_deep` | Tuque / visual “cozy” |
| `exercise` | (pouco no vanilla; criar próprio) |
| `formal` | Duster / Jacket / Robes |

### 3.3 Vanilla — Habitat (cena) (~741 PNGs)

| Pasta | PNGs | Exemplos | Domínio Life Colony projetado |
|---|---:|---|---|
| `vanilla_habitat_furniture/` | 160 | Bed*, Chair*, Table*, Dresser, Shelf, LampStanding | Sono, social, storage, luz |
| `vanilla_habitat_leisure/` | 32 | Chess, Billiards, Bookcase, TV, GameOfUr, Telescope, Piano/Harp… | Lazer, Atlas Musical |
| `vanilla_habitat_work/` | 38 | CraftingSpot, ToolCabinet, Smithy, Tailor, Brewery, Fabrication… | Trabalho / crafting |
| `vanilla_habitat_stations/` | 72 | ResearchBench*, Stove*, Comms, Heater/Cooler, Battery | Pesquisa, cozinha, clima |
| `vanilla_habitat_decor/` | 88 | Sculpture, Column, Brazier, Grave, Banner, Torch… | Decoração / atmosfera |
| `vanilla_habitat_plants/` | 147 | Daylily, Rose, Tree, Bush, Healroot, crops… | Plantas / bioma indoor |
| `vanilla_items/` | 113 | Meal, Beer, Medicine, resources, weapons… | Held items / props |
| `vanilla_structure/` | 91 | floors, Wall, Door, Fence, Autodoor, conduits | Tilemap do Habitat |

**Estações funcionais (spec §16) ↔ objetos:**

| Estação Habitat | Objetos de referência | Gatilho de vida real |
|---|---|---|
| Sono | Bed*, Bedroll*, HospitalBed | agenda sleep / baixa energia |
| Trabalho | ResearchBench*, CraftingSpot, ShipComputerCore, ToolCabinet | tarefas, projects, deep work |
| Cozinha | Stove*, NutrientPaste* | refeição / health routines |
| Social / mesa | DiningChair, Table*, ChessTable | reuniões, relações |
| Lazer | TV, Bookcase, Billiards, Piano/Harp | recreation / música |
| Comunicação | CommsConsole | calls, inbox crítica |
| Observação | Telescope | pesquisa / “olhar o mundo” |
| Clima | Heater, Cooler, TorchLamp, LampStanding | atmosfera dia/noite |

### 3.4 Modders

#### A) ISOR3X — `modder/isor3x-library-of-templates/` (CC BY 4.0) — 78 PNGs + `.ai`

Templates Illustrator + referências; crédito ISOR3X (human refs creditam Sarg).

#### B) Show Me Your Hands — `modder/ShowMeYourHands/` (MIT) — 17 PNGs

`Hand*.png` / `HandIcon_*` para camada `held_item`.

#### C) Vanilla Expanded (Workshop local) — `modder/vanilla_expanded/` — **7768 PNGs**

Cópia da Steam Workshop instalada via `tool/extract_ve_workshop_refs.ps1`. Manifest: `modder/vanilla_expanded/MANIFEST.csv`.

| Pasta | PNGs | Mod Workshop |
|---|---:|---|
| `props_decor/` | 1027 | VFE — Props and Decor (Border/Decals/Kitchen/Workshop/Spacer/…) |
| `furniture_core/` | 399 | Vanilla Furniture Expanded |
| `art/` | 71 | VFE — Art |
| `architect/` | 70 | VFE — Architect (walls, fences, terrains) |
| `spacer/` | 137 | VFE — Spacer Module |
| `production/` | 57 | VFE — Production |
| `farming/` | 26 | VFE — Farming |
| `power/` | 152 | VFE — Power |
| `medical/` | 24 | VFE — Medical |
| `security/` | 231 | VFE — Security |
| `apparel/` | 427 | Vanilla Apparel Expanded |
| `apparel_accessories/` | 51 | VAE — Accessories |
| `hair/` | 400 | Vanilla Hair Expanded |
| `terrain_textures/` | 2714 | Vanilla Textures Expanded |
| `terrain_variations/` | 1074 | VTE — Variations |
| `books/` | 39 | Vanilla Books Expanded |
| `cooking/` | 267 | Vanilla Cooking Expanded |
| `brewing/` + `brewing_coffee/` | 171 | Vanilla Brewing Expanded (+ Coffees) |
| `plants*` | 409 | VPE (+ More / Succulents / Mushrooms) |
| `decorative_vending/` | 21 | Decorative Vending Machines |
| `adaptive_storage/` | 1 | Adaptive Storage Framework |

**Uso:** props densos para Habitat (escritório, cozinha, workshop, plantas); hair/apparel extras; terrains para tile variety. **Não commit; não redistribuir.**

#### D) Workshop só estudo in-game (não extrair)

| Mod | Por quê | Restrição |
|---|---|---|
| [NL] Facial Animation | blink / expressões | autor proíbe redistribuir |
| Yayo's Animation | jobs animados | não extrair para o repo |
| RimHUD / UI Not Included | densidade de inspect | UI, não sprite |

---

## 4. Como o renderer deve consumir isso

Pacote alvo (spec §60): `living_habitat_assets` + `living_habitat_renderer_flame`.

### 4.1 Stack de camadas do pawn (ordem de paint)

```text
0 shadow
1 body
2 apparel_bottom (pants)
3 apparel_top (shirt/jacket)
4 head
5 beard (opcional)
6 hair
7 apparel_hat
8 held_item / hands
9 mote / selection
```

Cada layer: 3–4 direções, opcional mask de cor (`primary` / `secondary`).

### 4.2 Pipeline de produção (recomendado)

1. **V0:** copiar subset vanilla (body/head/hair/floor) para o bundle do app e colocar na tela.
2. **Estudar** vanilla + ISOR3X para offsets e camadas.
3. Completar gaps com arte LC ou templates CC-BY quando faltar cobertura / licença.
4. Declarar em atlas JSON:

```yaml
sprite:
  id: lc_body_a_south
  path: bodies/a_south.png
  anchor: [0.5, 0.85]
  direction: south
  layer: body
```

5. Golden tests: pawn nu → +roupa → +cabelo → +item.

### 4.3 Habitat tile / furniture

- Tile size base: alinhar a **1 célula** visual (RimWorld ≈ 1×1); no Flame usar `tileSize` constante (ex. 64 ou 96 logical px).
- Furniture: south/east/north (+ mask `*m` quando houver) como no vanilla.
- Objetos “projeção de vida” (spec §17): reusar silhueta de Bookcase/TV/Bench com skin LC.

---

## 5. Gaps (ainda não capturados)

| Gap | Por quê importa | Próximo passo |
|---|---|---|
| Animações walk/idle (spritesheet) | pawn vivo, não pose estática | Estudar Yayo in-game; ou tween Flame |
| Retratos / cards | inspect pane / top bar | Extrair UI portraits ou gerar do stack de camadas |
| DLC Biotech kids / xenotypes | fora do MVP civil | Fase 2 |
| Facial Animation textures | expressões | Só in-game; recriar olhos/boca LC |
| Royalty instruments dedicados | Atlas Musical | Filtros Piano/Harp já no leisure; enriquecer com DLC se necessário |

Re-extrair (máquina com RimWorld + Workshop + AssetStudio):

```powershell
# Vanilla (resources.assets → living_pawn/vanilla_*)
powershell -NoProfile -ExecutionPolicy Bypass -File tool\extract_living_pawn_refs.ps1

# Vanilla Expanded / decor Workshop → living_pawn/modder/vanilla_expanded/
powershell -NoProfile -ExecutionPolicy Bypass -File tool\extract_ve_workshop_refs.ps1
```

---

## 6. Checklist de prontidão para implementação

- [x] Corpos nas 5 body types × 3 dirs  
- [x] Cabeças Average/Narrow × Normal/Pointy/Wide  
- [x] Cabelos + barbas direcionais  
- [x] Apparel básico + outerwear + hats  
- [x] Camas, cadeiras, mesas, estantes, luzes  
- [x] Bancadas de pesquisa, fogão, comms, clima  
- [x] Decor / plantas / items vanilla  
- [x] Props VE (Props and Decor, furniture, plants, cooking…)  
- [x] Terrains VE + variations  
- [x] Templates CC-BY para desenhar apparel/corpo  
- [x] Mãos MIT para held items  
- [ ] Subset V0 copiado para bundle do app  
- [ ] Atlas Flame + `LivingPawnComponent`  
- [ ] Editor de Habitat consumindo furniture defs  

**Totais locais (aprox.):** vanilla ~1094 PNGs · modder ~7863 PNGs · **~8957 PNGs** sob `living_pawn/`.

---

## 7. Créditos

- **Ludeon Studios** — RimWorld (extração Steam local).  
- **Vanilla Expanded team** (Oskar Potocki et al.) — Workshop local; referência apenas.  
- **ISOR3X** — library-of-templates (CC BY 4.0); referências humanas creditam Sarg.  
- **Mlie (emipa606)** — Show Me Your Hands (MIT).  
- Spec normativa: `05-LIFE_COLONY_OS_LIVING_PAWN_SPEC.md`.  
- Build visual-first: `07-LIFE_COLONY_OS_LIVING_PAWN_VISUAL_FIRST_BUILD.md`.

---

## 8. Próximo slice

Seguir **Milestone V0** em `07-LIFE_COLONY_OS_LIVING_PAWN_VISUAL_FIRST_BUILD.md`:

1. Grid + floor tiles.  
2. Pawn body/head/hair andando (wander idle).  
3. Só depois props, jobs, agenda, inspect, Drift.
