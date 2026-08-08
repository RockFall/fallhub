# ADR-005: Local-first

## Status
Aceito

## Contexto
Spec §35: fonte operacional é o dispositivo; sync remoto é opcional e posterior.

## Decisão
Fase 0–2 sem backend. Persistência local completa. Export JSON manual. Sync stub não implementado.

## Consequências
- App funcional offline desde Fase 1
- Outbox/sync reservados para Fase 9
