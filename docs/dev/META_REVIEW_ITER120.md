# Meta-review — Iteração 120 (Day 0, iters 116–119)

Revisão após Export goldens v27–v29 e Commitment linked quest title. **Sem refactor-only code.**

**Baseline verificado:** 2026-08-07

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **94** |
| `flutter test packages/colony_domain` | **216** |
| `flutter test packages/colony_database` | **105** |
| **Total** | **415** testes |

---

## 1. Layering

| Área | Estado |
|------|--------|
| Export write **v29** / DB **v33** | Estável; goldens restore v27–v29 ✅ |
| Relations | Commitment list mostra título da missão vinculada |
| Travel | Packing N:N (Iter 113) + empty-state polish → 123 |
| Zones | Capabilities edit ainda sem helper / unavailableWorkTypes UI |
| Finance | CSV plan→apply sem widget test dedicado |
| App suite | ColonyScreen hang policy mantida |

---

## 2. Export / DB

Write **v29**, schema **v33**. Goldens restore cobrem v23–v29. Sem bump necessário neste bloco.

ADR-015 matriz até v29. Wipe/insert documenta `trip_inventory`, `zone_trips`, `health_appointments`.

---

## 3. Test pyramid

+ goldens v27–v29 restore; commitment linked quest subtitle widget.
Bloqueio host: ColonyScreen + `pumpAndSettle` — não reintroduzir.
SnackBar tests: `pump` curto + `_drainTimers`; evitar `pumpAndSettle` com SnackBar.

---

## 4. MVP depth

Phases 0–12 MVP+ depth. Defer: remote sync, LLM, Health Connect, OS calendar write-back, geofencing, PackingLoadout tipado, multi-currency.

---

## 5. UX

Commitment subtitle “Missão: …” — ok. Zone capabilities ainda só label sem exemplo. Packing empty sem hint de ação. Appointment só mark-done (falta cancelar).

---

## 6. Checklist Iter 115 §7

| Item | Status |
|------|--------|
| Export golden v27 | ✅ 116 |
| Export golden v28 | ✅ 117 |
| Export golden v29 | ✅ 118 |
| Commitment linked quest title | ✅ 119 |
| Pit | ✅ 120 |

---

## 7. Backlog 121–130

| Rank | Iter | Slice |
|------|------|-------|
| **P0** | 121 | Finance CSV import widget test (sem pumpAndSettle Colony) |
| **P1** | 122 | Zone capabilities edit polish (+ unavailableWorkTypes lite) |
| **P1** | 123 | Trip packing empty-state hint polish |
| **P1** | 124 | Health appointment mark-cancelled lite |
| **P1** | 125 | Pit stop |
| — | 126 | Zone unavailableWorkTypes list subtitle polish |
| — | 127 | Health appointment mark-done widget test |
| — | 128 | Finance CSV nothing-to-apply / empty error widget paths |
| — | 129 | Trip packing unlink snackbar-safe widget path |
| — | 130 | Pit stop |

**Defer:** Health Connect, LLM, remote E2EE, OS calendar write-back, multi-currency, geofencing, PackingLoadout tipado.
