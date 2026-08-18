# ADR-041: Prioridade de flashcards (1–5)

## Status
Aceito

## Contexto
Na sessão de estudo o utilizador precisa marcar quais cartões importam mais, sem abrir o editor. Cartões antigos e importações sem o campo devem continuar válidos.

## Decisão

1. **Escala** — inteiro **1 (mais alta) a 5 (mais baixa)**. Ausente, nulo ou fora da faixa → **5**.
2. **Persistência** — coluna `flashcards.priority INTEGER NOT NULL DEFAULT 5`. DB **v36**. Export **v32** inclui `priority`; v≤31 restaura como 5.
3. **Fila** — dentro do mesmo balde SRS (learning / review / new), 1 vem antes de 5.
4. **UI** — na sessão, menu ⋮ → **Definir prioridade** → slider 1–5. Dois toques; o valor grava ao soltar o slider.
5. **Evento** — `flashcardUpdated` (sem tipo novo).

## Fora de escopo
Filtro do hub por prioridade; FSRS; prioridade por baralho.
