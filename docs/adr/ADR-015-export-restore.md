# ADR-015: Export restore (import)

## Status
Aceito (Iter 8 … v22 Iter 71, v23 Iter 73, v24 Iter 76, v25 Iter 81, v26 Iter 86)

## Contexto
Export snapshots v1–v4 permitem backup offline, mas o app só implementava **export** (serialização). ADR-013 e ADR-014 adiaram restore/import. Iter 8 fecha o ciclo local-first: backup JSON → restaurar → re-exportar.

## Decisão

### Política de conflito: substituição total (full replace)
- Restore roda em **uma transação Drift** que apaga todos os dados do perfil e reinsere o snapshot.
- **Sem merge parcial** — não há restauração seletiva (só missões, só agenda, etc.).
- **IDs preservados** do snapshot (missões, tarefas, links N:N intactos).
- Perfil único: a linha de perfil do snapshot substitui a ativa.

### Versões suportadas

| Versão | Chaves adicionais | Normalização |
|--------|-------------------|--------------|
| **v1** | `profile`, `preferences`, `tasks`, `events` | Listas v2+ ausentes → `[]` |
| **v2** | + `quests` | Projetos/decisões → `[]` |
| **v3** | + `projects`, `quest_project_links` | Decisões → `[]` |
| **v4** | + `decision_records`, `quest_decision_links` | Forma canônica atual |
| **v5** | + `quest_prerequisite_links` | Pré-requisitos N:N |
| **v6** | + `daily_reviews`, `mood_factors` | Forma canônica pawn |
| **v7** | + `weekly_reviews` | Forma canônica §28.4 MVP |
| **v8** | + campos de aceite em `quests[]` (`accepted_at`, `acceptance_deadline`, `acceptance_assumptions`) | Forma canônica QUEST-001 |
| **v9** | + `research_nodes`, `research_prerequisite_links` | Forma canônica research lista |
| **v10** | + `learning_sessions`, `research_evidence` | Forma canônica research sessões |
| **v11** | + `financial_entities`, `financial_accounts`, `transactions` | Forma canônica finance |
| **v12** | + `quest_research_links` | Forma canônica quest↔research (ADR-022) |
| **v13** | + `health_conditions` | Forma canônica saúde local (ADR-023) |
| **v14** | + `symptom_entries` | Timeline de sintomas pontuais (ADR-023) |
| **v15** | + `inventory_items` | Inventário local MVP (ADR-024) |
| **v16** | + `people` | Relações/pessoas MVP (ADR-026) |
| **v17** | + `category_budgets` | Orçamento mensal por categoria (§23.7 lite) |
| **v18** | + `person_interactions` | Interaction log lite (§24.2 / ADR-026) |
| **v19** | + `trips` | Viagens/expedições MVP (ADR-027) |
| **v20** | + `organizations` | Organizações/facções MVP (ADR-028) |
| **v21** | + `person_organization_links` | Membership Person↔Org stub (ADR-028) |
| **v22** | + `home_maintenance_tasks` | Manutenção doméstica MVP (ADR-029) |
| **v23** | + `quest_inventory_links` | Inventory↔quest link lite |
| **v24** | + `commitments` | Commitments / promessas MVP (ADR-030) |
| **v25** | + `context_zones` | ContextZone MVP (ADR-031) |
| **v26** | + `integration_consents`, `external_calendar_events` | ICS import stub (ADR-032) |
| **v27** | + `zone_trip_links` | Zone↔Trip N:N (ADR-031) |
| **v28** | + `health_appointments` | Health appointment stub (ADR-023) |
| **v29** | + `trip_inventory_links` | Packing list stub trip↔inventory (§26.1) |

Chaves transversais (presentes em export v26+ completo, default `[]` se ausentes em backups antigos):
`work_priorities`, `bills`, `schedule_blocks`, `need_definitions`, `need_readings`, `check_ins`.

Versões **> 29** ou **< 1** rejeitadas com erro parseável; **nenhuma mutação** no banco.

### Ordem FK-safe

**Delete (filhos primeiro):**
`sync_operations` → `device_identities` → `external_calendar_events` → `integration_consents` → `zone_trips` → `trip_inventory` → `context_zones` → `commitments` → `quest_inventory` → `home_maintenance_tasks` → `person_organizations` → `organizations` → `trips` → `person_interactions` → `category_budgets` → `people` → `inventory_items` → `health_appointments` → `symptom_entries` → `health_conditions` → `ledger_transactions` → `financial_accounts` → `financial_entities` → `quest_decisions` → `quest_prerequisites` → `research_evidence` → `learning_sessions` → `research_prerequisites` → `quest_research` → `quest_projects` → `mood_factors` → `need_readings` → `tasks` → `domain_events` → `check_ins` → `daily_reviews` → `weekly_reviews` → `schedule_blocks` → `bills` → `work_priorities` → `decision_records` → `quests` → `research_nodes` → `projects` → `need_definitions` → `preferences` → `profiles`

**Insert:**
`profiles` → `preferences` → `need_definitions` → `quests` / `projects` / `decision_records` / `research_nodes` / `financial_entities` → `financial_accounts` → `ledger_transactions` → `health_conditions` → `symptom_entries` → `health_appointments` → `inventory_items` → `people` → `person_interactions` → `category_budgets` → `trips` → `organizations` → `person_organization_links` → `home_maintenance_tasks` → `quest_inventory_links` → `trip_inventory_links` → `commitments` → `context_zones` → `zone_trip_links` → `integration_consents` → `external_calendar_events` → `learning_sessions` / `research_evidence` → `tasks` / `domain_events` / `bills` / `schedule_blocks` / `check_ins` / `mood_factors` / `daily_reviews` / `weekly_reviews` / `need_readings` → `quest_projects` / `quest_decisions` / `quest_prerequisites` / `research_prerequisite_links` / `quest_research_links` → `work_priorities`

### UX (Configurações)
1. Selecionar arquivo JSON (`file_picker`)
2. Preview: versão export + contagens por entidade
3. **Dupla confirmação** destrutiva
4. Snackbar sucesso/erro; evento `exportRestored` na Crônica

### Evento de domínio
- `EventType.exportRestored` — payload: `{ version, task_count, quest_count, ... }`

## Consequências
- Round-trip export → restore → re-export idempotente (IDs e contagens).
- Restore não registra eventos históricos do snapshot — apenas substitui linhas.
- Evento `exportRestored` é append-only após commit bem-sucedido.

## Fora de escopo (MVP)
- Sync multi-dispositivo e resolução de conflitos em tempo real
- Restore parcial (só missões ou só agenda)
- Import CSV/calendário
- Criptografia, senha, hashes de manifesto (§46.6 completo)
- Remapeamento de IDs quando perfil destino difere (single-profile assume replace)

## Referências
- Spec §66.3, §75.3
- `META_REVIEW_ITER5.md` — lacuna export-only
- Iter 8 plan (72b699b2)
