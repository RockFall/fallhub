# ADR-030: Commitments / promises local MVP (§24.4)

## Status
Aceito (Iter 74 spike — doc-only; produto na Iter 76+)

## Contexto
Spec §24.4 define `Commitment` (promessas): `made_by`, `made_to`, `description`, `due_at_optional`, `status`, `source_event_id`, `privacy_level`. Person + interactions + Organization + membership já existem (ADR-026/028). O app pode lembrar compromissos **sem** calcular “qualidade da amizade”. Local-first; não é CRM.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN (1ª slice produto sugerida pós-ADR)
1. **`Commitment`**
   - Campos: `id`, `profileId`, `description`, `madeByLabel` (string livre — “eu” / nome), `madeToPersonId?` (Person opcional), `madeToOrganizationId?` (Organization opcional), `dueAt?`, `status` (`open` | `kept` | `broken` | `cancelled`), `notes?`, `createdAt`, `updatedAt`
   - Regra: ao menos um de `madeToPersonId` / `madeToOrganizationId` / `madeToLabel` (string livre) — MVP pode exigir Person **ou** label
2. **UI**
   - Seção em Person detail/edit **ou** rota `/relations/commitments` lista leve
   - Criar/editar/marcar kept|broken|cancelled
   - Empty/loading/error; strings localizadas
   - Disclaimer: registro pessoal; sem scoring social
3. **Export**
   - Bump export com `commitments[]`
   - DB schema bump dedicado
4. **Camada**
   - `features/relations/` (mesmo hub) application|presentation
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- Reputação / scoring / “qualidade da amizade”
- `source_event_id` / auto-extração de crônica
- Privacy levels avançados / compartilhamento
- Sync / cloud
- Notificações push de prazo
- Pipeline CRM / follow-up automático agressivo

### Políticas
- App **lembra** e lista; não julga
- Arquivar/cancelar remove da lista ativa; histórico no export
- Minimização de dados de terceiros

### Eventos propostos
- `commitmentCreated`, `commitmentUpdated`, `commitmentStatusChanged`

### Critérios de aceite da 1ª slice (Iter 76+ pós-ADR)
1. Criar/editar/alterar status de compromisso offline
2. Lista vazia/carregando/erro + disclaimer
3. Export/restore round-trip
4. Zero cópia RimWorld; strings localizadas; providers em feature/

## Consequências
- Fecha planning gap Relations §24.4
- Iter 75 pit pode recalcular se home/inventory polish absorver 76
- Não bloqueia Phase 9 sync cautela
