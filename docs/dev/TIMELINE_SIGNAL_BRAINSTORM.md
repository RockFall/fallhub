# Brainstorm — sinais da Timeline Google → Life Colony OS

Companheiro de [ADR-042](../adr/ADR-042-google-timeline-import.md). Spike de produto: o que o JSON **já contém**, o que dá para **derivar**, e ideias de funcionalidade da captura básica até o especulativo. Não é roadmap; é mapa de possibilidades com âncoras na spec.

**Estado atual (hub implementado, o que mergear, próximos cortes):** [`TIMELINE_HUB_MERGE.md`](TIMELINE_HUB_MERGE.md)

O sample analisado é um dia em Xangai (coords ~31.23°, 121.47°) + uma expedição de 5 dias a 1842 km da origem.

## 0. Guardrails (ler antes das ideias)

Spec §5.4–5.5, §11.5, §13.7, ADR-005, ADR-031, ADR-032, ADR-033:

- Todo derivado leva `confidence`, fonte, versão de cálculo e botão **“isso está errado”**.
- Sem score de disciplina, sem “preguiça”, sem inferir transtorno / sono clínico / diagnóstico.
- Subjetivo prevalece sobre inferência quando conflitam.
- App **lembra e sugere**; não vigia em tempo real (ADR-031: sem geofence).
- Importação é **batch opt-in** (ficheiro), não tracking contínuo nosso.
- **Nunca persistir** `wifiScan.mac`.
- Storyteller: sem urgência artificial, sem eventos falsos, toda sugestão dispensável.
- Saúde não diagnostica; finanças não executam; viagens não reservam.

Ideias marcadas **⚠** são as que mais facilmente viram julgamento moral. Ou nascem com tom observacional + opt-in, ou não nascem.

---

## 1. Leitura do sample como um dia

Ordem semântica (o JSON mistura trilhas, visitas e memória):

| Quando (UTC+8) | O que o Google afirma | Sinal Colony |
| --- | --- | --- |
| 18–22 ago | `timelineMemory.trip`: 2 destinos (`placeId` Xangai + Suzhou), **1842 km** da origem | Candidato a `Trip` / expedição |
| 08:00–10:00 | `timelinePath` com timestamps absolutos (3 pontos, ~800 m) | Trilha; “onde andei de manhã” |
| 08:10–09:35 | `visit` nível **0** (sítio) + nível **1** (sítio *dentro* do sítio), `UNKNOWN` | Permanência aninhada — campus/mall/prédio |
| 08:12, 08:24, 08:39 | `position` GPS 7 m → WIFI 18 m → CELL 85 m | Qualidade do sinal a degradar (talvez indoor) |
| 08:24 | `wifiScan` 3 APs | **Descartar MACs**; só prova “estava indoor/urbano” |
| 08:27 | `activityRecord` ON_FOOT 0.95 / WALKING 0.91 | Sensor confirma a pé *antes* do `activity` semântico |
| 09:35–10:05 | `activity` carro 4,3 km, p=0.97 | Deslocamento |
| 09:42 | `activityRecord` IN_VEHICLE 0.94 | Sensor confirma o carro |
| 10:00–12:00 | `timelinePath` com offset em **string** `"5"`, `"23"`, `"47"` | Parser: offsets são string; tempo = start + N min |
| 10:05–10:18 | `activity` a pé 731 m | Última milha |
| 14:10–14:40 | Carro 5,6 km + **`parking`** no destino | “O carro ficou aqui” |
| 18:00–23:00 | `timelineMemory.note` texto livre | Nota do Maps → inbox / crônica |
| perfil | HOME, WORK, 3.º lugar sem label; afinidades WALK 0.82 / DRIVE 0.66 / TRANSIT 0.57 / CYCLE 0.18 | Base, posto, satélite; “como eu me movo” |

Dois formatos de path no mesmo ficheiro (`time` vs `durationMinutesOffsetFromStartTime`). `timelineMemory.trip.destinations` no sample vive **dentro** de `trip` (noutros dumps aparece como irmão). Parser aceita os dois.

---

## 2. Catálogo de sinais (campo → facto)

Cada linha é um tijolo. Funcionalidades = combinação de tijolos.

### Tempo e fuso

