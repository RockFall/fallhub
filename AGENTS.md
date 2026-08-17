# Guia de implementação — Life Colony OS

Fonte de verdade: [`docs/produto/LIFE_COLONY_OS_SPEC.md`](docs/produto/LIFE_COLONY_OS_SPEC.md)

## Objetivo

Implementar vertical slices completos (domínio → persistência → estado → UI → testes), sem over-engineering. Cada agente deve ler a seção da spec correspondente antes de codar.

## Estrutura do repositório

```text
fallhub/                          # app Flutter (colony_app)
  lib/
    app/                          # bootstrap, routing, theme, l10n
    core/                         # providers, services transversais
    features/<feature>/           # domain/application/data/presentation
  packages/
    colony_design_system/         # tokens, tema, widgets reutilizáveis
    colony_domain/                # entidades puras Dart, enums, value objects
    colony_database/              # Drift, DAOs, repositórios concretos
  docs/adr/                       # Architecture Decision Records
  docs/produto/                   # PRD (não editar sem aprovação)
```

## Regras absolutas (spec §0.1)

- Não copiar assets/layouts de RimWorld.
- Local-first: app útil offline, sem conta.
- Dados derivados com proveniência e confiança.
- Saúde não diagnostica; finanças não executam operações.
- Textos de UI em localization (`lib/app/localization/`).
- Domínio imutável; SQL só em `colony_database`.
- Widgets não acessam banco diretamente.

## Camadas por feature

```text
features/<name>/
  domain/          # re-exporta ou estende colony_domain
  application/     # commands, queries, Notifiers
  presentation/    # screens, widgets, routes
```

## Ordem de implementação (roadmap §45)

| Fase | Escopo | Status |
|------|--------|--------|
| 0 | Monorepo, DS, routing, Drift, profile, settings | concluído |
| 1 | Inbox, tasks, events, timeline, export, undo | concluído |
| 2 | Pawn, needs, check-in, daily review | concluído |
| 3 | Work grid, schedule | concluído |
| 4 | Quests, projects, decisions, weekly review | concluído |
| 5 | Research tree MVP | concluído (Iters 15–18; links quest↔research Iter 24) |
| 6 | Finance ledger manual (§23) | MVP avançado+ (CSV apply Iter 107; plan→apply) |
| 7 | Health local (§45) | MVP+ (appointments Iter 111; DB v33 / export v29) |
| 8 | Inventory / relations | Zone↔Trip+Home↔Inv+Commitment↔Quest+Packing ✅ (DB v33 / export v29) |
| 9 | Sync e backup | Stub local ✅ (outbox Iter 78; remote defer) |
| 10 | Integrações | MVP stub ICS ✅ (Iter 86; DB v30 / export v27); Health Connect defer |
| 11 | IA e Storyteller | MVP rules digest ✅ (Iter 87); LLM remoto defer |
| 12 | Maturidade | MVP utilizável ✅ (a11y 91; beta guarantees 92; L10N 93) |

## Coordenação entre agentes

1. **Design system** — só `packages/colony_design_system/`. Sem lógica de negócio.
2. **Domínio** — só `packages/colony_domain/`. Sem Flutter, sem Drift.
3. **Database** — só `packages/colony_database/`. Implementa interfaces do domínio.
4. **Features** — uma feature por agente; não duplicar repositórios.
5. Antes de merge: `flutter analyze`, `flutter test`, migration test se schema mudou.

## ADRs obrigatórios

Ver `docs/adr/`. Novas decisões arquiteturais → novo ADR antes de implementar.

## Definition of Done (spec §50)

- Estados vazio/carregando/erro/offline
- Testes relevantes passando
- Strings localizadas
- Critérios de aceitação da seção §46 demonstrados

## Comandos

```bash
dart run build_runner build --delete-conflicting-outputs
./tool/test_all.ps1   # Windows — analyze + app + packages
./tool/test_all.sh    # Unix
flutter run -d android
```

`tool/test_all` executa `flutter analyze` (0 erros; infos/warnings não bloqueiam), `flutter test` (app), `flutter test packages/colony_domain` e `flutter test packages/colony_database` — gate Definition of Done.

APK de teste no celular (sem desktop): workflow `sideload_apk` → [`docs/dev/SIDELOAD.md`](docs/dev/SIDELOAD.md).
