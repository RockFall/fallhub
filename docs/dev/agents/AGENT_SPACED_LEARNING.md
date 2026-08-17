# Agente 2 — Aprendizado espaçado no dia a dia

Pilar: **entender o que fazer hoje; praticar um cartão agora vs. programar no tempo.**  
Fonte de verdade: spec §22.6–22.7, §5.6–5.7, ADR-036 §§3–5.  
Companheiros: `AGENT_FLASHCARD_UX.md`, `AGENT_KNOWLEDGE_TAXONOMY.md`.  
Plano: [`docs/dev/KNOWLEDGE_FLASHCARDS_EVOLUTION.md`](../KNOWLEDGE_FLASHCARDS_EVOLUTION.md).

Este agente **não implementa** até o coordenador pedir. Elabora política, digest e fluxos; quando autorizado, fecha o gap entre o SRS já correto e a decisão humana de 2 segundos.

---

## Missão

O usuário olha o telefone e responde, sem jargão de SRS:

1. **O que preciso fazer hoje?** (fila limitada, minutos, buckets)
2. **Quero só olhar este cartão agora** (prática pontual — não mexe no espaçamento)
3. **Quero que o sistema me traga de volta** (programar — entra no SM-2)

Conhecimento sem cartão continua válido. Prática não é revisão. Revisão não é prova.

## O que já existe (núcleo forte — preservar)

| Peça | Comportamento |
|------|----------------|
| `Sm2Scheduler` | Again/Hard/Good/Easy; learning 1 min → 10 min; formatura 1 d; Easy 4 d; lapse; leech ≥ 8 |
| `FlashcardScheduleMode` | `scheduled` \| `unscheduled` |
| `FlashcardCaptureIntent` | `schedule` / `saveOnly` / `practiceNow` |
| Sessão `practice` | Log `reviewKind=practice`; **não** muta SRS; não conta no limite nem no digest “agora” |
| `FlashcardTodayDigestPolicy` | due limitado (`cappedForSession`), later today, guardados, adiados por limite, feitos hoje, ~minutos |
| Fila | learning → reviews (limite) → novos (limite); intercalação por área no estudo global |
| Bury / undo / suspend / leech | Implementados no repositório + sessão |
| Herói do hub | Número = `cappedForSession`; CTA estudar; CTA praticar **só** se `unscheduledCount > 0` |
| Previsão | `forecastDue` 7 dias (UI sem legendas) |
| Baralho | `newLimitPerDay` / `reviewLimitPerDay` |

Testes: `flashcard_srs_test`, `flashcard_study_test`, `flashcard_repository_test`, `flashcards_practice_test`, `flashcards_hub_test`.

## Problemas a resolver

### 1. “Hoje” vive só dentro de `/flashcards`
Colônia, revisão diária, digest narrativo e inbox **não** mencionam a fila. O hábito espaçado compete com tarefas e pawn. Spec §9.3 “Agora” / próximas 24 h deveria poder incluir “12 cartões · ~6 min”.

### 2. Pontual vs. espaçado ainda é vocabulário de produto
- Hub: “Guardados” + “Praticar guardados”.
- Baralho: “Praticar baralho” no modo practice **filtra só unscheduled** (exceto `cardId`). Área com cartões só na fila → prática vazia — surpresa.
- Tile do cartão: “Na fila” / “Guardados”; próxima data **não aparece**.
- Editor existente: um botão alterna programar/guardar **sem salvar o texto** se o usuário só quer mudar o modo depois de editar.

O usuário precisa de duas ações óbvias, sempre:

- **Agora** — vê/responde, zero efeito na curva.
- **Na repetição** — entra (ou continua) no SM-2.

### 3. “Mais tarde hoje” é invisível
Learning steps de 1 e 10 min geram `dueLaterToday`. Não há reentrada, badge, nem som. Quem fecha o app perde o passo de 10 min até abrir de novo.

### 4. Digest vs. pool cru
O herói já mostra a fila **limitada** (certo). Os chips ao lado ainda misturam pool (`dueNowByBucket`) com capped. “3 novos” no chip pode ser maior que o que a sessão vai servir. Isso quebra confiança.

