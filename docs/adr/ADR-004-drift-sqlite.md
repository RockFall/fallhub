# ADR-004: Drift/SQLite

## Status
Aceito

## Contexto
Spec §34.7 escolhe Drift por dados relacionais, migrations e queries reativas.

## Decisão
SQLite via Drift 2.x em `colony_database`. Schema v1: profiles, domain_events, tasks, preferences.

## Consequências
- Migrations versionadas e imutáveis após release
- DAOs por agregado
- Export JSON via queries diretas
