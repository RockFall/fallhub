# Meta-review — Iteração 55 (Day 0, iters 51–54)

Revisão arquitetural após quatro iterações (Iter 51–54). Finance budget + CSV stub, Person interaction log, core platform doc. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 54 / herdado 53)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **77** testes |
| `flutter test packages/colony_domain` | **159** testes |
| `flutter test packages/colony_database` | **71** testes |
| **Total** | **307** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 54

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + CategoryBudget, FinanceCsvCodec, PersonInteraction; export **v18** | Correto |
| `packages/colony_database` | DB **v20**, `category_budgets`, `person_interactions` | Correto |
| `lib/features/finance/` | budget panel + CSV share (51–52) | **Saudável** |
| `lib/features/relations/` | interaction log (53) | Estável |
| `docs/dev/CORE_PLATFORM.md` | inventário core/ (54) | Débito documentado |
| `lib/core/providers/` | shims + plataforma | Residual P3 (não migrar urgente) |

### Recomendações

1. House/travel ADR antes de qualquer Trip/Home entity.
2. Budget alerts UI só após uso real do painel (Iter 59 sugerida).
3. Sync product permanece deferido (ADR-025).

---

## 2. Export v16 → v18 + DB v18 → v20

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v16** | v18 | `people` | ✅ |
| **v17** | v19 | `category_budgets` | ✅ |
| **v18** | v20 | `person_interactions` | ✅ |

Write version atual: **v18**.

Lacunas: Trip/Home OUT; orgs OUT; CSV import persist OUT; sync outbox OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 54 |
|--------|-------------|
| Domain | + budget policy; CSV codec; PersonInteraction; export v18 |
| Repository | + budgets; interactions; migrations v18→v19→v20; restore v17/v18 |
| Widget | + budget empty; CSV icon; interaction icon |
| CI | gate local **307** testes |
| Integration | Bootstrap E2E sem `/relations/people` ainda |

Prioridades: House/travel ADR → People E2E **ou** inventory↔quest → org ADR.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | budget lite + CSV export stub |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory | **MVP utilizável** | inalterado |
| Phase 8 Relations | **Person + interaction lite** | orgs/commitments defer |
| Phase 8 House/travel | **Não iniciado** | próximo P0 ADR |
| Phase 9 Sync | **ADR spike** | produto deferido |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Finance | Net worth + budgets + CSV — monitorar scroll mobile |
| Relations | Interaction sheet — OK; lista ainda plana |
| Core | Documentado — sem UI nova |

---

## 6. Checklist Iter 50 §7

| Ação | Status |
|------|--------|
| Finance budget lite | ✅ Iter 51 |
| Finance CSV fingerprint stub | ✅ Iter 52 |
| Interaction log lite | ✅ Iter 53 |
| Document core/ platform | ✅ Iter 54 |
| Pit stop | ✅ Iter 55 |
| House/travel / People E2E | ⏳ → Iter 56+ |

---

## 7. Backlog Iter 56–65

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 56 | House/travel ADR spike (Phase 8 §25–26) | Fecha planning restante Phase 8 |
| **P0** | 57 | People route no bootstrap E2E | Pirâmide |
| **P1** | 58 | Organization ADR spike (§24.3) | Relations expand |
| **P1** | 59 | Budget spent-vs-limit polish / over-limit chip | §23 incremental |
| **P2** | 60 | Pit stop meta-review | Protocolo LOOP |
| — | 61 | Trip MVP lite **ou** Home maintenance stub | Pós-ADR 56 |
| — | 62 | Inventory↔quest link lite | Cross-feature |
| — | 63 | CSV import persist stub (dedup by fingerprint) | §23.9 |
| — | 64 | Remove unused core/ shims (P3) | Layering |
| — | 65 | Pit stop | Protocolo |

**Defer:** loadouts/locations GPS, sync product, Health Connect, Open Finance, IA, exams/appointments, envelope multi-currency.

---

## Referências

- `META_REVIEW_ITER50.md`, ADR-015, ADR-024–026, `CORE_PLATFORM.md`
- Iters 51–54 em `docs/dev/LOOP.md`
