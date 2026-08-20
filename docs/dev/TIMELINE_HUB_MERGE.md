# Timeline Google Maps — nota de merge

Companheiro curto de [ADR-042](../adr/ADR-042-google-timeline-import.md) e do [brainstorm de sinais](TIMELINE_SIGNAL_BRAINSTORM.md). Serve para revisão e merge: o que entrou, o que mudou no código, o que fica para depois.

**Onde usar no app:** Recursos → Viagens (`/resources/travel`). Título no ecrã: *Linha do tempo*.

---

## Resumo (30 segundos)

Não há API da Timeline. O utilizador exporta o JSON no telemóvel e importa no Colony. Um re-import **apaga o JSON antigo e grava o novo**; os nomes/categorias que a pessoa deu aos lugares **ficam**.

O ecrã de Viagens virou um hub com abas no espírito do Google Maps (Dia, Viagens, Estatísticas, Lugares, Cidades, Mundo, Ritmo, Sinais), no visual Colony — sem copiar fotos, layout ou assets do Maps.

O JSON atual é rico em movimento e pobre em nomes de sítios. Categorias tipo “gastronomia” são **inferidas** (horário, `HOME`/`WORK`, heurística) e corrigíveis à mão. Cidades/países vêm de um gazetteer offline nas coordenadas, não do ficheiro.

- Base de dados: schema **38 → 39**
- Export/restore: snapshot **33 → 34**

---

## O que foi feito (produto)

### Captura
- Folha de import com passos **Android** e **iPhone**, mais link da ajuda oficial do Maps.
- Escolher ficheiro (`json` / `txt`) ou colar JSON; parse em isolate.
- Pré-visualização (visitas, deslocamentos, viagens, `placeId`s) antes de gravar.
- Confirmação de **overwrite** se já existir import.
- Rejeita Takeout antigo (`timelineObjects`) e `Records.json`.
- **Não persiste** MACs de `wifiScan`.

### Hub
| Aba | Conteúdo |
| --- | --- |
| Dia | Chips de datas com dados + rail de visitas / deslocamentos / parking / notas |
| Viagens | Cartões `timelineMemory.trip` + viagens manuais que já existiam |
| Estatísticas | km a pé / carro / transportes / avião / bicicleta, sparklines, casa vs trabalho, noites fora, raio, buracos, trechos implausíveis |
| Lugares | Mosaico 2 colunas por categoria + lista; tap para rotular nome/categoria |
| Cidades | Cartões com bandeira, país, contagens |
| Mundo | Grelha de países |
| Ritmo | Heatmap 7×24 (minutos parados) |
| Sinais | Proveniência, persona vs km reais, parking, notas, lugares frequentes, GPS/sensores, re-import |

### O que o JSON **não** dá (e o que fizemos em vez disso)
- Nomes oficiais de restaurantes/hotéis → rótulo humano + heurística.
- Fotos dos cartões Maps → ícones e gradientes do design system.
- Cidades/países → gazetteer Dart (~cidades grandes + metros BR/CN do sample).

Viagens manuais (`Trip` ADR-027) **não foram apagadas**; ficam na aba Viagens, abaixo das da Timeline.

---

## O que foi alterado (código)

### Domínio (`packages/colony_domain`)
- `google_timeline.dart` — documento normalizado (visitas, atividades, paths, trips, notas, perfil, GPS, sensores).
- `google_timeline_codec.dart` — parser on-device (`semanticSegments` / array; path `time` **ou** offset em string; destinos dentro ou ao lado de `trip`).
- `google_timeline_analytics.dart` — rollups de transporte, lugares, cidades, países, heatmap, qualidade do rasto.
- `city_gazetteer.dart` — nearest-city + nomes de país em PT.
- `enums.dart` — `AggregateType.googleTimeline`, `EventType.googleTimelineImported`.
- `export_snapshot.dart` — versão máxima **34**; campos `google_timeline_import` e `google_timeline_place_labels` só em v34+.

