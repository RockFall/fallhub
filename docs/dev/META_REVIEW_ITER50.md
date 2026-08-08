# Meta-review — Iteração 50 (Day 0, iters 46–49)

Revisão arquitetural após quatro iterações (Iter 46–49). Relations ADR + Person MVP, inventory polish (purchase/warranty), inventory bootstrap E2E. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 49)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **77** testes |
| `flutter test packages/colony_domain` | **148** testes |
| `flutter test packages/colony_database` | **66** testes |
| **Total** | **291** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 49

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + Person; InventoryItem polish fields; export **v16** | Correto |
| `packages/colony_database` | DB **v18**, `people`, `inventory_items` | Correto |
| `lib/features/relations/` | Person lista create/edit/archive (Iter 47) | **Saudável** |
| `lib/features/inventory/` | purchase/warranty UI (Iter 48); E2E route (Iter 49) | Estável |
| `docs/adr/` | ADR-024 inventory; ADR-025 sync; ADR-026 relations | Spikes alinhados |
| `lib/core/providers/` | shims + plataforma (inbox/undo/export) | Residual (P3 — documentar) |

### Recomendações

1. Relations permanece em `features/relations/` — interaction log como slice dedicada (não expandir Person).
2. Finance budget/CSV são polish §23 — vertical slice própria, sem Open Finance.
3. Sync product só após Phase 8 interactions/orgs estabilizar (ADR-025 permanece spike).
4. Documentar `core/` residual como plataforma — não migrar urgente.

---

## 2. Export v15 → v16 + DB v17 → v18

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v15** | v17 | `inventory_items` | ✅ fixture |
| **v16** | v18 | `people`; inventory purchase/warranty additive UI-only | ✅ fixture + round-trip |

Write version atual: **v16**.

Lacunas: budgets/CSV OUT; interaction log OUT; orgs/commitments OUT; sync outbox OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 49 |
|--------|-------------|
| Domain | + Person; export v16 schema |
| Repository | + people CRUD; migration v17→v18; restore v16 |
| Widget | + people screen; inventory polish; inventory no bootstrap E2E |
| CI | gate local **291** testes |
| Integration | Bootstrap E2E: colony → finance → health → **inventory** → research → quests |

Prioridades: Finance budget lite → CSV fingerprint → interaction log → house/travel ADR.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado** | archive; budget/CSV ainda defer → Iter 51+ |
| Phase 7 Health | **MVP utilizável** | + E2E route |
| Phase 8 Inventory | **MVP utilizável** | ADR-024 + polish + E2E |
| Phase 8 Relations | **Person MVP** | ADR-026 + Iter 47; interactions defer |
| Phase 8 House/travel | **Não iniciado** | ADR spike futuro |
| Phase 9 Sync | **ADR spike** | ADR-025; produto deferido |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Relations/People | Lista mínima + disclaimer — OK mobile |
| Inventory | Purchase/warranty fields — monitorar sheet length |
| Finance | Inalterado nesta janela; pronto para budget panel |
| Sync | Sem UI (correto) |

---

## 6. Checklist Iter 45 §7

| Ação | Status |
|------|--------|
| Relations/people ADR | ✅ Iter 46 |
| Person MVP lite | ✅ Iter 47 |
| Inventory polish purchase/warranty | ✅ Iter 48 |
| Inventory bootstrap E2E | ✅ Iter 49 |
| Pit stop | ✅ Iter 50 |
| Finance budget / CSV / interaction log | ⏳ → Iter 51+ |

---

## 7. Backlog Iter 51–60

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 51 | Finance budget lite (§23.7 monthly category limit) | Fecha lacuna §23 budgets |
| **P0** | 52 | Finance CSV export fingerprint stub | §23 polish / import prep |
| **P1** | 53 | Interaction log lite (Person §24.2) | Completa relations MVP |
| **P1** | 54 | Document core/ platform residual | Débito layering (doc-only) |
| **P2** | 55 | Pit stop meta-review | Protocolo LOOP |
| — | 56 | House/travel ADR spike (Phase 8) | Fecha planning Phase 8 |
| — | 57 | Inventory↔quest link lite **ou** People bootstrap E2E | Cross-feature / pirâmide |
| — | 58 | Organization ADR spike (§24.3) | Relations expand |
| — | 59 | Budget spent-vs-limit polish / alerts UI | §23 incremental |
| — | 60 | Pit stop | Protocolo |

**Defer:** loadouts/locations, sync product, Health Connect, Open Finance, IA, exams/appointments, envelope budgets multi-currency.

---

## Referências

- `META_REVIEW_ITER45.md`, ADR-015, ADR-024, ADR-025, ADR-026
- Iters 46–49 em `docs/dev/LOOP.md`
