# ADR-027: House / Travel local MVP (Phase 8)

## Status
Aceito (Iter 56 spike — doc-only; produto na Iter 61+)

## Contexto
Spec §25 (casa, locais, zonas) e §26 (viagens/expedições) fecham Phase 8 junto com inventário e relações. Inventory (ADR-024), Person + interaction lite (ADR-026) e sync spike (ADR-025) já existem. Local-first: útil offline, sem conta. Finanças não executam operações; saúde não diagnostica — viagens não devem virar agência/OTA.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN (1ª slice produto sugerida pós-ADR)
1. **`Trip`** (subset §26.1)
   - Campos: `id`, `profileId`, `title`, `destinations[]` (strings livres), `startAt?`, `endAt?`, `purpose?`, `notes?`, `status` (`planned` | `active` | `completed` | `cancelled`), `createdAt`, `updatedAt`
   - Soft-archive opcional via `archivedAt?` se necessário — MVP pode usar só status
2. **UI**
   - Rota `/travel` ou `/resources/travel` — lista + criar/editar/mudar status
   - Empty/loading/error; strings localizadas
   - Disclaimer: planejamento pessoal local; não reserva voos/hotéis
3. **Export**
   - Bump export com `trips[]`
   - DB schema bump dedicado
4. **Camada**
   - `features/travel/application|presentation`
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- `ContextZone` / capabilities (§25.2) — ADR/slice futura
- `Location` cadastral completo (§25.1) — labels livres em Trip bastam no MVP
- Manutenção doméstica (§25.3) — **ADR-029** (Iter 68); produto Iter 71+
- Bookings, itinerary items, insurance
- Packing loadout entity completa (`packing_loadout_id`) — stub N:N `trip_inventory` / `TripInventoryLink` entregue na Iter 113; loadout tipado defer
- Multi-currency trip budget (usar `budget_id` só após CategoryBudget/trip link)
- Modo viagem offline pack completo (§26.3 biométrico)
- Sync / cloud / Open Finance

### Políticas
- **Minimização:** sem scraping de calendário/e-mail no MVP
- Trip **não** cria reservas externas; só registro manual
- Participantes: strings ou Person IDs opcionais — Person link defer até slice dedicada
- App **não** recomenda destinos nem preços

### Eventos propostos
- `tripCreated`, `tripUpdated`, `tripStatusChanged`

### Critérios de aceite da 1ª slice (Iter 61+ pós-ADR)
1. Criar/editar/concluir viagem local offline
2. Lista vazia/carregando/erro + disclaimer
3. Export/restore round-trip da nova versão
4. Zero cópia de assets RimWorld; strings localizadas
5. Providers em `features/travel/application/`

## Consequências
- Phase 8 house/travel tem ADR antes de código — alinha protocolo AGENTS.md
- Iter 57 (People E2E) e 58 (Organization ADR) podem intercalar sem bloquear Trip MVP
- Home maintenance: ver ADR-029
