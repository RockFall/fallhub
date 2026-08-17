# ADR-038: Importação JSON de flashcards (prompt para IA)

## Status
Aceito

## Contexto
O utilizador gera cartões com uma IA externa e precisa de os carregar no mapa local. ADR-036 deixa LLM **dentro** do app fora de escopo; importar um documento estruturado que a pessoa colou/escolheu é importação (spec §38), não geração.

## Decisão

1. **Documento v1** (`FlashcardJsonCodec`) — `cards[]` e/ou `decks[]`. Cada cartão declara `front`, `back`, `kind`, `deck`, `areaPath`, opcionais `alsoIn`, `extra`, `tags`, `schedule`, `bidirectional`. Aceita JSON puro ou cercado em ```json.
2. **Prateleiras** — `areaPath` é a cadeia de títulos raiz→folha. Segmentos inexistentes são **criados**. Se a cadeia casa com o catálogo sugerido, usa-se `catalogKey` (ativar prateleira canónica). `alsoIn` cria colocações secundárias (ADR-037).
3. **Dedup** — na mesma baralho (título, case-insensitive): mesma frente normalizada + mesmo `kind` + mesmo verso → **ignorar**; frente igual e verso diferente → **overwrite** (SRS intacto).
4. **Prompt copiável** — texto gerado a partir das áreas/baralhos atuais + schema. Muda quando o mapa muda. A IA não corre no dispositivo.
5. **Sem bump de schema.** Evento `flashcardJsonImported`.

## Fora de escopo
Import Anki `.apkg`, imagens, LLM remoto, sync.
