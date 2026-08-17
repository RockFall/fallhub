# Fallhub — Life Colony OS

Sistema operacional pessoal em Flutter: tarefas, rotina, habitat vivo e gestão de colônia — **local-first**, offline, sem conta.

Repo: [github.com/RockFall/fallhub](https://github.com/RockFall/fallhub)

## O que é

App Android-first (também roda em Windows/desktop) com:

- Inbox, tasks, timeline, quests, projects
- Pawn / needs / check-in / reviews
- Finanças e saúde locais (sem diagnosticar / sem executar operações bancárias)
- **Living Habitat** — mapa Flame com pawns, zonas, limpeza, conversas sociais
- Assets visuais do habitat versionados em `packages/living_habitat_assets/`

Especificação de produto: [`docs/produto/LIFE_COLONY_OS_SPEC.md`](docs/produto/LIFE_COLONY_OS_SPEC.md)  
Guia para agentes/devs: [`AGENTS.md`](AGENTS.md)

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) estável (SDK Dart compatível com `^3.11.4` no `pubspec.yaml`)
- Git
- Para Android: Android Studio / SDK + licenças (`flutter doctor --android-licenses`)
- Para Windows desktop: Visual Studio com workload *Desktop development with C++*

Confira o ambiente:

```bash
flutter doctor
```

## Clone e rode (notebook / máquina nova)

```bash
git clone https://github.com/RockFall/fallhub.git
cd fallhub

flutter pub get

# Gera código Drift (obrigatório na primeira vez / após mudar schema)
cd packages/colony_database
dart run build_runner build --delete-conflicting-outputs
cd ../..

# Lista dispositivos / emuladores
flutter devices

# App
flutter run
# ou alvo explícito:
# flutter run -d windows
# flutter run -d android
```

Os assets do habitat (`packages/living_habitat_assets/assets/`) vêm no clone — não precisa baixar nada extra para ver o Living Habitat.

### Atalho Windows (analyze + testes)

```powershell
./tool/test_all.ps1
```

Unix:

```bash
./tool/test_all.sh
```

## Estrutura

```text
fallhub/
  lib/                          # App Flutter (features, routing, l10n)
  packages/
    colony_domain/              # Entidades Dart puras
    colony_database/            # Drift, DAOs, repositórios
    colony_design_system/       # Tokens, tema, widgets
    living_habitat_assets/      # Sprites / tiles do Habitat (versionados)
  docs/
    produto/                    # Spec / PRD
    adr/                        # Architecture Decision Records
  tool/                         # Scripts (test_all, captures, etc.)
  test/                         # Testes do app
```

## Plataforma

| Alvo        | Status |
|-------------|--------|
| Android     | Primário |
| Windows     | Ok para desenvolver / Habitat |
| iOS / macOS / Linux | Compilam; UX prioriza Android |
| Web         | Não suportada na v1 (SQLite local) |

## Testar no celular (sem desktop)

O GitHub Actions gera um APK debug a cada push em `main` (e em PRs) e publica sempre no mesmo link:

**[fallhub-sideload.apk](https://github.com/RockFall/fallhub/releases/download/sideload-latest/fallhub-sideload.apk)**

No Android: abra o link → permitir instalação → instalar. Confira o commit em **Configurações → Build de teste** (tem de bater com o SHA do release [sideload-latest](https://github.com/RockFall/fallhub/releases/tag/sideload-latest)).

Guia completo: [`docs/dev/SIDELOAD.md`](docs/dev/SIDELOAD.md) · ADR-035

Disparo manual (GitHub no celular): **Actions → sideload_apk → Run workflow**.

## Build Android (APK debug, máquina local)

```bash
flutter build apk --debug
# Saída: build/app/outputs/flutter-apk/app-debug.apk
```

## Testes

```bash
flutter test
flutter test packages/colony_domain
flutter test packages/colony_database
```

## Notas

- **Local-first:** dados no dispositivo; sem login.
- Referências RimWorld brutas (`docs/produto/assets/reference/…`) **não** entram no git (EULA). Os assets do app em `living_habitat_assets` **sim**.
- Após alterar tabelas Drift: rode `build_runner` de novo em `packages/colony_database`.

## Licença / uso

Projeto privado de desenvolvimento. Assets e código sujeitos às regras do repositório e à spec (não redistribuir material de terceiros com EULA restritiva).
