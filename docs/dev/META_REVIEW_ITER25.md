# Meta-review — Iteração 25 (Day 0, iters 21–24)

Revisão arquitetural após quatro iterações (Iter 21–24). Iter 21 fecha polish Finance categories; Iters 22–23 migram providers legacy; Iter 24 entrega quest↔research (ADR-022). **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós-implementação Iter 24)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **61** testes |
| `flutter test packages/colony_domain` | **125** testes |
| `flutter test packages/colony_database` | **53** testes |
| **Total** | **239** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 24

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + TransactionCategory, QuestResearchLink; export v12 | Correto |
| `packages/colony_database` | DB **v13**, `quest_research`, finance tables | Correto |
| `lib/features/quests/application/` | providers + controllers (Iter 22) | **Migrado** |
| `lib/features/pawn/application/` | providers + controllers (Iter 23) | **Migrado** |
| `lib/features/work/application/` | providers + controllers (Iter 23) | **Migrado** |
| `lib/features/research|finance/application/` | padrão desde Iters 15–19 | Estável |
| `lib/core/providers/` | shims + **projects/decisions** ainda concretos | **Parcial** |

### Recomendações

1. Completar migração `project_*` + `decision_*` → `features/*/application/` (shims em core/).
2. Manter research/finance/quests/pawn/work em features — não reverter para core/.
3. Quest detail shell + tabs permanece saudável; nova seção research na tab Relações (Iter 24) sem reinflar shell.

---

## 2. Export v11 → v12 + restore

| Export | Schema DB | Chaves novas | Restore |
|--------|-----------|--------------|---------|
| **v11** | v12 | finance entities/accounts/transactions | ✅ |
| **v12** | v13 | `quest_research_links` | ✅ round-trip Iter 24 |

FK order ADR-015 atualizada (delete/insert incluem `quest_research`).

Lacunas remanescentes: golden export JSON, teste E2E bootstrap+routing+DB.

---

## 3. Test pyramid

| Camada | Pós Iter 24 |
|--------|-------------|
| Domain | + TransactionCategory policy; export parse v12 quest research links |
| Repository | + finance edit/delete; quest↔research link; migration v12→v13; export v12 |
| Widget | + finance edit flow; quest research links na tab Relações |
| CI | `test_all.yml` — gate local **239** testes |
| Integration | Nenhum bootstrap E2E |

Prioridades pós-meta-review:
- **P2:** golden/schema export JSON
- **P3:** integration bootstrap mínimo

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §22 Research tree | **MVP avançado ~80%** | + links quest↔research (ADR-022) |
| §23 Finance ledger | **MVP parcial avançado** | Categories + edit/delete (Iter 21); falta filtros/período, edit conta |
| §23 categorization | **Entregue lite** | Iter 21 |
| Phase 5 Research | **MVP avançado** | Links cross-feature fechados |
| Phase 6 Finance | **Em progresso** | Filtros/período = próximo P0 |
| Phase 7+ Health/sync/IA | **Deferido** | ADR spike no backlog |

---

## 5. UX hub complexity

| Hub | Rotas / entry | Secções / acoplamento |
|-----|---------------|------------------------|
| **Quest detail** | `/quests/:id` | Tabs Conteúdo / Relações; + pesquisa vinculada (Iter 24) |
| **Research** | `/research`, `/research/:id` | Inalterado; picker reutilizado por quests |
| **Finance** | `/resources/finance` | Ledger + categories + edit/delete; sem filtros período |
| **Restore preview** | `/settings` | Export v12 |
| **Command palette** | global | Research, Finance |

Quest detail permanece shell fino; Relações acumula projects / research / prereqs / chain / decisions — monitorar scroll em telas pequenas.

---

## 6. Checklist Iter 19 §7

| Ação | Status |
|------|--------|
| Finance categories + edit/delete | ✅ Iter 21 |
| Migrar legacy core/providers | 🟡 Quests/pawn/work ✅; projects/decisions ⏳ |
| Quest↔research links | ✅ Iter 24 (ADR-022) |
| Health ADR spike | ⏳ |
| Golden export schema | ⏳ |
| Finance filtros/período | ⏳ → Iter 26 P0 |

---

## 7. Backlog Iter 26–35

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 26 | Finance filtros período + conta | §23 MVP utilizável; lista recente só |
| **P1** | 27 | Migrar project + decision providers → features/ | Fecha legacy core/ |
| **P2** | 28 | Finance account edit/archive lite | Conta criada sem edição |
| **P3** | 29 | Health ADR spike (Phase 7) | Próxima fase major |
| **P4** | 30 | Golden export JSON schema (v12) | Lacuna desde Iter 9 |
| — | 31 | Finance net-worth lite / sensitive polish | §23 extensão |
| — | 32 | Research node ↔ quest reverse view | Simetria UX |
| — | 33 | Integration bootstrap E2E mínimo | Pirâmide |
| — | 34 | Health check-in symptoms MVP (pós-ADR) | Phase 7 slice |
| — | 35 | Pit stop meta-review | Protocolo LOOP |

**Defer:** Open Finance, orçamento completo, patrimônio avançado, sync, IA, rubricas, spaced repetition.

---

## Referências

- `META_REVIEW_ITER19.md`, ADR-015, ADR-020, ADR-022
- Iters 21–24 em `docs/dev/LOOP.md`
