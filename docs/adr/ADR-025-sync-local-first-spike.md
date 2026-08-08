# ADR-025: Sync local-first spike (Phase 9)

## Status
Aceito (Iter 43 spike — doc-only; 1ª slice produto Iter 78: outbox local + device + noop worker)

## Contexto
Spec §35 define local-first com outbox, sync remoto opcional, conflitos por campo e backup criptografado. Spec §45 Phase 9: device identity, outbox, remote blob store, conflicts, recovery, restore drills. Spec §62.7 / §63 descrevem `sync_operations` e contrato remoto. ADR-005 já fixou: fases iniciais sem backend; export JSON manual.

O app hoje tem **export/restore full-replace** (ADR-015) como único caminho de backup. Inventory MVP (ADR-024 / Iter 42) fecha o P0 de Phase 8 inventário; relations/casa ainda abertos. Sync product **não** deve começar antes de:

1. Este ADR (spike)
2. Continuidade de Phase 8 (relations/people ou polish inventário)
3. Decisão explícita de backend/protocolo na 1ª slice de produto

## Decisão (spike — sem código produto nesta iter)

### Princípios (IN)
1. **Local permanece fonte operacional** — mutações UI nunca bloqueiam em rede (ADR-005 + §35.1)
2. **Outbox append-only** — toda mutação sincronizável gera `SyncOperation` (§35.2 / §62.7)
3. **E2EE preferido para backup pessoal** — servidor guarda blobs/metadados; não lê payload em modo privado (§35.3, §63.1)
4. **Conflitos explícitos** — nunca merge silencioso de saúde ou decisões (§35.4)
5. **Export JSON atual permanece** — sync não substitui ADR-015 no MVP sync; coexistência

### Escopo OUT (defer explícito até fatia de produto)
- Implementação de tabela `sync_operations` / device registry
- Servidor remoto, auth, OpenAPI
- UI de conflito / status de sync na shell
- Recovery key UI e rotação de chaves
- Multi-dispositivo real
- Sync de anexos / blobs

### Modelo de domínio proposto (futuro)

```text
DeviceIdentity: id, label, createdAt, lastSeenAt?, publicKey?
SyncOperation:
  id, entityType, entityId, operation (upsert|delete),
  baseVersion?, payload (opaque/ciphertext), status,
  attempts, nextAttemptAt?, createdAt, updatedAt
SyncStatus: idle | pending | syncing | conflict | error
```

### Políticas de conflito (resumo §35.4)
| Domínio | Política |
|---------|----------|
| Domain events | append-only |
| Tags | union |
| Preferences simples | last-write-wins |
| Texto importante (notas, decisões) | merge manual |
| Ledger transactions | pairwise reconciliation |
| Health / decisions | **nunca** merge silencioso |

### Camada futura
- Pacote candidato: `colony_sync_protocol/` (spec § architecture) — puro Dart, sem Flutter
- Persistência outbox: `colony_database` (tabela dedicada)
- UI: `features/sync/` + indicador shell (status only)
- Providers em `features/sync/application/`

### Critérios de aceite da 1ª slice de produto (pós-ADR, não Iter 43)
1. Device identity local + outbox table + enqueue em ≥1 mutação piloto (ex.: task create)
2. Worker local no-op (processa idle → pending sem rede) ou mock transport
3. Export/restore ADR-015 continua verde (sem regressão)
4. Zero dependência de conta obrigatória; sync opt-in
5. Strings localizadas; disclaimer “sync opcional / offline-first”

### Ordem recomendada pós-spike
1. Fechar Phase 8 relations/people ADR ou inventory polish (META backlog)
2. Pit stop recalcula
3. Só então: schema outbox + device identity MVP (sem remote)

## Consequências
- Phase 9 tem ADR antes de código — alinha protocolo AGENTS.md
- Iter 43 **não** cria tabelas nem UI de sync
- ADR-005 permanece válido; este ADR detalha o caminho Phase 9
- Produto sync só após backlog P0 de inventário/relações estabilizar
