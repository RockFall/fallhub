# ADR-ACT-010: segurança Home Assistant

## Status
Aceito (dry-run only)

## Contexto
Automação residencial é reversível na spec, mas HTTP local implica rede e credenciais.

## Decisão
`ActivationHomeAutomationPolicy.dryRun` apenas simula. Nenhuma chamada de rede, nenhum token persistido. Cenas reais exigem consentimento, idempotência e este ADR atualizado.

## Consequências
Falha de ambiente não quebra a rota: o comando continua com prova manual.
