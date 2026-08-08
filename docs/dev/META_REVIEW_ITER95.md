# Meta-review — Iteração 95 (Day 0, iters 91–94)

Revisão arquitetural após quatro iterações (Iter 91–94). Phase 12 maturity MVP (a11y + beta guarantees + L10N) + digest period polish. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 94; gate herdado **375** testes)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** (infos/warnings não bloqueiam) |
| `flutter test` (app) | **89** testes |
| `flutter test packages/colony_domain` | **199** testes |
| `flutter test packages/colony_database` | **87** testes |
| **Total** | **375** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 94

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | Integration*; NarrativeDigest; export **v26** | Correto |
| `packages/colony_database` | DB **v29**, ICS + outbox + zones | Correto |
| `lib/features/integrations/` | ICS opt-in + import | **Saudável** |
| `lib/features/storyteller/` | NarrativeDigest efêmero + período UTC | **Saudável** |
| `lib/features/sync/` | Outbox local noop | **Stub OK** — remote defer |
| `lib/core/providers/` | só `app_providers` + `feature_controllers` | **Limpo** |
| `docs/dev/` | A11Y_BASELINE, BETA_MIGRATION_GUARANTEES, L10N_HUBS_10_12 | Phase 12 docs ✅ |

### Recomendações

1. **P0:** Golden fixture `export_v26.json` + restore test — fecha lacuna pirâmide (fixtures param em v22).
2. **P0:** Zone↔Trip link lite (spec §25–26) — cross-link Phase 8 depth, shippable.
3. Sync: polish enqueue/status UX sem remote; ICS→ScheduleBlock confirm opcional.
4. NarrativeDigest: rules_v1 depth (mais sinais) sem persist/LLM.
5. Core shims: **fechado**.

---

## 2. Export v26 + DB v29

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v26** | v29 | `integration_consents`, `external_calendar_events` | ✅ schema + round-trip vivo |
| **v25** | v28 | `context_zones` | ✅ schema; **sem** fixture JSON |
| **v24–v23** | v26–v25 | commitments / quest_inventory | ✅ schema; **sem** fixture JSON |
| outbox/device | v27+ | **não** exportados | wipe no restore ✅ |

Write version atual: **v26**.

**Lacunas P0:** fixtures JSON v23–v26 ausentes (último arquivo: `export_v22.json`). Golden v26 fecha banda beta.

OUT explícito: NarrativeDigest (efêmero); multi-currency; remote sync/E2EE; Health Connect; LLM.

---

## 3. Test pyramid

| Camada | Pós Iter 94 |
|--------|-------------|
| Domain | + export band 1…26; NarrativeDigest period strings; L10N hubs |
| Repository | migration v28→v29; integrations CRUD; export write v26 |
| Widget | Sync/ICS/Digest Semantics; digest período |
| CI | gate local **375** testes |
| Integration | Bootstrap E2E inclui integrations |

Prioridades: golden v26 → Zone↔Trip → digest/sync depth → privacy stub → pit 100.

---

## 4. MVP vs spec (depth pós-MVP)

| Spec | Status | Gap de profundidade |
|------|--------|---------------------|
| Phase 8 Inventory/Relations/House | **MVP utilizável** | Zone↔Trip; home↔inventory; packing lite |
| Phase 9 Sync | **Stub local** | enqueue expand; status polish; remote defer |
| Phase 10 Integrations | **MVP stub ICS** | ICS→ScheduleBlock confirm; write-back defer |
| Phase 11 IA/Storyteller | **MVP rules digest** | mais regras/sinais; LLM defer |
| Phase 12 Maturity | **MVP utilizável** | perf smoke; privacy/legal stub; a11y expand |

Fases 0–12 têm MVP mínimo — **não é término**. Loop aprofunda produto.

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Settings | Sync + Integrations — OK; consolidar antes de novos toggles |
| Resources | Densidade alta — Zone↔Trip via edit sheets, sem nova rota |
| Crônica / Weekly | Digest com período — leve |
| Float menu | Monitorar overflow; sem novas entradas Phase 12 |

---

## 6. Checklist Iter 90 §7

| Ação | Status |
|------|--------|
| A11y baseline + Semantics lite | ✅ Iter 91 |
| Beta migration guarantees | ✅ Iter 92 |
| Localization hubs 10–12 | ✅ Iter 93 |
| Digest UI polish | ✅ Iter 94 |
| Pit stop | ✅ Iter 95 |

---

## 7. Backlog ambicioso Iter 96–110 (depth, não stubs)

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 96 | Golden export **v26** fixture + restore test | Pirâmide; fecha banda beta |
| **P0** | 97 | Zone↔Trip link lite (FK opcional / N:N mínima) | Spec §25–26 cross-link |
| **P1** | 98 | Sync enqueue polish (mais entity types ou status UX) | Phase 9 depth |
| **P1** | 99 | NarrativeDigest rules depth (mais sinais locais) | Phase 11 sem LLM |
| **P1** | 100 | Pit stop meta-review | Protocolo LOOP |
| — | 101 | ICS→ScheduleBlock confirm lite | Phase 10 polish |
| — | 102 | Performance smoke note + cold-start checklist | Phase 12 |
| — | 103 | Privacy/legal prep doc stub | Phase 12 defer-lite |
| — | 104 | Home↔Inventory link lite **ou** packing list stub | Phase 8 depth |
| — | 105 | Pit stop | Protocolo |
| — | 106 | Finance CSV import apply lite (dedup→persist) | Phase 6 depth |
| — | 107 | Health appointment stub local (não clínico) | Phase 7 depth |
| — | 108 | Commitment↔Quest link lite | Phase 8 relations |
| — | 109 | Export golden v23–v25 fill **ou** digest chronicle chip | Completeness |
| — | 110 | Pit stop | Protocolo |

**Defer:** Health Connect, HealthKit, Open Finance, LLM remoto, calendar write-back, remote sync/E2EE, certificação clínica/legal, multi-currency, geofencing/GPS.

---

## Referências

- `META_REVIEW_ITER90.md`, ADR-015, ADR-025, ADR-027, ADR-031–034
- Iters 91–94 em `docs/dev/LOOP.md`
- Spec §25 ContextZone, §26 Trip, §45 roadmap
