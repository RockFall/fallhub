# ADR-001: Flutter e plataformas

## Status
Aceito

## Contexto
Life Colony OS precisa rodar offline em Android, iOS, Windows, macOS e Linux, com web secundário.

## Decisão
Flutter stable (3.41.x) como framework único. App principal em `fallhub/` (codinome colony_app).

## Consequências
- UI compartilhada entre plataformas
- Platform channels isolados em adapters futuros
- Golden tests multi-plataforma viáveis
