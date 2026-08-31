# ADR-043: Google Calendar — conector local-first

## Status
Proposto (pesquisa em [`docs/dev/GOOGLE_CALENDAR_INTEGRATION.md`](../dev/GOOGLE_CALENDAR_INTEGRATION.md); OAuth ainda sem código produto)

**Interino em produção:** [ADR-050](ADR-050-google-agenda-ical.md) liga o Google Agenda por feed iCal secreto (read-only, no dispositivo) até existir o slice C deste ADR.

## Contexto
Spec §37.2 lista Google Calendar, EventKit, calendários locais e ICS. ADR-032 entregou o stub ICS read-only e **deferiu** OAuth e write-back. O modelo `ExternalCalendarEvent` (título + intervalo + UID) não suporta réplica fiável nem criação de eventos.

Queremos: poucos cliques no Android, extração completa (atual + histórico + metadados), e criar/manejar eventos com a superfície real da Calendar API v3 — sem obrigar conta Colony nem servidor.

## Decisão

1. **Provedor:** Google Calendar API v3 no dispositivo, via `google_sign_in` + `googleapis` (`CalendarApi`). Sem Nylas/Nango/CalDAV/device_calendar como fonte da verdade.
2. **Auth:** OAuth do utilizador, scopes incrementais (`calendar.readonly` / `calendar.events.readonly` na ligação; `calendar.events` só no write). Tokens ficam no Account Manager; **não** entram no export JSON.
3. **Sync:** full paginado → `nextSyncToken` por `calendarId` → incremental. `410 Gone` dispara full **merge** (preserva anotações Colony). Checkpoint atómico: token novo só depois de aplicar todas as páginas. Sem `timeMin`/`orderBy`/`q` no ciclo de sync (histórico completo).
4. **Atualização:** poll no resume + pull-to-refresh; WorkManager depois. `events.watch` **defer** (exige webhook público).
5. **Modelo:** tabelas próprias (contas, calendários, eventos com `rawJson` + colunas indexáveis, sync state, outbox). ICS (`calendarIcs`) permanece. `IntegrationKind.googleCalendar` novo.
6. **Write:** outbox local-first; `insert`/`patch`/`delete` com `id` cliente e `If-Match` etag; séries como mestres + exceções (`singleEvents=false` no sync, expansão local).
7. **Plataforma MVP:** Android. Desktop/iOS OAuth noutro ADR.
8. **Camadas:** portas em `colony_domain`; SQL em `colony_database`; SDKs Google só no adapter Flutter (`lib/core/integrations/google/` ou pacote `colony_integrations`).

Plano de slices A–G, campos da API, casos-limite e repos de referência: o doc de pesquisa acima.

## Alternativas rejeitadas
- **CalendarContract / `device_calendar`:** poucos campos, histórico incompleto, write opaco.
- **Só ICS:** não atualiza, não escreve.
- **Webhook + backend:** viola ADR-005 no MVP.
- **Agregadores SaaS:** conta obrigatória, dados fora do dispositivo.

## Consequências
- Phase 10 passa de stub ICS para conector Google opt-in.
- Bump Drift + export quando o código existir (próximo livre após consolidação: previsto v40 / export v35).
- Beta sideload usa OAuth *Testing* (test users). Play Store exige verificação de sensitive scope + política de privacidade hospedada.
- Verificar este ADR **antes** da 1.ª PR de código (slice A pode começar assim que aceite).

## Próximos passos após merge deste ADR

1. Marcar este ADR **Aceito** (ou devolver comentários neste PR / follow-up).
2. Implementar slices A→C do plano (`docs/dev/GOOGLE_CALENDAR_INTEGRATION.md` §13): motor testável → persistência → OAuth Android read-only.
3. Só então writes (E/F) e poll em background (G). Webhook Google fica defer até existir backend.
