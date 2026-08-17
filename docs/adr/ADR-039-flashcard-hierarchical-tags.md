# ADR-039: Tags hierárquicas de flashcards

## Status
Aceito

## Contexto
`Flashcard.tags[]` era uma lista plana de strings. O utilizador precisa de associar um cartão a N tags, aninhar subtags, e estudar a fila de uma tag (incluindo descendentes). Tags não substituem o mapa de áreas (ADR-036): área = taxonomia de assunto; tag = classificação flexível cruzada.

## Decisão

1. **`FlashcardTag`** — árvore por perfil (`parent_id` opcional). Título único por irmão (case-insensitive).
2. **`FlashcardTagLink`** — N:N cartão↔tag. Estudar uma tag inclui cartões ligados a ela **ou a qualquer subtag**.
3. **`tags_json` no cartão** permanece como títulos das tags ligadas (busca/export antigo). A árvore e as ligações são a fonte de verdade.
4. **DB v36 / export v32.** Migração cria tags-raiz a partir de `tags_json` existente.
5. **UI** — aba Tags no hub; `/flashcards/tags/:id`; sessão `?tagId=`.

## Fora de escopo
Tags em outros agregados, cores/ícones, sync remoto.
