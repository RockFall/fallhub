# ADR-037: Mapa de conhecimento multi-caminho e pontes com pesquisa

## Status
Aceito

## Contexto
ADR-036 modelou `KnowledgeArea` como árvore de um pai. Isso impede o caso real: Tropicalismo vive em Música **e** em História → Brasil; ODD vive num ramo profundo de Carros autônomos. Pesquisa (ADR-017) é intenção/evidência; área é prateleira. Precisam se cruzar sem se fundir.

## Decisão

### 1. Um nó canônico + colocações secundárias
- `KnowledgeArea` continua com `parentId` **primário** (mapa do hub, breadcrumb padrão).
- `KnowledgeAreaPlacement` é aresta secundária `(areaId, parentAreaId)`.
- Mesmo `id`, mesmo calor, mesmos baralhos/cartões — acessível pelos dois caminhos.
- Ciclos proibidos no grafo combinado (pai primário + colocações).

### 2. Cartão e baralho
- `Flashcard.areaId` e `FlashcardDeck.areaId` apontam para o tópico **canônico**.
- Visibilidade numa área = canônico está no subconjunto de descendentes (primário ∪ secundário), sem duplicar calor.

### 3. Pesquisa ↔ conhecimento
- `ResearchKnowledgeLink` N:N (`primary` | `related` | `practice`).
- `FlashcardDeck.researchNodeId` permanece o foco primário do baralho.
- Área mostra pesquisa ligada; nó de pesquisa mostra prateleiras.

### 4. Visual
- Hub: floresta **primária** (sem duplicar alias).
- Detalhe da área: chips “Também em…” + filhos alias com rótulo atalho.
- Sem grafo force-directed no mapa.

### 5. Persistência
- DB **v35**: `knowledge_area_placements`, `research_knowledge_links`
- Export **v31**: as duas coleções; v≤30 restauram `[]`

## Fora de escopo
Fundir ResearchNode na taxonomia; múltiplos `areaId` por cartão; LLM sugerindo colocações.
