# ADR-036: Flashcards, mapa de conhecimento e SRS

## Status
Aceito

## Contexto
Spec §22.6 permite repetição espaçada como **subsistema** — cartões, exercícios, repertório, recordação livre e prática intercalada — sem obrigar todo conhecimento a virar flashcard. A árvore de pesquisa (ADR-017) já existe; falta um instrumento de prática diária e um mapa de áreas/subáreas independente do grafo de pesquisa.

O uso-alvo é estudar no celular (sideload, ADR-035): captura rápida, sessão de 2–20 minutos, fila justa, e um mapa que mostre onde o conhecimento está firme ou frágil.

## Decisão

### 1. Mapa de conhecimento (independente da research tree)
`KnowledgeArea` tem um pai **primário** (`parent_id` opcional). Colocações secundárias e pontes com pesquisa: **ADR-037**.
- Não substitui `ResearchNode`. Pesquisa = intenção/evidência; área = taxonomia.
- Catálogo sugerido (linguagens, matemática, ciências, computação, humanidades, artes, sociedade, vida prática, engenharia) — o usuário **escolhe** o que semear. Não despejamos 50 áreas vazias.
- Áreas customizadas são cidadãs de primeira classe.

### 2. Baralho e cartão
`FlashcardDeck`: título, área opcional, nó de pesquisa opcional, limites diários (novos/revisões), arquivo.
`Flashcard`:
- `kind`: `basic` | `reverse` | `cloze` | `freeRecall` | `exercise` | `repertoire`
- `front`, `back`, `extra?`, `tags[]`, `clozeIndex?`, `reverseOfId?`, `suspended`
- `scheduleMode`: `scheduled` (SRS) | `unscheduled` (guardado / prática pontual)
- Cloze: `{{cN::texto}}` — um cartão por índice; o verso mostra o texto completo.
- Reverse: o controller cria o par invertido (`reverseOfId`) com SRS **separado**.

Conhecimento sem cartão é válido. Baralho sem área é válido. Área sem baralho é válida.

### 3. SRS (SM-2 com passos de aprendizado)
Algoritmo local, determinístico, testável (`Sm2Scheduler`):
- Notas: Again / Hard / Good / Easy
- Novos: passos 1 min → 10 min; formatura 1 dia; Easy 4 dias
- Review: intervalo × ease; Hard × 1.2; Easy × ease × 1.3
- Again em review: relearning + lapse; ease −0.20 (mín. 1.3)
- Sanguessuga: ≥ 8 lapsos → suspende e marca `leech`
- Preview do próximo intervalo em cada botão

Fila do dia (`StudyQueuePolicy`):
1. learning/relearning vencidos
2. reviews vencidos (mais antigos primeiro), até o limite do baralho
3. novos, até o limite restante
4. intercalação por área quando o estudo é global (prática intercalada §22.6)

Bury = empurrar `dueAt` para o próximo dia local. Undo = reverte o último log + estado SRS.

Sessão **prática** (`FlashcardStudySessionMode.practice`): avalia sem mutar SRS; log com `reviewKind = practice`. Não conta no limite diário nem no digest “agora”.

Digest do dia (`FlashcardTodayDigestPolicy`): fila **limitada** (o que a sessão vai servir), “mais tarde hoje”, guardados, adiados por limite. O herói do hub mostra esse número — não o pool cru.

### 4. Persistência e export
- DB **v35**: áreas, baralhos, cartões (`schedule_mode`), SRS, logs (`review_kind`), colocações, research↔área
- Export **v31**: coleções v30 + `schedule_mode` / `review_kind` + colocações + links; v≤30 default `scheduled` / `srs`
- Eventos: deck/card/area created/updated, `flashcardReviewed`, `flashcardPracticed`, `flashcardScheduled`, `flashcardCatalogSeeded`

### 5. UI
Hub `/flashcards` (hero do dia + mapa com calor de retenção + baralhos).
Área `/flashcards/areas/:id`, baralho `/flashcards/decks/:id`,
sessão `/flashcards/study?deckId=&areaId=` — superfície tipográfica, tap para revelar, 1–4 / espaço.
Estilo: espaçamento amplo, tipo grande, chrome mínimo na sessão (Material calmo sobre tokens Colony). Não copiar Anki/Quizlet.

### Fora de escopo
- FSRS remoto / sync de reviews
- Imagens/áudio nos cartões
- Import Anki `.apkg`
- LLM gerando cartões
- Forçar research node → flashcard
