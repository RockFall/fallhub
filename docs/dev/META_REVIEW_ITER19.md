# Meta-review — Iteração 20 (Day 0, iters 16–19)

Revisão arquitetural após quatro iterações de produto (Iter 16–19). Iter 19 abre **Phase 6 Finance** (ADR-020). **Sem refactor-only code** na fase meta-review.

**Baseline verificado:** 2026-08-06 via `./tool/test_all.ps1` (pós-implementação Iter 19)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** / 67 infos |
| `flutter test` (app) | **59** testes |
| `flutter test packages/colony_domain` | **119** testes |
| `flutter test packages/colony_database` | **49** testes |
| **Total** | **227** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 19

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + LearningSession, ResearchEvidence, graph layout, progress, finance entities/policies | Correto |
| `packages/colony_database` | DB v12, sessions/evidence, finance tables | Correto |
| `lib/core/providers/` | 12 arquivos — quests, projects, pawn, work, decisions | **Legacy** — threshold meta-review mantido |
| `lib/features/research/application/` | providers + controllers (Iters 15–18) | **Padrão adotado** |
| `lib/features/finance/application/` | providers + controllers (Iter 19) | **Padrão adotado** |

### Recomendações

1. **Research** e **Finance** permanecem em `features/*/application/` — não mover para `core/`.
2. Migrar quests/projects/pawn/work/decisions de `core/providers/` para `features/*/application/` em Iter 21+ (refactor incremental, não bloqueante).
3. Quest detail reduzido a shell ~132 linhas + tabs extraídas (Iter 17) — composição **melhorada** vs ~754 linhas pré-tabs.

---

## 2. Export v6 → v11 + restore

| Export | Schema DB | Chaves novas | Restore |
|--------|-----------|--------------|---------|
| **v6** | ≤ v7 | `daily_reviews`, `mood_factors` | ✅ pawn round-trip |
| **v7** | v8 | `weekly_reviews` | ✅ |
| **v8** | v9 | quest acceptance fields | ✅ QUEST-001 |
| **v9** | v10 | `research_nodes`, `research_prerequisite_links` | ✅ |
| **v10** | v11 | `learning_sessions`, `research_evidence` | ✅ demonstrate gate |
| **v11** | v12 | `financial_entities`, `financial_accounts`, `transactions` | ✅ |

Restore preview inclui labels para sessions, evidence e finance (`restoreCountLabel`). FK order ADR-015 atualizada até v11.

Lacunas remanescentes: golden export JSON, teste E2E bootstrap+routing+DB.

---

## 3. Test pyramid

| Camada | Pós Iter 19 |
|--------|-------------|
| Domain | + session/evidence policy, graph layout, progress, search filter, finance ledger, transaction category policy |
| Repository | + sessions/evidence CRUD, export v10–v11, finance CRUD, migration v10→v11, v11→v12 |
| Widget | + research session/evidence, graph canvas, quest tabs, finance ledger |
| CI | `test_all.yml` (Iter 12) — gate local 227 testes |
| Integration | Nenhum bootstrap E2E |

Lacunas remanescentes: golden export JSON, integration bootstrap, estados offline/erro em widgets finance.

Prioridades pós-meta-review:
- **P2:** golden/schema export JSON
- **P3:** integration bootstrap mínimo

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §22 Research tree | **MVP avançado ~75–80%** | Lista + sessões + evidência + grafo + busca + progress lite; sem rubricas/trilhas/spaced repetition |
| §22.1 demonstrate gate | **Entregue** | ADR-019; grandfathering migration |
| §60.7 graph canvas | **MVP lite** | ADR-021; sem minimapa/trilhas |
| §23 Finance ledger | **MVP parcial** | Entidades, contas, transações manuais; sem orçamento/patrimônio/import |
| §23 categorization | **Parcial** | Domain + picker existem; ADR-020 addendum Iter 21 para edit/delete polish |
| Phase 4 QUEST-001 | **100%** | Inalterado desde Iter 14 |
| §61.2 quest lifecycle | Intencional | ADR-018; draft→active via acceptAndActivate |
| Phase 5 Research | **MVP avançado** | Iters 15–18 |
| Phase 6 Finance | **Iniciado** | Iter 19 ADR-020 ledger MVP |
| Phase 7+ Health/sync/IA | **Deferido** | Sem ADR dedicado |

---

## 5. UX hub complexity

### Superfícies de integração

| Hub | Rotas / entry | Secções / acoplamento |
|-----|---------------|------------------------|
| **Quest detail** | `/quests/:id` | Tabs Conteúdo / Relações; shell ~132 linhas; relações isoladas |
| **Research** | `/research`, `/research/:id` | Toggle Lista/Grafo; busca; WIP=1; sessões/evidence panels; progress summary |
| **Finance** | `/resources/finance` | Ledger, contas, transações; disclaimer banner; toggle mascaramento |
| **Restore preview** | `/settings` | + sessions, evidence, finance entity counts |
| **Command palette** | global | Research, Finance entries |

Quest detail **desacoplado** vs meta-review Iter 14 (~834 linhas monolíticas). Research hub concentra complexidade visual (lista + grafo) mas permanece coeso em uma feature.

---

## 6. Checklist Iter 14 §6

| Ação | Status |
|------|--------|
| Research sessions + evidence lite | ✅ Iter 16 (ADR-019) |
| Quest detail tabs / extrair relações | ✅ Iter 17 |
| Graph canvas §60.7 | ✅ Iter 18 (ADR-021) |
| Finance ADR spike | ✅ Iter 17 ADR-020; impl Iter 19 |
| Mover controllers para features/ | ⏳ Research + Finance feitos; legacy 12 arquivos em `core/` |
| Golden export schema | ⏳ |
| Phase 5 research MVP lista | ✅ Iters 15–18 avançado |
| Phase 6 finance | ✅ Iter 19 ledger MVP |
| CI test_all | ✅ Iter 12 |

---

## 7. Backlog Iter 21+

| Rank | Slice | Rationale |
|------|-------|-----------|
| **P0** | Finance categories lite + edit/delete transaction polish | ADR-020 addendum; `category_id` já no schema |
| **P1** | Migrar legacy `core/providers/` → `features/*/application/` | Threshold atingido; research/finance provam padrão |
| **P2** | Quest↔research links | §22 cross-feature; evitar re-inflar quest detail |
| **P3** | Health ADR spike (Phase 7) | Próxima fase major; finanças MVP estabilizado |
| **P4** | Golden export JSON schema | Lacuna persistente desde Iter 9 |
| **Defer** | Open Finance, orçamento, patrimônio, sync, IA, rubricas, learning paths | Escopo grande; ADRs dedicados |

---

## Referências

- `META_REVIEW_ITER14.md`, ADR-015, ADR-017, ADR-019, ADR-020, ADR-021
- Plan Iter 16 (4c281ff2), Iter 17 (866a5322), Iter 18 (2e72f0b9), Iter 19
