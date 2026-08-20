# ADR-042: Importação da Timeline do Google Maps (Viagem)

## Status
Aceito (implementado — hub Timeline, DB v37 / export v33)

## Contexto
Viagem hoje é registro manual (`Trip` em ADR-027: título, destinos livres, datas, status). Spec §26 pede `timezone_sequence`, itinerário (voo/trem/hotel/deslocamento) e modo viagem offline. Um fluxo comum em apps de “criar vídeo / crônica de viagem” é importar o JSON que o Google Maps chama de Timeline / “Linha do tempo”.

Perguntas desta spike:

1. Dá para obter esse JSON **sem** a etapa manual (export + escolher arquivo)?
2. Que dados vêm no arquivo atual (`Linha do tempo.json` / `Timeline.json`)?
3. Além de coordenadas, há categorias, tipos de lugar, modos de transporte, “viagens” já agrupadas?

Brainstorm de produto (além de Viagem): [`docs/dev/TIMELINE_SIGNAL_BRAINSTORM.md`](../dev/TIMELINE_SIGNAL_BRAINSTORM.md).

## Decisão

### 1. Sem API oficial — export manual é o caminho

Desde o rollout 2024–2025 a Timeline **não vive mais na conta Google acessível por Takeout/web**. Fica **on-device** (Play Services / Maps), com backup criptografado opcional na conta. Consequências:

| Caminho | Status | Encaixa no Colony? |
| --- | --- | --- |
| API OAuth / Location History REST | **Não existe** para o formato atual | — |
| Google Takeout “Location History” | Só histórico **antigo** (pré-migração); dados novos não entram | Legado opcional |
| Export no aparelho → JSON | **Único canal oficial** | Sim — igual ICS/CSV |
| Intent Android para *disparar* o export | **Não existe** API pública | — |
| Abrir Ajustes de Localização | Intent genérico (`LOCATION_SOURCE_SETTINGS` / tela Location); o utilizador ainda toca “Exportar dados da Timeline” | UX, não automação |
| Fetch não oficial (`geller` / protobuf `odlh-storage.db`) | Reverse-engineering, ToS, frágil, exige conta Google | **Fora** (local-first, ADR-005 / ADR-032) |
| GPS contínuo no nosso app | Histórico futuro só; bateria + permissão; não recupera o passado | Fora desta slice |

O app do print faz exatamente o que é possível: instruir o export + atalho para os ajustes de localização + file picker. **Não há integração que substitua o toque “Exportar”.**

Passos oficiais (rótulos variam por OEM / idioma):

- **Android:** Ajustes → Localização → Serviços de localização → Timeline → Exportar dados da Timeline. Ou Maps → foto de perfil → Timeline → ⋮ → Localização e privacidade → Exportar.
- **iOS:** Google Maps → foto de perfil → Ajustes → Conteúdo pessoal → Exportar dados da Timeline.

O ficheiro pode chamar-se `Timeline.json`, `Linha do tempo.json`, `location-history.json`, etc. **Detectar pelo conteúdo**, não pelo nome.

### 2. Formatos (o snippet do utilizador é o formato novo)

Três gerações coexistiram. O head com `topCandidate.type = IN_PASSENGER_VEHICLE`, `parking.location.latLng` em `"lat°, lng°"` e `startTimeTimezoneUtcOffsetMinutes` é o **export on-device** (chave `semanticSegments`).

| Detecção | Origem | Rico em nomes/categorias? |
| --- | --- | --- |
| `locations[]` + `latitudeE7` | Takeout `Records.json` (pings brutos) | Não — GPS + activity Recognition |
| `timelineObjects[]` + `placeVisit` / `activitySegment` | Takeout Semantic Location History (mensal) | **Sim** — `name`, `address`, `semanticType` tipo `TYPE_CAFE` |
| `semanticSegments` / `rawSignals` / `userLocationProfile` | Export do telemóvel (atual) | **Parcial** — `placeId` + coords; **quase nunca** nome/categoria de negócio |

Parser da 1ª slice: **formato on-device**. Takeout legado (`timelineObjects`) fica P2 se alguém ainda tiver arquivo antigo.

