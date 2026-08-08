# Meta-review — Iteração 70 (Day 0, iters 66–69)

Revisão arquitetural após quatro iterações (Iter 66–69). Organizations E2E, Person↔Org membership, Home maintenance ADR, remoção de shims core/. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 69)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **83** testes |
| `flutter test packages/colony_domain` | **172** testes |
| `flutter test packages/colony_database` | **79** testes |
| **Total** | **334** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 69

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | PersonOrganizationLink; export **v21** | Correto |
| `packages/colony_database` | DB **v23**, `person_organizations` | Correto |
| `lib/features/relations/` | Membership UI em edit sheets (67) | **Saudável** |
| `lib/core/providers/` | só `app_providers` + `feature_controllers` | **Limpo** (shims removidos) |
| `docs/adr/ADR-029` | Home maintenance spike | Doc pronto → produto |

### Recomendações

1. Home maintenance MVP é o próximo P0 natural (ADR-029).
2. inventory↔quest permanece lacuna Phase 8 opcional.
3. Sync product continua cauteloso (ADR-025); outbox stub só se Phase 8 house fechar.
4. Core shims: **fechado** — não recriar.

---

## 2. Export v20 → v21 + DB v22 → v23

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v20** | v22 | `organizations` | ✅ |
| **v21** | v23 | `person_organization_links` | ✅ |

Write version atual: **v21**.

Lacunas: home maint OUT (produto); inventory↔quest OUT; sync outbox OUT; commitments OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 69 |
|--------|-------------|
| Domain | + PersonOrganizationLink; export schema v21 |
| Repository | + membership link/unlink; migration v22→v23; fixture v21 |
| Widget | + membership section; orgs E2E (66) |
| CI | gate local **334** testes |
| Integration | Bootstrap E2E: travel + people + organizations |

Prioridades: Home maint MVP → E2E home → inventory↔quest **ou** commitments ADR → pit 75.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | inalterado |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory | **MVP utilizável** | link quest defer |
| Phase 8 Relations | **Person+interactions+Org+membership** | ✅ stub |
| Phase 8 House/travel | **Trip MVP ✅; home ADR ✅** | produto maint → 71 |
| Phase 9 Sync | **ADR spike** | produto deferido |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Relations | People + Orgs + membership nos sheets — monitorar densidade mobile |
| Travel | Lista leve — OK |
| Core | Shims removidos — menos ruído analyze |
| Home (futuro) | Novo hub `/resources/home` — manter leve |

---

## 6. Checklist Iter 65 §7

| Ação | Status |
|------|--------|
| Organizations bootstrap E2E | ✅ Iter 66 |
| Person↔Org membership stub | ✅ Iter 67 |
| Home maintenance ADR | ✅ Iter 68 (ADR-029) |
| Remove core/ shims | ✅ Iter 69 |
| Pit stop | ✅ Iter 70 |

---

## 7. Backlog Iter 71–80

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 71 | Home maintenance MVP lite (ADR-029) | Fecha Phase 8 house |
| **P1** | 72 | Home bootstrap E2E | Pirâmide |
| **P1** | 73 | inventory↔quest link lite **ou** Trip polish dates | Cross-feature / UX |
| **P2** | 74 | Commitments ADR spike (§24.4) | Relations expand |
| **P2** | 75 | Pit stop meta-review | Protocolo LOOP |
| — | 76 | Commitments MVP lite (pós-ADR) **ou** inventory↔quest se 73 foi Trip | Relations |
| — | 77 | Sync outbox stub local (ADR-025) **ou** skip se house ainda instável | Phase 9 cautela |
| — | 78 | ContextZone ADR spike (§25.2) **ou** polish home | Phase 8 resto |
| — | 79 | Finance multi-currency envelope ADR **ou** polish | Phase 6+ |
| — | 80 | Pit stop | Protocolo |

**Defer:** loadouts/GPS, Health Connect, Open Finance, IA, exams/appointments, multi-currency produto, organograma rico.

---

## Referências

- `META_REVIEW_ITER65.md`, ADR-015, ADR-024–029, `CORE_PLATFORM.md`
- Iters 66–69 em `docs/dev/LOOP.md`