| Campo | Facto derivado |
| --- | --- |
| `startTime` / `endTime` | Duração da visita ou da perna |
| offset minutos (início ≠ fim) | Cruzou fuso *durante* o segmento (voo / comboio longo) |
| sequência de offsets no dia | `timezone_sequence` §26; jet-lag calendário (não clínico) |
| buracos entre `endTime` e o próximo `startTime` | Telefone desligado, túnel, modo avião, falha de Timeline |
| overnight STILL/visita em HOME | *Proxy* fraco de “noitou em casa” — **não** é sono |

### Lugar

| Campo | Facto derivado |
| --- | --- |
| `placeId` estável | Identidade do sítio mesmo sem nome |
| `latLng` | Cluster, distância a HOME, país/cidade via reverse geocode P2 |
| `semanticType` / `frequentPlaces.label` | HOME, WORK, INFERRED, SEARCHED, alias |
| `frequentPlaces` sem `label` | “Terceiro lugar” — o Google já acha que é hábito |
| `hierarchyLevel` 0 vs 1+ | Sítio-pai vs sítio-filho (mall → loja, campus → edifício) |
| `isTimelessVisit` | Visita “sem tempo” (bookmark / sítio marcado, não estadia) |
| `visit.probability` vs `topCandidate.probability` | “Estavas aqui” vs “é *este* POI” — dois tipos de incerteza |
| revisita ao mesmo `placeId` | Frequência, intervalo, streak de dias, “sumiu há 6 meses” |
| primeira vez neste `placeId` / célula H3 | Sítio novo — variedade |

### Movimento

| Campo | Facto derivado |
| --- | --- |
| `activity.topCandidate.type` | Modo (a pé, carro, comboio, avião…) |
| `distanceMeters` | km/dia, km/modo, km/semana |
| duração + distância | velocidade média; cruzar com o modo (carro a 4 km/h = suspeito) |
| `parking` | âncora do veículo; “onde deixei o carro” |
| `timelinePath` | forma da rota, loops, ida-e-volta |
| `FLYING` / `IN_TRAIN` longo / offset grande | expedição |
| `timelineMemory.trip` | viagem já agrupada + km à origem + destinos |

### Sensores (`rawSignals`) — úteis se reduzidos; perigosos se crus

| Campo | Facto derivado | Política |
| --- | --- | --- |
| `position.source` GPS/WIFI/CELL/UNKNOWN | outdoor vs indoor vs torre | pode agregar |
| `accuracyMeters` 7 vs 250 | confiança espacial do instante | pode agregar |
| `altitudeMeters` | subida acumulada (fraco) | opcional |
| `speedMetersPerSecond` | confirma modo | opcional |
| `activityRecord` STILL/ON_FOOT/IN_VEHICLE | corrobora `activity` semântico | agregar por hora, não ponto a ponto |
| `wifiScan.mac` | fingerprint de interior | **nunca guardar** |

### Perfil e memória

| Campo | Facto derivado |
| --- | --- |
| `persona.travelModeAffinities` | auto-retrato Google de “como me desloco” |
| afinidade vs km reais da semana | deriva / hipocrisia suave (“digo que ando a pé, esta semana foi 90% carro”) — ⚠ tom |
| `timelineMemory.note` | texto que a pessoa já escreveu no Maps |
| HOME `placeId` muda entre exports | mudança de base → evento de crônica “migração” |

---

## 3. Camada 0 — captura e atlas (o básico que desbloqueia o resto)

Sem isto, o resto é fanfic.

1. **Import opt-in** (já em ADR-042): ficheiro → preview → confirmar. Intervalo de datas. Minimização.
2. **Atlas de sítios** (`placeId` + coords + rótulo manual). HOME/WORK pré-etiquetados. O utilizador nomeia o resto (“Café da esquina”, “Casa da M.”).
3. **Visitas** como eventos com proveniência: início, fim, duração, confiança, `hierarchyLevel`.
4. **Pernas** (activities): modo, km, velocidade, parking.
5. **Expedições** a partir de `timelineMemory.trip` + heurística FLYING/fuso.
6. **Notas do Maps** → Inbox (spec §27) ou crônica, nunca silenciosas.
7. **Redação:** “esquecer este sítio”, “não importar HOME”, “só expedições”.
8. **Qualidade do dia:** % do tempo com accuracy ≤ 50 m; dias “borrados” (CELL 250 m) aparecem como desconhecidos, não como zero.