### 5. Falta de recorte humano
- Sem timebox (“só 5 min”).
- Sem “hoje por área” (quais prateleiras puxam a sessão).
- Sem ver `dueAt` no tile.
- Praticar um cartão da busca do hub não existe (abre o baralho).
- Trocar scheduled↔unscheduled está no overflow do tile — certo para avançado, errado como único caminho.

### 6. Integração pesquisa
Nó de pesquisa tem painel de baralhos, mas não “revise 4 cartões deste foco”. Demonstrar skill (§22.1) continua separado — **manter** — mas a prática do dia deveria ser um clique a partir do nó em pesquisa.

## Direção de produto (obrigatória)

1. **Uma frase no herói:** “12 agora · ~6 min” + subtítulo opcional “3 aprendendo · 7 revisar · 2 novos **nesta sessão**”.
2. **Dois modos nomeados na UI, sempre iguais:** `Estudar (espaçado)` e `Praticar (sem fila)`. Praticar um baralho/área = **todos** os cartões não suspensos, sem mutar SRS. Praticar guardados = atalho do hub para o conjunto unscheduled.
3. **Captura:** três chips iguais em todo lugar (inbox futuro, editor, research): Programar · Guardar · Praticar agora.
4. **Reentrada “mais tarde hoje”:** no hub, chip tocável que reabre `/flashcards/study` quando `dueLaterToday > 0`; sem notificação push neste slice (local-first, sem conta).
5. **Timebox opcional:** query `?minutes=5` ou chip no herói; a sessão para com resumo, fila restante intacta.
6. **Colônia / revisão diária:** um painel “Aprendizado hoje” com o mesmo digest (não um segundo algoritmo).
7. **Tile:** status em linguagem humana + “próxima: 3 d” ou “guardado · praticar”.

Não trocar SM-2 por FSRS. Não contar practice no ease. Não forçar todo conhecimento a virar cartão.

## Entregáveis quando autorizado a implementar

1. **Alinhar números** — chips do herói = sessão limitada, não pool cru; teste de regressão no digest.
2. **Prática vs. estudo** — copy + fila de practice (todos / guardados / um cartão); corrigir área/baralho vazios.
3. **Due visível** — tile, busca, área (heat.dueCount já existe).
4. **Hoje no resto do app** — Colônia + daily review (read-only + CTA).
5. **Timebox + later-today** — sem push.
6. **Pesquisa** — “Estudar este nó” usando decks ligados + `ResearchKnowledgeLinkKind.practice`.

## Critérios de aceitação

- Com due > 0, um toque no herói (ou na Colônia) inicia a fila **capped**.
- Praticar um cartão programado **não** altera `dueAt` / ease; log `practice`; teste já existente deve continuar verde e ganhar o caso “practice de scheduled”.
- Guardar vs. programar é decidível na captura sem abrir menu.
- Usuário distingue “12 agora” de “4 mais tarde hoje” e “8 adiados pelo limite”.
- Timebox encerra a sessão sem bury silencioso.
- Strings localizadas; disclaimer de que SRS ≠ evidência de pesquisa permanece (pode ficar no inspect, não no herói).
- `flutter analyze` 0 erros; testes de domínio + widget.

## Fora de escopo deste agente

- Visual da virada / DS de cartão (Agente 1) — este agente define **o que** o herói mostra; o 1 define **como**.
- Taxonomia e multi-caminho (Agente 3) — este agente consome `areaId` + intercalação já existentes.
- FSRS, sync de reviews, notificações remotas, LLM gerando intervalos.
- Rubricas de skill / “demonstrado” (ADR-017/019) — prática de flashcard **não** marca domínio.

## Perguntas que este agente deve responder no plano (antes de codar)

1. Practice de baralho deve incluir scheduled? (Recomendação: sim; o hub “Praticar guardados” cobre o outro conjunto.)
2. Timebox corta no cartão atual ou só entre cartões?
3. “Mais tarde hoje” reabre só learning due, ou mistura com novos que passaram do limite? (Só due real, sem furar limite de novos.)
4. Daily review: campo automático “revisei N cartões” vs. só atalho?
