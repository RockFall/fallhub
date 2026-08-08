# Loop de desenvolvimento contínuo



## Iteração 1 — CONCLUÍDA

**Escopo:** Fase 3 — Work grid, schedule, bills básico, rotas, providers, testes



**Entregue:**

- Domínio: WorkType, PriorityLevel, WorkPriority, Bill, ScheduleBlock

- DB v3: work_priorities, bills, schedule_blocks + repositórios

- UI: WorkScreen (grid tap-to-cycle), ScheduleScreen (dia), Bills section

- Rotas `/work`, `/work/schedule`; command palette; domain events

- Testes: priority cycle, repo save/load, widget grid



## Iteração 2 — CONCLUÍDA

**Escopo:** Fase 4 — Quest MVP (vertical slice)



**Entregue:**

- Domínio: Quest, QuestStatus, QuestLifecyclePolicy; questId em ColonyTask; EventTypes questCreated/questStatusChanged; ExportSnapshot v2

- DB v4: quests table, tasks.quest_id; QuestRepository CRUD + transições; export v2 com backfill

- UI: QuestBoardScreen (Ativas/Pausadas/Rascunhos/Histórico), QuestDetailScreen, CreateQuestSheet

- Ações: ativar, pausar, concluir, abandonar; vincular próxima ação (pick ou quick create)

- Rotas `/quests`, `/quests/:id`; command palette Missões/Nova missão; chronicle titles

- Testes: lifecycle policy, repo quest+export, widget board empty state



## Protocolo

1. Agente implementa slice completo

2. Agente revisor: erros, lacunas, melhorias

3. Agente planejador: próximos passos ideais

4. Coordenador implementa melhorias e inicia próxima iteração

5. A cada 5 iterações: revisão meta de arquitetura/UX



## Histórico

| # | Fase | Status | Notas |

|---|------|--------|-------|

| 0 | 0-2 Pawn/needs | concluído | Android-first, web guard |

| 1 | 3 Work/schedule | concluído | Grid prioridades, agenda dia, bills CRUD básico |

| 2 | 4 Quest MVP | concluído | Board, detail, lifecycle, task link, export v2 |

| 3 | 4b Quest authoring | concluído | Create/edit criteria & risks, validation, tests |

| 4 | 3b Schedule authoring | concluído | Day nav, deep link, add/edit/delete blocks, time pickers |
| 5 | 4c Projects + quality | concluído | Projects MVP, quest-project links, export v3, migrations |
| 6 | 4d Decision log MVP | concluído | DecisionRecord, quest-decision links, export v4, migration v6, meta-review |
| 7 | 3c Schedule timeline | concluído | Day timeline, overlap conflicts, project edit/status |
| 8 | 1a Export restore + decisions | concluído | Restore v1–v4, settings import, decision browse/delete/polish |
| 9 | 4e Quest prerequisites + chain | concluído | DB v7, export v5, ADR-016, chain view, test:all (analyze 0 erros), project lifecycle |
| 10 | Meta-review (iters 6–9) | concluído | META_REVIEW_ITER9.md; lacunas export pawn; backlog Iter 11 |
| 11 | Export v6 pawn restore | concluído | `daily_reviews` + `mood_factors`; ADR-015 v6; fixtures + round-trip |
| 12 | Weekly review MVP | concluído | §28.4; DB v8; export v7; preview labels; CI test_all |
| 13 | 3c Schedule 3-day view | concluído | Toggle Dia/3 dias; timeline+conflitos por dia; deep link preservado |
| 14 | 4f Quest acceptance lite | concluído | ADR-018; DB v9; export v8; QUEST-001 |
| 15 | Meta-review 11–15 + Research MVP | concluído | ADR-017; DB v10; export v9; lista hierárquica |
| 16 | Research sessions + evidence lite | concluído | ADR-019; DB v11; export v10; demonstrate gate |
| 17 | Quest detail tabs + research search | concluído | ADR-020 docs; sem migration/export bump |
| 18 | Graph canvas + progress lite | concluído | ADR-021; sem migration/export bump |
| 19 | Finance ledger MVP | concluído | ADR-020; DB v12; export v11; `/resources/finance` |
| 20 | Meta-review (iters 16–19) | concluído | META_REVIEW_ITER19.md; 227 testes; AGENTS.md Phase 5/6 |
| 21 | Finance categories + tx edit/delete | concluído | TransactionCategory enum; picker; edit/delete sheets; sem export bump |
| 22 | Quest providers → features/ | concluído | TIPO C; shims core/; 234 testes |
| 23 | Pawn+work providers → features/ | concluído | TIPO C; shims core/; 234 testes |
| 24 | Quest↔research links | concluído | ADR-022; DB v13; export v12; tab Relações |
| 25 | Meta-review (iters 21–24) | concluído | META_REVIEW_ITER25.md; 239 testes |
| 26 | Finance filtros período+conta | concluído | FinanceTransactionFilterPolicy; chips+dropdown |
| 27 | Project+decision providers → features/ | concluído | TIPO C; shims core/; legacy core fechado |
| 28 | Finance account edit lite | concluído | EditFinancialAccountSheet; saveAccount |
| 29 | Health ADR spike Phase 7 | concluído | ADR-023; doc-only; sem código produto |
| 30 | Golden export schema v12 | concluído | fixture + keys test + restore |
| 31 | Finance net-worth lite | concluído | FinanceNetWorthPolicy + UI patrimônio |
| 32 | Research↔quest reverse | concluído | watchLinkedQuests + painel no detail |
| 33 | Bootstrap E2E mínimo | concluído | DB+routing colony/finance/research/quests |
| 34 | Health check-in MVP | concluído | ADR-023; DB v14; export v13; gate 259 testes |
| 35 | Meta-review (iters 26–34) | concluído | META_REVIEW_ITER35.md; backlog 36–45 |
| 36 | Health edit condition | concluído | EditHealthConditionSheet; status; ADR-023 edit |
| 37 | SymptomEntry timeline lite | concluído | DB v15; export v14; painel + log sheet |
| 38 | Golden export v13+v14 fixtures | concluído | fixtures + restore tests |
| 39 | Finance archive account lite | concluído | isArchived; DB v16; UI archive |
| 40 | Meta-review (iters 36–39) | concluído | META_REVIEW_ITER40.md; backlog 41–50 |
| 41 | Inventory ADR spike Phase 8 | concluído | ADR-024; doc-only |
| 42 | InventoryItem MVP | concluído | DB v17; export v15; `/resources/inventory` |
| 43 | Sync ADR spike Phase 9 | concluído | ADR-025; doc-only |
| 44 | Health bootstrap E2E | concluído | rota `/resources/health` no E2E |
| 45 | Meta-review (iters 41–44) | concluído | META_REVIEW_ITER45.md; backlog 46–55 |
| 46 | Relations/people ADR spike | concluído | ADR-026; doc-only |
| 47 | Person MVP lite | concluído | DB v18; export v16; `/relations/people` |
| 48 | Inventory polish purchase/warranty | concluído | UI campos ADR-024; sem migration |
| 49 | Inventory bootstrap E2E | concluído | rota `/resources/inventory` no E2E |
| 50 | Meta-review (iters 46–49) | concluído | META_REVIEW_ITER50.md; 291 testes |
| 51 | Finance budget lite | concluído | DB v19; export v17; category_budgets |
| 52 | Finance CSV fingerprint stub | concluído | FinanceCsvCodec encode/parsePreview + share |
| 53 | Interaction log lite | concluído | DB v20; export v18; person_interactions |
| 54 | Document core/ platform | concluído | CORE_PLATFORM.md doc-only |
| 55 | Meta-review (iters 51–54) | concluído | META_REVIEW_ITER55.md; 307 testes |
| 56 | House/travel ADR spike | concluído | ADR-027 doc-only |
| 57 | People bootstrap E2E | concluído | rota `/relations/people` no E2E |
| 58 | Organization ADR spike | concluído | ADR-028 doc-only |
| 59 | Budget over-limit polish | concluído | barra + chip; clockProvider |
| 60 | Meta-review (iters 56–59) | concluído | META_REVIEW_ITER60.md; 308 testes |
| 61 | Trip MVP lite (ADR-027) | concluído | DB v21; export v19; `/resources/travel` |
| 62 | Organization MVP lite (ADR-028) | concluído | DB v22; export v20; `/relations/organizations` |
| 63 | Travel bootstrap E2E | concluído | rota `/resources/travel` no E2E |
| 64 | CSV import fingerprint dedup | concluído | FinanceCsvImportPolicy + persist stub |
| 65 | Meta-review (iters 61–64) | concluído | META_REVIEW_ITER65.md; 327 testes |
| 66 | Organizations bootstrap E2E | concluído | rota `/relations/organizations` no E2E |
| 67 | Person↔Org membership stub | concluído | DB v23; export v21; link/unlink UI |
| 68 | Home maintenance ADR spike | concluído | ADR-029 doc-only; produto →71 |
| 69 | Remove unused core/ shims | concluído | 10 shims apagados; CORE_PLATFORM.md |
| 70 | Meta-review (iters 66–69) | concluído | META_REVIEW_ITER70.md; 334 testes |
| 71 | Home maintenance MVP lite | concluído | DB v24; export v22; `/resources/home` |
| 72 | Home bootstrap E2E | concluído | rota `/resources/home` no E2E |
| 73 | inventory↔quest link lite | concluído | DB v25; export v23; UI edit item |
| 74 | Commitments ADR spike | concluído | ADR-030 doc-only; produto →76 |
| 75 | Meta-review (iters 71–74) | concluído | META_REVIEW_ITER75.md; 345 testes |
| 76 | Commitments MVP lite | concluído | ADR-030; DB v26; export v24; `/relations/commitments` |
| 77 | Commitments bootstrap E2E | concluído | rota `/relations/commitments` no E2E |
| 78 | Sync outbox stub local | concluído | ADR-025; DB v27; `/settings/sync`; noop worker |
| 79 | ContextZone ADR spike | concluído | ADR-031 doc-only; produto →81 |
| 80 | Meta-review (iters 76–79) | concluído | META_REVIEW_ITER80.md; 355 testes |
| 81 | ContextZone MVP lite | concluído | ADR-031; DB v28; export v25; `/resources/zones` |
| 82 | ContextZone bootstrap E2E | concluído | rota `/resources/zones` no E2E |
| 83 | Integrations Phase 10 ADR | concluído | ADR-032 doc-only; ICS stub →86+ |
| 84 | Storyteller/IA Phase 11 ADR | concluído | ADR-033 doc-only; rules digest →futuro |
| 85 | Meta-review (iters 81–84) | concluído | META_REVIEW_ITER85.md; 360 testes; backlog 86–95 |
| 86 | ICS import stub (ADR-032) | concluído | DB v29; export v26; `/settings/integrations` |
| 87 | NarrativeDigest rules_v1 | concluído | ADR-033; efêmero; weekly+chronicle UI |
| 88 | Integrations bootstrap E2E | concluído | rota `/settings/integrations` no E2E |
| 89 | Maturity Phase 12 ADR | concluído | ADR-034 doc-only; a11y →91+ |
| 90 | Meta-review (iters 86–89) | concluído | META_REVIEW_ITER90.md; 374 testes; backlog 91–100 |
| 91 | A11y baseline + Semantics lite | concluído | ADR-034; A11Y_BASELINE.md; Sync/ICS/Digest |
| 92 | Beta migration guarantees | concluído | BETA_MIGRATION_GUARANTEES.md + band test |
| 93 | Localization hubs 10–12 | concluído | L10N_HUBS_10_12.md; paste hint string |
| 94 | Digest period polish | concluído | período UTC no NarrativeDigest sheet |
| 95 | Meta-review (iters 91–94) | concluído | META_REVIEW_ITER95.md; backlog 96–110 depth |
| 96 | Golden export v26 fixture | concluído | export_v26.json + restore test |
| 97 | Zone↔Trip link lite | concluído | DB v30; export v27; zone_trips UI |
| 98 | Sync enqueue polish | concluído | trip+zone outbox; labels; pending count |
| 99 | NarrativeDigest rules depth | concluído | trip/zone/commitment signals |
| 100 | Meta-review (iters 96–99) | concluído | META_REVIEW_ITER100.md; backlog 101–110 |
| 101 | ICS→ScheduleBlock confirm | concluído | checkbox + meeting blocks |
| 102 | Performance smoke note | concluído | PERFORMANCE_SMOKE.md |
| 103 | Privacy/legal prep stub | concluído | PRIVACY_LEGAL_PREP.md |
| 104 | Gate unblock colony test | concluído | widget hang → repo policy test |
| 105 | Meta-review (iters 101–104) | concluído | META_REVIEW_ITER105.md; 388 testes |
| 106 | Home↔Inventory link UI | concluído | dropdown no edit sheet |
| 107 | Finance CSV import apply lite | concluído | plan→apply + fingerprint + account override |
| 108 | Commitment↔Quest link lite | concluído | DB v31 linked_quest_id; UI dropdown |
| 109 | Export golden v23–v25 fill | concluído | fixtures + restore tests |
| 110 | Meta-review (iters 106–109) | concluído | META_REVIEW_ITER110.md; 398 testes |
| 111 | Health appointment stub local | concluído | DB v32 / export v28; painel UI |
| 112 | Digest chronicle chip polish | concluído | ActionChip + signal chips + health signal |
| 113 | Packing list stub trip↔inventory | concluído | DB v33 / export v29; EditTripSheet |
| 114 | Sync processLocal snackbar polish | concluído | snackbar count/empty + loading |
| 115 | Meta-review (iters 111–114) | concluído | META_REVIEW_ITER115.md; 411 testes |
| 116 | Export golden v27 fixture | concluído | zone_trip_links restore |
| 117 | Export golden v28 fixture | concluído | health_appointments restore |
| 118 | Export golden v29 fixture | concluído | trip_inventory_links restore |
| 119 | Commitment list linked quest title | concluído | subtitle Missão: title |
| 120 | Meta-review (iters 116–119) | concluído | META_REVIEW_ITER120.md; 415 testes |
| 121 | Finance CSV import widget test | concluído | preview+apply snackbar; empty error |
| 122 | Zone capabilities edit polish | concluído | hints + unavailableWorkTypes UI |
| 123 | Trip packing empty-state hint | concluído | tripPackingEmptyHint |
| 124 | Health appointment mark-cancelled | concluído | cancel action + hide tile |
| 125 | Meta-review (iters 121–124) | concluído | META_REVIEW_ITER125.md; 420 testes |
| 126 | Zone unavailableWorkTypes subtitle | concluído | list subtitle Indisponível: |
| 127 | Health appointment mark-done widget | concluído | hide tile + status done |
| 128 | Finance CSV error widget paths | concluído | invalid + nothing-to-apply |
| 129 | Trip packing unlink widget path | concluído | unlink → empty hint |
| 130 | Meta-review (iters 126–129) | concluído | META_REVIEW_ITER130.md; 424 testes |
| 131 | Zone create sheet helpers smoke | concluído | CreateZoneSheet + save caps |
| 132 | Health appointments only-cancelled empty | concluído | empty when só cancelled |
| 133 | Commitment linked quest clear polish | concluído | helperText + clear test |
| 134 | Sync pending count chip polish | concluído | Chip no pending header |
| 135 | Meta-review (iters 131–134) | concluído | META_REVIEW_ITER135.md; 427 testes |
| 136 | Finance CSV account override widget | concluído | override → Poupança |
| 137 | Trip packing link-from-empty | concluído | link Adaptador from empty |
| 138 | Home linked inventory empty hint | concluído | helperText sem inventário |
| 139 | Zone list combined subtitle test | concluído | caps + unavailable juntos |
| 140 | Meta-review (iters 136–139) | concluído | META_REVIEW_ITER140.md; 431 testes |
| 141 | Commitment create sheet helper smoke | concluído | linked quest hint |
| 142 | Sync Chip absent when empty | concluído | assert no Chip |
| 143 | Finance CSV apply disabled until plan | concluído | FilledButton onPressed null |
| 144 | Packing picker empty snackbar | concluído | short pump snackbar |
| 145 | Meta-review (iters 141–144) | concluído | META_REVIEW_ITER145.md; 433 testes; backlog depth 146–155 |
| 146 | Finance edit CategoryBudget | concluído | EditCategoryBudgetSheet + saveBudget UI |
| 147 | Health edit/reschedule appointment | concluído | EditHealthAppointmentSheet + saveAppointment |
| 148 | Digest evidence → Chronicle deep-link | concluído | ?eventIds=&highlight=; TimelineLetter.highlighted |
| 149 | Research SkillRubricPolicy lite | concluído | levels 0–6 + stale hint; skill detail panel |
| 150 | Meta-review (iters 146–149) | concluído | META_REVIEW_ITER150.md; 444 testes; backlog 151–160 |
| 151 | Sync widen pilot enqueue | concluído | task/quest/inventory_item create → outbox |
| 152 | Digest signals + priority ranking | concluído | finance/research/inventory + prioritizeBullets |

