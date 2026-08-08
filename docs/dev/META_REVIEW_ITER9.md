# Meta-review — Iteração 9 (Day 0, iters 6–10)

Revisão arquitetural após quatro iterações de vertical slices (Iter 6–9) e fechamento do segundo bloco de cinco iterações (Iter 10 = doc only). **Sem refactor-only code** nesta iteração.

**Baseline verificado:** 2026-08-06 via `./tool/test_all.ps1`

| Gate | Resultado |
|------|-----------|
| `flutter analyze` | **0 erros**, **43 infos** (`--no-fatal-infos`) |
| `flutter test` (app) | **31** passed |
| `flutter test packages/colony_domain` | **60** passed |
| `flutter test packages/colony_database` | **25** passed |
| **Total** | **116** tests, exit 0 |

Infos dominantes: `unnecessary_underscores` em Riverpod `.when(orElse: (_, __))`; 4× `deprecated_member_use` (`DropdownButtonFormField.value`); 1× `use_null_aware_elements` em `colony_repositories.dart`; 1× `depend_on_referenced_packages` (sqlite3 em test fixtures).

---

## 1. Layering: `core/` vs `features/`

### Estado atual (pós Iter 9)

| Camada | Conteúdo observado | Avaliação |
|--------|-------------------|-----------|
| `packages/colony_domain` | Entidades, policies, `ExportSnapshot`, enums | Correto |
| `packages/colony_database` | Drift, mappers, repositórios concretos, restore | Correto |
| `lib/core/providers/` | **12 arquivos** — providers + controllers transversais | Aceitável no MVP; crescendo |
| `lib/core/widgets/` | Command palette, quick capture | Correto |
| `lib/features/<name>/` | Screens, sheets, widgets de apresentação | Correto |

### Controllers/providers em `core/` (Iter 6–9 additions)

| Arquivo | Feature lógica | Cross-imports |
|---------|----------------|---------------|
| `decision_providers.dart`, `decision_controllers.dart` | Decisions | Quest detail |
| `project_providers.dart`, `project_controllers.dart` | Projects | Quest create/edit |
| `quest_providers.dart`, `quest_controllers.dart` | Quests | Projects, prerequisites |
| `work_providers.dart`, `work_controllers.dart` | Work/schedule | — |
| `pawn_providers.dart`, `pawn_controllers.dart` | Pawn/check-in/review | — |
| `feature_controllers.dart` | Restore, capture, undo | Settings |
| `app_providers.dart` | Profile, prefs, repos | Global |

### Desvios menores (herdados + novos)

- **Controllers permanecem em `core/`** apesar de 4+ features com lógica de aplicação. Iter 6–9 adicionou `DecisionController`, `RestoreController`, providers de chain/prerequisites — concentração aumentou.
- **Acoplamento de apresentação cross-feature**: `quest_detail_screen.dart` (~754 linhas) importa sheets de `decisions/`, `projects/` e widgets de prerequisites/chain. Padrão tolerável no MVP; alternativa futura: seções composáveis + callbacks ou feature flags por painel.
- **`RestoreController` em `feature_controllers.dart`**: settings dispara restore; repositório em `colony_database` — layering OK, mas UX destrutiva vive longe de pawn/export domain.
- **Repositórios sem ports no domínio**: inalterado; alinhado ao roadmap local-first.

### Recomendações (Iter 11+, não bloqueantes)

1. Manter regra: widgets nunca acessam Drift; apenas `repositoriesProvider`.
2. **Threshold para mover para `features/<name>/application/`**: feature com ≥3 controllers **ou** Iter 15 meta-review — o que vier primeiro.
3. ADR quando provider `core/` for consumido por ≥2 features (ex.: `questChainProvider` usado em detail + futuro colony hub).
4. Considerar extrair `quest_detail_screen` em painéis por domínio antes de adicionar research/finance links.

---

## 2. Export versioning (v1 → v5) + restore gaps

### Matriz versão export ↔ schema DB

| Export | Schema DB | Chaves JSON novas | Restore |
|--------|-----------|-------------------|---------|
| **v1** | ≤ v2 | `profile`, `preferences`, `tasks`, `events` + transversais | ✅ full replace |
| **v2** | v4 | `quests`, `tasks[].quest_id` | ✅ |
| **v3** | v5 | `projects`, `quest_project_links`, `quests.pause_reason` | ✅ |
| **v4** | v6 | `decision_records`, `quest_decision_links` | ✅ |
| **v5** | v7 | `quest_prerequisite_links` | ✅ round-trip |

Chaves transversais (presentes em export v5 completo; default `[]` se ausentes em backups antigos):
`work_priorities`, `bills`, `schedule_blocks`, `need_definitions`, `need_readings`, `check_ins`.

`buildSnapshot()` emite **version: 5**; `fromJson` aceita v1–v5; v>5 ou v<1 → `ExportSnapshotException`, sem mutação.

### Restore data-loss matrix (audit `_wipeAll` vs `ExportSnapshot`)

