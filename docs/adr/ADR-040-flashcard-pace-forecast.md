# ADR-040: Ritmo de flashcards e previsão de término

## Status
Aceito

## Contexto
Os logs de revisão já guardam `duration_ms`, data e rating. O hub estimava o tempo da sessão com 30 s fixos e mostrava só a fila dos próximos 7 dias. Falta um ritmo observado (tempo por cartão, cartões/dia, repetições) e uma previsão de quando a coleção agendada completa a **primeira passagem** (todos os cartões formados no SM-2).

## Decisão

1. **Fonte** — métricas derivadas dos logs SRS e do estado SM-2. Sem tabela nova; proveniência = reviews manuais locais.
2. **Janela** — 14 dias locais. Durações &lt; 400 ms ou &gt; 5 min são outliers. Prática pontual não entra no ritmo.
3. **Término** — “acabar os cartões” = todos os agendados saírem de novo/aprendendo/reaprendendo (formados). Revisões espaçadas continuam depois.
4. **Carga restante** — soma das avaliações SRS ainda necessárias para formar cada cartão (novos: 2 goods, ou a média observada se houver amostra). `dias = ceil(carga / cartões por dia)`.
5. **Inverso** — `cartões/dia = ceil(carga / dias alvo)`.
6. **Sessão de hoje** — `estimatedMinutes` usa o tempo médio observado quando houver amostra.

## Fora de escopo
Simulação completa da fila SM-2 no futuro, FSRS, sync remoto.
