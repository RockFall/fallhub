# ADR-016: Quest prerequisites

## Status
Aceito (Iter 9)

## Contexto
A spec §21.3 define `prerequisites[]` em missões. Iter 8 adiou persistência e UI (8b) até restore (ADR-015) estar pronto. Com export/restore v1–v4 estável, prerequisites precisam de modelo N:N, gate de ativação e export v5.

## Decisão

### Modelo
- Tabela de junção `quest_prerequisites` (N:N), espelhando ADR-013 `quest_projects`.
- Aresta `(quest_id, prerequisite_quest_id)` significa: **missão B só pode ativar quando missão A estiver `completed`**.
- Sem auto-desbloqueio: o usuário ativa manualmente quando pré-requisitos estão satisfeitos.

### Validação (domínio)
- **Self-link** rejeitado.
- **Ciclos** (diretos ou indiretos) rejeitados via DFS antes de persistir; nenhuma mutação no banco.
- `QuestPrerequisitePolicy.canActivate`: `draft→active` e `paused→active` bloqueados se algum pré-requisito ∉ `{completed}`.

### Gate de ativação
- `QuestRepository.updateStatus(..., active)` e `create(..., status: active)` chamam `_assertCanActivate`.
- Erro parseável: `QuestPrerequisiteException`.

### Export / restore
- **Export v5** adiciona `quest_prerequisite_links`.
- Backups v4 restauram com links `[]`.
- Restore FK-safe: delete `quest_prerequisites` antes de `quests`; insert links após quests.

### UI (MVP)
- Picker para vincular/desvincular pré-requisitos (detail/edit).
- Badge “Aguardando” no board quando missão tem pré-requisitos incompletos.
- Snackbar ao tentar ativar bloqueada.
- **Chain view** read-only (topo sort) — edição só via picker; sem grafo interativo.

## Consequências
- Cadeias lineares (§21.6 viagem) e DAGs pequenos suportados.
- Restore v5 round-trip preserva grafo de dependências.
- Research tree (§22) permanece domínio separado.

## Fora de escopo
- Notificação automática ao concluir pré-requisito
- Tipos além de quest→quest (projetos, condições externas)
- Editor de grafo drag-and-drop

## Referências
- Spec §21.3, §21.6
- ADR-013, ADR-015
- Iter 8 plan — 8b deferido
