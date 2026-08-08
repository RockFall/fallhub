# Meta-review — Iteração 40 (Day 0, iters 36–39)

Revisão arquitetural após quatro iterações (Iter 36–39). Health polish (edit + SymptomEntry), golden fixtures v13/v14, finance archive. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 39)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **71** testes |
| `flutter test packages/colony_domain` | **140** testes |
| `flutter test packages/colony_database` | **60** testes |
| **Total** | **271** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 39

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + SymptomEntry; FinancialAccount.isArchived; export **v14** | Correto |
| `packages/colony_database` | DB **v16**, symptom_entries, is_archived | Correto |
| `lib/features/health/` | edit + symptom timeline (Iters 36–37) | **Saudável** |
| `lib/features/finance/` | archive lite (Iter 39) | Estável |
| `lib/core/providers/` | shims + app_providers + feature_controllers | **Plataforma residual** (documentar, não migrar urgente) |

### Recomendações

1. Manter inbox/undo/export/onboarding em `core/` como plataforma até Phase 9.
2. Health/finance permanecem em features/.
3. Próxima fase major: Inventory ADR (Phase 8) antes de sync product.

---

## 2. Export v13 → v14 + DB v14 → v16

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v13** | v14 | `health_conditions` | ✅ fixture |
| **v14** | v15–v16 | `symptom_entries`; account `is_archived` (additive) | ✅ fixture + round-trip |

Write version permanece **v14** (is_archived default false em backups antigos).

Lacunas: appointments/exams OUT; budget/CSV deferidos.

---

## 3. Test pyramid

| Camada | Pós Iter 39 |
|--------|-------------|
| Domain | + SymptomEntry; export v14 schema; isArchived em net-worth |
| Repository | + symptom CRUD; archive account; migrations v14→v15→v16 |
| Widget | + health edit/symptom; finance archive |
| CI | gate local **271** testes |
| Integration | Bootstrap E2E (Iter 33) — sem health route ainda |

Prioridades: Inventory ADR → Inventory MVP lite → sync ADR.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado** | + archive conta |
| Phase 7 Health | **MVP utilizável** | conditions + edit + symptoms; exams OUT |
| Phase 8 Inventory | **Não iniciado** | próximo P0 ADR |
| Phase 9 Sync | **Deferido** | ADR spike após inventory |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Health | Edit sheet + symptom panel — monitorar scroll mobile |
| Finance | Archive remove da lista; txs históricas permanecem |
| Quest/Research | Inalterados |

---

## 6. Checklist Iter 35 §7

| Ação | Status |
|------|--------|
| Health edit condition | ✅ Iter 36 |
| SymptomEntry timeline | ✅ Iter 37 |
| Golden export v13/v14 | ✅ Iter 38 |
| Finance archive account | ✅ Iter 39 |
| Document core platform / migrate inbox | ⏳ → defer como P3 |
| Inventory ADR | ⏳ → Iter 41 P0 |
| Pit stop | ✅ Iter 40 |

---

## 7. Backlog Iter 41–50

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 41 | Phase 8 inventory ADR spike | Próxima fase major (doc-only) |
| **P0** | 42 | InventoryItem MVP lite | Vertical slice pós-ADR |
| **P1** | 43 | Sync ADR spike (Phase 9) | Doc-only; device/outbox |
| **P1** | 44 | Health route no bootstrap E2E | Pirâmide |
| **P2** | 45 | Pit stop meta-review | Protocolo LOOP |
| — | 46 | Finance budget lite **ou** relations/people ADR | Um slice |
| — | 47 | Inventory↔quest link lite | Cross-feature |
| — | 48 | Document core/ platform residual | Débito layering |
| — | 49 | CSV import stub fingerprint | §23 polish |
| — | 50 | Pit stop | Protocolo |

**Defer:** appointments/exams, Health Connect, Open Finance, sync product, IA.

---

## Referências

- `META_REVIEW_ITER35.md`, ADR-015, ADR-023
- Iters 36–39 em `docs/dev/LOOP.md`
