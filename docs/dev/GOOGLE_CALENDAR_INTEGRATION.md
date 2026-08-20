# Integração Google Agenda — pesquisa e plano

Status: **proposta** (pesquisa + plano; sem código produto nesta entrega).  
Complementa: [ADR-032](../adr/ADR-032-integrations-phase10-spike.md) (ICS stub), [ADR-005](../adr/ADR-005-local-first.md), spec §37.2 / Phase 10.  
ADR de decisão: [ADR-043](../adr/ADR-043-google-calendar.md).

## Resumo para merge

Entrega **só documentação**. Nenhum pacote Dart, schema, UI ou dependência muda. O stub ICS continua a ser o único conector de calendário no código.

### O que foi feito

Pesquisa da forma oficial de ligar um app Flutter/Android à Google Agenda (Calendar API v3 + OAuth no dispositivo) e um plano para o Colony: poucos cliques, sync fiável (incremental + recovery `410`), leitura completa (atual e histórico) e escrita de eventos com os campos reais da API. Resultado em dois ficheiros novos (este plano + ADR-043).

### O que foi alterado

| Ficheiro | Tipo | Conteúdo |
|----------|------|----------|
| `docs/dev/GOOGLE_CALENDAR_INTEGRATION.md` | **novo** | Pesquisa, repos de referência, superfície da API, modelo, fiabilidade, UX, slices A–G |
| `docs/adr/ADR-043-google-calendar.md` | **novo** | Decisão proposta: API v3 no telemóvel, local-first, ICS mantém-se |

Nada em `lib/`, `packages/`, testes ou `pubspec`. ADR-042 ficou com a Timeline do Maps nesta consolidação; o plano de Agenda é **ADR-043**.

### Próximos passos (depois do merge)

