# Meta-review — Iteração 75 (Day 0, iters 71–74)

Revisão arquitetural após quatro iterações (Iter 71–74). Home maintenance MVP + E2E, inventory↔quest link, Commitments ADR. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 74)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **84** testes |
| `flutter test packages/colony_domain` | **178** testes |
| `flutter test packages/colony_database` | **83** testes |
| **Total** | **345** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 74

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | HomeMaintenanceTask; QuestInventoryLink; export **v23** | Correto |
| `packages/colony_database` | DB **v25**, `home_maintenance_tasks`, `quest_inventory` | Correto |
| `lib/features/home/` | `/resources/home` MVP (71) + E2E (72) | **Saudável** |
| `lib/features/inventory/` | quest link UI (73) | **Saudável** |
| `lib/core/providers/` | só `app_providers` + `feature_controllers` | **Limpo** |
| `docs/adr/ADR-030` | Commitments spike | Doc pronto → produto |

### Recomendações

1. Commitments MVP (ADR-030) é o próximo P0 natural — fecha §24.4 Relations.
2. Phase 8 house/inventory/relations está **MVP utilizável**; polish residual só se bloqueante.
3. Sync product continua cauteloso (ADR-025); outbox stub local só após Commitments estável.
4. Core shims: **fechado** — não recriar.

---

## 2. Export v22 → v23 + DB v24 → v25

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v22** | v24 | `home_maintenance_tasks` | ✅ |
| **v23** | v25 | `quest_inventory_links` | ✅ |

Write version atual: **v23**.

Lacunas: commitments OUT (produto →76); sync outbox OUT; ContextZone OUT; multi-currency OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 74 |
|--------|-------------|
| Domain | + HomeMaintenanceTask; QuestInventoryLink; export schema v23 |
| Repository | + home CRUD; inventory↔quest; migration v24→v25; fixtures |
| Widget | + home screen; home E2E (72) |
| CI | gate local **345** testes |
| Integration | Bootstrap E2E: travel + people + orgs + home |

Prioridades: Commitments MVP → E2E commitments → sync outbox stub **ou** ContextZone ADR → pit 80.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | inalterado |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory | **MVP utilizável** | quest link ✅ |
| Phase 8 Relations | **Person+interactions+Org+membership** | Commitments ADR ✅ → produto 76 |
| Phase 8 House/travel | **Trip + Home MVP ✅** | Phase 8 **fechada** para MVP |
| Phase 9 Sync | **ADR spike** | produto deferido (cautela →77+) |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Resources | Home + Inventory + Travel + Finance + Health — monitorar densidade float menu |
| Relations | People + Orgs; Commitments adicionará rota/lista — manter leve |
| Home | Lista leve — OK |
| Core | Shims removidos — estável |

---

## 6. Checklist Iter 70 §7

| Ação | Status |
|------|--------|
| Home maintenance MVP lite | ✅ Iter 71 |
| Home bootstrap E2E | ✅ Iter 72 |
| inventory↔quest link lite | ✅ Iter 73 |
| Commitments ADR spike | ✅ Iter 74 (ADR-030) |
| Pit stop | ✅ Iter 75 |

---

## 7. Backlog Iter 76–85

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 76 | Commitments MVP lite (ADR-030) | Fecha §24.4 Relations |
| **P1** | 77 | Commitments bootstrap E2E | Pirâmide |
| **P1** | 78 | Sync outbox stub local (ADR-025) | Phase 9 cautela — 1ª slice produto |
| **P2** | 79 | ContextZone ADR spike (§25.2) **ou** Commitment polish due/filter | Phase 8 resto / UX |
| **P2** | 80 | Pit stop meta-review | Protocolo LOOP |
| — | 81 | ContextZone MVP lite **ou** Sync envelope encrypt stub | Phase 8/9 |
| — | 82 | Finance multi-currency envelope ADR **ou** polish | Phase 6+ |
| — | 83 | Integration stub ADR (Phase 10) **ou** Health appointments defer skip | Phase 10 planning |
| — | 84 | Storyteller/IA ADR spike (Phase 11) **ou** polish sync | Phase 11 planning |
| — | 85 | Pit stop | Protocolo |

**Defer:** loadouts/GPS, Health Connect, Open Finance, IA produto, exams/appointments, multi-currency produto, organograma rico, privacy levels avançados em commitments, push notifications.

---

## Referências

- `META_REVIEW_ITER70.md`, ADR-015, ADR-024–030, `CORE_PLATFORM.md`
- Iters 71–74 em `docs/dev/LOOP.md`