### 3. O que o JSON atual traz (além de “um sítio”)

#### 3.1 `semanticSegments[]` — o miolo

Cada segmento tem `startTime` / `endTime` ISO-8601 **com offset** e, em geral, `startTimeTimezoneUtcOffsetMinutes` / `endTimeTimezoneUtcOffsetMinutes` (ex.: `-180` = UTC−3). Isto preenche spec §26 `timezone_sequence` melhor do que qualquer outra fonte local.

Quatro formas (um segmento usa **uma**):

**A. `visit` — permanência**

```json
"visit": {
  "hierarchyLevel": 0,
  "probability": 0.85,
  "isTimelessVisit": false,
  "topCandidate": {
    "placeId": "ChIJ…",
    "semanticType": "UNKNOWN",
    "probability": 0.45,
    "placeLocation": { "latLng": "-19.93°, -43.94°" }
  }
}
```

- `placeId` — identificador Google Maps (útil para link `https://www.google.com/maps/place/?q=place_id:…`; **não** traz nome sozinho).
- `semanticType` no formato **novo** é papel **do utilizador**, não categoria POI:
  - `HOME` / `TYPE_HOME`
  - `WORK` / `TYPE_WORK`
  - `UNKNOWN` (a maioria)
  - `INFERRED` (sítio frequente que não é HOME/WORK)
  - `SEARCHED_ADDRESS` / `TYPE_SEARCHED_ADDRESS`
  - `TYPE_ALIASED_LOCATION` (rótulo privado no Maps)
- `visit.probability` vs `topCandidate.probability` — “estavas aqui” vs “é este POI”.
- `hierarchyLevel` 0 = sítio; **1+** = sítio-filho (campus→edifício). O sample demonstra nível 1.
- `isTimelessVisit` — bookmark / sítio sem estadia real.
- **Não** vem `restaurant`, `cafe`, `airport`, `lodging` neste JSON. Isso existia no Takeout antigo (`TYPE_CAFE`, `name`, `address`) e **caiu** no export on-device.

**B. `activity` — deslocamento** (é o snippet do utilizador)

```json
"activity": {
  "distanceMeters": 12345.6,
  "probability": 0.88,
  "start": { "latLng": "…" },
  "end": { "latLng": "…" },
  "topCandidate": {
    "type": "IN_PASSENGER_VEHICLE",
    "probability": 0.7614648938179016
  },
  "parking": {
    "location": { "latLng": "-19.932851°, -43.9468642°" },
    "startTime": "2025-12-16T06:00:33.000+08:00"
  }
}
```

Modos observados no enum Google (Takeout + campo `type` atual; o parser deve aceitar string desconhecida):

| Tipo | Significado típico |
| --- | --- |
| `WALKING`, `WALKING_NORDIC`, `RUNNING` | A pé |
| `CYCLING` | Bicicleta |
| `IN_PASSENGER_VEHICLE` | Carro (condutor/passageiro) |
| `IN_TAXI`, `MOTORCYCLING` | Táxi / moto |
| `IN_BUS`, `IN_TRAM`, `IN_SUBWAY`, `IN_TRAIN` | Transporte público |
| `IN_FERRY`, `IN_CABLECAR`, `IN_FUNICULAR`, `IN_GONDOLA_LIFT` | Outros veículos |
| `IN_VEHICLE` | Veículo genérico |
| `FLYING` | Avião — **sinal forte de viagem** |
| `BOATING`, `SAILING`, `KAYAKING`, `ROWING`, … | Água |
| `HIKING`, `SKIING`, `SNOWBOARDING`, `SWIMMING`, … | Outdoor |
| `STILL`, `UNKNOWN_ACTIVITY_TYPE`, `IN_WHEELCHAIR` | Parado / incerto |
| `CATCHING_POKEMON` | Legado (raro) |

`parking` — sítio e instante em que o Google inferiu que o carro ficou. Útil para itinerário “chegada de carro”, não para hotel.

**C. `timelinePath` — trilha GPS**