Isto já alimenta `Trip`, `ContextZone` (rótulo), crônica e Need `movimento`.

---

## 4. Camada 1 — estatísticas de locomoção (úteis, pouco dramáticas)

Painel modo `Análise` (spec §5.3), nunca no sítio de Foco.

- **Mix modal da semana:** minutos e km a pé / carro / trânsito / avião. Comparar com `travelModeAffinities`.
- **Passos-proxy:** soma de `WALKING`+`RUNNING`+`HIKING` em metros — Need `movimento` com `calculation_mode: imported`, validade do export, chip de confiança. Não é Health Connect.
- **Tempo em casa / no posto / em terceiros / em trânsito / em expedição.** Barras empilhadas. Sem veredito.
- **Raio de vida:** percentil da distância a HOME; convex hull; “esta semana não saí de 2 km”.
- **Commute:** clusters HOME→WORK no mesmo fuso horário, mesma janela (ex. 7:40–8:20). Distribuição de duração. Anomalia: “terça demorou o dobro” (observacional).
- **Estacionamentos:** mapa dos `parking` — “onde o carro costuma dormir”.
- **Subidas:** Δ altitude em `position` (barómetro mentiroso; só com disclaimer).
- **Calendário de calor:** dias coloridos por km a pé, não por “produtividade”.
- **Buracos:** horas sem segmento. Útil para não inventar o dia.
- **Velocidade vs modo:** flag interna de qualidade (WALKING a 40 km/h → lixo), não alerta ao utilizador.

Hooks Colony: Need `movimento`; revisão semanal (spec §28.4); `NarrativeDigest` com novos `templateId` (`walk_km`, `nights_away`, `new_places`) — mesmo padrão de `trip_activity`.

---

## 5. Camada 2 — padrões e “como vivo” (o miolo interpretável)

Aqui o app deixa de ser GPS e passa a ser o simulador pessoal da spec §3.3.

### Ritmo

- **Semana tipo:** segunda–sexta vs fim-de-semana. Dois mapas mentais. “Sábado o raio cresce 4×.”
- **Âncoras horárias:** hora mediana de sair de HOME / chegar a WORK / regressar. Não é ponto; é distribuição.
- **Noites fora:** visita overnight longe de HOME → candidato a trip *ou* a “dormi noutro sítio” (rótulo do utilizador: hotel / família / outro). Nunca assumir infidelidade, doença, nada.
- **Estações:** terceiros lugares que só aparecem no verão (praia, parque) vs inverno.
- **Fuso como clima da colônia:** offset +480 vários dias = “capítulo Ásia”; voltou a −180 = “capítulo casa”. Relógio da colônia (spec §26.3) pode usar isto *depois* do import, não em live.

### Geografia pessoal

- **Cinco habitats:** clustering de visitas (k-means / H3). O utilizador nomeia: Base, Posto, Ginásio, Casa da família, Cidade B.
- **Terceiro lugar** (Oldenburg): o `frequentPlaces` sem label + top N `placeId` que não são HOME/WORK. “Onde a colônia respira fora da base.”
- **Sítios-filho:** `hierarchyLevel ≥ 1` — InspectPane em profundidade: “dentro de A, estiveste em B 40 min”.
- **Névoa do mapa pessoal:** células H3 visitadas vs não visitadas *na tua cidade*. Revelação por evidência, não cópia de fog-of-war de jogo. Primeira visita a uma célula = marco de crônica opcional (“pioneiro”).
- **Isochronas empíricas:** não “quanto o Maps diz”; “em 30 min a pé, historicamente, onde já cheguei”. Útil para escolher sítio de compromisso.
- **Sítios que desapareceram:** `placeId` frequente que não aparece há N semanas. Storyteller Guardião: “faz 9 semanas que não vais a X — querés arquivar, lembrar, ou ignorar?” Dispensável.

### Deriva de identidade de movimento

- Comparar `persona.travelModeAffinities` com o mix real do mês. Tom: “o Google acha que andas 82% a pé; neste export o tempo a pé foi 18%.” Facto vs modelo alheio, não vs moral.
- Se o utilizador tem Valores (spec §16.4) tipo “mobilidade ativa”, *ele* pode ligar o valor ao mix. O app não prega.

