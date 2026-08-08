# Meta-review — Iteração 14 (Day 0, iters 11–15)

Revisão arquitetural após cinco iterações (Iter 11–15). Iter 15 abre **Phase 5 Research** (ADR-017). **Sem refactor-only code** na fase meta-review.

**Baseline verificado:** 2026-08-06 via `./tool/test_all.ps1` (pós-implementação Iter 15)

| Gate | Resultado esperado |
|------|-------------------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | regressão + research widget tests |
| `flutter test packages/colony_domain` | + `research_node_test` |
| `flutter test packages/colony_database` | + migration v9→v10, export v9 |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 15

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + ResearchNode, policies, hierarchy | Correto |
| `packages/colony_database` | DB v10, ResearchRepository | Correto |
| `lib/core/providers/` | 12 arquivos — quests, projects, pawn, work, decisions | Threshold meta-review **atingido** |
| `lib/features/research/application/` | providers + controllers (Iter 15) | **Padrão adotado** para features novas |

### Recomendações

1. **Research** permanece em `features/research/application/` — não mover para `core/`.
2. Migrar quests/projects para `features/*/application/` em Iter 16+ (refactor incremental, não bloqueante).
3. Quest detail (~834 linhas) **inalterado** nesta iter — zero links research no detail (ADR-017).

---

## 2. Export v6 → v9 + restore

| Export | Schema DB | Chaves novas | Restore |
|--------|-----------|--------------|---------|
| **v6** | ≤ v7 | `daily_reviews`, `mood_factors` | ✅ pawn round-trip |
| **v7** | v8 | `weekly_reviews` | ✅ |
| **v8** | v9 | quest acceptance fields | ✅ QUEST-001 |
| **v9** | v10 | `research_nodes`, `research_prerequisite_links` | ✅ |

Lacunas pawn (Iter 11) **fechadas**. Restore preview inclui `research_nodes`.

---

## 3. Test pyramid

| Camada | Pós Iter 15 |
|--------|-------------|
| Domain | + research policy, WIP, hierarchy, export v9 parse |
| Repository | + research CRUD, export v9, quest accept gate |
| Widget | + research_list, research_prerequisite, quest paused resume |
| CI | `test_all.yml` (Iter 12) |

Lacunas remanescentes: golden export JSON, integration bootstrap E2E.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| Phase 4 QUEST-001 | **100%** | ADR-018 acceptance lite (Iter 14) |
| §22 Research tree | **MVP parcial** | Lista hierárquica; sem grafo/sessões/evidência |
| §61.2 quest lifecycle | Intencional | ADR-018; draft→active via acceptAndActivate |
| Phase 5 Research | **Iniciado** | Iter 15 ADR-017 |

---

## 5. UX hub complexity

- Quest detail: sem nova seção research (composição preservada).
- `/research` + command palette; lista hierárquica + detail + WIP=1.
- Restore preview: + `research_nodes` count label.

---

## 6. Checklist Iter 9 §6

| Ação | Status |
|------|--------|
| Export v6 pawn | ✅ Iter 11 |
| Weekly review | ✅ Iter 12 |
| Schedule 3-day | ✅ Iter 13 |
| Quest acceptance | ✅ Iter 14 |
| CI test_all | ✅ Iter 12 |
| Mover controllers para features/ | ⏳ Research feito; legacy em core/ |
| Golden export schema | ⏳ |
| Phase 5 research | ✅ Iter 15 MVP lista |

---

## 7. Backlog Iter 16+

| Rank | Slice | Rationale |
|------|-------|-----------|
| **P0** | Research sessions + evidence lite | §22.1; DB v11, export v10 |
| **P1** | Quest detail tabs / extrair relações | Meta-review limite composição |
| **P2** | Graph canvas §60.7 | Após lista estável |
| **P3** | Finance ADR spike | Phase 6 |
| **Defer** | Health, sync, IA | Phase 7+ |

---

## Referências

- `META_REVIEW_ITER9.md`, ADR-015, ADR-017, ADR-018
- Plan Iter 15 (f242eba3)