## Iteração 152 — CONCLUÍDA

**Escopo:** Digest finance/research/inventory signals + priority ranking (META_REVIEW_ITER150 P1)

**Entregue:**

- `NarrativeDigestRules`: sinais `finance_activity`, `research_activity`, `inventory_activity`
- `prioritizeBullets` / `bulletPriority` ao capar em 7
- Strings chip/bullet; testes domain
- Sem migration/export bump

## Iteração 151 — CONCLUÍDA

**Escopo:** Sync widen pilot enqueue (META_REVIEW_ITER150 P0)

**Entregue:**

- Enqueue best-effort em `TaskRepository.capture`, `QuestRepository.create`, `InventoryRepository.create`
- Labels UI: tarefa/missão/inventário; hint sync atualizado
- Teste repo: task+quest+inventory na outbox
- Sem migration/export bump

## Iteração 150 — CONCLUÍDA

**Escopo:** Meta-review iters 146–149 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER150.md` — gate **444** (118 app + 220 domain + 106 database)
- Checklist 145 §7 fechado; backlog depth 151–160
- Sem código produto

## Iteração 149 — CONCLUÍDA

**Escopo:** Research SkillRubricPolicy lite (META_REVIEW_ITER145 P1)

**Entregue:**

- Domain: `SkillRubricPolicy` / `SkillRubricAssessment` (nível 0–6 + stale 60d)
- UI painel rubrica só em nós `skill`
- Strings pt-BR; testes domain + widget
- Sem migration/export bump; não persiste nível

## Iteração 148 — CONCLUÍDA

**Escopo:** Digest evidence → Chronicle deep-link (META_REVIEW_ITER145 P1 / ADR-033)

**Entregue:**

- Tap evidência no NarrativeDigestSheet → `/chronicle?eventIds=&highlight=`
- `ChronicleScreen` filtra, destaca e limpa filtro
- DS: `TimelineLetter.highlighted`
- Strings de filtro/ação; testes deep-link + tap
- Sem migration/export bump

## Iteração 147 — CONCLUÍDA

**Escopo:** Health Edit/reschedule appointment (META_REVIEW_ITER145 P0)

**Entregue:**

- `HealthController.saveAppointment`
- `EditHealthAppointmentSheet` (título, data/hora, local, profissional, notas)
- Botão editar no tile de consulta
- String `healthEditAppointment`
- Widget test: editar título
- Sem migration/export bump

## Iteração 146 — CONCLUÍDA

**Escopo:** Finance edit CategoryBudget (META_REVIEW_ITER145 P0)

**Entregue:**

- `FinanceController.updateBudget` → `saveBudget`
- `EditCategoryBudgetSheet` + botão editar no painel de orçamentos
- String `financeEditBudget`
- Testes: widget edit limit; repo saveBudget + `categoryBudgetUpdated`
- Sem migration/export bump

## Iteração 145 — CONCLUÍDA

**Escopo:** Meta-review iters 141–144 (protocolo LOOP / pit stop); reorientar backlog para depth de produto

**Entregue:**

- `docs/dev/META_REVIEW_ITER145.md` — gate **433** (112 app + 216 domain + 105 database)
- Checklist 140 §7 fechado; polish residual demoted
- Backlog 146–155 depth-first (budget edit, appointment edit, digest evidence, rubric lite, sync enqueue, …)
- Sem código produto

## Iteração 144 — CONCLUÍDA

**Escopo:** Packing picker empty snackbar (META_REVIEW_ITER140 P1)

**Entregue:**

- Widget test: link sem inventário → snackbar (pump curto)
- Sem migration/export bump

## Iteração 143 — CONCLUÍDA

**Escopo:** Finance CSV apply disabled until plan (META_REVIEW_ITER140 P1)

**Entregue:**

- Assert Apply `onPressed == null` antes do preview
- Sem migration/export bump

## Iteração 142 — CONCLUÍDA

**Escopo:** Sync Chip absent when outbox empty (META_REVIEW_ITER140 P1)

**Entregue:**

- `sync_status_screen_test` empty: `Chip` findsNothing
- Sem migration/export bump

## Iteração 141 — CONCLUÍDA

**Escopo:** Commitment create sheet helper smoke (META_REVIEW_ITER140 P0)

**Entregue:**

- `test/create_commitment_sheet_test.dart`: helper + no-quest option
- Sem migration/export bump

## Iteração 140 — CONCLUÍDA

**Escopo:** Meta-review iters 136–139 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER140.md` — gate **431** (110 app + 216 domain + 105 database)
- Backlog 141–150
- Sem código produto

## Iteração 139 — CONCLUÍDA

**Escopo:** Zone list capabilities+unavailable combined subtitle test (META_REVIEW_ITER135 P1)

**Entregue:**

- Widget test subtitle com caps e Indisponível
- Sem migration/export bump

## Iteração 138 — CONCLUÍDA

**Escopo:** Home maintenance linked inventory empty hint (META_REVIEW_ITER135 P1)

**Entregue:**

- HelperText vazio vs com itens no edit sheet
- AppStrings + widget test
- Sem migration/export bump

## Iteração 137 — CONCLUÍDA

**Escopo:** Trip packing link-from-empty path widget (META_REVIEW_ITER135 P1)

**Entregue:**

- Widget test: empty → link → item na lista
- Sem migration/export bump

## Iteração 136 — CONCLUÍDA

**Escopo:** Finance CSV account override dropdown widget (META_REVIEW_ITER135 P0)

**Entregue:**

- Widget test override conta destino no import sheet
- Sem migration/export bump

## Iteração 135 — CONCLUÍDA