### Zona contextual (ADR-031 hoje é manual)

Import **não** é geofence ao vivo. É retroativo:

- Sugerir `ContextZone` a partir de HOME/WORK/terceiro + modos (`FLYING` → zona “avião”: `connectivity: limited`, capabilities `read`, `notes`).
- Na revisão do dia: “ontem das 9h–18h o sinal é WORK — queres marcar a zona Posto nesse intervalo?” Confirmação.
- Work grid: *depois* de confirmado, filtrar tipos indisponíveis (já previsto em §25.2). Nunca bloquear o SO.

### Agenda vs facto

- ICS já existe. Overlay: evento “Reunião escritório” vs visita WORK vs visita noutro `placeId`. Inconsistência → “estavas noutro sítio; queres corrigir o calendário ou a zona?” Tool confirmation (ADR-033).
- Compromissos (§24.4): due_at vs hora de chegada ao `placeId` que o utilizador ligou à pessoa. Só se a ligação for explícita.

---

## 6. Camada 3 — cruzamentos com o que o Colony já é

Cada feature existente ganha um *sensor* de lugar, com proveniência.

| Domínio já no app | O que a Timeline acrescenta | Como não estragar |
| --- | --- | --- |
| **Pawn / Needs** | `movimento` importado; `variedade` (sítios únicos/semana vs baseline); `tempo sozinho` *só* se o utilizador definir “HOME sozinho” — senão não | Sem “social score”. Need ocultável. |
| **Capacidades §14** | Prontidão para “treino” usa km a pé recentes + visita a sítio etiquetado ginásio; prontidão para “foco” usa minutos em WORK vs trânsito | Fórmula editável, nunca readiness global |
| **Check-in / pensamentos §12.2** | Pensamento com evidência: “caminhada 731 m às 10h” / “noite fora da base”. O utilizador aceita ou descarta | Nunca inventar emoção |
| **Daily / weekly review** | Factos: km, sítios novos, noites fora, mix modal, buracos de dados | Distinguir facto vs interpretação |
| **NarrativeDigest** | Templates novos com `evidenceEventIds` | Rules first, sem LLM |
| **Storyteller §30** | Calmo: quase nada. Analista: deriva modal. Explorador: “há 11 dias o raio < 2 km — um passeio longo?” Guardião: “3 noites fora sem trip ativa” | Máximo semanal; quiet hours |
| **Crônica §28** | Cartas `TimelineLetter` por expedição, migração de HOME, primeiro sítio, nota do Maps | Filtro por local/fonte (já na spec) |
| **Quests** | Evidência “visitar 3 sítios novos”; “caminhar 20 km esta semana” com metros de `WALKING` | O utilizador cria a missão; o import só prova |
| **Research / flashcards** | Semana noutro fuso → convite *opcional* a baralho de idioma. Nada automático | Sem patriotismo de app |
| **Schedule / work grid** | Zona confirmada altera `unavailable_work_types` | Depois da confirmação |
| **Finance** | Dia com `distanceFromOriginKms` alto ou `FLYING` → sugerir atribuir gastos do ledger à `Trip` | Não inventar transações |
| **Health** | Minutos de movimento como *contexto* ao lado de sintomas (correlação exploratória §13.8: n, cobertura, não causal) | Sem diagnóstico; sem “devias caminhar mais” clínico |
| **Relations / Person** | Utilizador liga `placeId` a uma Pessoa (“casa da J.”). Tempo lá vira interação *lite* candidata | Sem inferir com quem esteve |
| **Inventory / packing** | `FLYING` histórico ou trip ativa → packing list; `parking` → “o carro está neste sítio” como loadout | Sem IoT |
| **Habitat** | Troca cosmética de quarto vs “estás na Base” por visita HOME confirmada *no passado* | Habitat continua cosmético ao vivo |
| **Inbox** | Notas `timelineMemory.note`; “sítios novos por nomear” | Classificação com confirmação |
| **Decisões §70** | HOME `placeId` mudou → rascunho “mudei de base” | Só rascunho |

### Need `movimento` — exemplo de cálculo honesto