Audit em `RestoreRepository._wipeAll()` / `_insertAll()` e `ExportSnapshot` / `buildSnapshot()`:

| Tabela DB | Wipe | Export JSON | Insert on restore | Pós-restore |
|-----------|------|-------------|-------------------|-------------|
| `quest_decisions` | ✅ | `quest_decision_links` | ✅ | OK |
| `quest_prerequisites` | ✅ | `quest_prerequisite_links` | ✅ | OK |
| `quest_projects` | ✅ | `quest_project_links` | ✅ | OK |
| **`mood_factors`** | ✅ | **ausente** | **não** | **Perda:** fatores de humor por check-in |
| `need_readings` | ✅ | `need_readings` | ✅ | OK |
| `tasks` | ✅ | `tasks` | ✅ | OK |
| `domain_events` | ✅ | `events` | ✅ | OK |
| `check_ins` | ✅ | `check_ins` | ✅ | OK (sem filhos mood) |
| **`daily_reviews`** | ✅ | **ausente** | **não** | **Perda:** revisões diárias |
| `schedule_blocks` | ✅ | `schedule_blocks` | ✅ | OK |
| `bills` | ✅ | `bills` | ✅ | OK |
| `work_priorities` | ✅ | `work_priorities` | ✅ | OK |
| `decision_records` | ✅ | `decision_records` | ✅ | OK |
| `quests` | ✅ | `quests` | ✅ | OK |
| `projects` | ✅ | `projects` | ✅ | OK |
| `need_definitions` | ✅ | `need_definitions` | ✅ | OK |
| `preferences` | ✅ | `preferences` | ✅ | OK |
| `profiles` | ✅ | `profile` | ✅ | OK |

**Conclusão:** restore é **idempotente** para entidades exportadas. Duas lacunas causam **perda silenciosa de dados pawn** após backup/restore — **bug de integridade local-first**, não desvio intencional de spec.

### Lacunas documentadas

| Entidade | ADR | Impacto usuário | Fix proposto (Iter 11) |
|----------|-----|-----------------|------------------------|
| `daily_reviews` | ADR-015 (nota existente) | Histórico de reflexão diária some | Export **v6** + chave `daily_reviews` |
| `mood_factors` | ADR-015 (addendum Iter 10) | Tags/contexto de check-in somem | Export **v6** — chave `mood_factors` ou nested em check-ins |

`mood_factors` é filho FK de `check_ins` (`CheckInRepository.save` insere ambos). Export atual serializa check-ins sem fatores; wipe apaga fatores antes de check-ins — ordem FK-safe correta, mas dados órfãos no sentido inverso (check-in restaurado, fatores não).

### Regras adotadas (ADR-015, ADR-016)

1. Full replace transacional; sem merge parcial.
2. IDs preservados; evento `exportRestored` append-only pós-commit.
3. Versão export independente de `schemaVersion`.
4. Restore v4→[] prerequisites; v≤4→[] decision links quando aplicável.

---

## 3. Test pyramid — gaps

```
        /\
       /  \  E2E / integration (zero)
      /----\
     / widget \  ~18 testes app (quest, schedule, project, decision, restore)
    /----------\
   / repo + mig  \  colony_database: 25 (export restore v2–v5, migrations v3→v7)
  /----------------\
 /  domain unit     \  colony_domain: 60 (lifecycle, prereq, chain, schedule, export parse)
/--------------------\
```

| Camada | Cobertura | Lacunas |
|--------|-----------|---------|
| Domain unit | Quest/project lifecycle, prereq policy, chain topo sort, schedule conflict, export parse | Sem testes de `DailyReview`/`MoodFactor` factories; decision record policy mínima |
| Repository | CRUD, export v3–v5, restore fixtures, migrations | Sem teste explícito **perda** daily_reviews/mood_factors pós-restore |
| Widget | Fluxos felizes + alguns erros (prereq snackbar, restore confirm) | Poucos estados offline/erro rede; sem golden |
| Integration | Nenhum bootstrap+routing+DB | — |
| Export | `export_snapshot_test`, `export_restore_test` v2–v5 | Sem JSON schema/golden; lacunas pawn não assertadas |
| CI | `tool/test_all.ps1` local gate | **Não wired em CI**; Windows `native_assets` workaround no script |

Prioridades pós-meta-review:
- **P1 Iter 11:** teste restore prova perda → fix v6 prova round-trip pawn data
- **P2:** wire `test_all` em CI
- **P3:** golden/schema export JSON

---

## 4. MVP vs spec — desvios intencionais e bugs

