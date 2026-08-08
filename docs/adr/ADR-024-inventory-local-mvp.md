# ADR-024: Inventory local MVP (Phase 8 spike)

## Status
Aceito (Iter 41 spike — doc-only; produto na Iter 42+)

## Contexto
Spec §17 define inventário amplo (itens, localização, garantia, manutenção, loadouts, anexos, vínculo financeiro). Spec §45 Phase 8: inventário, relações, casa e viagem. O app ainda não tem entidade de inventário. Local-first: útil offline, sem conta. Não copiar layouts RimWorld.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN
1. **`InventoryItem`** (subset §17.3)
   - Campos: `id`, `profileId`, `name`, `category` (enum lite), `status` (`active` | `stored` | `lent` | `disposed` | `archived`), `locationLabel?` (string livre no MVP — sem entidade Location), `notes?`, `tags[]` (strings), `purchaseDate?`, `purchasePriceMinor?` + `purchaseCurrency?`, `warrantyEnd?`, `createdAt`, `updatedAt`
   - Categorias MVP: `electronics`, `document`, `clothing`, `tool`, `consumable`, `media`, `other`
2. **UI**
   - Rota `/resources/inventory` — lista + criar/editar/arquivar
   - Empty/loading/error; strings localizadas
3. **Export**
   - Bump export (v15+) com `inventory_items[]`
   - DB schema bump dedicado (v17+)
4. **Camada**
   - `features/inventory/application|presentation`
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- Entidade `Location` / mapa de casa (§17)
- Loadouts e checklists (§17.4)
- `serial_number_encrypted`, attachments, manutenção recorrente
- `linked_financial_asset_id` / vínculo ledger
- People/organizations/commitments (outras fatias Phase 8)
- Trip mode
- Sync / cloud

### Políticas
- Inventário é **registro pessoal**; não rastreia localização GPS automaticamente
- Preço/valor são opcionais e manuais; app **não** avalia mercado
- `disposed` / `archived` removem da lista ativa; histórico permanece no export

### Eventos propostos
- `inventoryItemCreated`, `inventoryItemUpdated`, `inventoryItemStatusChanged`

### Critérios de aceite da 1ª slice (Iter 42+ pós-ADR)
1. Criar/editar/arquivar item local offline
2. Lista vazia/carregando/erro
3. Export/restore round-trip da nova versão
4. Zero cópia de assets RimWorld; strings localizadas
5. Providers em `features/inventory/application/`

## Consequências
- Phase 8 tem ADR antes de código — alinha protocolo AGENTS.md
- Iter 42 deve referenciar este ADR e **não** expandir para loadouts/locations
- People/relations e sync permanecem ADRs separados