```text
value: km_walk_run_hike / meta_pessoal   # meta é do utilizador, default off
confidence: min(probabilidades das pernas) * cobertura_do_dia
freshness: stale se o JSON tem > N dias
sources: [google_timeline_json]
explanation: "4,1 km a pé no export de 20 ago; 2 pernas WALKING p≥0,96"
```

Se o utilizador fez check-in “não me mexi” no mesmo dia, o subjetivo ganha e a barra mostra conflito, não média escondida.

---

## 7. Camada 4 — criativo / colônia (ainda interpretável)

Aqui o vocabulário de gestão de colônia ganha corpo **sem** copiar RimWorld.

- **Mapa operacional de ontem:** Base / Posto / satélites / caravana (pernas) / veículo estacionado. O centro da tela Colônia (§9) deixa de ser só widgets: um dia importado vira o mapa do território *real*. Densidade `Foco` = 3 sítios; `Análise` = path.
- **Expedição com relatório automático:** `timelineMemory.trip` → rascunho de crônica: datas, km à origem, destinos (links `place_id`), mix de modos, noites fora, buracos. Editável. Nunca inventa “foi incrível”.
- **Ledger de atenção:** horas-sítio como o ledger financeiro — “gastei 47 h no Posto, 11 h em trânsito, 3 h em sítios novos”. Orçamento *opcional* (“quero ≤40 h no Posto”) que o utilizador liga. ⚠ fácil virar panóptico; default off; sem vermelho de falha.
- **Capítulos de biografia:** mudança de HOME, primeira vez num país (fuso + reverse geocode), expedição > 500 km. A crônica ganha *marcos* filtráveis (§28.2 já lista “marco”).
- **Dia gémeo:** assinatura (mix modal + raio + âncora HOME/WORK) → “3 de março parece-se com hoje”. Útil para lembrar o que funcionou (“nesse dia saíste mais cedo”).
- **Contraponto de valores:** se existe Valor “presença em casa” vs tempo real em HOME. Só com o valor ligado pelo utilizador.
- **Modo avião retrospectivo:** pernas `FLYING` aplicam a zona “avião” àquele intervalo na revisão — “aquelas 11 h só serviam para leitura/notas”. Pedagogia de §25.2 com evidência.
- **Packing fantasma:** itens de inventário ligados a trip anterior semelhante (mesmo `distanceFromOriginKms` band, mesmo `FLYING`). “Da última vez levaste X.” Já temos `trip_inventory`.
- **Moeda e fuso:** offset muda → hint no ledger “gastos destes dias talvez sejam outra moeda”. Não converter sozinho.
- **Aniversário espacial:** “há um ano estavas neste `placeId`.” Carta de crônica, opt-in, quiet.

---

## 8. Camada 5 — especulativo (bom para Storyteller Explorador; fácil de fazer mal)

- **Física da semana:** “energia cinética” como metáfora visual (km × modo), não número científico. Só se for lúdico e desligável.
- **Sinfonia modal:** sequência WALK → CAR → WALK como ritmo do dia na revisão. Tocar com isso no digest, não no dashboard de Foco.
- **Clima da colônia por habitat:** muito CELL/WIFI + STILL no Posto = “interior, estático”; GPS + WALKING = “exterior”. Alimenta Need `ambiente` *se* o utilizador criar essa need (seed da spec tem ambiente; o seed atual do código ainda não). Proxy grosseiro.
- **Índice de localness:** % do tempo num raio de 1 km de HOME. Explorador: “a colônia está hibernando no hex da Base.” Guardião não usa isto como alarme.
- **Fronteira pessoal:** células na orla do hull — “quase saíste do mapa habitual.” Convite a documentar, não a consumir.
- **Correlação §13.8:** energia do check-in vs km a pé com n, cobertura, “associação observacional”. O texto da spec já é o UI.
- **Quest gerada (sempre rascunho):** “3 sítios novos no mês” / “uma perna `CYCLING` se a afinidade é 0.18 e nunca aparece.” Explorador; recusar é o default feliz.
- **Replay 60×** dum dia no mapa (path). Memória, não jogo de score.
- **Export GPX** duma perna `HIKING`/`WALKING` longa — devolver o rasto ao utilizador (simetria: entrou JSON, sai GPX).
- **Dois mundos:** comparar duas expedições (km, modos, noites, raio no destino).
- **Migração:** HOME mudou + WORK mudou no mesmo mês → rascunho de DecisionRecord “mudei de cidade”.
- **Esquecimento ritual:** “redigir 2022” apaga segmentos mas guarda estatísticas anuais agregadas (km, países, noites fora) — memória sem vigilância.

