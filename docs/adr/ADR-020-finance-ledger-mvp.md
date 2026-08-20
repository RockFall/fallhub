# ADR-020: Finance ledger MVP

## Status
Implementado (Iter 19)

## Contexto
A spec §23 define finanças multi-entidade com contas, transações, orçamento, patrimônio e importações. Phase 6 (FIN-001) ainda não tem ADR dedicado; ADR-011 (Open Finance) **não existia** no repositório na Iter 17. Iter 17 registra o escopo MVP **manual local-first** antes de qualquer código de produto. ADR-011 foi registrado depois como spike de imports/Open Finance (pesquisa Inter em `docs/dev/INTER_BANKING_INTEGRATION.md`).

## Decisão

### Entidades MVP (subset §23.3–23.5)

**`FinancialEntity`**
- Campos: `id`, `profileId`, `name`, `kind`, `createdAt`, `updatedAt`
- **Kinds MVP:** `personal`, `business`, `project`, `trip`, `shared`
- Transferências entre entidades exigem par explícito (deferido para pós-MVP)

**`FinancialAccount`**
- Campos: `id`, `profileId`, `entityId`, `institution`, `name`, `type`, `currency`, `currentBalanceMinor`, `balanceAsOf`, `includeInNetWorth`, `sensitiveDisplayMode`, `createdAt`, `updatedAt`
- **Types MVP:** `checking`, `savings`, `cash`, `creditCard`, `investment`, `receivable`, `payable`, `other`
- `externalConnectionId` **deferido** (Open Finance → ADR futuro)

**`Transaction`**
- Campos: `id`, `profileId`, `accountId`, `occurredAt`, `descriptionOriginal`, `amountMinor`, `currency`, `direction`, `categoryId?`, `notes?`, `fingerprint`, `createdAt`, `updatedAt`
- Valores em **`amount_minor`** (int) + `currency` ISO 4217
- `direction`: `inflow` | `outflow`
- `fingerprint`: hash estável para deduplicação manual/import futuro
- **Deferido:** `postedAt`, `merchantNormalized`, `transferPairId`, `installmentGroupId`, splits

### Políticas

**`FinanceDisplayPolicy`**
- Máscara de valores sensíveis quando `sensitiveDisplayMode = hidden` (spec §0)
- App **não executa** transferências bancárias, pagamentos ou investimentos

**`FinanceLedgerPolicy`**
- CRUD local manual; saldo derivado de transações + snapshot opcional `currentBalanceMinor`
- Reconciliação automática **fora de escopo** MVP

### Disclaimers (spec §0, §23.9)
- Não diagnostica situação financeira nem recomenda investimentos
- Não substitui contador ou assessor
- Dados são registro pessoal local; usuário responsável por precisão

### Export / restore (v11)
- **Export v11:** `financial_entities[]`, `financial_accounts[]`, `transactions[]`
- Backups v≤10 restauram finance `[]`
- DB **v12 (Iter 19):** tabelas `financial_entities`, `financial_accounts`, `ledger_transactions` com FK → `profiles`, `financial_entities`, `financial_accounts`

### Ordem FK proposta (addendum ADR-015)
**Delete:** `transactions` → `financial_accounts` → `financial_entities` → …
**Insert:** `financial_entities` → `financial_accounts` → `transactions` → …

### UI / rotas
- Rota `/resources/finance` — lista de contas + transações recentes
- Sem Sankey/waterfall, orçamento ou simulação no MVP

### Eventos (propostos)
- `financialAccountCreated`, `financialAccountUpdated`
- `transactionCreated`, `transactionUpdated`, `transactionDeleted`

## Consequências
- Phase 6 desbloqueada para implementação em Iter 19+ sem scope creep de Open Finance
- Export permanece **v10** até Iter 19 (v11 com finance)
- Quest/Research **inalterados** nesta iter

## Fora de escopo (MVP e Iter 17)
- Open Finance / imports automatizados (ADR-011 futuro)
- Orçamento, fluxo de caixa, patrimônio, investimentos, dívidas, assinaturas
- Split de transação, transfer pair, reconciliação bancária
- Sankey/waterfall (spec §4942)
- Execução de operações financeiras

## Addendum — Categorias lite (Iter 21)

- **`TransactionCategory`:** enum flat com 10 categorias predefinidas (`food`, `transport`, `housing`, `health`, `entertainment`, `shopping`, `utilities`, `education`, `income`, `other`)
- **Persistência:** reutiliza `category_id` nullable em `ledger_transactions` (IDs estáveis `cat_<name>`); **sem** tabela de categorias nem migration v12→v13
- **`TransactionCategoryPolicy`:** mapeamento id↔enum, validação, filtro por `direction` (income só em entradas)
- **UI:** picker em add/edit transaction; tap em transação recente abre edit sheet com delete confirmado
- **Export:** permanece **v11** (campo `category_id` já serializado)
- **Deferido:** categorias customizadas, subcategorias, regras automáticas, edição em massa

## Addendum — ADR-011 (imports / Open Finance)

Spike em `docs/adr/ADR-011-financial-imports-open-finance.md`. Pesquisa Inter: `docs/dev/INTER_BANKING_INTEGRATION.md`. O ledger MVP permanece manual; a 1ª slice de import automática é arquivo OFX/CSV Inter, não API PF.

## Referências
- Spec §23, §62.5, FIN-001, §0 (disclaimers)
- ADR-015 (export v11 outline)
- ADR-005 (local-first)
- ADR-011 (financial imports / Open Finance)
- Plan Iter 17 (866a5322)
