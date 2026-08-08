# ADR-014: Decision records and quest links

## Status
Aceito

## Contexto
Iteration 6 introduz o registro de decisões (DecisionRecord) conforme spec §70.1, vinculáveis a missões via junção N:N. O MVP cobre CRUD, reversibilidade e export, sem matriz de decisão, premortem ou links com projetos.

## Decisão
- Tabela `decision_records` com campos textuais e listas JSON (alternativas, critérios, premissas, resultados esperados, riscos).
- Tabela de junção `quest_decisions` (N:N) em vez de `decision_id` direto em `quests`.
- `DecisionRepository` concentra CRUD e link/unlink com missões; `watchByQuest` para UI reativa.
- Export snapshot v4 inclui `decision_records` e `quest_decision_links`.
- Eventos: `decisionCreated`, `decisionUpdated` (AggregateType `decision`).

## Consequências
- UI de missão mostra seção “Decisões vinculadas” com criar, picker multi-seleção e edição inline.
- Restore/import de export v4 fica para iteração futura.
- Migração v6 adiciona `decision_records` e `quest_decisions`.
- Matriz, premortem, revisão posterior estruturada e links projeto-decisão ficam fora do escopo atual.
