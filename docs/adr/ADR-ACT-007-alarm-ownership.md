# ADR-ACT-007: posse do alarme

## Status
Aceito

## Contexto
Exact alarms no Android 14+ e alarmes no iOS são restritos. O app já tem agenda e notificações.

## Decisão
O Motor de Ignição não toma posse do alarme do sistema. Janelas de agenda (`ScheduleBlock`) abrem oportunidade; não inferem inércia sozinhas. Exact alarm só se o caso de uso for central e a permissão for pedida à parte.

## Consequências
Morning Launch inicia por gesto explícito ou restauração. Descanso planejado bloqueia auto-start.
