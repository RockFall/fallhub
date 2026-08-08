# Meta-review — Iteração 60 (Day 0, iters 56–59)

Revisão arquitetural após quatro iterações (Iter 56–59). House/travel ADR, People E2E, Organization ADR, budget over-limit polish. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 59)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **78** testes |
| `flutter test packages/colony_domain` | **159** testes |
| `flutter test packages/colony_database` | **71** testes |
| **Total** | **308** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 59

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | CategoryBudget, FinanceCsvCodec, PersonInteraction; export **v18** | Correto |
| `packages/colony_database` | DB **v20**, budgets + interactions | Correto |
| `lib/features/finance/` | budget progress + over-limit chip (59) | **Saudável** |
| `lib/features/relations/` | Person + interactions; People E2E (57) | Estável |
| `docs/adr/` | ADR-027 house/travel; ADR-028 organization | Spikes prontos p/ produto |
| `lib/core/providers/` | shims + plataforma | Residual P3 |

### Recomendações

1. **Trip MVP** (ADR-027) é o próximo P0 — vertical slice em `features/travel/`.
2. **Organization MVP** (ADR-028) em seguida — hub relations.
3. Sync product permanece deferido (ADR-025).
4. Home maintenance / ContextZone OUT até slice dedicada.

---

## 2. Export v18 + DB v20 (sem bump 56–59)

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v18** | v20 | `person_interactions` | ✅ |
| (write atual) | | budgets, people, inventory… | ✅ |

Iters 56–58 foram doc/E2E; Iter 59 polish sem migration. Lacunas: `trips[]` OUT; `organizations[]` OUT; CSV import persist OUT; sync outbox OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 59 |
|--------|-------------|
| Domain | inalterado vs 55 (+ budget policy já em 51) |
| Repository | inalterado schema |
| Widget | + budget over-limit; People E2E route |
| CI | gate local **308** testes |
| Integration | Bootstrap: colony → finance → health → inventory → **people** → research → quests |

Prioridades: Trip MVP → Organization MVP → travel E2E / inventory↔quest → CSV import stub.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | over-limit UI; CSV import ainda defer |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory | **MVP utilizável** | inalterado |
| Phase 8 Relations | **Person + interaction** | orgs ADR-028 → produto 62 |
| Phase 8 House/travel | **ADR-027 ✅** | produto Trip → Iter 61 |
| Phase 9 Sync | **ADR spike** | produto deferido |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Finance | Net worth + budgets + over-limit — OK mobile |
| Relations | People + interactions; orgs ainda ausentes |
| Travel | Sem UI — próximo hub leve `/resources/travel` |
| Core | Documentado — sem UI nova |

---

## 6. Checklist Iter 55 §7

| Ação | Status |
|------|--------|
| House/travel ADR spike | ✅ Iter 56 |
| People route no bootstrap E2E | ✅ Iter 57 |
| Organization ADR spike | ✅ Iter 58 |
| Budget spent-vs-limit polish | ✅ Iter 59 |
| Pit stop | ✅ Iter 60 |
| Trip / Org produto | ⏳ → Iter 61+ |

---

## 7. Backlog Iter 61–70

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 61 | Trip MVP lite (ADR-027) — DB v21 / export v19 | Fecha Phase 8 travel |
| **P0** | 62 | Organization MVP lite (ADR-028) — DB v22 / export v20 | Fecha núcleo relations |
| **P1** | 63 | Travel route no bootstrap E2E | Pirâmide |
| **P1** | 64 | Inventory↔quest link lite **ou** CSV import persist stub | Cross-feature / §23.9 |
| **P2** | 65 | Pit stop meta-review | Protocolo LOOP |
| — | 66 | Organizations E2E **ou** Person↔Org membership stub | Relations expand |
| — | 67 | Home maintenance stub ADR **ou** Trip status polish | Phase 8 house |
| — | 68 | CSV import fingerprint dedup (se 64 foi link) | §23.9 |
| — | 69 | Remove unused core/ shims (P3) | Layering |
| — | 70 | Pit stop | Protocolo |

**Defer:** loadouts/locations GPS, sync product, Health Connect, Open Finance, IA, exams/appointments, envelope multi-currency, ContextZone, commitments CRM.

---

## Referências

- `META_REVIEW_ITER55.md`, ADR-015, ADR-024–028, `CORE_PLATFORM.md`
- Iters 56–59 em `docs/dev/LOOP.md`
