# Meta-review — Iteração 100 (Day 0, iters 96–99)

Revisão arquitetural após quatro iterações (Iter 96–99). Golden export v26, Zone↔Trip (DB v30 / export v27), sync enqueue expand, NarrativeDigest depth. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 99)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** (infos/warnings não bloqueiam) |
| `flutter test` (app) | ver contagem ao fechar gate |
| `flutter test packages/colony_domain` | **205** |
| `flutter test packages/colony_database` | **92** |
| **Total** | packages **297** + app (gate serial) |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 99

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | ZoneTripLink; export **v27**; digest signals | Correto |
| `packages/colony_database` | DB **v30**, `zone_trips`; sync enqueue trip/zone | Correto |
| `lib/features/zones/` | ZoneLinkedTripsSection | **Saudável** |
| `lib/features/sync/` | pending labels + count | **Saudável** |
| `lib/features/storyteller/` | digest rules depth (domain) | **Saudável** |
| `lib/core/providers/` | limpo | **OK** |

### Recomendações

1. **P0:** ICS→ScheduleBlock confirm lite — fecha Phase 10 polish do backlog 95.
2. Performance smoke + privacy stub — Phase 12 residual.
3. Home↔Inventory / packing — Phase 8 depth.
4. Core shims: **fechado**. Remote sync / LLM / Health Connect: **defer**.

---

## 2. Export v27 + DB v30

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v27** | v30 | `zone_trip_links` | ✅ |
| **v26** fixture | — | ICS + zones + commitments | ✅ golden file |
| outbox/device | v27+ | **não** exportados | wipe ✅ |

Write version atual: **v27**. Lacunas: fixtures JSON v23–v25; NarrativeDigest OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 99 |
|--------|-------------|
| Domain | ZoneTripLink; export schema v27; digest trip/zone/commitment |
| Repository | migration v29→v30; zone-trip link; sync enqueue trip/zone |
| Widget | zone linked trips; sync pending labels |
| CI | gate Iter 100 |

---

## 4. MVP vs spec (depth)

| Spec | Status | Gap |
|------|--------|-----|
| Phase 8 | **MVP+** Zone↔Trip | home↔inventory; packing |
| Phase 9 | **Stub+** enqueue expand | remote defer |
| Phase 10 | **MVP stub ICS** | ICS→ScheduleBlock |
| Phase 11 | **rules digest+** | mais sinais OK; LLM defer |
| Phase 12 | **MVP** | perf smoke; privacy stub |

---

## 5. UX hub complexity

Settings Sync/Integrations densos mas estáveis. Resources sem nova rota (Zone↔Trip em sheet). Digest permanece efêmero.

---

## 6. Checklist Iter 95 §7

| Ação | Status |
|------|--------|
| Golden export v26 | ✅ Iter 96 |
| Zone↔Trip link | ✅ Iter 97 |
| Sync enqueue polish | ✅ Iter 98 |
| NarrativeDigest depth | ✅ Iter 99 |
| Pit stop | ✅ Iter 100 |

---

## 7. Backlog Iter 101–110

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 101 | ICS→ScheduleBlock confirm lite | Phase 10 polish |
| **P1** | 102 | Performance smoke note + cold-start checklist | Phase 12 |
| **P1** | 103 | Privacy/legal prep doc stub | Phase 12 |
| **P1** | 104 | Home↔Inventory link lite | Phase 8 depth |
| **P1** | 105 | Pit stop | Protocolo |
| — | 106 | Finance CSV import apply lite | Phase 6 |
| — | 107 | Health appointment stub local | Phase 7 |
| — | 108 | Commitment↔Quest link lite | Phase 8 |
| — | 109 | Export golden v23–v25 fill | Completeness |
| — | 110 | Pit stop | Protocolo |

**Defer:** Health Connect, LLM, remote sync/E2EE, calendar write-back SO, multi-currency, geofencing.

---

## Referências

- `META_REVIEW_ITER95.md`, ADR-015/025/027/031–034
- Iters 96–99 em `docs/dev/LOOP.md`
