# ADR-047: Capacidades de tarefa (projeto, prazo, data, subtarefa, prioridade)

## Status
Aceito

## Contexto

`ColonyTask` (ADR-002/§20) já carrega título, descrição, FSM de status, `dueAt`, `scheduledStart`, energia, estimativa e vínculo opcional a quest. A captura continua sendo "só o nome". Falta um backlog explícito (**Tarefas**) separado do plano do dia (ADR-046) e da inbox (captura), e faltam capacidades que o uso real pede sem aumentar a fricção do caminho feliz:

1. associar a um **Projeto**;
2. ter **prazo** (`dueAt`) ou **data específica** (`scheduledStart`) — campos que já existem no domínio/DB mas não estavam no export nem na página da tarefa;
3. ter **subtarefas**;
4. ter **priorização qualitativa** (não um score);
5. abrir uma **página da tarefa** (hoje `TaskInspectScreen` é só um painel de ações).

Restrição de produto: criar tarefa continua sendo **só o título**. Campos extras são opcionais e só aparecem na página da tarefa. O plano do dia (**Hoje**) permanece uma lista datada independente — não se sobrecarrega `scheduledStart` como "está no plano de hoje".

## Opções consideradas

**A. Subtarefas como JSON/checklist dentro de `description`.**
Rejeitada — não dá para marcar, puxar para Hoje, nem exportar como entidades.

**B. Tabela `task_subtasks` separada, sem ser `ColonyTask`.**
Rejeitada — duplicaria título/conclusão e impediria puxar uma subtarefa para o plano do dia.

**C. `parentTaskId` opcional em `ColonyTask`, um nível só; `projectId` e `TaskPriority` opcionais.** — **Escolhida.**

## Decisão

### Entidades

- **`projectId`** opcional. Sem FK rígida (mesmo padrão de `questId`) para restore e para não bloquear arquivar projeto.
- **`TaskPriority`**: `none` (default) | `later` | `soon` | `now`. Qualitativa, sem peso numérico e sem streak.
- **`parentTaskId`** opcional. Um nível: pai não pode ser filho; filho não pode ter filhos. Ciclo proibido.
- **`dueAt`** = prazo (deadline). **`scheduledStart`** = "para o dia" (data/hora de intenção). Independentes do `DayPlan`.
- Completar o pai **não** completa filhos. Completar todos os filhos **não** completa o pai.
- Backlog (**Tarefas**) lista só tarefas de topo (`parentTaskId == null`). Subtarefas vivem na página do pai. Podem ser puxadas para Hoje porque continuam sendo `ColonyTask`.
- Criar pelo backlog usa status `next` (já é trabalho, não captura). Captura rápida continua `inbox`.

### Export / schema

- Drift `schemaVersion` 43 → **44**: colunas `project_id`, `priority` (default `none`), `parent_task_id` em `tasks`.
- `ExportSnapshot` v37 → **v38**: chaves opcionais em cada task (`project_id`, `priority`, `parent_task_id`, e também `due_at` / `scheduled_start` / `estimated_minutes` / `energy_requirement` / `blocked_reason`, que já existiam no domínio e não iam no JSON).
- Snapshots v37 sem as chaves novas continuam válidos (defaults: `priority=none`, resto `null`).

### UI

- Rota `/tasks` = backlog. `/tasks/:id` = página da tarefa.
- Agrupar por projeto é um modo, não o default (lista plana permanece o caminho simples).
- Campos extras só na página da tarefa; o compositor do backlog é um campo de nome.

## Consequências

- Fecha o gap de "lista de tarefas" sem contaminar Hoje nem a inbox.
- Backup passa a preservar prazo e data das tarefas (lacuna pré-existente).
- Abre caminho para promover item ad-hoc do dia a tarefa (fora de escopo).

## Reversão

Colunas novas são anuláveis / com default. Reverter `schemaVersion`/export não apaga `title`/`status`. Filhos órfãos (`parent_task_id` apontando para tarefa apagada) são tratados como topo no backlog.

## Fora de escopo

Recorrência, tags, pontuação, auto-completar pai/filhos, mais de um nível de subtarefa, promoção automática de item do dia.
