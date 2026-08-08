# `lib/core/` — plataforma residual

Documento da Iter **54**; atualizado Iter **69** (remoção de shims).

## Papel

`lib/core/` hospeda bootstrap de app, providers de infraestrutura e widgets transversais. Features de domínio vivem em `lib/features/<name>/`. Widgets de feature **não** acessam Drift diretamente — passam por `repositoriesProvider` / feature providers.

## Inventário (pós Iter 69)

| Path | Tipo | Destino |
|------|------|---------|
| `providers/app_providers.dart` | **Plataforma** | DB, profile, preferences, repositories, routing glue |
| `providers/feature_controllers.dart` | **Plataforma** | Export/import, undo, captura transversal |
| `widgets/command_palette.dart` | **Plataforma** | Paleta global cross-feature |
| `widgets/quick_capture_sheet.dart` | **Plataforma** | Inbox/captura rápida |

## Shims removidos (Iter 69)

Removidos após auditoria (`rg` zero callers em `lib/` e `test/`):

- `providers/quest_*.dart`
- `providers/pawn_*.dart`
- `providers/work_*.dart`
- `providers/project_*.dart`
- `providers/decision_*.dart`

Callers usam diretamente `features/<name>/application/`.

## Regras

1. **Não** mover inbox/undo/export/onboarding para `features/` sem ADR — são transversais.
2. Novos providers de domínio → `features/<name>/application/` apenas.
3. **Não** recriar shims de compatibilidade sem necessidade documentada.

## Débito aceito

- Command palette importa rotas de várias features — acoplamento UI aceitável para hub Android.

## Próximos passos

- Phase 9 sync: outbox/providers em `features/sync/` via ADR-025.
- Home maintenance produto: ADR-029 / Iter 71+.
