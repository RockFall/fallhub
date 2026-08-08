# Beta migration & export guarantees (ADR-034 / Phase 12)

**Última atualização:** Iter 111  
**Schema DB atual:** v32  
**Export write atual:** v28  

## Promessas (beta local-first)

1. **Upgrade in-place** — abrir o app após update aplica migrations Drift `onUpgrade` sequenciais; dados locais não são apagados no upgrade.
2. **Export/restore** — backup JSON versões **1…28** restauram com full-replace (ADR-015); versões fora da faixa são rejeitadas sem mutar o DB.
3. **Outbox/sync device** — `sync_operations` / `device_identities` **não** entram no export; restore faz wipe dessas tabelas (comportamento intencional).
4. **NarrativeDigest** — efêmero (não persistido); não há garantia de histórico de digests.
5. **Saúde / finanças** — restore não “reexecuta” operações externas; apenas reinsere registros locais.

## Matriz rápida

| De → Para | Mecanismo | Teste |
|-----------|-----------|-------|
| DB v28 → v29 | migration `integration_*` | `migration_test` |
| DB v29 → v30 | migration `zone_trips` | `migration_test` |
| Export v26 → app atual | parse + backfill `[]` zone_trip_links | `export_schema_v27_test` |
| Export v27 round-trip | buildSnapshot → restore → buildSnapshot | `export_restore_test` |
| Export v1 mínimo | parse + defaults | `export_snapshot_test` |

## Fora de garantia (beta)

- Merge parcial / restore seletivo
- Downgrade de schema DB
- Multi-device sync remoto / E2EE
- Compatibilidade com forks não oficiais do schema

## Como validar antes de beta

```powershell
cd C:\fall\dev\fallhub
.\tool\test_all.ps1
```

Gate verde = migrations + export/restore + pirâmide mínima OK.
