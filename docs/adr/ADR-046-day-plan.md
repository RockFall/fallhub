# ADR-046: Day Plan (Planejar Dia)

## Status
Supersedido pela UI de ADR-048 (tabelas `day_plans` / `day_plan_items` permanecem no schema/export)

## Contexto

`ColonyTask` (ADR-002/§20) é o backlog global — inbox/next/scheduled/doing/blocked/waiting/done/cancelled/archived, com `scheduledStart` como um *slot* opcional de agenda. Não existe hoje uma lista diária ordenada, editável com fricção mínima ("Planejar Dia", estilo Google Tasks), que:

1. aceite itens **ad-hoc** (não precisam existir como `ColonyTask`);
2. aceite itens **puxados** de `ColonyTask` existentes;
3. seja **datada** (um dia = uma lista) e sobreviva independente de mudanças no backlog global;
4. suporte check/uncheck de baixa fricção sem forçar a máquina de estados completa de `TaskStatus`.

Restrição explícita do produto (spec §0.1 / issue): **não** sobrecarregar `scheduledStart` como "está no plano de hoje" — isso colidiria com o significado existente de "horário agendado" (usado por `ScheduleBlocks`, work grid) e impediria um item ad-hoc (sem `ColonyTask`) de aparecer na lista.

## Opções consideradas

**A. Sobrecarregar `ColonyTask.scheduledStart`/`status` como "plano de hoje".**
Rejeitada — proibida explicitamente. Também não resolve itens ad-hoc (todo item precisaria de um `ColonyTask`), e colide com o significado de agenda (`ScheduleBlocks`/work grid já usa `scheduledStart`).

**B. Lista puramente derivada em memória (sem persistência), recalculada a partir de tarefas com `scheduledStart == hoje`.**
Rejeitada — não acomoda itens ad-hoc, não persiste ordem, não permite check independente do status da tarefa, e quebra a auditabilidade local-first (Crônica/export) exigida pelo produto.

**C. Novo status `TaskStatus.plannedToday` na máquina de estados existente.**
Rejeitada — `TaskStatus` é uma FSM de estado único; um item não pode estar simultaneamente "next" e "planejado hoje". Também não resolve itens ad-hoc.

**D. Novo agregado `DayPlan` + `DayPlanItem`, com item opcionalmente referenciando `ColonyTask.id`, sempre com snapshot de título.** — **Escolhida.**

## Decisão

### Entidades (`colony_domain`)

- **`DayPlan`**: um por `(profileId, localDate)`. `localDate` é `String` `YYYY-MM-DD` (calendário local do dispositivo, mesma convenção de `scheduleCalendarDay`), **não** instante UTC — evita o bug de fronteira de fuso/DST que atingiria uma coluna epoch-millis (ex.: `DailyReviews.reviewDate`) quando o dispositivo muda de fuso (viagem) entre a criação e a consulta do plano.
- **`DayPlanItem`**: pertence a um `DayPlan`; `taskId` **opcional**; **sempre** tem `title` (snapshot). `taskId == null` ⇒ item ad-hoc, sem `ColonyTask` correspondente.

### Por que item ad-hoc não cria `ColonyTask` automaticamente

1. Backlog global (`ColonyTask`) carrega máquina de estados completa, bloqueios, quest links, agenda — carga cognitiva incompatível com "digitar e marcar" de baixa fricção.
2. Promoção automática exigiria uma política implícita para o destino do `ColonyTask` quando o item é removido/concluído do plano (arquivar? deixar pendurado no Inbox?) — acoplamento oculto que o slice deve evitar.
3. O modelo já é uniforme: todo `DayPlanItem` tem um snapshot de título; com ou sem `taskId`, a UI trata os dois casos igual. Auto-criar tarefa quebraria essa uniformidade só para o caso que deveria ficar leve.
4. "Promover item ad-hoc a tarefa global" é uma ação explícita e futura (fora de escopo aqui), não efeito colateral implícito de digitar um item do dia.

### Políticas (puras, `colony_domain`)

