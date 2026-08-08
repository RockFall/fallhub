# Meta-review — Iteração 85 (Day 0, iters 81–84)

Revisão arquitetural após quatro iterações (Iter 81–84). ContextZone MVP + E2E, Integrations ADR, Storyteller/IA ADR. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 84)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** (infos/warnings não bloqueiam) |
| `flutter test` (app) | **87** testes |
| `flutter test packages/colony_domain` | **187** testes |
| `flutter test packages/colony_database` | **86** testes |
| **Total** | **360** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 84

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | ContextZone; export **v25** | Correto |
| `packages/colony_database` | DB **v28**, `context_zones` | Correto |
| `lib/features/zones/` (ou resources) | ContextZone MVP (81) + E2E (82) | **Saudável** |
| `lib/features/sync/` | Outbox stub (78) — inalterado | **Saudável** |
| `lib/core/providers/` | só `app_providers` + `feature_controllers` | **Limpo** |
| `docs/adr/ADR-032` | Integrations Phase 10 spike | Doc pronto → produto ICS |
| `docs/adr/ADR-033` | Storyteller/IA Phase 11 spike | Doc pronto → NarrativeDigest |

### Recomendações

1. **P0:** ICS import stub (ADR-032) — 1ª fatia produto Phase 10.
2. **P1:** NarrativeDigest rules_v1 (ADR-033) — 1ª fatia produto Phase 11.
3. Sync remote/E2EE permanece defer; outbox local suficiente para Phase 9 MVP stub.
4. Core shims: **fechado** — não recriar.
5. Phase 12 maturity: ADR + slices de a11y/perf/export guarantees após 10–11 MVP mínimo.

---

## 2. Export v25 + DB v28

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v25** | v28 | `context_zones` | ✅ |
| **v24** (sem bump) | v27 | outbox/device **não** exportados | wipe no restore ✅ |

Write version atual: **v25**.

Lacunas: IntegrationConsent / ICS events OUT; NarrativeDigest OUT; multi-currency OUT; remote sync OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 84 |
|--------|-------------|
| Domain | + ContextZone; export schema v25 |
| Repository | + context_zones CRUD; migration v27→v28 |
| Widget | + zones screen; zones E2E |
| CI | gate local **360** testes |
| Integration | Bootstrap E2E inclui zones + commitments + home + travel |

Prioridades: ICS stub → NarrativeDigest rules → polish/E2E → Phase 12 maturity ADR → pit 90.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | inalterado |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory/Relations/House | **MVP utilizável** | ContextZones ✅ |
| Phase 9 Sync | **Stub local** | outbox+device+noop ✅; remote defer |
| Phase 10 Integrations | **ADR only** | ADR-032 ✅ → ICS stub Iter 86 |
| Phase 11 IA/Storyteller | **ADR only** | ADR-033 ✅ → rules digest Iter 87+ |
| Phase 12 Maturity | **Não iniciado** | ADR + polish →89+ |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Resources | +zones — densidade alta; evitar mais entradas sem consolidar |
| Settings | Sync link; **Integrations** virá em 86 — manter leve |
| Relations | People + Orgs + Commitments — OK |
| Float menu | Monitorar overflow; preferir Settings para integrações |

---

## 6. Checklist Iter 80 §7

| Ação | Status |
|------|--------|
| ContextZone MVP lite | ✅ Iter 81 |
| ContextZone bootstrap E2E | ✅ Iter 82 |
| Integrations Phase 10 ADR | ✅ Iter 83 (ADR-032) |
| Storyteller/IA Phase 11 ADR | ✅ Iter 84 (ADR-033) |
| Pit stop | ✅ Iter 85 |

---

## 7. Backlog Iter 86–95

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 86 | ICS import stub (ADR-032) — consent + parse + preview | Phase 10 MVP mínimo |
| **P1** | 87 | NarrativeDigest rules_v1 (ADR-033) | Phase 11 MVP mínimo |
| **P1** | 88 | Integrations bootstrap E2E **ou** Digest UI polish | Pirâmide / UX |
| **P2** | 89 | Phase 12 maturity ADR spike | Planning maturidade |
| **P2** | 90 | Pit stop meta-review | Protocolo LOOP |
| — | 91 | Maturity slice: a11y audit lite **ou** export beta guarantee note | Phase 12 |
| — | 92 | ICS → ScheduleBlock confirm persist **ou** Digest persist+export | Fechar 10/11 |
| — | 93 | Sync enqueue expand (task create) **ou** Zone↔Trip link | Phase 8/9 polish |
| — | 94 | Localization completeness pass **ou** performance smoke | Phase 12 |
| — | 95 | Pit stop | Protocolo |

**Defer:** Health Connect, HealthKit, Open Finance, LLM remoto/on-device, calendar write-back, OAuth, geofencing, multi-currency produto, remote sync/E2EE, clinical review formal.

---

## Referências

- `META_REVIEW_ITER80.md`, ADR-015, ADR-025, ADR-031–033
- Iters 81–84 em `docs/dev/LOOP.md`
