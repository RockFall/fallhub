# ADR-031: ContextZone local MVP (§25.2)

## Status
Aceito (Iter 79 spike — doc-only; produto na Iter 81+)

## Contexto
Spec §25.2 define `ContextZone`: nome, `location_id_optional`, `capabilities[]`, `unavailable_work_types[]`, `required_items[]`, `connectivity`, `noise_profile`, `privacy_profile`. Exemplo: “avião” permite leitura offline e notas, mas não chamadas ou tarefas dependentes de rede.

Phase 8 já tem Trip (ADR-027), Home maintenance (ADR-029), Inventory e Relations. Zonas contextuais fecham o restante de §25 sem GPS/loadouts. Local-first; app **não** rastreia localização em tempo real nem bloqueia o SO.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN (1ª slice produto sugerida pós-ADR)
1. **`ContextZone`**
   - Campos: `id`, `profileId`, `name`, `capabilities` (lista de strings livres — ex.: `read`, `notes`, `calls`), `unavailableWorkTypes` (lista de `WorkType` names ou strings), `requiredInventoryItemIds?` (opcional → InventoryItem), `connectivity` (`online` | `offline` | `limited` | `unknown`), `notes?`, `archivedAt?`, `createdAt`, `updatedAt`
   - MVP **sem** `Location` entity — nome da zona basta; `locationLabel?` string livre opcional
2. **UI**
   - Rota `/resources/zones` lista leve + create/edit/archive
   - Empty/loading/error; strings localizadas
   - Disclaimer: registro pessoal; não geofencing; não bloqueia o dispositivo
3. **Uso leve (opcional na 1ª slice)**
   - Exibir zona ativa sugerida manualmente (picker) — **sem** auto-detect
   - Não filtrar Work grid automaticamente na 1ª slice (defer polish)
4. **Export**
   - Bump export com `context_zones[]`
   - DB schema bump dedicado
5. **Camada**
   - `features/zones/` (ou sob `features/home/`) application|presentation
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- `Location` entity / GPS / geofencing
- Auto-ativação por Wi‑Fi / Bluetooth / horário
- Bloquear UI ou SO conforme zona
- Noise/privacy profiles avançados (MVP: só connectivity + capabilities texto)
- Sync / cloud
- Integração automática com Trip (zona “em viagem”)

### Políticas
- App **lembra** e sugere; não vigia
- Capabilities são labels, não permissões do SO
- Minimização: sem coordenadas

### Eventos propostos
- `contextZoneCreated`, `contextZoneUpdated`, `contextZoneArchived`

### Critérios de aceite da 1ª slice (Iter 81+ pós-ADR)
1. Criar/editar/arquivar zona offline
2. Lista vazia/carregando/erro + disclaimer
3. Export/restore round-trip
4. Zero cópia RimWorld; strings localizadas; providers em feature/

## Consequências
- Fecha planning gap §25.2
- Iter 80 pit pode recalcular se sync polish absorver 81
- Não bloqueia Phase 10 integrations ADR