- Unicidade: um `DayPlan` por `(profileId, localDate)`; um `taskId` ligado por vez por `DayPlan` (índice único `(dayPlanId, taskId)`, `NULL` não conta).
- Puxar tarefa copia `title` (snapshot). Edições futuras no `ColonyTask.title` **não** reescrevem o snapshot — só um novo evento de vínculo (pull ou carry-over) re-captura o título atual. Justificativa: snapshot é "o que eu decidi fazer hoje", não um espelho ao vivo; espelho ao vivo tornaria o item indistinguível de simplesmente exibir a tarefa, e quebraria a possibilidade de o usuário editar o texto do item do dia sem afetar o backlog.
- Completar item ad-hoc: local, não toca `ColonyTask`.
- Completar item vinculado: só conclui e propaga `ColonyTask → done` se `TaskTransitionPolicy.canTransition(task.status, done)` for verdadeiro. Se a tarefa está `blocked`/`cancelled`/`archived` (nenhum permite → `done`), a conclusão do item é **rejeitada** (nada muda) — o usuário precisa resolver o bloqueio na tarefa primeiro. Isso é a "porta" exigida pela `TaskTransitionPolicy`.
- Desfazer conclusão de item vinculado só reverte a tarefa para `next` se a tarefa ainda estiver em `done` (não foi alterada por outro caminho desde a conclusão) — evita sobrescrever mudanças concorrentes.
- Remover do plano nunca deleta a `ColonyTask` global.
- Carry-over copia itens não concluídos para um novo `DayPlan` (mantendo `taskId`), sem mover/alterar o plano de origem; re-captura o título atual da tarefa (mesma regra de "re-snapshot em evento de vínculo"); pula itens cuja tarefa vinculada já está em status terminal (`done`/`cancelled`/`archived`); idempotente (chamar duas vezes não duplica, via `carriedFromItemId`).
- **Hard delete** para `DayPlanItem` removido do plano (não soft delete). `DayPlanItem` é uma linha leve de junção/snapshot, não fonte de verdade (a `ColonyTask`, quando existe, é); o histórico de auditoria fica no `DomainEvent` (`dayPlanItemRemoved`), e a reversibilidade imediata é via `UndoAction` (snapshot completo para reinserção), não via tombstone permanente na tabela.

### Export

Bump `ExportSnapshot` v36 → **v37**: `day_plans[]`, `day_plan_items[]`. Compatível com v36 (chaves ausentes ⇒ listas vazias).

### Schema Drift

`schemaVersion` 42 → **43**: novas tabelas `day_plans`, `day_plan_items` (índice único `(profile_id, local_date)` em `day_plans`; índice único `(day_plan_id, task_id)` em `day_plan_items`). Sem índice único em `orderIndex` — reordenar reescreve todos os índices de uma vez, dentro de uma transação, evitando violação transitória de unicidade; contiguidade é invariante de repositório, não de banco.

### Undo

Estende `UndoAction` (não cria uma pilha nova) com `dayPlanItemBefore`/`dayPlanItemId`; reaproveita `taskBefore`/`taskId` já existentes para o efeito cascata em `ColonyTask` quando aplicável. Três novos `UndoActionType`: `dayPlanItemAdded`, `dayPlanItemRemoved`, `dayPlanItemToggled`. Reordenar e criar o plano do dia não entram na pilha de undo (não são destrutivos).

## Consequências

- Fecha o gap de "todo list diário" sem contaminar `ColonyTask`/`TaskStatus`.
- Nenhuma migração de dados existentes é necessária (tabelas novas, vazias).
- Abre caminho natural para "promover item ad-hoc a tarefa" e para métricas de execução diária **sem** virar scoring da pessoa (contagem de fatos, não julgamento).
- Consulta de "tarefas agendadas para hoje" (`scheduledStart`) e "itens do plano de hoje" permanecem independentes; a UI pode oferecer "puxar" as primeiras para o plano, mas isso é uma ação explícita do usuário, não um join automático.

## Reversão

Reversível sem perda de dados de outras features: `DROP TABLE day_plan_items; DROP TABLE day_plans;` e reverter `schemaVersion`/export version não afeta `tasks`, `quests` ou qualquer outra tabela (nenhuma FK de outra tabela aponta para `day_plans`/`day_plan_items`). Snapshots de export v37 continuam parseáveis como v36 por leitores antigos se os campos novos forem ignorados (aditivo, não há remoção/renomeação de chave existente).

## Fora de escopo
Recorrência, horário do dia (time-of-day) nos itens, subtarefas, IA/sugestão automática, contas/bills gerando itens de plano.

## Referências
- Spec: seção correspondente a Planejar Dia / listas diárias
- ADR-002 (arquitetura modular), ADR-004 (Drift), ADR-015 (export/restore), ADR-030 (padrão de MVP local pequeno)
- `packages/colony_domain/lib/src/task.dart` (`ColonyTask`, `TaskTransitionPolicy`)
- `packages/colony_domain/lib/src/schedule_day.dart` (convenção de data-calendário local)
