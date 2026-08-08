# ADR-002: Arquitetura modular

## Status
Aceito

## Contexto
Spec §34 exige modular monolith feature-first com packages separados para domínio, DB e design system.

## Decisão
Packages locais via path dependency:
- `colony_domain` — Dart puro
- `colony_database` — Drift/SQLite
- `colony_design_system` — Flutter widgets/tokens

Features em `lib/features/<name>/` com camadas application e presentation.

## Consequências
- Domínio testável sem Flutter
- Migrations centralizadas em colony_database
- App permanece na raiz (evita mover android/ios/windows)