1. **Aceitar ADR-043** (ou anotar alterações) — tranca a arquitetura antes de código.
2. **Slice A** — motor de sync puro em `colony_domain` com JSON fake (paginação, `syncToken`, `410`). Sem Google Cloud.
3. **Slice B** — tabelas Drift (previsto schema v40 / export v35) + `IntegrationKind.googleCalendar`.
4. **Slice C** — OAuth Android + 1.ª sync só leitura (projeto Cloud em modo Testing).
5. Slices D–G — grelha Colony, writes, recorrência/Meet, poll em background. Detalhe na [§13](#13-slices-de-implementação-ordem).

Fora deste merge: webhook/`events.watch`, agregadores SaaS, `device_calendar`, OAuth desktop/iOS.

---

## 1. Objetivo

Ligar o Colony à Google Agenda de forma:

1. **Fácil** — poucos cliques no Android (conta Google já no aparelho + consentimento OAuth).
2. **Confiável** — réplica local à prova de falhas: sync incremental com `syncToken`, recuperação `410 Gone`, writes idempotentes com `etag`, retries com backoff, atualização garantida mesmo sem servidor.
3. **Completa na leitura** — calendários, eventos atuais e históricos, tipos especiais, metadados úteis (fuso, cores, settings).
4. **Completa na escrita** — criar, editar, apagar e gerir eventos com todos os campos/operações relevantes da Calendar API v3.

O app hoje só importa `.ics` offline (preview → confirmar). Isso continua a existir; Google Agenda é um conector novo, opt-in, revogável, local-first.

---

## 2. Estado atual no Colony

| Peça | Onde | Limite |
|------|------|--------|
| Consentimento opt-in | `IntegrationKind.calendarIcs`, tabela `integration_consents` | Só ICS |
| Parser ICS | `IcsCodec` | `SUMMARY`, `DTSTART`, `DTEND`, `UID` |
| Persistência | `external_calendar_events` | título + intervalo + `externalUid` |
| UI | `/settings/integrations` | ficheiro / colar texto |
| Write-back | nenhum | ADR-032 deferiu OAuth e write no calendário |
| Schema / export | Drift **v39**, export **v34** | bump obrigatório se persistirmos tokens/eventos ricos |

`ExternalCalendarEvent` **não** guarda descrição, localização, recorrência, convidados, Meet, lembretes, cor, `etag`, calendário de origem nem payload bruto. Qualquer sync Google de verdade precisa de um modelo novo (ou uma evolução grande desta tabela) — não dá para “esticar” o stub ICS.

O contrato de domínio já previsto na spec §37.1 (`DataConnector` com `import(cursor)` + `disconnect`) é o sítio certo para o adapter Google.

---

## 3. Como se faz hoje (forma oficial, 2026)

A forma correta **não** é CalDAV da Google, nem o calendário do sistema Android como fonte da verdade, nem um agregador pago. É a **Google Calendar API v3** sobre **OAuth 2.0 do utilizador**.

### 3.1 Autenticação no Flutter (caminho oficial)

Documentado em [Flutter — Google APIs](https://docs.flutter.dev/data-and-backend/google-apis):

1. Projeto Google Cloud → ativar **Google Calendar API**.
2. OAuth consent screen + client IDs (Android SHA-1, iOS URL scheme, Desktop se existir).
3. `package:google_sign_in` (v7+: `GoogleSignIn.instance.initialize()`, `attemptLightweightAuthentication()`, `authorizationClient.authorizeScopes`).
4. `package:extension_google_sign_in_as_googleapis_auth` → `http.Client` autenticado.
5. `package:googleapis` → `CalendarApi(client)`.

No Android isto usa a conta Google já no aparelho. **Não precisamos de guardar refresh token em SQLite** — o GMS/Account Manager trata da renovação. Isso alinha com local-first e reduz superfície de segredo.

Desktop (Windows/Linux) **não** tem o mesmo fluxo maduro; aí seria `googleapis_auth` + loopback. Fora do MVP (o sideload atual é Android).

### 3.2 Scopes (mínimo privilegiado, incremental)

| Scope | Serve para | Quando pedir |
|-------|------------|--------------|
| `calendar.events.readonly` | Ler eventos dos calendários a que o user tem acesso | 1.ª ligação, se só leitura |
| `calendar.events` | CRUD de eventos (não cria/apaga calendários) | No momento em que o user cria/edita um evento |
| `calendar.readonly` | `calendarList`, settings, cores, `events.watch` | Se precisarmos da lista completa de calendários + settings |
| `calendar` | Tudo o que é write de calendário (ACL, criar calendário) | Evitar no MVP |

Pedido incremental (“só leitura agora, escrita quando precisares”) reduz fricção e passa melhor na verificação OAuth.

**Verificação Google:** leitura de eventos de Calendar é **sensitive scope**. Exceções úteis para nós: *personal use* / *testing* (até 100 test users) — suficiente para beta sideload. Produção Play Store exige homepage + política de privacidade + vídeo de demonstração (3–5 dias úteis típicos). Ver [Sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification).

### 3.3 Sync incremental (a peça de fiabilidade)

Guia oficial: [Synchronize resources efficiently](https://developers.google.com/workspace/calendar/api/guides/sync).

```
full sync (sem syncToken)
  → paginar nextPageToken até à última página
  → guardar nextSyncToken POR calendário
incremental
  → events.list(syncToken=...)  [sem timeMin/timeMax/q/orderBy]
  → aplicar creates/updates + status=cancelled
  → só então persistir o novo nextSyncToken
410 Gone
  → token inválido (expirou / ACL mudou)
  → full sync de novo (merge, não wipe cego)
```

Regras que falham em quase todos os tutoriais:

- `nextSyncToken` **só vem na última página**. Se parares a meio, não tens token válido.
- `syncToken` **não combina** com `timeMin`, `timeMax`, `updatedMin`, `orderBy`, `q`, `iCalUID`, extended-property filters. `400` ou token omitido.
- Os outros parâmetros (`singleEvents`, `showDeleted`) têm de ser **iguais** ao full sync inicial.
- Incremental **sempre** traz apagados (`status: cancelled`). `showDeleted=false` é ilegal com `syncToken`.
- Um `syncToken` **por `calendarId`**. `calendarList` tem o seu próprio token.

### 3.4 Histórico completo vs janela

Se o full sync usar `timeMin` (ex.: 1 ano), **nunca** recebes os eventos mais antigos que não mudarem. Incremental só reporta *deltas desde o token*, não o passado omitido.

Para “atual **e histórico**”:

- Full sync **sem** `timeMin`/`timeMax` (ou `timeMin` suficientemente antigo, p.ex. 2006 — nascimento efetivo do Google Calendar).
- UI com progresso por página (`maxResults=2500`).
- Opcional: *fast path* (90 dias) **só como cache de UI**, seguido de *backfill* no mesmo calendário **antes** de gravar o `syncToken` definitivo. Não se podem ter dois tokens no mesmo calendário.

Na prática, agendas pessoais cabem em dezenas de milhares de eventos; a API pagina. Não precisamos de um data warehouse.

### 3.5 Push (`events.watch`) vs poll

[Push notifications](https://developers.google.com/workspace/calendar/api/guides/push): Google faz POST HTTPS para um webhook público. O body **não traz o evento** — só “houve mudança”; o cliente corre incremental. Canais expiram (~7–30 dias) e exigem renovação. Domínio verificado, TLS válido, servidor sempre ligado.

Isto **quebra local-first** (ADR-005): precisaria de um relay. **Defer.** MVP = poll no dispositivo:

- ao abrir / resume da app;
- pull-to-refresh;
- WorkManager periódico (~15–30 min, jitter ±25% — Google pede para **não** sincronizar todos à meia-noite).

Garantia: se o user abrir o Colony, a réplica fica atualizada. Background é melhoria, não fonte da verdade.

### 3.6 Quotas (2026)

[Usage limits](https://developers.google.com/workspace/calendar/api/guides/quota):

| Limite | Valor |
|--------|--------|
| Por minuto / projeto | 10 000 |
| Por minuto / user / projeto | 600 |
| Limiar diário faturação / projeto | 1 000 000 (não aumenta) |

`403`/`429 usageLimits` → exponential backoff truncado (1, 2, 4, … até 32–64 s + jitter). Um user no telemóvel está ordens de magnitude abaixo disto se usarmos incremental + poll razoável.

### 3.7 Writes oficiais

[Create events](https://developers.google.com/workspace/calendar/api/guides/create-events) + [Events resource](https://developers.google.com/workspace/calendar/api/v3/reference/events):

| Operação | Método | Notas |
|----------|--------|-------|
| Criar | `events.insert` | `start`+`end` obrigatórios; **ID gerado pelo cliente** para idempotência |
| Editar parcial | `events.patch` | Preferir a `update` (não clobber campos omitidos) |
| Substituir | `events.update` | Recurso completo |
| Apagar | `events.delete` | |
| Mover de calendário | `events.move` | |
| Importar iCal | `events.import` | |
| Instâncias de série | `events.instances` | |
| RSVP | patch `attendees[].responseStatus` | |
| Conflito | header `If-Match: etag` → `412` | |

Parâmetros de pedido que a UI precisa de conhecer:

- `sendUpdates`: `none` \| `all` \| `externalOnly` (e-mails a convidados).
- `conferenceDataVersion=1` para criar/alterar Google Meet.
- `supportsAttachments=true` para anexos Drive.

---

## 4. Caminhos avaliados

| Caminho | Poucos cliques | Fidedignidade / histórico | Write completo | Local-first | Veredicto |
|---------|----------------|---------------------------|----------------|-------------|-----------|
| **Calendar API v3 + `google_sign_in`** | 2 diálogos (conta + scope) | Sim, com `syncToken` | Sim | Sim (tokens no SO) | **Escolher** |
| Android `CalendarContract` / `device_calendar` | 1 permissão runtime | Não: janela do provider, campos pobres, sync Google assíncrono | Parcial e opaco | Sim | Só fallback futuro |
| ICS já no app | Vários (exportar no Google, partilhar ficheiro) | Snapshot morto | Não | Sim | Manter como fallback offline |
| CalDAV Google | Péssimo UX | Possível | Possível | Sim | Não |
| Nylas / Nango / similar | Fácil, mas **conta + servidor de terceiros** | Sim | Sim | **Não** | Fora |
| `events.watch` via backend Colony | Tempo-real | Sim | Sim | **Não** no MVP | Depois do sync remoto |

`device_calendar` **não** é integração Google: lê o cache do SO. Perde Meet, `extendedProperties`, `eventType`, histórico longo, `etag`, e o write “desaparece” até o Google Calendar app sincronizar. Incompatível com “atualização garantida”.

---

## 5. Repositórios e código que podemos usar de base

Não há um SDK Flutter “drop-in” de sync fiável. O que existe de qualidade é **algoritmo + client gerado**. Copiamos padrões, não um app inteiro.

### 5.1 Usar de verdade (dependências / algoritmo)

| Repo | Porque importa |
|------|----------------|
| [dart-lang/googleapis](https://github.com/dart-lang/googleapis) `calendar/v3.dart` | Client oficial Dart. Tipos `Event`, `CalendarList`, `Settings`, `FreeBusy`. **Dependência do produto.** |
| [flutter/packages `google_sign_in`](https://github.com/flutter/packages/tree/main/packages/google_sign_in) | OAuth no dispositivo. |
| [extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) | Ponte oficial para `CalendarApi`. |
| [Google Calendar sync sample (Java)](https://developers.google.com/workspace/calendar/api/guides/sync) (`SyncTokenSample.java`) | Algoritmo canónico full → incremental → `410`. Traduzir para Dart. |

### 5.2 Copiar o algoritmo de sync (não o produto)

Estes são os únicos sítios públicos que implementam o contrato `nextSyncToken` / `410` / paginação **corretamente**. Servem de checklist, não de vendor.

| Repo | O que acertam | Cuidado |
|------|---------------|---------|
| [NangoHQ/integration-templates `integrations/google-calendar/syncs/events.ts`](https://github.com/NangoHQ/integration-templates/blob/main/integrations/google-calendar/syncs/events.ts) | Checkpoint por página (`syncToken` + `pageToken`); `showDeleted`; não mistura filtros no incremental; trata cancelled vs upsert | É para o runtime Nango (servidor). Extraímos só o loop. |
| [receptron/mulmoclaude `packages/core/src/google/calendar.ts`](https://github.com/receptron/mulmoclaude/blob/main/packages/core/src/google/calendar.ts) | Função `syncCalendarEvents` com `fullResyncRequired` no `410`; documenta que `syncToken` **não** pode ir com `timeMin`/`orderBy` | `singleEvents=true` — mau para write-back de RRULE (ver §8) |
| [lobu-ai/lobu `packages/connectors/src/google_calendar.ts`](https://github.com/lobu-ai/lobu/blob/main/packages/connectors/src/google_calendar.ts) | Captura `nextSyncToken` em **cada** página (o valor útil é o da última); teto `MAX_PAGES` | Também é connector servidor |
| [toeverything/AFFiNE `.../calendar/providers/google.ts`](https://github.com/toeverything/AFFiNE/blob/e9ef3c50/packages/backend/server/src/plugins/calendar/providers/google.ts) | Paginação, `showDeleted`, guarda `raw` do evento | No full sync usa `orderBy=startTime` + `timeMin` — **isso impede `nextSyncToken`**. Não copiar essa combinação. |

Artigo útil (arquitetura produção, mesmo sendo SaaS): [Nango — real-time Google Calendar](https://nango.dev/blog/how-to-build-a-real-time-google-calendar-api-integration/) — webhooks sem payload, renovação de canal, quota, refresh token. Confirma que **poll + incremental** é o desenho certo sem servidor.

### 5.3 Não usar como base de sync

| Repo | Porquê |
|------|--------|
| [draganovik/day32-mobile](https://github.com/draganovik/day32-mobile) | Flutter + `googleapis` + `google_sign_in`, mas lista “agora”; sem `syncToken`; abandonado (2022); GPL |
| [Shadow60539/GoogleCalendarClone_Flutter](https://github.com/Shadow60539/GoogleCalendarClone_Flutter) | Clone visual + Firebase; não é sync fiável |
| Tutoriais `timeMin=now` + `singleEvents=true` + `orderBy=startTime` | Perdem histórico, token e séries |

### 5.4 Pacotes Dart auxiliares (produto)

- `googleapis` + `googleapis_auth` + `http`
- `google_sign_in` + `extension_google_sign_in_as_googleapis_auth`
- `rrule` (ou equivalente RFC 5545) para expandir séries **localmente**
- `flutter_workmanager` (Android) para poll em background — slice posterior
- **Não** adicionar `device_calendar` no MVP

---

## 6. Superfície de leitura (tudo o que devemos extrair)

### 6.1 Calendários — `calendarList.list`

Por cada calendário visível na UI do Google:

- `id`, `summary`, `summaryOverride`, `description`, `timeZone`
- `primary`, `selected`, `hidden`, `deleted`
- `accessRole`: `none` \| `freeBusyReader` \| `reader` \| `writer` \| `owner`
- `backgroundColor` / `foregroundColor` / `colorId`
- `defaultReminders[]`, `notificationSettings`
- `conferenceProperties.allowedConferenceSolutionTypes` (Meet vs Hangouts)

Útil no Colony: saber se podemos escrever; cor na grelha; calendários de feriados/subscritos (read-only).

### 6.2 Evento — resource `Event` (campos a persistir)

Persistir **duas camadas**: colunas indexáveis + `rawJson` (recurso completo). O raw garante que um campo novo da Google não se perde e que o `patch` não inventa dados.

**Identidade e sync**

- `id`, `iCalUID`, `etag`, `status` (`confirmed` / `tentative` / `cancelled`)
- `created`, `updated`, `sequence`
- `htmlLink`, `recurringEventId`, `originalStartTime`

**Conteúdo**

- `summary`, `description`, `location`, `colorId`
- `start` / `end`: `date` *ou* `dateTime` + `timeZone` (all-day vs timed; `end` exclusive em all-day)
- `endTimeUnspecified`, `transparency` (`opaque`/`transparent`), `visibility`
- `eventType`: `default` \| `outOfOffice` \| `focusTime` \| `workingLocation` \| `birthday` \| `fromGmail`

**Recorrência**

- `recurrence[]` — linhas `RRULE` / `EXDATE` / `RDATE` (RFC 5545), **sem** DTSTART/DTEND
- Instâncias-exceção: `recurringEventId` + `originalStartTime`

**Pessoas**

- `creator`, `organizer` (`email`, `displayName`, `self`)
- `attendees[]`: email, displayName, `responseStatus`, `optional`, `organizer`, `self`, `resource`, `comment`, `additionalGuests`
- `attendeesOmitted` (lista truncada — precisa `events.get`)
- flags: `guestsCanInviteOthers`, `guestsCanModify`, `guestsCanSeeOtherGuests`, `anyoneCanAddSelf`

**Conferência e anexos**

- `hangoutLink`, `conferenceData` (`entryPoints`, `conferenceSolution`, `createRequest.status`)
- `attachments[]` (`fileUrl`, `title`, `mimeType`, `iconLink`)

**Lembretes e extras**

- `reminders.useDefault` + `overrides[]` (`popup`/`email` + minutos; máx. 5)
- `extendedProperties.private` / `.shared`
- `source` (url/title de apps)
- `workingLocationProperties`, `outOfOfficeProperties`, `focusTimeProperties`, `birthdayProperties`
- `locked`, `privateCopy`, `gadget` (legado / aniversários)

### 6.3 Outros recursos úteis

| Recurso | Para quê no Colony |
|---------|--------------------|
| `settings.list` | `timezone`, `weekStart`, `dateFieldOrder`, `autoAddHangouts` — alinhar grelha local |
| `colors.get` | mapa `colorId` → hex (calendário e evento) |
| `freebusy.query` | “está ocupado?” sem vazar título — Storyteller / work grid |
| `calendars.get` | timezone “oficial” do calendário |
| `acl` | fora do MVP |
| People API (`birthdayProperties.contact`) | só se quisermos ligar aniversários a `Person`; scope extra — defer |

### 6.4 Tipos de evento — comportamento

[Event types](https://developers.google.com/workspace/calendar/api/guides/event-types):

- `default` — CRUD normal.
- `birthday` — all-day + `RRULE:FREQ=YEARLY`; insert com regras rígidas; ligados a Contactos não se muda a data via Calendar.
- `fromGmail` — só ler/apagar; não se cria via API.
- `outOfOffice` / `focusTime` / `workingLocation` — só no **primary**, nem todos os users; campos `*Properties` específicos.

Full sync **sem** filtrar `eventTypes` para não perder histórico. A UI pode esconder `workingLocation` por omissão.

---

## 7. Superfície de escrita (criar e manejar)

### 7.1 Campos no formulário Colony (paridade útil)

MVP write (eventos `default` em calendário `writer`/`owner`):

- título, descrição, localização
- início/fim (timed com TZ **ou** all-day)
- calendário destino
- recorrência (RRULE simples: diário/semanal/mensal/anual + UNTIL/COUNT + BYDAY)
- convidados (e-mail) + `sendUpdates`
- lembretes (default do calendário **ou** overrides)
- cor, visibilidade, transparency (ocupa / livre)
- Meet (`conferenceData.createRequest.requestId` único)
- “este evento” vs “este e os seguintes” vs “toda a série”

Depois: anexos Drive (precisa scope Drive), OOO/focus/working location, aniversários.

### 7.2 Recorrência na escrita

[Recurring events](https://developers.google.com/workspace/calendar/api/guides/recurringevents):

- Série = um evento-mestre com `recurrence[]`.
- “Só esta ocorrência” = `events.instances` → `patch` dessa instância (cria exceção).
- “Esta e as seguintes” = **dois** pedidos: `update` no mestre com `UNTIL` antes do corte + `insert` de uma nova série a partir da instância alvo.
- Cancelar ocorrência = instância com `status=cancelled` (não apagar o mestre).

Por isso a réplica local **guarda mestres + exceções**, não só instâncias expandidas (`singleEvents=false` no sync). A grelha expande com `rrule` numa janela (ex. −1 ano … +2 anos).

### 7.3 Idempotência e conflito

- `insert` com `id` gerado por nós no alfabeto Google (`[a-v0-9]{5,1024}`). Retry do mesmo insert não duplica.
- Guardar `etag` local. `patch` com `If-Match`. `412` → puxar remoto, mostrar conflito (nunca last-write-wins silencioso em texto — alinhado a ADR-025).
- Outbox local (já existe stub Phase 9): mutação UI **nunca** espera a rede. Worker empurra quando houver conectividade; se falhar, o bloco continua no Colony com `syncStatus=pending`.

### 7.4 Ligação Colony ↔ Google

`extendedProperties.private.colonyEntityType` + `colonyEntityId` no evento que **nós** criámos. Permite reencontrar o evento após 410/reinstall sem servidor. Eventos que só existem no Google não levam esta chave (são só importados).

Não reutilizar `conferenceData` entre eventos (aviso oficial: vaza salas Meet).

---

## 8. Casos que o código tem de tratar

| Caso | Tratamento |
|------|------------|
| All-day | `start.date` / `end.date` (end exclusivo). Não converter para meia-noite local sem TZ. |
| Timed com TZ | Guardar `timeZone` IANA; converter para UTC só para a grelha. |
| Timed *floating* (sem TZ) | Raro; tratar como TZ do calendário. |
| Recorrência infinita | Não materializar o infinito; expandir janela. |
| Exceção movida | `originalStartTime` ≠ `start` — a chave da instância é o original. |
| Série cancelada vs ocorrência cancelada | Mestre `cancelled` vs instância `cancelled`. |
| Calendário holandês / feriados | `accessRole=reader`, `selected`; read-only na UI. |
| Calendário partilhado | Podemos ser `writer` sem ser `owner`; ACL alheia. |
| `attendeesOmitted=true` | `events.get` antes de editar convidados. |
| Meet `pending` | `conferenceData.status` assíncrono; re-get depois. |
| Evento `locked` | UI só leitura. |
| `privateCopy` / visibilidade `private` em calendário partilhado | Título “Ocupado” para outros; para o dono vem completo. |
| Primary vs secundário | OOO/focus/working location só no primary. |
| Conta Google revogada | `invalid_grant` → marcar consent revoked, **não** apagar histórico local (ADR-032). |
| Troca de conta | Binding `googleSub` / e-mail no consent; recusar misturar réplicas. |
| Incremental a meio (crash) | `pageToken` + `syncToken` antigo em checkpoint; **não** gravar `nextSyncToken` novo até aplicar todas as páginas. |
| 410 | Merge por `(calendarId, eventId)`: remoto ganha campos Google; anotações Colony (quest link, notes) sobrevivem. Tombstone o que o remoto já não lista após full sync. |
| Rate limit | Backoff; não disparar full sync de todos os calendários em paralelo sem limite (p.ex. 2 em flight). |
| Quota / `userRateLimitExceeded` | Idem. |
| Evento duplicado ICS + Google | Dedup por `iCalUID` quando o user também importou `.ics`. |
| Relógio do dispositivo errado | Usar `updated` do servidor; não filtrar por relógio local. |

---

## 9. Fiabilidade — desenho à prova de falhas

```
                    ┌─────────────────────────┐
   Google Calendar  │  Calendar API v3         │
                    └──────────┬──────────────┘
                               │ OAuth (GMS)
                               ▼
                    ┌─────────────────────────┐
                    │ GoogleCalendarConnector │  colony_domain port
                    │ (sem Flutter, sem Drift)│
                    └──────────┬──────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        SyncEngine        WriteOutbox      TokenSession
        (full/incr)       (insert/patch)   (google_sign_in)
              │                │
              ▼                ▼
        Drift: calendars, events_raw, sync_state, outbox
              │
              ▼
        Projection → ScheduleBlock / UI (opt-in)
```

**Invariantes**

1. App útil **sem** esta integração (ADR-005 / ADR-032).
2. Token OAuth **não** vai para export JSON em claro. Estado de sync (`syncToken`, etags, event ids) pode ir no export; credenciais não.
3. `nextSyncToken` só se persiste **depois** de um commit Drift de todas as páginas daquela ronda.
4. Writes: local commit → outbox → API. Falha de rede ≠ perda de dados Colony.
5. 410 ≠ `DELETE FROM events`. É “reconciliação”.
6. Poll no resume **sempre** que `enabled && lastSuccessAt > staleThreshold` (ex. 5 min).
7. Full sync inicial mostra progresso e é resumível (`pageToken` checkpoint).
8. Testes de domínio cobrem o motor de sync **com HTTP fake** (ver §14) — sem Cloud.

Atualização “garantida” na prática: **eventual consistency curta**. Não há push sem servidor. A garantia é: (a) nenhum delta perdido enquanto o token for válido; (b) se o token morrer, full merge recupera; (c) se o user abrir a app online, corre incremental antes de pintar a agenda do dia.

---

## 10. UX — poucos cliques

Fluxo alvo Android:

1. Settings → Integrações → **Google Agenda** → interruptor.
2. Folha de explicação (o que se lê, que não enviamos a um servidor nosso, revogável).
3. **Um** toque “Continuar” → seletor de conta Google (muitas vezes 0 toques extra se só há uma conta) → ecrã de consentimento Google.
4. Lista de calendários já com **primary + selected** marcados; toque em “Sincronizar” (default: pode sincronizar já os preselecionados sem este passo — 1 toque a menos).
5. Progresso “A importar… 3/8 calendários”.
6. Pronto. Agenda do Colony mostra os eventos. Pull-to-refresh visível.

Write: na criação de evento Colony, checkbox **“Também no Google Agenda”** (só aparece com consent write; se só houver readonly, um toque pede o scope extra — incremental auth).

Revogar: interruptor off → para o poll, esquece tokens via `google_sign_in.signOut/disconnect`, **mantém** eventos já importados (tombstone de consent, ADR-032). Ação separada “Apagar réplica Google” se o user quiser.

Estados DoD: empty (nunca ligou) / loading (sync) / error (OAuth, 410 em curso, offline) / offline (última sync há X, dados locais).

---

## 11. Arquitetura no monorepo

Alinhado a AGENTS.md / ADR-002 / ADR-032:

```
packages/colony_domain/
  integration.dart          → IntegrationKind.googleCalendar
  google_calendar_models.dart
  google_calendar_sync_engine.dart   # puro: aplica páginas, 410, checkpoints
  google_calendar_rrule.dart

packages/colony_database/
  tabelas + DAOs + mappers
  GoogleCalendarRepository implements port

lib/features/integrations/
  application/   GoogleCalendarController, providers
  presentation/  secção na IntegrationsScreen + picker + conflito

lib/core/integrations/google/   # único sítio com google_sign_in / googleapis
  GoogleSignInSession
  GoogleapisCalendarClient implements CalendarPort
```

**Regra absoluta:** `colony_domain` e widgets **não** importam `googleapis`. O client HTTP vive no adapter Flutter (`lib/core/...`) ou, se crescer, `packages/colony_integrations` (já previsto no ADR-032). SQL só em `colony_database`.

ICS e Google são **dois** `IntegrationKind`. Podem coexistir. Dedup por `iCalUID`.

Projeção para `ScheduleBlock`: opt-in como hoje (`IcsSchedulePolicy`), modo `meeting` / mapeamento `eventType` (OOO → bloco próprio se existir). Não sobrescrever blocos manuais.

---

## 12. Modelo de dados proposto

Novas tabelas (nomes indicativos; schema Drift **v40**, export **v35**):

**`google_calendar_accounts`**  
`id`, `profileId`, `googleSub`, `email`, `grantedScopes`, `grantedAt`, `revokedAt`, `enabled`.

**`google_calendars`**  
`accountId`, `calendarId`, `summary`, `timeZone`, `accessRole`, `primary`, `selected`, `colorId`, `syncEnabled`, `rawJson`.

**`google_calendar_sync_state`**  
`calendarId`, `syncToken`, `pageToken` (checkpoint), `phase` (`full`/`incremental`/`resync`), `lastSuccessAt`, `lastError`, `resourceEtag`.

**`google_calendar_events`**  
`calendarId`, `eventId` (PK composta), `iCalUID`, `etag`, `status`, `eventType`,  
`title`, `startAt`, `endAt`, `allDay`, `timeZone`,  
`recurringEventId`, `isMaster`, `rawJson`,  
`colonyLinkType`, `colonyLinkId`,  
`sourceUpdatedAt`, `tombstonedAt`.

**`google_calendar_outbox`**  
Pode reutilizar `sync_operations` (Phase 9) com `entityType=googleCalendarEvent` **ou** tabela dedicada se o outbox atual for demasiado genérico. Campos: op (`insert`/`patch`/`delete`/`move`), payload, `ifMatchEtag`, `attempts`, `nextAttemptAt`, `clientEventId`.

Índices: `(profileId, startAt, endAt)`, `(iCalUID)`, `(status)`, `(recurringEventId)`.

`rawJson` é a fonte para rehidratar o `Event` no `patch`. Colunas densas servem queries/UI.

Export: incluir calendários + eventos + sync state **sem** tokens OAuth. Restore: user precisa de voltar a autorizar; depois incremental ou full conforme token ausente.

---

## 13. Slices de implementação (ordem)

Cada slice é um vertical testável. Não misturar OAuth Cloud Console com motor de sync na mesma PR se for grande demais.

### Slice A — domínio + motor de sync (sem rede real)

- Portas: `CalendarRemote` (listCalendars, listEventsPage, insert/patch/delete).
- `GoogleCalendarSyncEngine` com fixtures JSON copiadas do formato da API.
- Casos: paginação, `nextSyncToken` só no fim, incremental cancelled, 410 merge, checkpoint.
- Testes em `packages/colony_domain`.

### Slice B — persistência

- Tabelas + mappers + export v35 + migration test.
- Consent `IntegrationKind.googleCalendar`.
- Repositório: apply page, save token atómico.

### Slice C — OAuth Android + 1.ª sync read-only

- Cloud project (doc em `docs/dev/` de setup: SHA-1, `google-services` **não** é obrigatório se só usarmos Calendar, mas o consent screen sim).
- `google_sign_in` + `CalendarApi`.
- UI: ligar, escolher calendários, progresso, lista.
- Scope `calendar.readonly` ou `calendar.events.readonly` + `calendar.readonly` para `calendarList`.
- App em Testing, test users.

### Slice D — projeção na agenda Colony

- Mapear para UI da schedule / timeline.
- Opt-in “criar ScheduleBlock”.
- Dedup ICS.

### Slice E — write básico

- Outbox + `insert`/`patch`/`delete` de evento `default` simples (sem convidados).
- ID cliente + etag.
- Pedido incremental do scope `calendar.events`.

### Slice F — write completo

- Recorrência (mestre, esta, esta-e-seguintes).
- Convidados + `sendUpdates`.
- Meet (`conferenceDataVersion`).
- Lembretes, cor, all-day, mover de calendário.
- Conflito `412` na UI.

### Slice G — polish fiabilidade

- WorkManager poll.
- Backoff / jitter.
- `settings` + `colors`.
- `freebusy` se o work grid precisar.
- Telemetria local de “última sync / eventos aplicados” (sem analytics remoto).

**Fora de propósito até haver backend:** `events.watch`, Nylas/Nango, Health/People scopes, Desktop OAuth, criar calendários novos, ACL.

---

## 14. Testes, l10n, DoD

- Motor de sync: vetores JSON (full 2 páginas, incremental com cancelled, 410, filtro ilegal).
- Repository: transação “apply pages then token”; crash a meio não avança token (teste Drift).
- Widget: empty / loading / error / offline na secção Google; a11y Semantics como ICS.
- Strings em `lib/app/localization/` — zero copy em inglês na UI.
- `flutter analyze` + testes app + domain + database + **migration test** no bump de schema.
- Aceite spec §37 / ADR-032: opt-in, proveniência `SourceType.integration`, revogar ≠ apagar, app útil offline.
- **Não** commitar client secret. Android OAuth client é público por natureza; SHA-1 no Cloud Console.

Testes de integração reais contra a API ficam manuais (conta de teste) — CI não deve depender da Google.

---

## 15. Riscos

| Risco | Mitigação |
|-------|-----------|
| Verificação OAuth bloqueia distribuição | Beta = Testing + test users; Play Store só com política hospedada (já listada em `PRIVACY_LEGAL_PREP.md`) |
| `google_sign_in` v7 API nova | Seguir doc Flutter atual; encapsular session |
| Agendas enormes na 1.ª sync | Progresso + resumable; `maxResults=2500` |
| `singleEvents=true` tentador para a UI | Proibido no sync; expandir local |
| AFFiNE e tutoriais com `orderBy` | Checklist no motor: asserts contra parâmetros ilegais |
| Scope demasiado largo (`calendar`) | Incremental: readonly → events |
| User espera push instantâneo | Copy: “atualiza ao abrir e ao puxar”; background depois |
| LGPD / calendar = dados pessoais | Disclaimer; dados só no dispositivo; sem relay |
| Export com `rawJson` grande | Aceitável em backup local; compressão depois se necessário |

---

## 16. Decisões a trancar (resumo)

1. **Calendar API v3 + `google_sign_in` + `googleapis`**, no dispositivo.
2. **Réplica local** de calendários e eventos (mestre + exceções + `rawJson`).
3. **Sync incremental oficial** com merge em `410`; token por calendário.
4. **Histórico:** full sync sem `timeMin` (ou mínimo ~2006).
5. **Sem webhook** no MVP; poll resume + refresh + (depois) WorkManager.
6. **Writes** via outbox, `patch` + `etag`, ID cliente.
7. **ICS permanece** fallback offline.
8. **Android primeiro**; desktop/iOS OAuth noutro momento.
9. Novo ADR (este plano) **antes** de código — [ADR-043](../adr/ADR-043-google-calendar.md).

---

## 17. Fontes

- [Calendar API — sync](https://developers.google.com/workspace/calendar/api/guides/sync)
- [Calendar API — events resource](https://developers.google.com/workspace/calendar/api/v3/reference/events)
- [Calendar API — events.list](https://developers.google.com/workspace/calendar/api/v3/reference/events/list)
- [Calendar API — create events](https://developers.google.com/workspace/calendar/api/guides/create-events)
- [Calendar API — recurring events](https://developers.google.com/workspace/calendar/api/guides/recurringevents)
- [Calendar API — event types](https://developers.google.com/workspace/calendar/api/guides/event-types)
- [Calendar API — push](https://developers.google.com/workspace/calendar/api/guides/push)
- [Calendar API — quota](https://developers.google.com/workspace/calendar/api/guides/quota)
- [Calendar API — extended properties](https://developers.google.com/calendar/api/guides/extended-properties)
- [Flutter Google APIs](https://docs.flutter.dev/data-and-backend/google-apis)
- [OAuth sensitive scopes](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification)
- Repos: `dart-lang/googleapis`, NangoHQ `integration-templates`, mulmoclaude `calendar.ts`, lobu `google_calendar.ts`, AFFiNE `providers/google.ts` (anti-padrão `orderBy`)
