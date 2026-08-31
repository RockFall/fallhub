# ADR-051: Backup SQLite à prova de atualização

## Status
Aceito

## Contexto
O export JSON (ADR-015) serializa um subconjunto versionado do domínio. Ele já ficou atrás do schema Drift (`export` v39 vs schema 45) e não cobre sidecars em ficheiro (`google_timeline_*.json`). Restaurar JSON após um update do app exige manter um codec paralelo para cada tabela nova.

Um backup do ficheiro SQLite é o que o próprio Drift já sabe migrar: `PRAGMA user_version` + `onUpgrade`.

## Decisão

### Formato `COLNYBK1`
Contentor TLV (big-endian):

| Campo | Tamanho | Notas |
|-------|---------|--------|
| magic | 8 | `COLNYBK1` |
| container version | u32 | informativo; o decoder **não rejeita** versões futuras |
| section count | u32 | 1–256 |
| secções | type u32 + length u64 + body | tipos desconhecidos são **ignorados** |

Tipos conhecidos:

1. **manifest** — JSON `{ schemaVersion, exportedAt, dbFileName }`
2. **sqlite** — bytes do `colony.db` (obrigatório)
3. **sidecar** — nome UTF-8 + ficheiro (hoje `google_timeline_*.json`)

Também se aceita um `.db` / `.sqlite` cru (`SQLite format 3`). A versão vem do header, offset 60 (`user_version`), **sem** abrir o ficheiro com `ColonyDatabase` (isso migraria o probe).

### Update-proof
- Backup **mais antigo** que o app: `install` + `ColonyDatabase.open` corre `onUpgrade`.
- Backup **mais novo** que o app: rejeitado (`ColonySqliteBackupTooNewException`) **antes** de fechar o banco vivo.
- Secções TLV novas: apps velhos saltam-nas; o SQLite continua restaurável.
- JSON ADR-015 permanece como export portátil/parcial, não como backup primário.

### Export
`VACUUM INTO` no diretório de dados (mesmo filesystem). Fallback: `wal_checkpoint(TRUNCATE)` + cópia de `colony.db`. SharedPreferences (URL iCal, mapas de habitat, etc.) ficam de fora — o pedido é o banco.

### Restore
1. Validar contentor / schema (fail closed se `schema > app`).
2. Fechar a conexão Drift.
3. Copiar `colony.db` → `colony.db.bak`.
4. Escrever SQLite + substituir sidecars `google_timeline_*.json`.
5. Reabrir (migrações).
6. Se falhar: rollback do `.bak` e devolver a conexão recuperada. A UI troca o `ProviderScope` (`ColonyRoot`) sem matar o processo.

### UX
Configurações: **Guardar backup do banco** (partilha `.colonybk`) e **Restaurar backup** (file picker `any`, sniff SQLite / `COLNYBK1` / JSON). JSON antigo continua a usar ADR-015. Dupla confirmação destrutiva.

## Consequências
- Um update do app não exige bump do codec de backup: migrações Drift bastam.
- Restore SQLite substitui o ficheiro inteiro (incluindo a Crônica do snapshot); não acrescenta `exportRestored`.
- Testes de export precisam de `NativeDatabase` em ficheiro; in-memory não tem `VACUUM INTO`.

## Fora de escopo
- Merge parcial, backup incremental, sync remoto.
- SharedPreferences e ficheiros que não sejam sidecars conhecidos / secções TLV.
