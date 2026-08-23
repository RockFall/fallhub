# ADR-ACT-006: FamilyControls e extensões iOS

## Status
Aceito (defer de entitlement)

## Contexto
ManagedSettings/DeviceActivity exigem entitlement Apple e extensões nativas.

## Decisão
Não implementar extensões nesta fatia. Capacidades iOS são descritas como indisponíveis (`iosConservative`). Shield local permanece `policyOnly`. Entitlement e DeviceActivityMonitor entram só após aprovação e plugin interno dedicado.

## Consequências
Paridade falsa com Android é proibida. A UI fala o que o dispositivo realmente faz.