| Spec | MVP atual | Tipo | Notas |
|------|-----------|------|-------|
| §61.2 quest lifecycle (Available/Accepted/Failed/Historical) | `draft/active/paused/completed/abandoned` | **Intencional** | Ativação direta; board “Histórico” cobre terminais |
| §61.3 project lifecycle | 3 estados + `ProjectLifecyclePolicy` bloqueia `active→archived` | **Intencional** | Iter 9 policy; UI complete→archive |
| §21.3 prerequisites | N:N + gate activate + export v5 | **Entregue** | ADR-016 |
| §21.6 chain view | `QuestChainPanel` read-only topo sort | **Entregue** | Iter 9 |
| §70.1 decision log | CRUD, links, browse `/decisions`, delete | **MVP parcial** | Sem matriz/premortem/links projeto |
| §46.6 export/restore | Full replace JSON; sem senha/manifest | **Intencional MVP** | Restore entregue Iter 8; criptografia fora |
| §28.4 weekly review | Só daily review (`/pawn/review`) | **Deferido** | Phase 4 roadmap |
| Export pawn data | daily_reviews + mood_factors wiped | **Bug** | Iter 11 export v6 |
| §45 Phase 5–7 research/finance/health | Não iniciado | **Deferido** | Pós export integrity |

**Confirmação quest lifecycle:** desvio permanece intencional até ignition engine ou sync multi-dispositivo.

---

## 5. UX hub complexity

### Superfícies de integração

| Hub | Rotas / entry | Secções / acoplamento |
|-----|---------------|------------------------|
| **Quest detail** | `/quests/:id` | Purpose, criteria, risks, deadline, next action, lifecycle actions, **projects**, **prerequisites**, **chain panel**, **decisions** — 4 imports cross-feature |
| **Colony home** | `/colony` | Active quests panel (≤3), needs summary — hub leve |
| **Settings restore** | `/settings` | File pick → preview counts → dupla confirmação → wipe — destrutivo, bem sinalizado |
| **Command palette** | global | 11 comandos; **sem** Pawn, Projects deep link além de list/create |
| **App shell nav** | 5 destinos | Inbox/Chronicle/Decisions só via “More” compact ou palette |

### Quest detail — limite de composição

~754 linhas, 4 `_Linked*Section` widgets privados + `QuestChainPanel`. Cada nova relação N:N (research, finance) aumenta scroll e imports. **Recomendação:** antes de Phase 5, extrair tabs ou accordion “Relações” vs “Conteúdo”.

### Restore UX

Preview usa `entityCounts` (não inclui daily_reviews/mood_factors — reforça lacuna invisível ao usuário). Iter 11 deve estender preview counts.

---

## 6. Prior meta-review action checklist (Iter 5)

Fonte: `META_REVIEW_ITER5.md` §5.

| Ação | Status | Evidência |
|------|--------|-----------|
| Iter 6: decision log MVP + export v4 + migration v6 | ✅ | ADR-014, LOOP Iter 6 |
| Restore ADR + implementação | ✅ | ADR-015, Iter 8 |
| Export round-trip import | ✅ | `export_restore_test`, settings restore UI |
| Mover controllers grandes para `features/*/application/` | ⏳ | 12 arquivos ainda em `core/providers/` |
| Teste schema export (json_schema / golden) | ⏳ | Só parse unit + fixtures v2–v5 |
| Reavaliar quest lifecycle (ignition/sync) | ⏳ | Aguardando roadmap |
| Wire `test:all` em CI | ⏳ | Script existe; sem workflow |
| Documentar lacunas export pawn | ✅ | ADR-015 + este doc |

---

## 7. Backlog ranqueado — Iter 11+

| Rank | Iteração sugerida | Slice | Rationale |
|------|-------------------|-------|-----------|
| **P0** | **Iter 11** | **Export v6: `daily_reviews` + `mood_factors`** | Maior risco local-first; restore já destrutivo para essas tabelas |
| **P1** | Iter 11 fast follow | Wire `tool/test_all` em CI | Gate manual não escala |
| **P2** | Iter 12 | Weekly review MVP (§28.4) | Phase 4; reutiliza padrões daily review |
| **P3** | Iter 13 | Schedule 3-day view | UX polish; day nav + timeline maduros |
| **P4** | Iter 14+ | Phase 5 research graph | Domínio novo; ADR-017; distinto de quest prereqs |
| **Defer** | TBD | Finance (Phase 6), Health (Phase 7) | ADRs dedicados; escopo grande |

### Iter 11 file targets (forward pointer)

- `packages/colony_domain/lib/src/export_snapshot.dart` — v6 fields + parse/serialize
- `packages/colony_database/.../colony_repositories.dart` — `buildSnapshot`, `_insertAll`
- `docs/adr/ADR-015-export-restore.md` — matriz v6
- Fixtures `export_v6.json`; `export_restore_test.dart`, `export_snapshot_test.dart`
- Teste regressão: seed daily_review + mood_factors → restore → assert counts

**Explicitamente fora de Iter 11 bundle único:** weekly review + schedule 3d + Phase 5 no mesmo slice.

---

## Referências

- `META_REVIEW_ITER5.md` (iters 1–5)
- ADR-014, ADR-015, ADR-016
- `export_snapshot.dart`, `RestoreRepository` em `colony_repositories.dart`
- Plan Iter 10 (`64f00b99`)
