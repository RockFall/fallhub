# ADR-048: Hoje é projeção de ColonyTask

## Status
Aceito (substitui a UI de ADR-046)

## Contexto

ADR-046 criou `DayPlan` / `DayPlanItem` como lista diária **paralela** ao backlog. O resultado prático: criar em **Hoje** não criava `ColonyTask`; **Tarefas** e **Hoje** eram dois mundos. O produto pede uma coisa só:

- **Tarefas** = todas as `ColonyTask` que existem.
- **Hoje** = as mesmas tarefas, filtradas: *sem data de dia* (sempre ativas, em qualquer dia da seta) **ou** *marcadas para o dia em vista*.
- Criar pelo compositor de Hoje (só o nome) gera tarefa **sem data**, não “para hoje”.
- A única forma de marcar um dia é na página da tarefa (`scheduledStart` / “Para o dia”).
- Hoje também agrupa por projeto.

`dueAt` (prazo) **não** é a data do dia: uma tarefa só com prazo continua “sem data de dia” e aparece em todos os dias até ser marcada ou concluída.

## Decisão

- Fonte de verdade do que aparece em Hoje: `ColonyTask` de topo (`parentTaskId == null`).
- **Aberta no dia D**: status trabalhável (`next` / `scheduled` / `doing` / `blocked` / `waiting`) e (`scheduledStart == null` **ou** data local de `scheduledStart` == D). `inbox` não entra — a caixa de entrada continua só captura.
- A lista de Hoje **separa** “Neste dia” (marcadas em D) e “Sem data” (sempre ativas).
- Progresso do dia conta **só** as marcadas em D. Sem data não entra no numerador/denominador.
- **Concluída no dia D**: `status == done` e (marcada para D **ou** sem data de dia e `completedAt` em D) — evita que concluídas sem data inundem todos os dias.
- Compositor de Hoje / card da Home chama `createSimple` (igual Tarefas): título, `next`, sem `scheduledStart`. Fora de hoje, um aviso deixa isso explícito.
- A página da tarefa tem um campo **Para o dia** (calendário + atalho “Hoje” + limpar). Não há segundo botão “marcar para o plano”.
- Inbox e atalhos **não** marcam data (só abrem a tarefa).
- Tabelas `day_plans` / `day_plan_items` e export v37+ **permanecem** (dados antigos / restore). A UI de Hoje deixa de escrever nelas.
- `scheduledStart` agora é a marca de dia de Hoje **e** o slot de agenda. Agenda/work grid que leem o instante devem tratar meia-noite local como “dia inteiro”, não como horário.

## Consequências

- Uma tarefa criada em Hoje aparece em Tarefas e, por não ter data, em todos os dias da seta.
- Navegar com as setas mostra as sem data + as marcadas naquele `YYYY-MM-DD`.
- Carry-over, puxar da inbox para o plano e item ad-hoc sem `ColonyTask` saem da UI.

## Reversão

Voltar a UI a `DayPlanItem`. Colunas de tarefa não precisam ser revertidas.
