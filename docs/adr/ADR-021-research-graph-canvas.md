# ADR-021: Research graph canvas MVP

## Status
Aceito (Iter 18, Day 0)

## Contexto
ADR-017 entregou lista hierárquica de `ResearchNode` sem visualização espacial. Iter 17 adicionou busca por título/descrição. A spec §60.7 descreve controles de árvore de pesquisa incluindo pan/zoom, busca e foco no nó ativo. Iter 18 fecha o gap visual **lite** — layout DAG em camadas, sem minimapa ou trilhas.

## Decisão

### Modos de visualização
- Toggle **Lista | Grafo** em `ResearchListScreen`; default = **Lista** (a11y fallback)
- Lista hierárquica Iter 15–17 **inalterada** em modo Lista
- Grafo usa `InteractiveViewer` (pan/zoom) + `CustomPaint` (arestas) + tiles posicionados

### Layout (`buildResearchGraphLayout`)
- Camadas derivadas de `buildResearchHierarchy` (depth = layer)
- Posições `(x, y)` computadas em domínio puro com spacing fixo
- Arestas prereq: `prerequisite → dependent`; toggle **Mostrar dependências** (default **visível**)
- Links órfãos (endpoint ausente) ignorados

### Busca (reuso Iter 17)
- Mesma `researchSearchQueryProvider`
- Nós matching: opacidade normal; demais atenuados (`opacity 0.35`)
- Query sem match: mensagem `researchSearchNoResults` (lista e grafo)

### Foco WIP
- Nó `inResearch` destacado com borda/ícone (via `activeResearchFocusProvider`)

### Progress lite (Iter 18 P1)
- Badges de evidência nos tiles do grafo
- Summary no topo da lista (`demonstrated / activeTotal`)
- Contagens derivadas — sem persistência, sem §33.6 confidence

### Export / restore / DB
- **Sem migration**; export permanece **v10**
- Layout e progress são derivados em runtime

## Consequências
- RESEARCH-001 ~75–80%: lista + grafo + progress lite
- ADR-017 §UI atualizado — canvas deferido → implementado (ADR-021)
- Keyboard nav completa no grafo **deferida**; lista cobre a11y

## Fora de escopo (Iter 18)
- Minimapa §60.7
- Filtro por trilha (§22.7)
- Pan/zoom persistido entre sessões
- Links quest↔research no grafo
- Pacote de layout externo; animações
- Performance tuning além de cap visual ~50 nós MVP

## Referências
- Spec §60.7, RESEARCH-001
- ADR-017 (lista MVP)
- ADR-019 (sessões/evidência)
- Plan Iter 18 (2e72f0b9)