Fora (mesmo no especulativo):

- Inferir com quem esteve (não há IDs de outras pessoas).
- Inferir sono, humor, álcool, infidelidade, pobreza.
- Score de “vida saudável”.
- Recomendar restaurantes/hotéis/preços (ADR-027).
- Usar MAC de Wi‑Fi para reidentificar sítios.
- Tracking live, geofence, “o pawn move-se agora”.

---

## 9. O sample, desdobrado em produtos concretos

Se só existisse este JSON, já daria para:

1. Criar `Trip` “18–22 ago, 1842 km, 2 destinos” (Suzhou+Xangai como `placeId` por nomear).
2. Itinerário do dia 20: permanência aninhada 08:10–09:35 → carro 4,3 km → a pé 731 m → (buraco) → carro 5,6 km com parking.
3. Need `movimento`: ~0,73 km a pé *semântico* + possível trilha da manhã; confiança alta nas pernas (p≥0,96), baixa se misturarmos path sem modo.
4. Zona candidata “Posto” se o visit bater com WORK; aqui os `placeId` de visita ≠ WORK do perfil — portanto **não** assumir escritório; perguntar.
5. Indoor heurístico: GPS 7 m → WIFI 18 m → CELL 85 m durante a visita. “Provável interior.” Confiança média.
6. Nota 18:00–23:00 → inbox.
7. Afinidade WALK 0.82 vs dia com duas pernas de carro: um bullet de digest, tom neutro.
8. Mapa: Base (HOME 31.22, 121.46) distante ~2–3 km das visitas — dia *fora da Base*, coerente com a expedição.

Um dia já é um relatório de expedição. Um ano é um atlas da colônia.

---

## 10. Ordem de implementação sugerida (quando sairmos do spike)

Não fazer tudo. Fatias que pagam a próxima:

| Ordem | Fatia | Desbloqueia |
| --- | --- | --- |
| A | Import + codec + preview de `Trip` (ADR-042) | Expedições |
| B | Atlas `placeId` + rótulo manual + HOME/WORK | Geografia |
| C | Mix modal + km + Need `movimento` importado | Pawn |
| D | Digest templates + cartas de crônica | Storyteller |
| E | Overlay ICS vs visitas; zona sugerida (confirmação) | Agenda / work |
| F | Ledger de horas-sítio opt-in; packing por trip semelhante | Gestão |
| G | H3 / mapa operacional / replay / GPX | Análise / prazer |
| H | Gazetteer offline (cidades/países) + categorias opt-in | Abas tipo Maps |

A e B são o contrato de dados. C–E são o produto Colony (não um tracker). F–H são tempero.

---

## 11. Princípio de desenho

A Timeline não é um feed de GPS. É um **arquivo de evidências de território**. O Colony já sabe o que fazer com evidências: proveniência, confiança, revisão, missões, necessidades, crônica.

O erro seria construir um clone de Maps. O acerto é: o pawn olha para o mapa da colônia e reconhece a vida que já viveu — e decide o que isso *significa*, nunca o app.

---

## 12. Reconstruir as abas do Maps (Lugares / Cidades / Mundo / Estatísticas / Viagens)

As telas do Google Maps **não estão no JSON**. O app junta `placeId` com a base Places (nome, `types`, foto) e faz reverse geocode interno. Ferramentas de terceiros (maps-timeline-viewer, mileage exporters) confirmam: o export traz IDs; nomes e categorias exigem **Place Details** à parte.

Não copiar layout, fotos stock nem IA do Maps. Recriar a *capacidade* no visual Colony.

### 12.1 O que cada aba precisa vs o que o JSON dá