Pontos `"lat°, lng°"` com `time` **ou** `durationMinutesOffsetFromStartTime`. No sample o offset vem como **string** (`"5"`, `"23"`), não número — o parser aceita os dois. Tempo do ponto = `startTime + N minutos`. Bom para mapa/crônica; pesado; **não** é necessário para criar um `Trip`.

**D. `timelineMemory` — memória do Maps (viagem ou nota)**

Duas formas no sample:

```json
"timelineMemory": {
  "trip": {
    "destinations": [
      { "identifier": { "placeId": "ChIJ…" } }
    ],
    "distanceFromOriginKms": 1842
  }
}
```

```json
"timelineMemory": {
  "note": { "note": "texto que a pessoa escreveu no Maps" }
}
```

`destinations` por vezes aparece **dentro** de `trip` (sample) e por vezes como irmão (dumps antigos). Aceitar os dois. `trip` é o candidato a `Trip` Colony; `note` vai para Inbox/crônica, nunca aplicado em silêncio.

#### 3.2 `userLocationProfile`

- `frequentPlaces[]` — `label` `HOME` / `WORK`; entradas **sem** label = terceiro lugar habitual.
- `persona.travelModeAffinities[]` — `{ mode: WALKING|CYCLING|DRIVING|TRANSIT, affinity: 0..1 }`. Auto-retrato Google; comparar com o mix real do export (digest), não com moral.

#### 3.3 `rawSignals[]` — agregar no máximo; não persistir cru no MVP

- `position` — campo `LatLng` (L maiúsculo no sample). `source`: `GPS` | `WIFI` | `CELL` | `UNKNOWN`. `accuracyMeters`, `altitudeMeters`, `speedMetersPerSecond`.
- `activityRecord.probableActivities` — `STILL`, `ON_FOOT`, `WALKING`, `RUNNING`, `IN_VEHICLE`, `UNKNOWN` (confianças 0..1). Corrobora o `activity` semântico.
- `wifiScan.devicesRecords[].mac` — **MACs de redes vizinhas**. **Descartar na parse**; nunca persistir.

### 4. Categorias de lugar: o que falta e como (não) completar

| Dado | No JSON atual | Como obter |
| --- | --- | --- |
| Lat/lng, janela de tempo, timezone | Sim | Parser local |
| Modo de transporte + km + parking | Sim | Parser local |
| HOME / WORK / frequente | Sim (`semanticType` + `frequentPlaces`) | Parser local |
| Viagem agrupada | Parcial (`timelineMemory`) | Parser + heurística |
| Nome do sítio (“Aeroporto Confins”) | Quase nunca | Places API **ou** geocodificação reversa |
| Categoria POI (hotel, café, aeroporto) | **Não** no formato novo | Places `types` (Essentials) / `primaryType` (Pro) / etiqueta humana |
| Cidade / país | **Não** | Gazetteer offline (GeoNames) a partir do `latLng` |
| Fotos de cartão (skyline, POI) | **Não** | Fora; ver brainstorm §12 |
| Linha de autocarro, paragens, horários | Só Takeout antigo (`transitPath`) | Fora |

**Places API (Place Details com `placeId`)** devolve `types` (SKU Essentials), `displayName` + `primaryType` (SKU Pro), morada, fotos. Custa chave Maps Platform, ToS e rede. **Fora do MVP.** 621 `placeId` únicos cabem na faixa gratuita Pro (~5k/mês) *se* cachearmos para sempre — passo opt-in posterior (brainstorm §12), não importação. Link `maps/place/?q=place_id:` no preview é gratuito.

**Cidades/países** não precisam de Places: gazetteer GeoNames embarcado sobre o `latLng` (brainstorm §12.2).

**OSM/Nominatim** (P2, opt-in, com throttle): geocodificação reversa sem chave Google. Categorias OSM ≠ Google; qualidade variável.

Heurística local sem rede (1ª slice): `FLYING` → perna aérea; mudança grande de `timezoneUtcOffsetMinutes` + `distanceFromOriginKms` / longe de HOME → candidato a viagem; `visit` longo longe de HOME → destino.

### 5. Mapeamento para o domínio Colony

Alinha ADR-032 (opt-in, preview, proveniência, sem OAuth) e spec §0.1 (dados derivados com confiança).

