# ADR-013: Project–Quest links

## Status
Aceito

## Contexto
Iteration 5 introduz projetos como agrupadores opcionais de missões. Uma missão pode estar vinculada a zero ou mais projetos; um projeto pode agrupar várias missões. Isso difere de hierarquia rígida task→project da spec completa (fases futuras).

## Decisão
- Tabela de junção `quest_projects` (N:N) em vez de `project_id` direto em `quests`.
- `ProjectRepository` concentra CRUD de projetos e link/unlink com missões.
- Export snapshot v3 inclui `projects` e `quest_project_links`.
- Eventos de domínio: `projectCreated`, `projectUpdated`; edições de missão usam `questUpdated`, transições de status usam `questStatusChanged` (com `pause_reason` no payload quando pausada).

## Consequências
- UI de missão mostra seção “Projetos vinculados” com picker multi-seleção.
- Restore/import de export v3 fica para iteração futura (fora do escopo atual).
- Migração v5 adiciona `projects`, `quest_projects` e coluna `pause_reason` em `quests`.