**Escopo:** Meta-review iters 131–134 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER135.md` — gate **427** (106 app + 216 domain + 105 database)
- Backlog 136–145
- Sem código produto

## Iteração 134 — CONCLUÍDA

**Escopo:** Sync pending count chip polish (META_REVIEW_ITER130 P1)

**Entregue:**

- `SyncStatusScreen`: Chip com ícone + `syncPendingLabel`
- Assert `Chip` no widget test de pending
- Sem migration/export bump

## Iteração 133 — CONCLUÍDA

**Escopo:** Commitment linked quest clear/edit polish (META_REVIEW_ITER130 P1)

**Entregue:**

- HelperText create/edit commitment
- AppStrings `commitmentLinkedQuestHint`
- Widget test clear linked quest
- Sem migration/export bump

## Iteração 132 — CONCLUÍDA

**Escopo:** Health appointments empty when only cancelled (META_REVIEW_ITER130 P1)

**Entregue:**

- Widget test: appointment cancelled pré-seeded → empty state
- Sem migration/export bump

## Iteração 131 — CONCLUÍDA

**Escopo:** Zone create sheet capabilities helper smoke test (META_REVIEW_ITER130 P0)

**Entregue:**

- `test/create_zone_sheet_test.dart`: helpers + save capabilities/unavailable
- Sem migration/export bump

## Iteração 130 — CONCLUÍDA

**Escopo:** Meta-review iters 126–129 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER130.md` — gate **424** (103 app + 216 domain + 105 database)
- Backlog 131–140; nota hang `watch(...).first`
- Sem código produto

## Iteração 129 — CONCLUÍDA

**Escopo:** Trip packing unlink widget path (META_REVIEW_ITER125 P1)

**Entregue:**

- Extensão de `trip_packing_list_test`: unlink remove item e mostra empty+hint
- Sem migration/export bump

## Iteração 128 — CONCLUÍDA

**Escopo:** Finance CSV nothing-to-apply / invalid widget paths (META_REVIEW_ITER125 P1)

**Entregue:**

- `import_finance_csv_sheet_test`: CSV inválido + apply com só duplicatas
- Sem migration/export bump

## Iteração 127 — CONCLUÍDA

**Escopo:** Health appointment mark-done widget test (META_REVIEW_ITER125 P1)

**Entregue:**

- Widget test mark-done esconde tile e persiste `done`
- Sem migration/export bump

## Iteração 126 — CONCLUÍDA

**Escopo:** Zone unavailableWorkTypes list subtitle polish (META_REVIEW_ITER125 P0)

**Entregue:**

- `ZonesScreen` subtitle inclui `Indisponível: …`
- AppStrings `zoneUnavailableWorkTypesLabel`
- Widget test na lista
- Sem migration/export bump

## Iteração 125 — CONCLUÍDA

**Escopo:** Meta-review iters 121–124 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER125.md` — gate **420** (99 app + 216 domain + 105 database)
- Backlog 126–135
- Sem código produto

## Iteração 124 — CONCLUÍDA

**Escopo:** Health appointment mark-cancelled lite (META_REVIEW_ITER120 P1)

**Entregue:**

- `HealthController.markAppointmentCancelled`
- `HealthScreen`: botão cancelar + mark done
- AppStrings `healthAppointmentMarkCancelled`
- Domain test cancelled hidden; widget test hide tile
- Sem migration/export bump

## Iteração 123 — CONCLUÍDA

**Escopo:** Trip packing empty-state hint polish (META_REVIEW_ITER120 P1)

**Entregue:**

- `TripPackingListSection`: hint sob empty state
- AppStrings `tripPackingEmptyHint`
- Widget test empty packing
- Sem migration/export bump

## Iteração 122 — CONCLUÍDA

**Escopo:** Zone capabilities edit polish (META_REVIEW_ITER120 P1)

**Entregue:**

- HelperText capacidades + campo `unavailableWorkTypes` create/edit
- `ZonesController.create` aceita unavailableWorkTypes
- AppStrings hints
- Widget test save round-trip
- Sem migration/export bump

## Iteração 121 — CONCLUÍDA

**Escopo:** Finance CSV import widget test (META_REVIEW_ITER120 P0)

**Entregue:**

- `test/import_finance_csv_sheet_test.dart`: preview plan + apply snackbar + empty error
- Sem `pumpAndSettle` com SnackBar; sem ColonyScreen
- Sem migration/export bump

## Iteração 120 — CONCLUÍDA

**Escopo:** Meta-review iters 116–119 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER120.md` — gate **415** (94 app + 216 domain + 105 database)
- Backlog 121–130: CSV widget, zone capabilities, packing hint, appointment cancel
- Sem código produto

## Iteração 119 — CONCLUÍDA

**Escopo:** Commitment list shows linked quest title (META_REVIEW_ITER115 P1)

**Entregue:**

- `CommitmentsScreen`: subtitle inclui `Missão: {title}` via `questsProvider`
- AppStrings `commitmentLinkedQuestTitle`
- Widget test com compromisso vinculado
- Sem migration/export bump

## Iteração 118 — CONCLUÍDA

**Escopo:** Export golden v29 fixture (META_REVIEW_ITER115 P1)

**Entregue:**

- Fixture `export_v29.json` com `trip_inventory_links` + trip + inventory
- Restore test: packing links persistidos
- Sem migration/export write bump

## Iteração 117 — CONCLUÍDA

**Escopo:** Export golden v28 fixture (META_REVIEW_ITER115 P1)

**Entregue:**

- Fixture `export_v28.json` com `health_appointments`
- Restore test: appointment local persistido
- Sem migration/export write bump

## Iteração 116 — CONCLUÍDA

**Escopo:** Export golden v27 fixture (META_REVIEW_ITER115 P0)

**Entregue:**

- Fixture `export_v27.json` com `zone_trip_links` (+ trips/zones/ICS do v26)
- Restore test: parse v27 + persistência Zone↔Trip
- Sem migration/export write bump (write permanece v29)

## Iteração 115 — CONCLUÍDA

**Escopo:** Meta-review iters 111–114 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER115.md` — gate **411** (93 app + 216 domain + 102 database)
- DB **v33** / export write **v29**; P0 seguinte: Export golden v27 fixture
- Sem código produto

## Iteração 114 — CONCLUÍDA

**Escopo:** Sync processLocal snackbar polish (META_REVIEW_ITER110 P1)

**Entregue:**

- `SyncStatusScreen`: snackbar vazio / N processadas / erro; botão desabilitado + spinner enquanto processa
- AppStrings: `syncProcessLocalEmpty`, `syncProcessLocalError`, `syncProcessLocalDone`
- Widget tests: process 1 pendente → snackbar + empty; outbox vazia → snackbar empty
- Sem migration/export bump

## Iteração 113 — CONCLUÍDA

**Escopo:** Packing list stub trip↔inventory (META_REVIEW_ITER110 P1)

**Entregue:**

- Domínio: `TripInventoryLink` (N:N trip↔inventory; §26.1 stub)
- DB **v33**: `trip_inventory`; export write **v29** `trip_inventory_links[]`
- Repo: `listInventoryLinks` / `watchLinkedInventory` / link+unlink idempotente
- UI: `TripPackingListSection` em `EditTripSheet`; AppStrings
- ADR-015 v29 + ADR-027 addendum; testes domain/migration/repo/widget
- Sem PackingLoadout tipado (defer)

## Iteração 112 — CONCLUÍDA

**Escopo:** Digest chronicle chip polish (META_REVIEW_ITER110 P1)

**Entregue:**

- Chronicle: `ActionChip` com contagem de sinais do digest
- Sheet: Wrap de chips por `templateId` + label “Sinais detectados”
- Domínio: sinal `health_appointment_activity` (rules_v1)
- Strings L10N; testes domain + widget sheet
- Sem migration/export bump

## Iteração 111 — CONCLUÍDA

**Escopo:** Health appointment stub local (META_REVIEW_ITER110 P0)

**Entregue:**

- Domínio: `HealthAppointment` + status scheduled/done/cancelled
- DB **v32**: `health_appointments`; export write **v28** `health_appointments[]`
- ADR-023 addendum; UI painel + create sheet + mark done
- Testes: domain create/copyWith; migration v31→v32; export parse v28
- Disclaimer: lembrete local, não diagnostica

## Iteração 110 — CONCLUÍDA

**Escopo:** Meta-review iters 106–109 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER110.md` — gate **398** (91 app + 208 domain + 99 database)
- DB **v31** / export write **v27**; P0 seguinte: Health appointment stub local
- Sem código produto

## Iteração 109 — CONCLUÍDA

**Escopo:** Export golden v23–v25 fill (META_REVIEW_ITER105 P1)

**Entregue:**

- Fixtures: `export_v23.json` (quest↔inventory), `export_v24.json` (commitments), `export_v25.json` (context_zones)
- Restore tests cobrindo parse + persistência
- Sem migration/export write bump

## Iteração 108 — CONCLUÍDA

**Escopo:** Commitment↔Quest link lite (META_REVIEW_ITER105 P1)

**Entregue:**

- Domínio: `Commitment.linkedQuestId` + copyWith clear
- DB **v31**: `commitments.linked_quest_id` FK → quests; migration fixture phase 30
- Export: serializa/parse `linked_quest_id` (sem bump de versão — campo opcional)
- UI: dropdown missões não-terminais em create/edit commitment
- Testes: domain copyWith; migration v30→v31 persist/clear
- Export write permanece **v27**

## Iteração 107 — CONCLUÍDA

**Escopo:** Finance CSV import apply lite (META_REVIEW_ITER105 P1)

**Entregue:**

- Domínio: `FinanceCsvImportPolicy.withAccountOverride`; plan `hasWork`; fingerprint opcional em `LedgerTransaction.create`
- Repo: `planCsvImport` (sem write) + `applyCsvImport` (preserva fingerprint, `SourceType.import`)
- UI: sheet em 2 passos Analisar → Aplicar; override opcional de conta destino
- Testes: policy remap/hasWork; plan não persiste; apply preserva fingerprint externo; accountOverride
- Sem migration/export bump

## Iteração 106 — CONCLUÍDA

**Escopo:** Home↔Inventory link UI (META_REVIEW_ITER105 P0)

**Entregue:**

- EditHomeMaintenanceSheet: dropdown de inventário ativo → `linkedInventoryItemId`
- AppStrings + repo test link persist
- Campo já existia em domínio/DB (ADR-029); fatia fecha UI
- Sem migration/export bump

## Iteração 105 — CONCLUÍDA

