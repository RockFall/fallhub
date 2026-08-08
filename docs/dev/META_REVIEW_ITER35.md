# Meta-review — Iteração 35 (Day 0, iters 26–34)

Revisão arquitetural após nove iterações de produto (Iter 26–34). Finance polish (filtros, conta, net-worth), providers legacy fechados para projects/decisions, Health ADR + check-in MVP (ADR-023). **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós gate Iter 34 + fixes inline)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** / 92 infos |
| `flutter test` (app) | **68** testes |
| `flutter test packages/colony_domain` | **136** testes |
| `flutter test packages/colony_database` | **55** testes |
| **Total** | **259** testes |

**Fixes de gate (retomada):** `ColonyPanel.title.toUpperCase()` restaurado; golden v12 = subset; fixture restore v12 espera `version: 12`.

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 34

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | + HealthCondition, HealthSafetyPolicy; export **v13** | Correto |
| `packages/colony_database` | DB **v14**, `health_conditions`, finance/research | Correto |
| `lib/features/{quests,pawn,work,projects,decisions}/application/` | providers migrados (Iters 22–27) | **Migrado** |
| `lib/features/{research,finance,health}/application/` | padrão features/ | Estável |
| `lib/core/providers/` | shims + **app_providers** + **feature_controllers** (inbox/undo/export/onboarding) | **Plataforma residual** |

### Recomendações

1. Tratar `app_providers` / `feature_controllers` como plataforma (não bloquear Phase 7/8).
2. Health permanece em `features/health/` — não mover para core/.
3. Completar critério ADR-023 “editar” na UI (saveCondition existe sem sheet).

---

## 2. Export v12 → v13 + restore

| Export | Schema DB | Chaves novas | Restore |
|--------|-----------|--------------|---------|
| **v12** | v13 | `quest_research_links` | ✅ fixture + round-trip |
| **v13** | v14 | `health_conditions` | ✅ schema golden + round-trip; **sem** `export_v13.json` fixture |

FK order ADR-015 atualizada até health.

Lacunas: golden fixture JSON v13 (espelhar Iter 30); SymptomEntry → futuro bump.

---

## 3. Test pyramid

| Camada | Pós Iter 34 |
|--------|-------------|
| Domain | + HealthSafetyPolicy; export schema v13; v12 keys = subset |
| Repository | + health CRUD; migration v13→v14; finance/research polish |
| Widget | + health screen; finance filters/net-worth; research reverse |
| CI | `test_all` — gate local **259** testes |
| Integration | Bootstrap E2E (Iter 33) colony/finance/research/quests |

Prioridades pós-meta-review:
- **P0:** Health edit UI
- **P1:** golden export_v13.json
- **P2:** SymptomEntry timeline lite

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §22 Research tree | **MVP avançado ~85%** | + reverse quest links (Iter 32) |
| §23 Finance ledger | **MVP avançado** | Filtros + edit conta + net-worth; falta archive conta, budget, CSV/OFX |
| Phase 6 Finance | **MVP utilizável** | Polish residual |
| Phase 7 Health | **MVP parcial** | Conditions create/list/archive; falta edit + symptoms |
| Phase 8 Inventory/relations | **Não iniciado** | Spec only |
| Phase 9 Sync | **Deferido** | ADR spike no backlog |

---

## 5. UX hub complexity

| Hub | Rotas / entry | Secções / acoplamento |
|-----|---------------|------------------------|
| **Quest detail** | `/quests/:id` | Tabs Conteúdo / Relações — estável |
| **Research** | `/research`, `/research/:id` | + linked quests reverse |
| **Finance** | `/resources/finance` | Ledger + filtros + patrimônio |
| **Health** | `/resources/health` | Disclaimer + lista + criar/arquivar |
| **Restore preview** | `/settings` | Export v13 |
| **Command palette** | global | + Saúde |

Health screen ainda fina; edit + symptoms não devem reinflar shell — painéis sob condição.

---

## 6. Checklist Iter 25 §7

| Ação | Status |
|------|--------|
| Finance filtros período + conta | ✅ Iter 26 |
| Migrar project + decision providers | ✅ Iter 27 |
| Finance account edit/archive lite | 🟡 edit ✅ Iter 28; archive ⏳ |
| Health ADR spike | ✅ Iter 29 (ADR-023) |
| Golden export schema v12 | ✅ Iter 30 |
| Finance net-worth lite | ✅ Iter 31 |
| Research↔quest reverse | ✅ Iter 32 |
| Bootstrap E2E | ✅ Iter 33 |
| Health check-in MVP | ✅ Iter 34 (edit UI gap) |
| Pit stop meta-review | ✅ Iter 35 |

---

## 7. Backlog Iter 36–45

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 36 | Health edit condition (status + sheet) | Fecha ADR-023 criar/editar/arquivar |
| **P0** | 37 | SymptomEntry timeline lite | §45 Phase 7; DB/export bump |
| **P1** | 38 | Golden `export_v13.json` + restore fixture | Lacuna vs Iter 30 pattern |
| **P1** | 39 | Finance archive account lite | Slip Iter 28 |
| **P2** | 40 | Documentar core/ platform residual **ou** migrate inbox lite | Débito layering |
| — | 41 | Phase 8 inventory ADR spike | Próxima fase major |
| — | 42 | Inventory MVP lite **ou** finance budget lite | Um slice só |
| — | 43 | Sync ADR spike (Phase 9) | Doc-only; sem código sync |
| — | 44 | Finance transfer-pair lite **ou** CSV stub | Só se Health estável |
| — | 45 | Pit stop meta-review | Protocolo LOOP |

**Defer:** appointments/exams, Health Connect/HealthKit, Open Finance, orçamento completo, sync product, IA, rubricas.

---

## Referências

- `META_REVIEW_ITER25.md`, ADR-015, ADR-020, ADR-022, ADR-023
- Iters 26–34 em `docs/dev/LOOP.md`
