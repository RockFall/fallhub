# ADR-ACT-005: estratégia de fricção no Android

## Status
Aceito

## Contexto
Não há API pública universal de Digital Wellbeing para terceiros. Accessibility Service é incompatível com as políticas da Play Store para este caso.

## Decisão
MVP: `FrictionShieldPlatformMode.policyOnly`. Sem Accessibility Service, sem VPN obrigatória, sem launcher. A UI descreve allowlist e escape. Usage Access fica como capacidade futura, opt-in, só para categorias escolhidas.

## Consequências
O app continua útil sem permissões especiais. Bloqueio nativo exige ADR e revisão de política.
