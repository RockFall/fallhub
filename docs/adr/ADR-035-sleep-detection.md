# ADR-035: Detecção automática de sono

## Status
Aceito (Iter sleep detection)

## Contexto
Spec §13 inclui sono e integrações Health Connect/HealthKit. O usuário espera detecção automática de início e fim do sono sem abrir o app (comportamento similar ao Samsung Health). Health Connect permanece opt-in (ADR-032); saúde não diagnostica (ADR-023 / §0.1).

## Decisão

### Duas fontes, uma entidade local
1. **`SleepSession`** local: `startedAt`, `endedAt?` (null = em andamento), `source` (`detected` | `healthConnect` | `manual`), `confidence`, `externalId?`, proveniência.
2. **Detecção on-device** (primária quando habilitada): foreground service Android amostrando acelerômetro + estado de tela + carregamento; motor puro Dart (`SleepDetectionEngine`) decide onset/wake.
3. **Health Connect** (opt-in): leitura de `SLEEP_SESSION` (ex.: Samsung Health / Galaxy Watch) e upsert local — máxima acurácia quando o SO já mede bem.
4. **Merge**: sessões sobrepostas preferem Health Connect; detecção local permanece se não houver sobreposição útil.

### Escopo IN
- Opt-in explícito (consentimento + permissões de SO)
- Persistência + export/restore
- UI na tela Saúde (lista + toggle de detecção + sync HC)
- Testes do motor e round-trip export

### Escopo OUT
- Estágios de sono (REM/deep) no MVP
- Microfone / snore scoring
- Diagnóstico ou “qualidade clínica”
- iOS HealthKit produto (port preparado; HC Android primeiro)

### Políticas
- Sem abrir o app após opt-in: serviço em foreground (notificação obrigatória no Android) + sync periódico HC
- Dados de saúde: `PrivacyClass.health`; disclaimer existente permanece
- Desligar opt-in para o serviço; histórico local não é apagado

## Consequências
- DB schema +1; export version +1
- Dependências nativas: `health`, `sensors_plus`, `flutter_foreground_task`, `battery_plus`, `permission_handler`
- ADR-032 permanece: HC é opt-in granular; este ADR é a 1ª slice real de Health Connect (só sono)
