# Meta-review — Iteração 90 (Day 0, iters 86–89)

Revisão arquitetural após quatro iterações (Iter 86–89). ICS stub + NarrativeDigest + E2E + Maturity ADR. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 89)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** (infos/warnings não bloqueiam) |
| `flutter test` (app) | **89** testes |
| `flutter test packages/colony_domain` | **198** testes |
| `flutter test packages/colony_database` | **87** testes |
| **Total** | **374** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 89

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | Integration*; IcsCodec; NarrativeDigest; export **v26** | Correto |
| `packages/colony_database` | DB **v29**, integration_consents, external_calendar_events | Correto |
| `lib/features/integrations/` | ICS opt-in + import (86) + E2E (88) | **Saudável** |
| `lib/features/storyteller/` | NarrativeDigest sheet (87) | **Saudável** (efêmero) |
| `lib/core/providers/` | só `app_providers` + `feature_controllers` | **Limpo** |
| `docs/adr/ADR-034` | Maturity Phase 12 spike | Doc pronto → produto a11y |

### Recomendações

1. **P0:** A11y baseline + Semantics lite (ADR-034) — fecha Phase 12 MVP mínimo.
2. NarrativeDigest permanece efêmero — persist/export só se usuário pedir histórico.
3. Health Connect / LLM / remote sync: **defer** explícito.
4. Core shims: **fechado**.

---

## 2. Export v26 + DB v29

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v26** | v29 | `integration_consents`, `external_calendar_events` | ✅ |
| **v25** | v28 | `context_zones` | ✅ |
| outbox/device | v27+ | **não** exportados | wipe no restore ✅ |

Write version atual: **v26**.

Lacunas: NarrativeDigest OUT (efêmero); multi-currency OUT; remote sync OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 89 |
|--------|-------------|
| Domain | + IcsCodec/consent; NarrativeDigest rules; export schema v26 |
| Repository | + integrations CRUD/import; migration v28→v29 |
| Widget | + integrations screen; digest sheet; integrations E2E |
| CI | gate local **374** testes |
| Integration | Bootstrap E2E inclui integrations |

Prioridades: a11y baseline → beta migration note → localization pass → pit 95.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| Phase 8 Inventory/Relations/House | **MVP utilizável** | inalterado |
| Phase 9 Sync | **Stub local** | inalterado |
| Phase 10 Integrations | **MVP stub ICS** | Iter 86–88 ✅ |
| Phase 11 IA/Storyteller | **MVP rules digest** | Iter 87 ✅; LLM defer |
| Phase 12 Maturity | **ADR only** | ADR-034 ✅ → a11y Iter 91 |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Settings | Sync + Integrations — OK; evitar mais toggles sem consolidar |
| Crônica / Weekly | Botão digest — leve |
| Float menu | +integrations — monitorar overflow |
| Resources | Densidade alta — sem novas entradas Phase 12 |

---

## 6. Checklist Iter 85 §7

| Ação | Status |
|------|--------|
| ICS import stub (ADR-032) | ✅ Iter 86 |
| NarrativeDigest rules_v1 (ADR-033) | ✅ Iter 87 |
| Integrations bootstrap E2E | ✅ Iter 88 |
| Phase 12 maturity ADR | ✅ Iter 89 (ADR-034) |
| Pit stop | ✅ Iter 90 |

---

## 7. Backlog Iter 91–100

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 91 | A11y baseline doc + Semantics lite (ADR-034) | Phase 12 MVP mínimo |
| **P1** | 92 | Beta migration guarantees doc **ou** Semantics em Sync/Integrations tests | DoD / garantia |
| **P1** | 93 | Localization completeness pass (hubs 10–12) | Spec Phase 12 |
| **P2** | 94 | Digest UI polish **ou** Sync enqueue expand | Polish residual |
| **P2** | 95 | Pit stop meta-review | Protocolo LOOP |
| — | 96 | Performance smoke note **ou** desktop keyboard polish lite | Phase 12 |
| — | 97 | Zone↔Trip link lite **ou** ICS→ScheduleBlock confirm | Phase 8/10 polish |
| — | 98 | Export golden v26 fixture file | Pirâmide |
| — | 99 | Privacy/legal prep doc stub | Phase 12 defer-lite |
| — | 100 | Pit stop | Protocolo |

**Defer:** Health Connect, HealthKit, Open Finance, LLM, calendar write-back, remote sync/E2EE, clinical/legal formal, multi-currency, geofencing.

---

## Referências

- `META_REVIEW_ITER85.md`, ADR-015, ADR-032–034
- Iters 86–89 em `docs/dev/LOOP.md`