| Fonte Timeline | Destino Colony (proposto, pós-spike) |
| --- | --- |
| `timelineMemory.trip` ou cluster heurístico | `Trip` (título sugerido, `startAt`/`endAt`, `destinations[]`) |
| Offsets de timezone no intervalo | futuro `timezone_sequence` |
| `activity.topCandidate.type` + `distanceMeters` | itinerário; Need `movimento` importado |
| `visit` (nível 0/1, não HOME) | permanência / sítio-filho; atlas `placeId` |
| `timelineMemory.note` | Inbox ou crônica (confirmação) |
| `frequentPlaces` + `persona.travelModeAffinities` | Base/Posto/terceiro; digest modal |
| `probability` | campo de confiança + proveniência |
| `placeId` | metadado opaco; link Maps; **não** chave de negócio |
| `rawSignals.wifiScan` | lixo |

Proveniência: `sourceType = google_timeline_json`, `confidence` = probabilidade do segmento, `importedAt`. Utilizador confirma no preview (não criar dezenas de trips no escuro).

Política de minimização: importar só o intervalo escolhido (ou só candidatos a viagem), não o histórico completo de anos, salvo o utilizador pedir.

### 6. 1ª slice produto (pós-ADR — não nesta iter)

1. UI em Viagem (espelho ICS): “Como obter o ficheiro” + atalho para ajustes de localização + “Escolher ficheiro”.
2. Codec local `GoogleTimelineCodec` em `colony_domain` (Dart puro): deteta `semanticSegments`, parseia visit/activity/`timelineMemory`, ignora `wifiScan`.
3. Preview: N candidatos a `Trip` (título, datas, destinos como coords/`placeId`/HOME-distance) + lista de modos (`FLYING`, `IN_TRAIN`, …).
4. Confirmar → `Trip.create` + evento `tripCreated` (ou evento de import dedicado). Sem Places API.
5. Empty/loading/erro; strings L10N; disclaimer: dados inferidos pelo Google, não reservas, não diagnóstico de deslocamento.

### Fora de escopo

- OAuth Google, Takeout automático, leitura de `odlh-storage.db`, scraping.
- Places API / chave Maps no app.
- Persistir trilhas GPS densas / Wi‑Fi MACs.
- Tracking GPS contínuo nosso.
- Itinerário completo §26.2 e modo viagem §26.3 (biométrico, packing, bookings).
- Escrever de volta na Timeline do Google.

## Consequências

- Evolução de Viagem começa por **importação de arquivo**, o mesmo padrão de ICS (ADR-032) e JSON de flashcards (ADR-038) — não por “integração Google”.
- O JSON **é rico em movimento e tempo**, pobre em **rótulos de lugar**. Quem espera “categorias de restaurante/hotel de graça” precisa de um passo extra (Places/OSM) ou de aceitar coords + modo de transporte.
- ADR-027 (“só registro manual”, “sem scraping”) permanece para o MVP já entregue; esta ADR **estende** com import opt-in, sem conta.
- Schema DB/export só muda na slice de produto, se persistirmos segmentos ou só `Trip`s confirmados.
- Mapa amplo de features (needs, zonas, crônica, storyteller, ledger de horas): [`docs/dev/TIMELINE_SIGNAL_BRAINSTORM.md`](../dev/TIMELINE_SIGNAL_BRAINSTORM.md).

## Fontes (consulta 2026-08)

- [Google Maps Help — Export Timeline (Android)](https://support.google.com/maps/answer/14169818)
- [Google Maps Help — Timeline on computer (on-device)](https://support.google.com/maps/answer/6258979)
- [Dawarich — What’s inside a Timeline export](https://dawarich.app/blog/whats-inside-your-google-timeline-export/)
- [locationhistoryformat.com — Semantic Location History (Takeout antigo)](https://locationhistoryformat.com/reference/semantic/)
- [LocationHistoryFormat#13 — schema on-device](https://github.com/CarlosBergillos/LocationHistoryFormat/issues/13)
- [Places API Place Details — `primaryType` / `types`](https://developers.google.com/maps/documentation/places/web-service/place-details) (enriquecimento pago, fora do MVP)
