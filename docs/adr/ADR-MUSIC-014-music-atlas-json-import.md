# ADR-MUSIC-014: Importação JSON do Atlas (prompt para IA)

## Status
Aceito

## Contexto
ADR-038 cobre flashcards. O Atlas precisa do mesmo ritual: prompt vivo, JSON colado ou ficheiro grande em isolate, preview, apply, rollback. A IA corre **fora** do app (ADR-033 / ADR-038).

## Decisão

1. **Documento v1** (`MusicAtlasJsonCodec`) — objecto ou lista; `nodes[]` obrigatório; `claims`, `encounters`, `expeditions`, `researchLinks`, `cards` opcionais. Cursor de bytes da Timeline; chaves desconhecidas saltadas.
2. **Clamp de estado** — import só aceita unknown/sighted/contact; o resto cai para `sighted` e entra no relatório. Ouvir/importar não cartografa.
3. **Dedup** — ID externo (`provider+entityType+id`) liga; mesmo tipo + título normalizado liga ou conflitua; skip se exactamente igual.
4. **Prompt** — `MusicAtlasJsonPromptBuilder` lê nós, claims, áreas, colocações, baralhos, tags e pesquisa. Muda quando o mapa muda.
5. **Ficheiro grande** — o picker passa o path; isolate (`parseMusicAtlasJsonFile`) não deita o dump no `TextField`.
6. **Eventos** — `musicAtlasJsonImported` / `musicAtlasJsonRolledBack`. Rollback marca nós criados pelo run como apagados.
7. **Cartões** — `cards[]` reutiliza o import de flashcards. Candidatos a partir de encontros recusam listen/contact/importListen.

## Fora de escopo
LLM in-app, canvas do mapa, River View, Anki.
