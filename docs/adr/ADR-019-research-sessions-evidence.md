# ADR-019: Research sessions + evidence lite

## Status
Aceito (Iter 16, Day 0)

## Contexto
ADR-017 entregou lista hierárquica de `ResearchNode` com demonstração manual sem evidência. A spec §22.1 exige que domínio só seja marcado quando houver evidência; §22.5 define `LearningSession`. Iter 16 fecha esse gap com vertical slice **lite** — sem trilhas, spaced repetition, anexos ou rubricas.

## Decisão

### Entidade `LearningSession` (subset §22.5)
- Campos: `id`, `profileId`, `nodeId`, `startedAt`, `durationMinutes`, `mode`, `notes?`
- **Modos MVP:** `read`, `watch`, `practice`, `review`
- **Deferido:** `source_id`, `questions[]`, `perceived_difficulty`, `focus_quality`, `next_step`

### Entidade `ResearchEvidence` (subset §22.1)
- Campos: `id`, `profileId`, `nodeId`, `sessionId?`, `type`, `title`, `body`, `createdAt`
- **Tipos MVP:** `note`, `practiceLog`, `summary`
- Evidência opcionalmente vinculada a sessão (`sessionId`)

### Política `ResearchDemonstrationPolicy`
- Transição `inResearch → demonstrated` **bloqueada** quando `evidenceCount(node) < 1`
- Exceção parseável: `ResearchDemonstrationException`
- Nota de demonstração (`demonstratedNote`) permanece opcional **após** gate satisfeito

### Grandfathering (migration v10→v11)
- Nós já `demonstrated` antes de Iter 16 recebem evidência sintética:
  - Se `demonstratedNote` presente → `type=summary`, `title='Demonstração (migrado)'`, `body=demonstratedNote`
  - Senão → `type=summary`, `title='Demonstração (migrado)'`, `body='Registro anterior à exigência de evidência'`
- Nós `demonstrated` após migration continuam válidos; gate aplica-se só a novas transições

### Export / restore
- **Export v10:** `learning_sessions[]`, `research_evidence[]`
- Backups v≤9 restauram sessions/evidence `[]`
- DB **v11:** tabelas `learning_sessions`, `research_evidence` (FK → `research_nodes`)

### Ordem FK (addendum ADR-015)
**Delete (filhos primeiro):** `research_evidence` → `learning_sessions` → … (existente)
**Insert:** `research_nodes` → `learning_sessions` → `research_evidence` → `research_prerequisite_links`

### Eventos
- `researchSessionLogged` — payload: `{ node_id, mode, duration_minutes }`
- `researchEvidenceCreated` — payload: `{ node_id, type, title }`

## Consequências
- RESEARCH-001 ~60%: lista + sessões + evidência + gate demonstrate
- ADR-017 demonstração manual sem evidência **supersedida** para novas transições
- WIP=1 (`ActiveResearchPolicy`) inalterado; sessões são histórico

## Fora de escopo (Iter 16)
- Grafo canvas (§60.7)
- Links quest↔research
- `LearningPath`, spaced repetition (§22.6–22.7)
- Anexos, rubricas, `source_id`

## Referências
- Spec §22.1, §22.5, RESEARCH-001
- ADR-017 (lista MVP)
- ADR-015 (export v10)
- Plan Iter 16 (4c281ff2)
