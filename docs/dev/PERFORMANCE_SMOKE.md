# Performance smoke — Phase 12 (Iter 102)

Checklist local-first para cold-start e hubs densos. **Não** é benchmark formal; é nota operacional para beta.

## Alvos (dispositivo mid-range Android)

| Cenário | Alvo suave | Como checar |
|---------|------------|-------------|
| Cold start → Colônia | < 3s até primeiro frame útil | `flutter run --profile`, cronômetro |
| Abrir hub Settings/Sync | < 500ms percepível | navegação manual |
| Abrir Resources (Finance/Health/Inventory) | < 700ms | lista vazia e com ~50 rows |
| Export JSON buildSnapshot | < 2s em DB típico beta | Settings → export |
| NarrativeDigest generate | < 100ms | weekly/chronicle botão |

## Hotspots conhecidos

1. **Bootstrap E2E / widget suite** — muitos `pumpAndSettle` + Drift streams; flushes com `SizedBox.shrink` evitam timers pendentes.
2. **sqlite3.dll (Windows host)** — lock em `build/native_assets` pode travar `flutter test`; limpar pasta e matar `flutter_tester`.
3. **Outbox enqueue** — best-effort pós-create; não bloquear UI se sync falhar.

## Antes de release beta

```powershell
cd C:\fall\dev\fallhub
.\tool\test_all.ps1
flutter run -d <android> --profile
```

Passar checklist mental dos alvos acima; registrar regressões em LOOP.md.

## Fora de escopo

- Flame graphs CI
- Desktop keyboard polish amplo
- Remote sync latency