| Aba Maps | O que vês | No `Timeline.json`? | Como obter |
| --- | --- | --- | --- |
| **Estatísticas → transporte** | km e tempo a pé / a dirigir / trânsito + sparkline 6 meses | **Sim** | Somar `activity.distanceMeters` e `endTime−startTime` por `topCandidate.type`. Mapear `WALKING`/`RUNNING`/`HIKING` → a pé; `IN_PASSENGER_VEHICLE`/`IN_TAXI`/`MOTORCYCLING` → a dirigir; `IN_BUS`/`IN_TRAIN`/`IN_SUBWAY`/`IN_TRAM` → trânsito; `FLYING` à parte. Sparkline = agrupar por mês do `startTime`. |
| **Estatísticas → visitas** | horas em gastronomia / compras / cultura / hotéis + “ver N lugares” | **Não** (só duração + `placeId`) | Categorias vêm de `types`/`primaryType` **depois** do lookup. Duração já está no segmento. |
| **Lugares** | 621 sítios em grelha por categoria (143 compras, 133 gastronomia…) | Contagem de `placeId` únicos **sim**; buckets **não** | Mesmo lookup. Sem categoria → balde “Por classificar”. |
| **Cidades** | Xangai 6 lugares, BH 321, Confins 5, recência | Coords **sim**; nome da cidade **não** | Reverse geocode das coords do `visit` (não precisa de Places). |
| **Mundo** | 10 países, N cidades, recência | Idem | País do gazetteer / `country_code`. |
| **Viagens** | “8 viagens / 59 dias”, cartão Pequim 12–17 ago, foto, mapa | `timelineMemory.trip` **parcial** (datas, `placeId` destino, km origem) | Nome da cidade = gazetteer; foto **não** vem. Heurística extra: noites longe de HOME + `FLYING`. |
| Fotos dos cartões | skyline, templo, aeroporto | **Não** | Places Photos (pago, ToS) ou Wikimedia por cidade, ou **sem foto** (ColonyPanel). |

### 12.2 Cidades e países — caminho de sucesso *offline*

Não precisa de API Google. Pipeline:

