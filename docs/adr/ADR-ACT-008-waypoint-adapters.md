# ADR-ACT-008: arquitetura de adapters de waypoint

## Status
Aceito

## Contexto
NFC, QR, BLE e Wi-Fi têm capacidades diferentes por plataforma.

## Decisão
`ActivationWaypoint` guarda tipo + token opaco. Observação passa por `observeWaypoint`. QR/deep link (`/activation/waypoints/reach?token=`) é o adapter real do MVP. NFC/BLE/Wi-Fi são tipos válidos com fallback manual. Sem coordenada exata.

## Consequências
Confiabilidade é empirica (observações confirmadas / total). Waypoint não é check-in de hábito.
