# Habitat — screenshots gerados

Milestone visual (spec `07` v1.2.0 + mirror `08` Fase A):

| Arquivo | Milestone | Como reproduzir |
|---|---|---|
| `v0_wander.png` | V0–V3.5 | `flutter test tool/capture_habitat_screenshot.dart` |
| `v4_inspect.png` | V4 inspect | mesmo comando |
| `v5_bubbles.png` | V5 bubbles | mesmo comando |
| `v6_cosmetics.png` | V6 body/apparel/loadout | mesmo comando |
| `m00_signal_debug.png` | M0 MirrorSignal | `flutter test tool/capture_mirror_habitat_screenshot.dart` |
| `m01_effective_state.png` | M1 EffectiveState | mesmo |
| `m02_clock_debug.png` | M2 Clocks | mesmo |
| `m03_embodied_state.png` | M3 Embodied | mesmo |
| `m04_state_explain.png` | M4 STATE explain | mesmo |

Os PNGs são **frames distintos**.

No app: `flutter run` → Mais → Habitat / Criar colonista.  
Selecionar um pawn abre o painel STATE (needs / capacities / conditions / signals / context).  
Debug: barra de relógio (1×/5×/30×/+1h) no topo do Habitat.