1. Deduplicar visitas por `placeId` (ou por célula ~100 m se não houver ID).
2. Para cada coordenada, nearest-city num gazetteer embarcado ([GeoNames](http://download.geonames.org/export/dump/) `cities5000` ~5 MB / ~50k sítios — apanha BH, Nova Lima, Confins melhor que `cities15000`).
3. `country_code` → nome localizado; agrupar cidades por país.
4. Recência = `max(endTime)` do grupo; “hoje / ontem / há 4 semanas” como no Maps.
5. Cache local `latlng_bucket → {city, country}` para não repetir o k-d tree.

Dart: k-d tree (ex. `geocoder_offline`) ou tabela nossa. Geocoder do SO (Android/iOS) é plano B *online*, sem chave nossa, qualidade variável.

Isto sozinho entrega as abas **Cidades** e **Mundo** com fidelidade alta. Municípios minúsculos podem cair na cidade vizinha — o utilizador corrige no atlas (uma vez por sítio).

### 12.3 Categorias (Lugares + Estatísticas de visitas) — o fosso

O Maps mostra Compras / Hotéis / Atrações / Gastronomia / Cultura / Aeroportos porque consulta a taxonomia Places. No JSON novo, `semanticType` é HOME/WORK/UNKNOWN — **não** é gastronomia.

Três vias, da mais Colony à mais “igual ao Maps”:

**V1 — Etiqueta humana (local-first, 0 rede)**  
Os ~50 `placeId` mais visitados pedem uma categoria Colony na primeira vez; o resto herda. 621 sítios não se etiquetam todos; o topo cobre a maior parte das *horas*. Balde “Outros / por classificar”.

**V2 — Gazetteer + heurística (offline, grosseiro)**  
`FLYING` que termina num sítio → candidato a aeroporto. Visita overnight longe de HOME → candidato a hotel. Não reproduz 133 restaurantes.

**V3 — Places API opt-in (o único jeito de *chegar perto* da grelha do Maps)**  
`GET places/{placeId}` com field mask. Billing (2026):

| Campo | SKU | Preço | Free / mês |
| --- | --- | --- | --- |
| `types` | Essentials | ~$5 / 1k | 10 000 |
| `displayName`, `primaryType` | **Pro** | ~$17 / 1k | 5 000 |
| fotos | Photos | ~$7 / 1k | 1 000 |

621 `placeId` únicos com Pro (`displayName`+`primaryType`) cabem na faixa gratuita **numa** corrida, se cachearmos **para sempre** por `placeId`. Reimportações não voltam a pagar. Chave Maps Platform do utilizador (opt-in, ADR-032: sem OAuth obrigatório; isto é “cola a tua chave”). ToS: atribuição Google, sem redistribuir o dump de Places.

Mapa `primaryType`/`types` → buckets Colony (espelho útil, não clone de strings):

| Bucket UI | types / primaryType (exemplos) |
| --- | --- |
| Gastronomia | `restaurant`, `cafe`, `bar`, `bakery`, `meal_takeaway` |
| Compras | `store`, `shopping_mall`, `supermarket`, `clothing_store`, … |
| Hotéis | `lodging`, `hotel`, `guest_house` |
| Cultura | `museum`, `art_gallery`, `church`, `hindu_temple`, `tourist_attraction` |
| Atrações | `tourist_attraction`, `park`, `amusement_park`, `zoo` |
| Aeroportos | `airport`, `international_airport` |
| Trânsito | `train_station`, `subway_station`, `bus_station` |
| Saúde / outro | `hospital`, `pharmacy`, … — só se quisermos; Maps não mostra tudo |

`types` (Essentials, mais barato) já permite o bucket; `primaryType` (Pro) escolhe melhor quando há vários types. Nome legível = `displayName` (Pro) ou rótulo manual.

**OSM/Nominatim** (alternativa sem chave Google): reverse + amenity. Taxonomia diferente, qualidade irregular, rate-limit na instância pública. Preferível gazetteer de cidade (V cidades) do que OSM para POI, a menos que o utilizador recuse Google.

### 12.4 Viagens e estatísticas de transporte — quase só JSON

Já desenhado no ADR-042 / camadas 0–1:

- Cartões de viagem: `timelineMemory.trip` + janela `startTime`/`endTime` + destinos geocodificados.
- “8 viagens / 59 dias”: count + soma das durações das trips (não do mês civil).
- Mapa: bounding box dos `latLng` das trips (tiles nossos / OSM; sem estilo Maps).
- Sparkline 6 meses: exige **histórico** no SQLite, não um único export de 1 dia. Cada import faz merge por `placeId`+janela (dedup).

### 12.5 Fotos

Não usar CDN do Maps. Opções Colony:

1. Sem foto — ícone de categoria + cor do DS (mais honesto, zero ToS).
2. Snapshot do mapa local (tiles OSM) na bbox da cidade.
3. Wikimedia por nome da cidade (rede, atribuição, falha silenciosa).
4. Places Photos só se V3 estiver ligado e o utilizador aceitar custo/ToS.

### 12.6 Arquitetura para “ter essas telas” de verdade

```text
Timeline.json
  → GoogleTimelineCodec          # local, sempre
  → Visit/Activity/Trip facts    # Drift
  → CityGazetteer (GeoNames)     # local, embarcado
  → PlaceEnrichmentPort          # opt-in: Places | manual | none
       cache placeId → {name?, types[], primaryType?, fetchedAt}
  → queries:
       transportStats(month)
       visitsByCategory(month)
       placesByCategory()
       cities() / countries()
       trips()
  → UI Colony (não clone Maps)
```

Proveniência: facto de visita = `google_timeline_json`; nome/categoria = `places_api` | `user_label` | `geonames`. Chip de confiança distinto. Sem enriquecimento, as abas Cidades/Mundo/Estatísticas-transporte/Viagens já vivem; Lugares mostra “621 sítios, 0 classificados” + CTA para etiquetar ou colar chave.

### 12.7 Ordem que chega às telas sem mentir

1. Import + atlas (A–B) → número de sítios, mapa de pontos, trips cruas.  
2. Gazetteer (H′) → **Cidades** e **Mundo**.  
3. Agregação modal (C) → **Estatísticas de transporte**.  
4. Etiqueta manual do topo-N → **Lugares** útil sem Google.  
5. Place Details opt-in + cache → grelha e horas por categoria no nível do Maps.  
6. Fotos: nunca no caminho crítico.

Isto é o caminho de sucesso: as abas que o JSON já explica nascem offline; a grelha “Gastronomia 133” só nasce com taxonomia (tua ou da Places API), e isso é um passo **explícito**, não magia do ficheiro.

