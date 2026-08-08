# ADR-022: Quest–Research links

## Status
Aceito (Iter 24)

## Contexto
Spec §22 e backlog META_REVIEW_ITER19 pedem vínculos N:N entre missões e nós de pesquisa. Quest detail já tem aba Relações (ADR-020) — novos links devem ir ali, sem reinflar o shell.

## Decisão
- Tabela de junção `quest_research` (PK `quest_id` + `research_node_id`, `linked_at`), espelhando ADR-013 `quest_projects`.
- `ResearchRepository` concentra `listQuestLinks` / `watchLinkedToQuest` / `linkQuest` / `unlinkQuest`.
- Export snapshot **v12** inclui `quest_research_links`.
- Schema DB **v13**.
- UI: seção na tab Relações + picker multi-seleção de nós ativos (não terminais).

## Consequências
- Restore/import v12 round-trip obrigatório.
- Domínio de research prerequisites (ADR-017) permanece separado — não misturar com quest↔research.
