# ADR-029: Home maintenance local MVP (Phase 8 / §25.3)

## Status
Aceito (Iter 68 spike — doc-only; produto na Iter 71+)

## Contexto
Spec §25.3 define manutenção doméstica (item/sistema, periodicidade, fornecedor, custo, garantia, histórico, checklist, documentação). ADR-027 entregou Trip MVP e deixou home maintenance OUT. Inventário (ADR-024) já cobre itens com `warrantyEnd` opcional, mas **não** agenda de manutenção recorrente nem sistemas da casa. Local-first; finanças não executam pagamentos; app não contrata fornecedores.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN (1ª slice produto sugerida pós-ADR)
1. **`HomeMaintenanceTask`** (subset §25.3)
   - Campos: `id`, `profileId`, `title`, `systemOrItem` (string livre — sem Location entity), `cadenceDays?` (periodicidade em dias; null = avulso), `nextDueAt?`, `lastDoneAt?`, `vendorLabel?` (fornecedor livre), `estimatedCostMinor?` + `currency?`, `notes?`, `linkedInventoryItemId?` (opcional → InventoryItem), `archivedAt?`, `createdAt`, `updatedAt`
2. **UI**
   - Rota `/resources/home` ou `/resources/maintenance` — lista + criar/editar/marcar feito/arquivar
   - Empty/loading/error; strings localizadas
   - Disclaimer: registro pessoal local; não agenda serviços externos nem recomenda fornecedores
3. **Ação “marcar feito”**
   - Atualiza `lastDoneAt`; se `cadenceDays` presente, avança `nextDueAt = lastDoneAt + cadenceDays`
4. **Export**
   - Bump export com `home_maintenance_tasks[]`
   - DB schema bump dedicado
5. **Camada**
   - `features/home/` (ou `features/maintenance/`) application|presentation
   - Domínio em `colony_domain`; SQL só em `colony_database`
   - Providers em feature application/

### Escopo OUT (defer explícito)
- `Location` / `ContextZone` (§25.1–25.2)
- Checklist aninhada / anexos / documentos criptografados
- Integração automática com ledger (criar despesa ao marcar feito)
- Notificações push / alarmes do SO
- Matching de fornecedores / marketplace
- Sync / cloud
- Multi-casa / multi-perfil de imóvel

### Políticas
- **Minimização:** campos opcionais; sem scrape de e-mail/calendário
- Custo é registro manual; app **não** executa pagamento
- Link com inventário é opcional e unidirecional (não cascade delete)
- App **não** diagnostica risco estrutural nem prioriza “urgência” além de ordenar por `nextDueAt`

### Eventos propostos
- `homeMaintenanceCreated`, `homeMaintenanceUpdated`, `homeMaintenanceCompleted`, `homeMaintenanceArchived`

### Critérios de aceite da 1ª slice (Iter 71+ pós-ADR)
1. Criar/editar/arquivar tarefa de manutenção local offline
2. Marcar feito atualiza datas conforme cadence
3. Lista vazia/carregando/erro + disclaimer
4. Export/restore round-trip da nova versão
5. Zero cópia RimWorld; strings localizadas; providers em feature/

## Consequências
- Fecha planning gap de Phase 8 house deixado por ADR-027
- Iter 69–70 podem intercalares (polish / pit) sem bloquear produto em 71
- Inventory warranty permanece independente; link opcional é polish futuro se necessário
