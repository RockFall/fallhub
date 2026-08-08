# ADR-017: Research graph (lista MVP)

## Status
Aceito (Iter 15, Day 0)

## Contexto
A spec §22 define `ResearchNode` com pré-requisitos, pesquisa ativa (WIP) e árvore de conhecimento. Iter 9 (ADR-016) manteve research como domínio separado de quest prerequisites. Iter 15 abre Phase 5 com vertical slice **lista hierárquica** — sem grafo canvas, sessões ou evidências.

## Decisão

### Entidade `ResearchNode`
- Campos: `id`, `profileId`, `title`, `description?`, `type`, `status`, `createdAt`, `updatedAt`, `demonstratedNote?`, `version`
- **Tipos MVP** (subset §22.2): `skill`, `knowledge`, `capability`, `practice`
- **Status MVP** (subset §22.3): `available` → `inResearch` → `demonstrated` → `archived`

### Pré-requisitos
- Tabela `research_prerequisites` N:N — domínio **separado** de `quest_prerequisites` (ADR-016 §Consequências)
- Aresta `(node_id, prerequisite_node_id)`: nó B só pode ir para `inResearch` quando A ∈ `{demonstrated}`
- Self-link e ciclos rejeitados via DFS (`ResearchPrerequisitePolicy`) antes de persistir

### Pesquisa ativa (WIP §22.4)
- `ActiveResearchPolicy`: máximo **1** nó `inResearch` por perfil
- Segundo foco bloqueado com exceção parseável (`ActiveResearchException`)

### Demonstração
- Transição `inResearch` → `demonstrated` manual; nota opcional em `demonstratedNote`
- **Sem** evidência obrigatória (§22.1 completo → Iter 16+)

### UI §60.7
- **Modo lista hierárquica**: topo sort + indentação (`buildResearchHierarchy`)
- **Grafo canvas** → ADR-021 (Iter 18): toggle Lista/Grafo, pan/zoom, arestas prereq

### Export / restore
- **Export v9**: `research_nodes[]`, `research_prerequisite_links[]`
- Backups v≤8 restauram research `[]`
- DB **v10**: tabelas + migration v9→v10

### Application layer
- Providers/controllers em `lib/features/research/application/` — **não** em `core/` (threshold meta-review Iter 15)

## Consequências
- Phase 5 iniciada; RESEARCH-001 parcial (modelo + prereqs + WIP + lista)
- Quest detail **inalterado** — zero links quest↔research nesta iter
- Restore v9 round-trip preserva grafo de dependências research

## Fora de escopo (Iter 15)
- Grafo canvas interativo (§60.7 completo) — **implementado em ADR-021 (Iter 18)**
- `LearningSession`, `Evidence`, `LearningPath`
- Links quest↔research
- Spaced repetition (§22.6)
- Music Atlas

## Referências
- Spec §22, §60.7, RESEARCH-001
- ADR-016 (quest prereqs separados)
- ADR-015 (export v9)
- Plan Iter 15 (f242eba3)
