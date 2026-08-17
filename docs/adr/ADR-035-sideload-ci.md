# ADR-035: Sideload CI — APK de teste sem desktop

## Status
Aceito

## Contexto
O desenvolvimento passa a ser guiado pela interface remota (Cursor) sem um desktop como intermediário para `flutter build apk`. É preciso instalar atualizações no celular Android e confirmar qual commit está rodando, sem perder dados locais (app local-first).

## Decisão
1. **GitHub Actions** (`sideload_apk.yml`) gera um APK debug a cada push em `master`, PR e `workflow_dispatch`.
2. Publica um **release rolling** `sideload-latest` com o asset estável `fallhub-sideload.apk` (ABI `arm64-v8a`, para o download caber no celular).
3. URL de download permanente:
   `https://github.com/RockFall/fallhub/releases/download/sideload-latest/fallhub-sideload.apk`
4. **Keystore de sideload versionado** (`android/keystore/sideload.keystore`) para o Android aceitar update in-place. Não é chave de loja.
5. O APK recebe `--dart-define` (`GIT_SHA`, `GIT_REF`, `BUILD_TIME`) e a tela de Configurações mostra o build.

## Fora de escopo
- Assinatura de Play Store / upload na Play Console
- Firebase App Distribution
- iOS / TestFlight
- Builds release ofuscados

## Consequências
- Teste no celular = abrir o link no Android e instalar (origem desconhecida).
- Um bookmark cobre todos os updates; o último workflow a terminar vence (concurrency única).
- Trocar o keystore exige desinstalar o app (perde dados locais) — não rotacionar sem motivo.