**Escopo:** Meta-review iters 101–104 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER105.md` — gate **388** (91 app + 205 domain + 92 database)
- P0 seguinte: Home↔Inventory link UI
- Sem código produto

## Iteração 104 — CONCLUÍDA

**Escopo:** Unblock app test suite (colony_active_quests hang)

**Entregue:**

- `colony_active_quests_test` deixou de usar ColonyScreen/`pumpAndSettle` (hang Windows + Drift streams)
- Cobertura da regra “máx 3 missões” via `quests.listAll` + `.take(3)`
- Log: widget ColonyScreen hung sob native_assets/sqlite3 neste host; bootstrap E2E ainda cobre rota Colônia
- Sem migration/export bump

## Iteração 103 — CONCLUÍDA

**Escopo:** Privacy/legal prep doc stub (META_REVIEW_ITER100 P1)

**Entregue:**

- `docs/dev/PRIVACY_LEGAL_PREP.md` — princípios já no código + pendências formais
- Sem código produto

## Iteração 102 — CONCLUÍDA

**Escopo:** Performance smoke note (META_REVIEW_ITER100 P1)

**Entregue:**

- `docs/dev/PERFORMANCE_SMOKE.md` — alvos cold-start/hubs + hotspots Windows sqlite
- Sem código produto

## Iteração 101 — CONCLUÍDA

**Escopo:** ICS→ScheduleBlock confirm lite (META_REVIEW_ITER100 P0)

**Entregue:**

- Domínio: `IcsSchedulePolicy` (mode meeting; filter ranges)
- `ScheduleRepository.create` aceita `sourceType`
- Integrations: checkbox “Criar blocos na agenda” → schedule blocks com `SourceType.integration`
- Testes: domain policy + repo ICS→schedule
- Sem migration/export bump

## Iteração 100 — CONCLUÍDA

**Escopo:** Meta-review iters 96–99 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER100.md` — DB v30 / export v27; backlog 101–110
- P0 seguinte: ICS→ScheduleBlock confirm lite
- Sem código produto

## Iteração 99 — CONCLUÍDA

**Escopo:** NarrativeDigest rules depth (META_REVIEW_ITER95 P1)

**Entregue:**

- `NarrativeDigestRules`: sinais `trip_activity`, `zone_activity`, `commitment_activity`
- AppStrings bullets localizados
- Domain test para novos sinais
- Sem migration/export bump
- Gate na Iter 100

## Iteração 98 — CONCLUÍDA

**Escopo:** Sync enqueue polish (META_REVIEW_ITER95 P1)

**Entregue:**

- Outbox enqueue em create de Trip e ContextZone (além de Commitment)
- Sync UI: labels de entity type + contagem pendente; hint atualizado
- Testes: repo enqueue + widget pending trip
- Sem migration/export bump

## Iteração 97 — CONCLUÍDA

**Escopo:** Zone↔Trip link lite (META_REVIEW_ITER95 P0 / §25–26)

**Entregue:**

- Domínio: `ZoneTripLink`; export v27 `zone_trip_links`
- DB v30: `zone_trips` + migration v29→v30; mappers + ContextZoneRepository link/unlink/watch
- UI: `ZoneLinkedTripsSection` no EditZoneSheet; AppStrings
- Testes: domain, migration, repo, export schema v27, widget
- Docs: BETA_MIGRATION_GUARANTEES, ADR-015 max 27, AGENTS/PIPELINE
- Gate parcial: packages + widget verdes; suite completa na Iter 98

## Iteração 96 — CONCLUÍDA

**Escopo:** Golden export v26 fixture + restore (META_REVIEW_ITER95 P0)

**Entregue:**

- `packages/colony_database/test/fixtures/export_v26.json` — zones, commitments, ICS consent/events, trip
- Restore test: `restore v26 fixture preserves zones, commitments and ICS`
- Sem migration/export bump
- Gate: restore v26 verde (suite completa na Iter 97)

## Iteração 95 — CONCLUÍDA

**Escopo:** Meta-review iters 91–94 (protocolo LOOP / pit stop)

**Entregue:**

- `docs/dev/META_REVIEW_ITER95.md` — Phase 12 MVP fechado; lacuna golden v26; plano depth 96–110
- P0 seguinte: Golden export v26 fixture + Zone↔Trip link
- Sem código produto
- Gate herdado **375** testes (89 app + 199 domain + 87 database)

## Iteração 94 — CONCLUÍDA

**Escopo:** Digest UI polish — período da janela (META_REVIEW_ITER90 P2)

**Entregue:**

- `AppStrings.narrativeDigestPeriod` + linha no sheet
- Widget test assert `Período:`
- Sem migration/export bump
- Gate **375** testes (89 app + 199 domain + 87 database)

## Iteração 93 — CONCLUÍDA

**Escopo:** Localization completeness pass hubs 10–12 (META_REVIEW_ITER90 P1)

**Entregue:**

- `docs/dev/L10N_HUBS_10_12.md` inventário
- Hint ICS → `AppStrings.integrationsPasteHint`
- Sem migration/export bump
- Gate **375** testes (89 app + 199 domain + 87 database)

## Iteração 92 — CONCLUÍDA

**Escopo:** Beta migration guarantees doc (META_REVIEW_ITER90 P1)

**Entregue:**

- `docs/dev/BETA_MIGRATION_GUARANTEES.md` — DB v29 / export v26 band
- Domain test: parse aceita 1…26, rejeita 0/27
- Sem migration/export bump
- Gate **375** testes (89 app + 199 domain + 87 database)

## Iteração 91 — CONCLUÍDA

**Escopo:** A11y baseline + Semantics lite (ADR-034 / META_REVIEW_ITER90 P0)

**Entregue:**

- `docs/dev/A11Y_BASELINE.md` — checklist + hubs cobertos
- Semantics + identifiers em Integrations, Sync, NarrativeDigest sheet
- Widget tests: texto + presença de Semantics
- Sem migration/export bump
- Gate **374** testes (89 app + 198 domain + 87 database)

## Iteração 90 — CONCLUÍDA

