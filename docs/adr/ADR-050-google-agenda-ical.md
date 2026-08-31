# ADR-050: Google Agenda via iCal (interino)

## Status
Aceito

## Contexto
A home mostra só `ScheduleBlock` locais. O stub ICS (ADR-032) vivia em Configurações → Integrações, abaixo do leitor de notificações — o utilizador não achava botão para ligar o Google Agenda. O conector OAuth da Calendar API v3 (ADR-043) continua planeado, mas precisa de projeto Cloud, scopes sensitive e verificação.

Enquanto isso, o Google Agenda já expõe um **endereço secreto iCal** (`basic.ics`) que o aparelho pode puxar sem conta Colony nem write-back.

## Decisão
1. **Descoberta:** botão na agenda da home (ícone + CTA vazio), botão na tela Agenda, item “Google Agenda” no menu Mais e na paleta. Rota `/settings/integrations?focus=calendar`.
2. **Painel Google Agenda** no topo de Integrações: passos para copiar o link iCal, campo, Sincronizar. Importação de ficheiro `.ics` fica como fallback no mesmo painel.
3. **Réplica local:** fetch HTTPS do feed → `IcsCodec` (TZ local, RRULE simples) → `ExternalCalendarEvent` com upsert por UID. Eventos aparecem na agenda do dia **sem** criar `ScheduleBlock` (títulos reais).
4. **URL do feed** fica em `SharedPreferences` (como o client id do Spotify). Não vai no export. Tabelas OAuth do ADR-043 substituirão isto.
5. **Refresh:** ao abrir home/agenda, se o feed tiver mais de 15 min, puxa de novo. Offline: dados locais.
6. **ADR-043 permanece** o caminho de sync incremental + write. Este ADR não autoriza `google_sign_in` nem webhook.

## Consequências
- App útil com Google Agenda no telemóvel sem Cloud Console.
- Recorrência coberta no subset FREQ/INTERVAL/COUNT/UNTIL/BYDAY.
- Write-back Google continua fora (spec §37 / ADR-032).
