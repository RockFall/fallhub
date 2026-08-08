# Meta-review — Iteração 65 (Day 0, iters 61–64)

Revisão arquitetural após quatro iterações (Iter 61–64). Trip MVP, Organization MVP, Travel E2E, CSV import dedup. **Sem refactor-only code** nesta fase meta-review.

**Baseline verificado:** 2026-08-07 via `./tool/test_all.ps1` (pós Iter 64)

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros** |
| `flutter test` (app) | **82** testes |
| `flutter test packages/colony_domain` | **169** testes |
| `flutter test packages/colony_database` | **76** testes |
| **Total** | **327** testes |

---

## 1. Layering: `core/` vs `features/`

### Estado pós Iter 64

| Camada | Conteúdo | Avaliação |
|--------|----------|-----------|
| `packages/colony_domain` | Trip, Organization, FinanceCsvImportPolicy; export **v20** | Correto |
| `packages/colony_database` | DB **v22**, `trips`, `organizations` | Correto |
| `lib/features/travel/` | Trip lista/create/edit (61) + E2E (63) | **Saudável** |
| `lib/features/relations/` | Organizations MVP (62) | Estável |
| `lib/features/finance/` | CSV import paste + dedup (64) | Estável |
| `lib/core/providers/` | shims + plataforma | Residual P3 |

### Recomendações

1. Organizations E2E e membership Person↔Org são próximos naturais.
2. Home maintenance ainda OUT (ADR-027 defer).
3. Sync product permanece deferido (ADR-025).
4. Core shims: documentado; migrar só se tocar o arquivo.

---

## 2. Export v19 → v20 + DB v21 → v22

| Export | Schema DB | Chaves / campos | Restore |
|--------|-----------|-----------------|---------|
| **v19** | v21 | `trips` | ✅ |
| **v20** | v22 | `organizations` | ✅ |

Write version atual: **v20**.

Lacunas: membership N:N OUT; home maint OUT; sync outbox OUT; inventory↔quest OUT.

---

## 3. Test pyramid

| Camada | Pós Iter 64 |
|--------|-------------|
| Domain | + Trip; Organization; CSV import policy; export v19/v20 |
| Repository | + trips; orgs; migrations; CSV import dedup |
| Widget | + travel; organizations; finance import icon |
| CI | gate local **327** testes |
| Integration | Bootstrap E2E inclui **travel**; orgs ainda não |

Prioridades: Orgs E2E → membership stub **ou** inventory↔quest → home ADR → pit 70.

---

## 4. MVP vs spec

| Spec | Status | Notas |
|------|--------|-------|
| §23 Finance | **MVP avançado+** | CSV import dedup utilizável |
| Phase 7 Health | **MVP utilizável** | inalterado |
| Phase 8 Inventory | **MVP utilizável** | link quest defer |
| Phase 8 Relations | **Person+interactions+Org** | membership defer → 66+ |
| Phase 8 House/travel | **Trip MVP ✅** | home maint OUT |
| Phase 9 Sync | **ADR spike** | produto deferido |

---

## 5. UX hub complexity

| Hub | Notas |
|-----|-------|
| Finance | + import CSV — monitorar densidade mobile |
| Relations | People + Organizations — hub OK |
| Travel | Lista leve — OK |
| Core | Sem UI nova |

---

## 6. Checklist Iter 60 §7

| Ação | Status |
|------|--------|
| Trip MVP lite | ✅ Iter 61 |
| Organization MVP lite | ✅ Iter 62 |
| Travel bootstrap E2E | ✅ Iter 63 |
| CSV import fingerprint dedup | ✅ Iter 64 |
| Pit stop | ✅ Iter 65 |
| Orgs E2E / membership | ⏳ → Iter 66+ |

---

## 7. Backlog Iter 66–75

| Rank | Iter | Slice | Rationale |
|------|------|-------|-----------|
| **P0** | 66 | Organizations route no bootstrap E2E | Pirâmide |
| **P1** | 67 | Person↔Org membership stub **ou** inventory↔quest link lite | Cross-feature |
| **P1** | 68 | Home maintenance ADR spike (§25.3) | Fecha planning house |
| **P2** | 69 | Remove unused core/ shims (P3) **ou** Trip polish dates | Layering / UX |
| **P2** | 70 | Pit stop meta-review | Protocolo LOOP |
| — | 71 | Home maintenance MVP lite (pós-ADR) | Phase 8 house |
| — | 72 | Membership UI se 67 foi stub | Relations expand |
| — | 73 | Sync product lite OUTBOX stub (ADR-025) **ou** skip | Phase 9 cautela |
| — | 74 | Commitments ADR spike (§24.4) | Relations expand |
| — | 75 | Pit stop | Protocolo |

**Defer:** loadouts/GPS, Health Connect, Open Finance, IA, exams/appointments, ContextZone, multi-currency envelope.

---

## Referências

- `META_REVIEW_ITER60.md`, ADR-015, ADR-024–028, `CORE_PLATFORM.md`
- Iters 61–64 em `docs/dev/LOOP.md`