**Escopo:** Meta-review iters 86–89 (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER90.md` — Phase 10–11 MVP; export v26/DB v29; backlog 91–100
- P0 seguinte: A11y baseline + Semantics lite (ADR-034)
- Sem código produto
- Gate **374** testes (89 app + 198 domain + 87 database)

## Iteração 89 — CONCLUÍDA

**Escopo:** Phase 12 maturity ADR spike (META_REVIEW_ITER85 P2)

**Entregue:**

- `docs/adr/ADR-034-maturity-phase12-spike.md` — a11y/DoD first, OUT certificação clínica/legal
- Sem código produto / sem migration
- Gate **374** testes (89 app + 198 domain + 87 database)

## Iteração 88 — CONCLUÍDA

**Escopo:** Integrations bootstrap E2E (META_REVIEW_ITER85 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/settings/integrations`
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **374** testes (89 app + 198 domain + 87 database)

## Iteração 87 — CONCLUÍDA

**Escopo:** NarrativeDigest rules_v1 Phase 11 (ADR-033 / META_REVIEW_ITER85 P1)

**Entregue:**

- Domínio: `NarrativeDigest`, `NarrativeDigestBullet`, `NarrativeDigestRules` (rules_v1)
- Efêmero — sem migration/export bump
- UI: sheet em Revisão semanal + Crônica; strings localizadas + disclaimer
- Feature `lib/features/storyteller/`
- Gate **374** testes (89 app + 198 domain + 87 database)

## Iteração 86 — CONCLUÍDA

**Escopo:** ICS import stub Phase 10 (ADR-032 / META_REVIEW_ITER85 P0)

**Entregue:**

- Domínio: `IntegrationConsent`, `ExternalCalendarEvent`, `IcsCodec` (VEVENT preview)
- DB **v29**: `integration_consents`, `external_calendar_events` + `IntegrationRepository`
- Export **v26**: consents + eventos ICS; ADR-015
- UI: `/settings/integrations` opt-in + import .ics / colar + preview/confirm
- Testes: codec/consent + schema v26 + migration v28→v29 + widget
- Gate **370** testes (88 app + 195 domain + 87 database)

## Iteração 85 — CONCLUÍDA

**Escopo:** Meta-review iters 81–84 (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER85.md` — ContextZone+ADRs 032/033; export v25/DB v28; backlog 86–95
- P0 seguinte: ICS import stub (ADR-032)
- AGENTS.md / PIPELINE.md fases 9–12 atualizadas
- Sem código produto
- Gate **360** testes (87 app + 187 domain + 86 database)

## Iteração 84 — CONCLUÍDA

**Escopo:** Storyteller/IA ADR spike Phase 11 (META_REVIEW_ITER80 P2)

**Entregue:**

- `docs/adr/ADR-033-storyteller-ia-phase11-spike.md` — rules first, NarrativeDigest, OUT LLM remoto
- Sem código produto / sem migration
- Gate **360** testes (87 app + 187 domain + 86 database)

## Iteração 83 — CONCLUÍDA

**Escopo:** Integrations Phase 10 ADR spike (META_REVIEW_ITER80 P1)

**Entregue:**

- `docs/adr/ADR-032-integrations-phase10-spike.md` — ICS import stub, opt-in, OUT Health Connect/Open Finance
- Sem código produto / sem migration
- Gate **360** testes (87 app + 187 domain + 86 database)

## Iteração 82 — CONCLUÍDA

**Escopo:** ContextZone bootstrap E2E (META_REVIEW_ITER80 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/resources/zones` após home
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **360** testes (87 app + 187 domain + 86 database)

## Iteração 81 — CONCLUÍDA

**Escopo:** ContextZone MVP lite (ADR-031 / META_REVIEW_ITER80 P0)

**Entregue:**

- Domínio: `ContextZone` + `ZoneConnectivity`
- DB **v28**: `context_zones` + `ContextZoneRepository`
- Export **v25**: `context_zones[]`; ADR-015
- UI: `/resources/zones` lista/create/edit/archive; command palette; float menu
- Testes: domain + schema v25 + migration v27→v28 + widget
- Gate **360** testes (87 app + 187 domain + 86 database)

## Iteração 80 — CONCLUÍDA

**Escopo:** Meta-review iters 76–79 (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER80.md` — Commitments+Sync stub; export v24/DB v27; backlog 81–90
- P0 seguinte: ContextZone MVP lite (ADR-031)
- Sem código produto
- Gate **355** testes (86 app + 184 domain + 85 database)

## Iteração 79 — CONCLUÍDA

**Escopo:** ContextZone ADR spike §25.2 (META_REVIEW_ITER75 P2)

**Entregue:**

- `docs/adr/ADR-031-context-zone-mvp.md` — ContextZone MVP, UI, export, OUT GPS/geofence/auto
- Sem código produto / sem migration
- Gate **355** testes (86 app + 184 domain + 85 database)

## Iteração 78 — CONCLUÍDA

**Escopo:** Sync outbox stub local (ADR-025 / META_REVIEW_ITER75 P1)

**Entregue:**

- Domínio: `DeviceIdentity`, `SyncOperation`, `SyncOpKind`, `SyncOpStatus`
- DB **v27**: `device_identities`, `sync_operations` + `SyncRepository`
- Pilot enqueue em `CommitmentRepository.create`; `processLocalNoop` sem rede
- UI: `/settings/sync` status + disclaimer; command palette; float menu
- Export: outbox **não** entra no snapshot (wipe no restore); write permanece **v24**
- Testes: domain + migration v26→v27 + widget
- Gate **355** testes (86 app + 184 domain + 85 database)

## Iteração 77 — CONCLUÍDA

**Escopo:** Commitments bootstrap E2E (META_REVIEW_ITER75 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/relations/commitments` após organizations
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **351** testes (85 app + 182 domain + 84 database)

## Iteração 76 — CONCLUÍDA

**Escopo:** Commitments MVP lite (ADR-030 / META_REVIEW_ITER75 P0)

**Entregue:**

- Domínio: `Commitment` + `CommitmentStatus` (open/kept/broken/cancelled)
- DB **v26**: `commitments` + `CommitmentRepository`
- Export **v24**: `commitments[]`; ADR-015
- UI: `/relations/commitments` lista/create/edit/status; command palette; float menu
- Testes: domain + schema v24 + migration v25→v26 + widget
- Gate **351** testes (85 app + 182 domain + 84 database)

## Iteração 75 — CONCLUÍDA

**Escopo:** Meta-review iters 71–74 (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER75.md` — Phase 8 MVP fechada; export v23/DB v25; backlog 76–85
- P0 seguinte: Commitments MVP lite (ADR-030)
- Sem código produto
- Gate **345** testes (84 app + 178 domain + 83 database)

## Iteração 74 — CONCLUÍDA

**Escopo:** Commitments ADR spike §24.4 (META_REVIEW_ITER70 P2)

**Entregue:**

- `docs/adr/ADR-030-commitments-mvp.md` — Commitment MVP, UI, export, OUT scoring/sync
- Sem código produto / sem migration
- Gate **345** testes (84 app + 178 domain + 83 database)

## Iteração 73 — CONCLUÍDA

**Escopo:** inventory↔quest link lite (META_REVIEW_ITER70 P1)

**Entregue:**

- Domínio: `QuestInventoryLink`
- DB **v25**: `quest_inventory`; link/unlink/watch no InventoryRepository
- Export **v23**: `quest_inventory_links`; ADR-015
- UI: painel missões no edit inventory item
- Testes: domain + schema + migration + repo
- Gate **345** testes (84 app + 178 domain + 83 database)

## Iteração 72 — CONCLUÍDA

**Escopo:** Home bootstrap E2E (META_REVIEW_ITER70 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/resources/home` após travel
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **341** testes (84 app + 176 domain + 81 database)

## Iteração 71 — CONCLUÍDA

**Escopo:** Home maintenance MVP lite (ADR-029 / META_REVIEW_ITER70 P0)

**Entregue:**

- Domínio: `HomeMaintenanceTask` + `markDone` cadence
- DB **v24**: `home_maintenance_tasks` + `HomeMaintenanceRepository`
- Export **v22**: `home_maintenance_tasks`; ADR-015
- UI: `/resources/home` lista/create/edit/markDone/archive; command palette; float menu
- Testes: domain + schema + migration + fixture + widget
- Gate **341** testes (84 app + 176 domain + 81 database)

## Iteração 70 — CONCLUÍDA

**Escopo:** Meta-review iters 66–69 (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER70.md` — layering limpo, export v21/DB v23, backlog 71–80
- P0 seguinte: Home maintenance MVP lite (ADR-029)
- Sem código produto
- Gate **334** testes (83 app + 172 domain + 79 database)

## Iteração 69 — CONCLUÍDA

**Escopo:** Remove unused core/ shims (META_REVIEW_ITER65 P2)

**Entregue:**

- Removidos 10 shims `lib/core/providers/{quest,pawn,work,project,decision}_*.dart` (zero callers)
- `docs/dev/CORE_PLATFORM.md` atualizado
- Sem migration/export bump
- Gate esperado: **334** testes (analyze infos de dangling_library nos shims eliminados)

## Iteração 68 — CONCLUÍDA

**Escopo:** Home maintenance ADR spike §25.3 (META_REVIEW_ITER65 P1)

**Entregue:**

- `docs/adr/ADR-029-home-maintenance-mvp.md` — HomeMaintenanceTask MVP, rota, export bump, OUT checklist/Location/sync
- ADR-027 aponta para ADR-029; AGENTS.md Phase 8 atualizado
- Sem código produto / sem migration
- Gate **334** testes (83 app + 172 domain + 79 database)

## Iteração 67 — CONCLUÍDA

**Escopo:** Person↔Org membership stub (META_REVIEW_ITER65 P1)

**Entregue:**

- Domínio: `PersonOrganizationLink` (role opcional)
- DB **v23**: tabela `person_organizations`; `OrganizationRepository` link/unlink/watch/list
- Export **v21**: chave `person_organization_links`; restore FK-safe; ADR-015/028
- UI: painéis em edit person/org; strings localizadas
- Testes: domain + migration + repo + fixture + widget
- Gate **334** testes (83 app + 172 domain + 79 database)

## Iteração 66 — CONCLUÍDA

**Escopo:** Organizations route no bootstrap E2E (META_REVIEW_ITER65 P0)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/relations/organizations` após people
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **327** testes (82 app + 169 domain + 76 database)

## Iteração 65 — CONCLUÍDA

**Escopo:** Pit stop meta-review (iters 61–64) — doc-only

**Entregue:**

- `docs/dev/META_REVIEW_ITER65.md` — layering, export/DB v20/v22, pirâmide, MVP vs spec, backlog 66–75
- Plano P0: Orgs E2E (66); membership/inventory link (67); home ADR (68); pit 70
- Baseline gate **327** testes (82 app + 169 domain + 76 database); analyze 0 erros
- Sem código produto

## Iteração 64 — CONCLUÍDA

**Escopo:** CSV import persist stub com dedup por fingerprint (§23.9 / META_REVIEW_ITER60 P1)

**Entregue:**

- Domínio: `FinanceCsvImportPolicy` (new vs duplicate + dedup intra-arquivo)
- `FinanceRepository.importCsvPreview` persiste só fingerprints novos
- UI: `ImportFinanceCsvSheet` + ícone upload no ledger
- Testes: policy + repo import; sem migration/export bump
- Gate **327** testes (82 app + 169 domain + 76 database)

## Iteração 63 — CONCLUÍDA

**Escopo:** Travel route no bootstrap E2E (META_REVIEW_ITER60 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/resources/travel` após inventory
- Asserts title + disclaimer + empty state
- Sem migration/export bump
- Gate **324** testes (82 app + 167 domain + 75 database)

## Iteração 62 — CONCLUÍDA

**Escopo:** Organization MVP lite (ADR-028 / META_REVIEW_ITER60 P0)

**Entregue:**

- Domínio: `Organization`, `OrganizationKind`; eventos organizationCreated/Updated/Archived
- DB v22: tabela `organizations` + `OrganizationRepository`; export write **v20**
- UI: `features/relations/` — OrganizationsScreen + sheets; rota `/relations/organizations`
- Fixture `export_v20.json` + migration v21→v22 + widget tests
- Gate **324** testes (82 app + 167 domain + 75 database)

## Iteração 61 — CONCLUÍDA

**Escopo:** Trip MVP lite (ADR-027 / META_REVIEW_ITER60 P0)

**Entregue:**

- Domínio: `Trip`, `TripStatus`; eventos tripCreated/Updated/StatusChanged
- DB v21: tabela `trips` + `TripRepository`; export write **v19** com `trips[]`
- UI: `features/travel/` — lista, create/edit sheets, concluir; rota `/resources/travel`
- Fixture `export_v19.json` + migration v20→v21 + widget empty/list
- Gate **316** testes (80 app + 163 domain + 73 database)

## Iteração 60 — CONCLUÍDA

**Escopo:** Pit stop meta-review (iters 56–59) — doc-only

**Entregue:**

- `docs/dev/META_REVIEW_ITER60.md` — layering, export/DB, pirâmide, MVP vs spec, UX, checklist, backlog 61–70
- Plano P0: Trip MVP (61) → Organization MVP (62); E2E travel (63); cross-feature/CSV (64); pit 65
- Baseline gate **308** testes (78 app + 159 domain + 71 database); analyze 0 erros
- Sem código produto

## Iteração 59 — CONCLUÍDA

**Escopo:** Budget spent-vs-limit polish / over-limit UI (META_REVIEW_ITER55 P1)

**Entregue:**

- Painel orçamento: LinearProgressIndicator + chip dentro/acima do limite
- `financeBudgetProgressProvider` usa `clockProvider` (testável)
- Widget test over-limit; strings `financeBudgetWithinLimit`
- Sem migration/export bump; gate **308** testes (78 app + 159 domain + 71 database)

## Iteração 58 — CONCLUÍDA

**Escopo:** Organization/factions ADR spike (§24.3 / META_REVIEW_ITER55 P1) — doc-only

**Entregue:**

- `docs/adr/ADR-028-organization-mvp.md` — Organization MVP + rota `/relations/organizations`; OUT membership/CRM
- Critérios de aceite para 1ª slice produto
- Sem código produto; gate herdado (**307** testes)

## Iteração 57 — CONCLUÍDA

**Escopo:** People route no bootstrap E2E (META_REVIEW_ITER55 P0)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/relations/people` após inventory
- Assert disclaimer + empty state
- Sem migration/export bump; gate **307** testes (app count estável — mesmo test file)

## Iteração 56 — CONCLUÍDA

**Escopo:** Phase 8 house/travel ADR spike (META_REVIEW_ITER55 P0) — doc-only

**Entregue:**

- `docs/adr/ADR-027-house-travel-mvp.md` — Trip MVP + rota `/travel`; OUT zones/bookings/home maintenance
- Critérios de aceite para 1ª slice produto (Iter 61+)
- Sem código produto / sem migration; gate herdado (**307** testes)

## Iteração 55 — CONCLUÍDA (PIT STOP)

**Escopo:** Meta-review doc-only (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER55.md` — 7 seções; baseline **307** testes (77+159+71)
- Backlog P0–P2 Iters 56–65 (House/travel ADR → People E2E → org ADR)
- `AGENTS.md` / `PIPELINE.md` fases atualizadas

## Iteração 54 — CONCLUÍDA

**Escopo:** Documentar `lib/core/` residual (META_REVIEW_ITER50 P1) — doc-only

**Entregue:**

- `docs/dev/CORE_PLATFORM.md` — inventário plataforma vs shims; regras; débito P3
- Sem código produto; gate herdado Iter 53 (**307** testes: 77+159+71)

## Iteração 53 — CONCLUÍDA

**Escopo:** Person interaction log lite (§24.2 / META_REVIEW_ITER50 P1)

**Entregue:**

- Domínio: `PersonInteraction`, `InteractionKind`
- DB **v20**: `person_interactions`; `logInteraction` atualiza `lastInteractionAt`
- Export **v18**: chave `person_interactions`; fixture + restore; ADR-015/026
- UI: botão registrar interação na lista de pessoas + sheet
- Gate **307** testes (77 app + 159 domain + 71 database)

## Iteração 52 — CONCLUÍDA

**Escopo:** Finance CSV export + fingerprint stub (§23.9 / META_REVIEW_ITER50 P0)

**Entregue:**

- Domínio: `FinanceCsvCodec` (encode com fingerprint; `parsePreview` stub sem persistir)
- UI: botão export CSV no ledger → SharePlus
- Strings pt-BR; testes domain + widget ícone
- Sem migration/export bump; gate **302** (77+156+69)

## Iteração 51 — CONCLUÍDA

**Escopo:** Finance budget lite — limite mensal por categoria (§23.7 / META_REVIEW_ITER50 P0)

**Entregue:**

- Domínio: `CategoryBudget`, `FinanceBudgetPolicy` (spent/remaining mês UTC)
- DB **v19**: `category_budgets`; métodos em `FinanceRepository`
- Export **v17**: chave `category_budgets`; fixture + restore; ADR-015
- UI: painel orçamentos no ledger + create sheet; spent vs limit
- Testes domain/schema/migration/restore/widget; gate **298** (77+152+69)

## Iteração 50 — CONCLUÍDA (PIT STOP)

**Escopo:** Meta-review doc-only (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER50.md` — 7 seções; baseline **291** testes (77 app + 148 domain + 66 database)
- Backlog P0–P2 Iters 51–60 (Finance budget → CSV stub → interaction log → house/travel ADR)
- `AGENTS.md` / `PIPELINE.md` fases atualizadas

## Iteração 49 — CONCLUÍDA

**Escopo:** Inventory route no bootstrap E2E (META_REVIEW_ITER45 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/resources/inventory` após health
- Assert empty state
- Sem migration/export bump

## Iteração 48 — CONCLUÍDA

**Escopo:** Inventory polish — purchase/warranty fields UI (META_REVIEW_ITER45 P1)

**Entregue:**

- Create/edit sheets: data de compra, preço+moeda, fim da garantia
- Lista mostra preço quando informado
- Strings pt-BR; widget test preço
- Sem migration/export bump

## Iteração 47 — CONCLUÍDA

**Escopo:** Person MVP lite (ADR-026 / META_REVIEW_ITER45 P0)

**Entregue:**

- Domínio: `Person`; eventos personCreated/Updated/Archived
- DB **v18**: `people`; `PersonRepository` CRUD + archive
- Export **v16**: chave `people`; fixture + restore round-trip; ADR-015
- UI: `/relations/people` lista + create/edit/archive; disclaimer; command palette
- Providers em `features/relations/application/`
- Testes domain/schema/migration/restore/widget

## Iteração 46 — CONCLUÍDA

**Escopo:** Phase 8 relations/people ADR spike (META_REVIEW_ITER45 P0) — doc-only

**Entregue:**

- `docs/adr/ADR-026-relations-people-mvp.md` — Person MVP + rota `/relations/people`; OUT orgs/interactions/sync
- Critérios de aceite para Iter 47 vertical slice
- Sem código produto / sem migration; gate herdado Iter 44 (**281** testes)

## Iteração 45 — CONCLUÍDA (PIT STOP)

**Escopo:** Meta-review doc-only (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER45.md` — 7 seções; baseline **281** testes (74 app + 144 domain + 63 database)
- Backlog P0–P2 Iters 46–55 (Relations ADR → Person MVP → sync product defer)
- `AGENTS.md` / `PIPELINE.md` fases atualizadas

## Iteração 44 — CONCLUÍDA

**Escopo:** Health route no bootstrap E2E (META_REVIEW_ITER40 P1)

**Entregue:**

- `test/bootstrap_e2e_test.dart` navega `/resources/health` após finance
- Assert disclaimer + empty state
- Sem migration/export bump

## Iteração 43 — CONCLUÍDA

**Escopo:** Phase 9 sync ADR spike (META_REVIEW_ITER40 P1) — doc-only

**Entregue:**

- `docs/adr/ADR-025-sync-local-first-spike.md` — outbox, E2EE, conflitos, OUT remoto/UI
- Critérios de aceite para 1ª slice produto sync (deferida)
- Sem código produto / sem migration; gate herdado Iter 42 (**281** testes: 74 app + 144 domain + 63 database)

## Iteração 42 — CONCLUÍDA

**Escopo:** InventoryItem MVP lite (ADR-024 / META_REVIEW_ITER40 P0)

**Entregue:**

- Domínio: `InventoryItem`, `InventoryCategory`, `InventoryItemStatus`; eventos inventory*
- DB **v17**: `inventory_items`; `InventoryRepository` CRUD + archive
- Export **v15**: chave `inventory_items`; fixture + restore round-trip; ADR-015
- UI: `/resources/inventory` lista + create/edit/archive; command palette; More menu
- Providers em `features/inventory/application/`
- Testes domain/schema/migration/restore/widget

## Iteração 41 — CONCLUÍDA

**Escopo:** Phase 8 inventory ADR spike (META_REVIEW_ITER40 P0) — doc-only

**Entregue:**

- `docs/adr/ADR-024-inventory-local-mvp.md` — InventoryItem MVP + rota `/resources/inventory`; OUT loadouts/locations/sync
- Critérios de aceite para Iter 42 vertical slice
- Sem código produto / sem migration; gate herdado Iter 39 (**271** testes)

## Iteração 40 — CONCLUÍDA (PIT STOP)

**Escopo:** Meta-review doc-only (protocolo LOOP)

**Entregue:**

- `docs/dev/META_REVIEW_ITER40.md` — 7 seções; baseline **271** testes (71 app + 140 domain + 60 database)
- Backlog P0–P4 Iters 41–50 (Inventory ADR → Inventory MVP → sync ADR)
- `AGENTS.md` / `PIPELINE.md` fases atualizadas

## Iteração 39 — CONCLUÍDA

**Escopo:** Finance archive account lite (META_REVIEW_ITER35 P1)

**Entregue:**

- Domínio: `FinancialAccount.isArchived`; net-worth ignora arquivadas
- DB **v16**: coluna `is_archived` (migração só se from ≥ 12)
- Export: campo `is_archived` (default false; sem bump de versão — write permanece v14)
- UI: botão arquivar no edit; lista/filtro só contas ativas
- Testes migration + widget; `./tool/test_all.ps1` pass — **271** testes (71 app + 140 domain + 60 database)

## Iteração 38 — CONCLUÍDA

**Escopo:** Golden export fixtures v13/v14 (META_REVIEW_ITER35 P1, alinhado write atual)

**Entregue:**

- `export_v13.json` — health_conditions sem symptoms
- `export_v14.json` — health + symptom_entries + finance/research
- Restore fixture tests v13/v14
- `./tool/test_all.ps1` pass — **269** testes (70 app + 140 domain + 59 database)

## Iteração 37 — CONCLUÍDA

**Escopo:** SymptomEntry timeline lite (META_REVIEW_ITER35 P0)

**Entregue:**

- Domínio: `SymptomEntry`; evento `symptomEntryLogged`
- DB **v15**: `symptom_entries`; migration fixture phase 14; `HealthRepository.logSymptomEntry`
- Export **v14**: chave `symptom_entries`; restore FK-safe; ADR-015/023
- UI: `SymptomTimelinePanel` + `LogSymptomEntrySheet` no edit de condição
- Testes domain/schema/migration/restore/widget; `./tool/test_all.ps1` pass — **267** testes (70 app + 140 domain + 57 database)

## Iteração 36 — CONCLUÍDA

**Escopo:** Health edit condition (META_REVIEW_ITER35 P0)

**Entregue:**

- UI: `EditHealthConditionSheet` (título, tipo, status active/monitoring/resolved, severidade, região, notas)
- `HealthScreen` tap-to-edit; `resolvedAt` set/clear por status
- Strings `healthEditCondition`, `healthConditionStatus`
- Widget test edit flow; `./tool/test_all.ps1` pass — **260** testes (69 app + 136 domain + 55 database)
- Sem migration/export bump

## Iteração 35 — CONCLUÍDA (PIT STOP)

**Escopo:** Meta-review doc-only (protocolo LOOP / PIPELINE)

**Entregue:**

- `docs/dev/META_REVIEW_ITER35.md` — 7 seções; baseline **259** testes (68 app + 136 domain + 55 database)
- Backlog P0–P4 Iters 36–45 (Health polish → inventory ADR → sync spike)
- `AGENTS.md` / `PIPELINE.md` fases atualizadas
- Gate Iter 34 fechado na retomada (ColonyPanel uppercase, golden v12 subset, fixture v12 version)

## Iteração 34 — CONCLUÍDA

**Escopo:** Health check-in symptoms MVP (ADR-023 / META_REVIEW_ITER25)

**Entregue:**

- Domínio: `HealthCondition`, `HealthSafetyPolicy`; eventos health*
- DB **v14**: `health_conditions`; `HealthRepository` CRUD + archive
- Export **v13**: chave `health_conditions`; restore FK-safe; ADR-015
- UI: `/resources/health`, disclaimer, lista, criar, arquivar; command palette
- Testes domain + migration + widget; `./tool/test_all.ps1` pass — **259** testes (68 app + 136 domain + 55 database)

## Iteração 33 — CONCLUÍDA

**Escopo:** Integration bootstrap E2E mínimo (META_REVIEW_ITER25)

**Entregue:**

- `test/bootstrap_e2e_test.dart` — perfil seedado + GoRouter estático
- Navega `/colony` → `/resources/finance` → `/research` → `/quests`
- TearDown com flush de timers Drift/stream
- Sem migration/export bump; `./tool/test_all.ps1` pass — **252** testes (66 app + 132 domain + 54 database)

## Iteração 32 — CONCLUÍDA

**Escopo:** Research node ↔ quest reverse view (META_REVIEW_ITER25)

**Entregue:**

- DB: `ResearchRepository.watchLinkedQuests`
- Providers/controllers: `researchLinkedQuestsProvider`, `setLinkedQuests`/`unlinkQuest`; invalidação cruzada
- UI: `ResearchLinkedQuestsPanel` + `QuestPickerSheet` no detail de pesquisa
- Strings pt-BR; testes repo reverse + widget
- Sem migration/export bump; `./tool/test_all.ps1` pass — **251** testes (65 app + 132 domain + 54 database)

## Iteração 31 — CONCLUÍDA

**Escopo:** Finance net-worth lite / sensitive polish (META_REVIEW_ITER25)

**Entregue:**

- Domínio: `FinanceNetWorthPolicy` + `NetWorthByCurrency` (soma por moeda; máscara all-or-nothing)
- Providers: `financeNetWorthProvider`, `financeNetWorthMaskedProvider`
- UI: card Patrimônio na ledger; hint “Fora do patrimônio”; create account com toggles include/mask
- Strings pt-BR; testes domain + widget exclusão
- Sem migration/export bump; `./tool/test_all.ps1` pass — **250** testes (64 app + 132 domain + 54 database)

## Iteração 30 — CONCLUÍDA

**Escopo:** Golden export JSON schema v12 (P4 META_REVIEW_ITER25)

**Entregue:**

- Fixture `packages/colony_database/test/fixtures/export_v12.json`
- Domain test `export_schema_v12_test` — chaves top-level canônicas
- Restore fixture preserva quest↔research + finance
- Sem bump de versão; `./tool/test_all.ps1` pass — **247** testes (63 app + 130 domain + 54 database)

## Iteração 29 — CONCLUÍDA

**Escopo:** Health ADR spike (Phase 7) — doc-only

**Entregue:**

- `docs/adr/ADR-023-health-local-mvp.md` — MVP HealthCondition + disclaimer; OUT exames/Health Connect/red flags
- Baseline estável pós-Iter 28; sem migration/export bump nesta iter
- `AGENTS.md` Phase 7+ aponta ADR-023
- Próximo: Iter 30 golden export JSON (P4) ou health MVP pós-ADR

## Iteração 28 — CONCLUÍDA

**Escopo:** Finance account edit lite (P2 META_REVIEW_ITER25)

**Entregue:**

- `FinanceController.updateAccount` → `saveAccount`
- `EditFinancialAccountSheet` (nome, instituição, tipo, patrimônio, máscara)
- Tap na conta abre edição; strings pt-BR; widget test
- Sem migration/export bump; `./tool/test_all.ps1` pass — **245** testes (63 app + 129 domain + 53 database)

## Iteração 27 — CONCLUÍDA

**Escopo:** Migrar `project_*` + `decision_*` → `features/*/application/` (TIPO C; fecha legacy)

**Entregue:**

- `lib/features/projects/application/`, `lib/features/decisions/application/`
- Shims re-export em `lib/core/providers/`
- Imports atualizados em presentation projects/decisions/quests + feature_controllers
- Sem migration/export bump; `./tool/test_all.ps1` pass — **244** testes

## Iteração 26 — CONCLUÍDA

**Escopo:** Finance filtros período + conta (P0 META_REVIEW_ITER25)

**Entregue:**

- Domínio: `FinancePeriod`, `FinanceTransactionFilterPolicy`
- Providers: `financePeriodFilterProvider`, `financeAccountFilterProvider`, `filteredLedgerTransactionsProvider`
- UI: ChoiceChips 7/30/90/tudo + dropdown conta na ledger
- Strings pt-BR; testes domain + widget período
- Sem migration/export bump; `./tool/test_all.ps1` pass — **244** testes (62 app + 129 domain + 53 database)

## Iteração 25 — CONCLUÍDA

**Escopo:** Meta-review protocolo LOOP (iters 21–24) — arquitetura, export v12, test pyramid, MVP Phase 6; **sem código de produto**

**Entregue:**

- `docs/dev/META_REVIEW_ITER25.md` — 7 seções + backlog Iter 26–35
- Baseline `./tool/test_all.ps1`: **239** testes (61 app + 125 domain + 53 database)
- `AGENTS.md`: Phase 6 avançada (categories + quest↔research); legacy providers parcialmente migrados
- Próximo: Iter 26 P0 finance filtros período

## Iteração 24 — CONCLUÍDA

**Escopo:** Quest↔research links N:N (tab Relações; sem reinflar quest detail)

**Entregue:**

- Domínio: `QuestResearchLink`; ADR-022
- DB **v13**: tabela `quest_research`; `ResearchRepository` link/unlink/watch/list
- Export **v12**: chave `quest_research_links`; restore FK-safe; ADR-015 atualizado
- UI: `QuestLinkedResearchSection` + `ResearchNodePickerSheet` na tab Relações
- Testes: domain parse v12, migration v12→v13, repo link, export round-trip, widget Relações
- `./tool/test_all.ps1` pass — **239** testes (61 app + 125 domain + 53 database)

## Iteração 23 — CONCLUÍDA

**Escopo:** Migrar `pawn_*` + `work_*` providers/controllers → `features/*/application/` (TIPO C)

**Entregue:**

- `lib/features/pawn/application/pawn_providers.dart`, `pawn_controllers.dart`
- `lib/features/work/application/work_providers.dart`, `work_controllers.dart`
- Shims re-export em `lib/core/providers/`
- Imports atualizados em presentation pawn/work, colony_screen, `test/schedule_screen_test.dart`
- Sem migration/export bump; `./tool/test_all.ps1` pass — **234** testes

## Iteração 22 — CONCLUÍDA

**Escopo:** Migrar `quest_providers` + `quest_controllers` → `features/quests/application/` (TIPO C, zero behavior change)

**Entregue:**

- `lib/features/quests/application/quest_providers.dart`, `quest_controllers.dart`
- Shims re-export em `lib/core/providers/quest_*.dart`
- Imports atualizados em presentation/quests, colony_screen, `test/quest_board_test.dart`
- Sem migration/export bump; `./tool/test_all.ps1` pass — **234** testes (60 app + 124 domain + 50 database)

## Iteração 21 — CONCLUÍDA

**Escopo:** Finance categories lite + transaction edit/delete (P0 FIN-001) per META_REVIEW_ITER19 §7

**Entregue:**

- Domínio: `TransactionCategory`, `TransactionCategoryPolicy` (IDs `cat_*`, validação, filtro por direction)
- `LedgerTransaction.create`/`copyWith` com `categoryId`; repo `createTransaction`/`saveTransaction` validam categoria
- UI: `TransactionCategoryPicker` em `AddTransactionSheet`; `EditTransactionSheet` (edit + delete confirmado); tap em transação recente
- `FinanceController`: `updateTransaction`, `deleteTransaction`
- Strings pt-BR: categoria, editar/excluir transação
- ADR-020 addendum categorias lite
- Testes: `transaction_category_test`, repo save/delete, widget edit flow
- Sem migration DB; export permanece **v11**
- `./tool/test_all.ps1` pass

## Iteração 20 — CONCLUÍDA

**Escopo:** Meta-review protocolo LOOP (iters 16–19) — arquitetura, export v6–v11, test pyramid, MVP spec Phase 5–6; **sem código de produto**

**Entregue:**

- `docs/dev/META_REVIEW_ITER19.md` — 7 seções: layering, export v6–v11, test pyramid, MVP spec deviations, UX hub complexity, checklist Iter 14, backlog Iter 21+
- `./tool/test_all.ps1` baseline: **227** testes (59 app + 119 domain + 49 database), analyze **0 erros / 67 infos**
- `AGENTS.md`: Phase 5 concluída (Iters 15–18); Phase 6 MVP iniciado (Iter 19); Phase 7+ deferido
- Deferidos confirmados: golden export JSON, legacy `core/providers/` migration, quest↔research links, health/sync/IA

## Iteração 19 — CONCLUÍDA

**Escopo:** Finance ledger MVP (P0) per ADR-020

**Entregue:**

- Domínio: `FinancialEntity`, `FinancialAccount`, `LedgerTransaction`, `FinanceDisplayPolicy`, `FinanceLedgerPolicy`, `computeTransactionFingerprint`
- DB v12: `financial_entities`, `financial_accounts`, `ledger_transactions`; migration v11→v12 com backfill entidade pessoal
- `FinanceRepository` CRUD + watch; export v11; restore FK order; ADR-015 v11
- `features/finance/application/` providers + controllers; bootstrap entidade pessoal
- UI: `FinanceLedgerScreen`, `CreateFinancialAccountSheet`, `AddTransactionSheet`, disclaimer banner, toggle mascaramento
- Rotas `/resources/finance`; link Colônia corrigido; command palette; eventos Crônica; strings pt-BR
- Testes: domain, migration v11→v12, export v11 restore, `finance_ledger_test` widget
- `./tool/test_all.ps1` pass

## Iteração 18 — CONCLUÍDA

**Escopo:** Graph canvas MVP (P0); Research progress lite (P1); ADR-021

**Entregue:**

- ADR-021-research-graph-canvas.md; ADR-017 addendum canvas → ADR-021
- Domínio: `buildResearchGraphLayout` em `research_graph_layout.dart` + testes
- Domínio: `computeResearchTreeProgress`, `computeResearchNodeActivity` em `research_progress.dart` + testes
- Providers: `ResearchViewMode`, `researchGraphLayoutProvider`, `researchTreeProgressProvider`, `researchNodeActivityProvider`, `researchShowDependenciesProvider`
- UI: `ResearchGraphView`, `ResearchGraphNodeTile`; toggle Lista/Grafo em `ResearchListScreen`
- Busca: highlight/dim nós no grafo (reuso query Iter 17)
- Progress: summary no topo da lista; linha de atividade no detail; badge evidência nos tiles
- Strings pt-BR: `researchViewList`, `researchViewGraph`, `researchProgressSummary`, etc.
- Testes: `research_graph_layout_test`, `research_progress_test`, `research_graph_canvas_test`; regressão lista/sessão
- Sem migration DB; export permanece v10; sem código finance
- `./tool/test_all.ps1` pass

## Iteração 17 — CONCLUÍDA

**Escopo:** Quest detail tabs (P0); Research search lite (P1); ADR-020 Finance ledger MVP (Day 0 docs)

**Entregue:**

- Quest detail: `TabController` shell (~120 linhas); abas Conteúdo / Relações
- Widgets extraídos: `quest_detail_content_tab`, `quest_detail_relations_tab`, seções `_Linked*`
- Strings pt-BR: `questDetailTabContent`, `questDetailTabRelations`
- Testes: `quest_detail_tabs_test`; regressão quest (prereq, chain, project, decision)
- Domínio: `filterResearchHierarchy` em `research_search.dart` + testes domain
- Providers: `researchSearchQueryProvider`, `filteredResearchHierarchyProvider`
- UI: `SearchBar` em `ResearchListScreen`; empty search state
- Strings pt-BR: `researchSearchHint`, `researchSearchNoResults`
- Testes: `research_search_test`, casos de busca em `research_list_test`
- ADR-020-finance-ledger-mvp.md (docs only; sem código finance)
- Sem migration DB; export permanece v10
- `./tool/test_all.ps1` pass
- Review Iter 16 P1: session picker em `AddEvidenceSheet`; delete última evidência bloqueado em nó demonstrado
- Fix: `QuestLifecycleActions` consulta `listPrerequisites` direto (evita race com StreamProvider loading)

## Iteração 16 — CONCLUÍDA

**Escopo:** Research sessions + evidence lite (ADR-019); demonstrate gate §22.1

**Entregue:**

- ADR-019-research-sessions-evidence.md; ADR-015 matriz v10
- Domínio: `LearningSession`, `ResearchEvidence`, `ResearchDemonstrationPolicy`
- DB v11: `learning_sessions`, `research_evidence`; migration v10→v11 com backfill demonstrated
- `ResearchRepository`: logSession, addEvidence, deleteEvidence, countEvidence; gate em updateStatus
- Export v10 + `export_v10.json`; restore FK-safe sessions/evidence
- Providers/controllers: `researchSessionsProvider`, `researchEvidenceProvider`, logSession/addEvidence
- UI: sheets/panels em `research_node_detail_screen`; snackbar gate demonstrate
- Eventos `researchSessionLogged`, `researchEvidenceCreated`; Crônica titles
- Strings pt-BR sessions/evidence; restore preview labels
- Testes: domain, migration v10→v11, export/restore v10, widget session/evidence
- `./tool/test_all.ps1` pass

## Iteração 15 — CONCLUÍDA

**Escopo:** Meta-review iters 11–15 + Research MVP lista (ADR-017); Review Iter 14 P1 quest accept gate

**Entregue:**

- `docs/dev/META_REVIEW_ITER14.md` — 7 seções; threshold controllers; backlog Iter 16+
- ADR-017-research-graph.md; ADR-015 matriz v9
- Domínio: `ResearchNode`, `ResearchPrerequisitePolicy`, `ActiveResearchPolicy`, `buildResearchHierarchy`
- DB v10: `research_nodes`, `research_prerequisites`; migration v9→v10
- `ResearchRepository` CRUD, link/unlink, watch; export v9; restore FK-safe
- `lib/features/research/application/` providers + controllers
- UI: lista hierárquica, detail, create sheet, prerequisite picker
- Rotas `/research`, `/research/:id`; command palette
- Eventos `researchNodeCreated`, `researchStatusChanged`; Crônica titles
- Strings pt-BR research
- Review P1: `updateStatus(draft→active)` bloqueado; widget paused→active sem accept sheet
- Testes: domain, migration, export v9, repo, widget research + quest accept
- `./tool/test_all.ps1` pass

## Iteração 14 — CONCLUÍDA

**Escopo:** Quest acceptance ADR-018 lite — último gap QUEST-001 (§46.5 aceitar)

**Entregue:**

- ADR-018-quest-acceptance.md; ADR-015 matriz v8
- Domínio: `acceptedAt`, `acceptanceDeadline`, `acceptanceAssumptions` + `copyWith`
- DB v9: colunas em `quests`; migration v8→v9 com backfill (`active`/`paused`/`completed` → `acceptedAt=createdAt`)
- Export v8 + `export_v8.json`; restore round-trip acceptance fields
- UI: `AcceptQuestSheet` (premissas ≥1, prazo opcional); detail “Aceitar e ativar”; create “Criar e ativar”
- Gate ADR-016 antes do sheet; retomar (`paused→active`) sem re-aceite
- Detail: tile “Aceita em” + premissas; `EventType.questAccepted` + Crônica
- Strings pt-BR (`questAcceptAndActivate`, `questAcceptanceAssumptions`, etc.)
- Testes: migration v8→v9, export v8 restore, repo `acceptAndActivate`, `quest_acceptance_test` widget
- `./tool/test_all.ps1` pass

## Iteração 13 — CONCLUÍDA

**Escopo:** Schedule 3-day view (backlog meta-review P3); presentation-only, sem migration/export

**Entregue:**

- Domínio: `scheduleThreeDayRange(anchor)` em `schedule_day.dart` + testes (mês/ano)
- Providers: `ScheduleViewMode` enum, `scheduleViewModeProvider`, `scheduleThreeDayRangeProvider`
- UI: `ScheduleThreeDayView` — 3 painéis com `ScheduleDayTimeline` (compact) + `ScheduleConflictPanel`
- `ScheduleScreen`: toggle Dia/3 dias (`SegmentedButton`); nav ±1 preserva anchor; deep link `?date=` ancora primeiro dia
- Layout: `LayoutBuilder` — `Row` se largura > 720, senão scroll vertical; timeline compacta (`hourHeight` 24)
- Strings pt-BR: `scheduleThreeDayView`, `scheduleViewDay`, `scheduleViewThreeDays`
- Testes: domain range; widget toggle, 3 painéis, nav 3-day, deep link
- P1 polish Iter 12: `restoreCountLabel` para `weekly_reviews`; `EventType.weeklyReviewCompleted` + evento no save; título Crônica
- `AGENTS.md`: Fase 4 marcada concluída
- `./tool/test_all.ps1` pass; sem migration DB, sem bump export

## Iteração 12 — CONCLUÍDA

**Escopo:** Weekly review MVP (§28.4); P1 restore preview labels + CI `test_all`

**Entregue:**

- `WeeklyReview` domain + `weekStartDateFor` helper (`weekStartsOnMonday`)
- DB v8: `weekly_reviews`; migration v7→v8; `WeeklyReviewRepository`
- Export v7 + `export_v7.json`; ADR-015 v7; restore round-trip
- UI: `WeeklyReviewScreen`, rota `/pawn/review/weekly`, entry Pawn + command palette
- `WeeklyReviewController` + `currentWeekWeeklyReviewProvider`
- Strings pt-BR (6 campos MVP)
- `restoreCountLabel` para `daily_reviews` + `mood_factors`
- `.github/workflows/test_all.yml` (ubuntu + `tool/test_all.sh`)
- Testes: domain week helper, migration v7→v8, repo upsert, export/restore v7, widget screen
- `./tool/test_all.ps1` pass

## Iteração 11 — CONCLUÍDA

**Escopo:** Export v6 — fechar lacuna restore pawn (`daily_reviews`, `mood_factors`); round-trip testado

**Entregue:**

- `ExportSnapshot` v6: parse v1–v6, backfill `[]` para chaves pawn em v≤5
- `ExportRepository.buildSnapshot()` emite version 6 com `dailyReviews` e `moodFactors`
- `RestoreRepository._insertAll`: insert FK-safe após `check_ins`
- `CheckInRepository.listAllMoodFactors`, `DailyReviewRepository.listAll`
- ADR-015 matriz v6; lacunas pawn resolvidas
- Fixture `export_v6.json`; testes domain + `export_restore_test` pawn round-trip
- `./tool/test_all.ps1` pass

## Iteração 10 — CONCLUÍDA

**Escopo:** Meta-review protocolo LOOP (segundo bloco de 5 iterações) — arquitetura, export/restore, test pyramid, desvios spec; **sem código de produto**

**Entregue:**

- `docs/dev/META_REVIEW_ITER9.md` — 7 seções: layering, export v1–v5 + restore gaps (`daily_reviews`, `mood_factors`), test pyramid, MVP spec deviations, UX hub complexity, checklist Iter 5, backlog Iter 11+
- ADR-015 addendum: lacuna `mood_factors` documentada junto a `daily_reviews`
- `./tool/test_all.ps1` baseline: **116** testes (31 app + 60 domain + 25 database), analyze **0 erros / 43 infos**
- Deferidos confirmados: schedule 3d, weekly review, Phases 5–7 (research/finance/health)

## Iteração 9 — CONCLUÍDA

**Escopo:** Fase 4e — Quest prerequisites (8b); P1 chain view + test:all; P2 project lifecycle policy

**Entregue:**

- ADR-016-quest-prerequisites.md; ADR-015 matriz v5 + ordem FK restore
- `QuestPrerequisiteLink`, `QuestPrerequisitePolicy`, cycle detection; `quest_prerequisite.dart`
- DB v7: `quest_prerequisites`; migration v6→v7; `QuestRepository` link/unlink + gate activate
- Export v5 + `export_v5.json`; restore round-trip v5
- UI: `QuestPrerequisitePickerSheet`, detail/board, badge “Aguardando”, snackbars
- `QuestChainPanel` + `quest_chain.dart` topo sort read-only
- `ProjectLifecyclePolicy`; block `active→archived`
- `tool/test_all.ps1` + `tool/test_all.sh` (`analyze --no-fatal-infos`; workaround Windows native_assets); AGENTS.md atualizado
- Fix Review Iter 8: `export_restore_test` fixture path quando cwd é package root; ADR-015 nota lacuna `daily_reviews`
- Testes: domain, migration, export restore v5, repo, widget `quest_prerequisite_test`, `quest_chain_panel_test`, `project_lifecycle_test`

## Iteração 8 — CONCLUÍDA

**Escopo:** Fase 1a — Export restore (8a); P1 decision log polish

**Entregue:**

- ADR-015 finalizado: política full-replace, matriz v1–v4, ordem FK-safe
- `ExportSnapshot.fromJson` / `fromJsonString` + `entityCounts`; `ExportSnapshotException`
- `RestoreRepository` transactional wipe-and-insert; `EventType.exportRestored`
- Fixtures `export_v2/v3/v4.json`; `export_snapshot_test`, `export_restore_test`
- `file_picker`; `RestoreController`; settings restore UI (preview, dupla confirmação, snackbars)
- `RestorePreviewSheet`; `settings_restore_test`
- Decision polish: assumptions, expectedOutcomes, reviewAt, outcomeReview nos sheets
- `DecisionRepository.delete` + `decisionDeleted`; `DecisionListScreen` `/decisions`; command palette
- `decision_list_test`; delete coverage em `decision_quest_link_test` + `repository_test`
- Crônica: títulos exportRestored, decisionDeleted
- P2 quest prerequisites (8b) **deferido** para Iter 9

## Iteração 7 — CONCLUÍDA

**Escopo:** Fase 3c — Schedule timeline + conflitos; P1 project polish

**Entregue:**

- Domínio: `ScheduleTimelineItem`, `ScheduleConflict`, detecção half-open (`schedule_conflict.dart`)
- DS: `DayTimeline` — timeline vertical 24h com faixa lateral de conflito
- Providers: `scheduleTimelineItemsProvider`, `scheduleConflictsProvider`, `buildScheduleTimelineItems`
- UI: `ScheduleDayTimeline`, `ScheduleConflictPanel`; integração em `ScheduleScreen` (timeline + lista explicativa; CRUD/dia/`?date=` preservados)
- Strings pt-BR: timeline, conflitos, sobreposição
- P1: `EditProjectSheet`; transições `active→completed→archived` em `ProjectDetailScreen` + `ProjectController`
- Testes: `schedule_conflict_test.dart` (adjacente, parcial, aninhado, three-way, tasks); widget timeline/conflitos; `project_detail_screen_test` (edit, complete, archive)
- ADR-015-export-restore.md (stub outline para Iter 8)
- Sem migration DB, sem bump export

## Iteração 6 — CONCLUÍDA

**Escopo:** Fase 4d — Decision log MVP + meta-review (Day 0 doc)

**Entregue:**

- Domínio: `DecisionRecord`, `DecisionReversibility`, `QuestDecisionLink`
- DB v6: `decision_records`, `quest_decisions`; `DecisionRepository` CRUD + link/unlink + `watchByQuest`
- Export v4 com `decision_records` e `quest_decision_links`
- Eventos: `decisionCreated`, `decisionUpdated`; títulos na Crônica
- UI: `CreateDecisionSheet`, `EditDecisionSheet`, `DecisionSummaryTile`; seção de decisões no detail da missão
- Providers/controllers em `decision_providers.dart` / `decision_controllers.dart`
- ADR-014-decision-records.md; `docs/dev/META_REVIEW_ITER5.md`
- Testes: migration v5→v6, repo round-trip + export v4, widget `decision_quest_link_test`
- P2: painel de missões ativas na Colônia (`colony_active_quests_test`)

## Iteração 3 — CONCLUÍDA

**Escopo:** Fase 4b — Quest authoring (critérios, riscos, edição)



**Entregue:**

- CreateQuestSheet: listas dinâmicas de critérios e riscos (add/remove), trim de linhas vazias

- EditQuestSheet: editar título, propósito, critérios, riscos e prazo (draft/active/paused)

- QuestDetailScreen: botão editar só para missões não terminais

- QuestController.create: repassa successCriteria/risks ao repositório

- Validação: título e propósito obrigatórios ao salvar

- Strings pt-BR em app_strings.dart

- Testes: widget create com critérios; repo edit round-trip criteria/risks

- P0: deadline scheduleCalendarDay; watchByQuest; error snackbars; paused→complete; create=1 deep link

## Iteração 4 — CONCLUÍDA

**Escopo:** Fase 3 polish — Schedule authoring

**Entregue:**

- Day navigation: prev/next, tap date → showDatePicker, scheduleCalendarDay
- Deep link `?date=YYYY-MM-DD` em `/work/schedule` → scheduleSelectedDayProvider
- ScheduleBlockSheet compartilhado (add/edit): modo + showTimePicker (use24HourFormat)
- Edit: tap tile → sheet → ScheduleController.updateBlock → save
- Delete: confirmação → ScheduleRepository.delete + EventType.scheduleBlockDeleted
- ScheduleController: updateBlock, deleteBlock; ScheduleSelectedDay.select
- Strings pt-BR; chronicle titles para blocos de agenda
- Testes: repo update/delete round-trip; widget day nav, add/edit/delete, invalid range snackbar

## Iteração 5 — CONCLUÍDA

**Escopo:** Fase 4c — Projects MVP + quality gate (migrations, quest events, pause reason)

**Entregue:**

- DB v5: `projects`, `quest_projects`, `quests.pause_reason`; `ProjectRepository` CRUD + link/unlink + watch
- Export v3 com `projects` e `quest_project_links`
- Eventos: `questUpdated` (edição), `questStatusChanged` (transição única com `pause_reason`), `projectCreated`, `projectUpdated`
- UI: `ProjectListScreen`, `CreateProjectSheet`, `ProjectPickerSheet`; rotas `/projects`, `/projects/:id`; command palette
- Missões: picker de projetos no create/edit; seção de projetos vinculados no detail; motivo de pausa visível
- Fix: deep link `?create=1` reabre sheet após fechar (reset dedup)
- Chronicle titles para missão/projeto atualizados
- Testes: migration v3→v4 e v4→v5, repo round-trips, export v3, widgets (project list, quest-project link, create=1 twice)
- ADR-013-project-quest-links.md

