# ADR-026: Relations / People local MVP (Phase 8)

## Status
Aceito (Iter 46 spike — doc-only; produto na Iter 47+)

## Contexto
Spec §24 define relações e facções: `Person`, interações, organizações/facções, commitments. Spec §45 Phase 8: inventário, relações, casa e viagem. Inventory MVP (ADR-024 / Iter 42) já existe. Sync (ADR-025) permanece deferido. Local-first: útil offline, sem conta. Minimização de dados de terceiros (§24.2) — não virar CRM comercial.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN
1. **`Person`** (subset §24.1)
   - Campos: `id`, `profileId`, `displayName`, `preferredName?`, `relationshipTypes[]` (strings livres no MVP — sem taxonomia rígida), `notes?` (contexto importante), `birthday?`, `lastInteractionAt?`, `nextFollowUpAt?`, `createdAt`, `updatedAt`
   - Status implícito: soft-archive via `archivedAt?` (nullable) — lista ativa omite arquivados
2. **UI**
   - Rota `/relations/people` — lista + criar/editar/arquivar
   - Empty/loading/error; strings localizadas
   - Disclaimer curto: dados de terceiros são pessoais; minimizar e proteger
3. **Export**
   - Bump export (v16+) com `people[]`
   - DB schema bump dedicado (v18+)
4. **Camada**
   - `features/relations/application|presentation`
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- `Organization` / facções (§24.3)
- Interaction log completo (§24.2) — **lite entregue Iter 53** (`PersonInteraction`); CRM/scoring ainda OUT
- `Commitment` (§24)
- Contact methods encrypted / consent scope
- CRM features (pipelines, funnels, scoring)
- Sync / cloud
- Link Person↔quest/inventory (cross-feature posterior)

### Políticas
- **Minimização:** campos opcionais por padrão; sem scraping de contatos do SO no MVP
- Notas podem ser sensíveis — privacyClass personal; sem export parcial
- App **não** sugere follow-ups automaticamente no MVP (só data opcional `nextFollowUpAt`)
- Arquivar remove da lista ativa; histórico permanece no export

### Eventos propostos
- `personCreated`, `personUpdated`, `personArchived`

### Critérios de aceite da 1ª slice (Iter 47+ pós-ADR)
1. Criar/editar/arquivar pessoa local offline
2. Lista vazia/carregando/erro + disclaimer
3. Export/restore round-trip da nova versão
4. Zero cópia de assets RimWorld; strings localizadas
5. Providers em `features/relations/application/`

## Consequências
- Phase 8 relations tem ADR antes de código — alinha protocolo AGENTS.md
- Iter 47 deve referenciar este ADR e **não** expandir para organizations/interactions
- Interaction log e organizations ficam ADRs/slices separados