### Persistência (`packages/colony_database`)
- Tabelas novas:
  - `google_timeline_imports` — **um** payload JSON normalizado por perfil.
  - `google_timeline_place_labels` — `(profile_id, place_id)` nome + categoria; **sobrevive** ao overwrite.
- `schemaVersion` **39**; migração `from < 39`.
- `GoogleTimelineRepository.replaceImport` — delete do payload antigo + insert do novo + evento de crônica.
- Export/restore incluem import + rótulos.
- `colony_database.g.dart` regenerado (Drift).

### App (`lib/features/travel/` + L10N)
- `TravelScreen` passou a ser o hub com `TabBar` scrollable.
- Folha de import, tabs, sparkline/heatmap/cartões de categoria.
- Strings em `lib/app/localization/app_strings.dart`.
- Paleta de comandos: *Linha do tempo*, *Importar Timeline*.
- Crônica: rótulo *Timeline importada*.

### Testes
- Codec + analytics no sample (Xangai, parking, path offset, trip 1842 km).
- Export v34; banda de export **1..34** (rejeita 35).
- Migração v36→v39: segundo import substitui visitas e **mantém** o rótulo.
- Widget: hub mostra CTA de import na aba Dia; aba Viagens ainda lista viagens manuais.
- Expectativas de versão de export nos testes de repositório/restore atualizadas para 34.

Não há mudança de spec/PRD (`docs/produto/` intocado).

---

## Como verificar no merge

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings   # 0 errors
flutter test packages/colony_domain
flutter test packages/colony_database
flutter test test/travel_screen_test.dart test/timeline_hub_test.dart test/bootstrap_e2e_test.dart
```

No telemóvel (sideload do PR): Viagens → ícone de upload → seguir os passos Android/iOS → escolher `Timeline.json` / `Linha do tempo.json` → confirmar. Re-importar o mesmo ficheiro (ou outro) e confirmar que as estatísticas mudam e os rótulos de lugares permanecem.

---

## Riscos / limites (não são bugs de merge)

- Ficheiros enormes (dezenas de MB) cabem em SQLite TEXT mas podem tornar o 1.º analyze lento; parse já vai para isolate, agregação ainda no isolate da UI.
- Gazetteer é uma lista curta, não GeoNames completo: cidades pequenas podem cair na metro mais próxima (~80 km).
- Heurísticas de categoria vão classificar mal (almoço longo ≠ restaurante). É intencional nesta fatia; o rótulo humano corrige.
- Sem mapa OSM / replay de path nesta PR.
- Sem Place Details da Google (conta, chave, ToS). 621 `placeId`s únicos *poderiam* caber no free tier **uma vez** se cacheássemos para sempre — não está ligado.

---

## Próximos passos (depois do merge)

Ordem sugerida; nada disto bloqueia o merge. Cortar o que não funcionar bem, como combinado.

1. **Usar com um JSON real grande** e decidir o que fica nas 8 abas (Ritmo/Sinais são exploratórias).
2. **Gazetteer maior** (GeoNames `cities5000` empacotado) se Cidades/Mundo errarem demais.
3. **Need `movimento`** — km a pé/ciclo como leitura *importada*, subjetiva ganha no conflito (spec §5).
4. **Cruzar com agenda ICS** — “bloco trabalho vs visita em WORK”.
5. **Sugerir zona / trip manual** a partir de `timelineMemory.trip` (confirmação, não auto-criar).
6. **Place Details opt-in** (chave do utilizador, cache eterno) só se os rótulos manuais forem insuficientes.
7. Parser **Takeout antigo** (`timelineObjects` com `TYPE_CAFE`) — P2, só quem ainda tem arquivo legado.
8. Mapa / GPX / packing automático — tempero; fora do contrato desta PR.

Fora de propósito (não fazer): tracking contínuo no app, ler `odlh-storage.db`, score de disciplina, diagnóstico de sono, persistir MAC de Wi‑Fi.
