# ADR-003: Riverpod

## Status
Aceito

## Contexto
Spec §34.5 recomenda Riverpod 3.x com Notifier/AsyncNotifier.

## Decisão
`flutter_riverpod` para DI e estado. Repositories expostos via providers. Commands como métodos de Notifier.

## Consequências
- Sem service locator global
- Widgets usam `ref.watch` com `select` quando apropriado
- Testes com `ProviderContainer`
