# ADR-028: Organization / factions local MVP (Phase 8)

## Status
Aceito (Iter 58 spike — doc-only; produto em iter futura)

## Contexto
Spec §24.3 define facções/organizações (empresa, universidade, família, clínica, etc.). Person MVP + interaction lite (ADR-026 / Iters 47+53) já existem. Organizations fecham o núcleo relations antes de commitments (§24.4). Local-first; não virar CRM comercial.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN (1ª slice produto sugerida)
1. **`Organization`** (subset §24.3)
   - Campos: `id`, `profileId`, `name`, `kind` (enum lite: `company`, `university`, `family`, `friends`, `association`, `community`, `vendor`, `clinic`, `financial`, `other`), `notes?`, `archivedAt?`, `createdAt`, `updatedAt`
2. **UI**
   - Rota `/relations/organizations` — lista + criar/editar/arquivar
   - Empty/loading/error; strings localizadas
   - Disclaimer: registro pessoal; minimizar dados de terceiros
3. **Export**
   - Bump export com `organizations[]`
   - DB schema bump dedicado
4. **Camada**
   - `features/relations/` (mesmo hub) ou `features/organizations/` se crescer
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Membership stub (Iter 67)
- Tabela N:N `person_organizations` (`person_id`, `organization_id`, `role?`, `linked_at`)
- Link/unlink na UI de editar pessoa/organização
- Export **v21** chave `person_organization_links`; DB **v23**

### Escopo OUT (defer explícito)
- Reputação subjetiva / scoring / pipelines CRM
- Commitments (§24.4)
- Documentos/projetos/decisões linkados
- Sync / cloud
- Importação de contatos do SO
- Papéis ricos / hierarquia / organograma

### Políticas
- **Minimização:** campos opcionais; sem scrape de LinkedIn/contatos
- App **não** calcula “qualidade” de relação com organização
- Arquivar remove da lista ativa; histórico no export

### Eventos propostos
- `organizationCreated`, `organizationUpdated`, `organizationArchived`

### Critérios de aceite da 1ª slice
1. Criar/editar/arquivar organização local offline
2. Lista vazia/carregando/erro + disclaimer
3. Export/restore round-trip
4. Zero cópia RimWorld; strings localizadas
5. Providers em feature application/

## Consequências
- Relations planejado: Person → interactions → Organization → membership → commitments
- Não bloqueia Trip MVP (ADR-027) nem budget polish
