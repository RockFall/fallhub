# ADR-018: Quest acceptance (lite)

## Status
Aceito (Iter 14)

## Contexto
A spec §46.5 lista **“aceitar”** como ação de missão; §21.3 e §61.2 definem `accepted_at`, `acceptance_deadline` e premissas de aceite. Iter 9–13 entregaram lifecycle, pré-requisitos e cadeia, mas ativação (`draft → active`) ainda não exige momento explícito de aceite.

A máquina de estados completa §61.2 (`Available`/`Rejected`/`Expired`/`Failed`/`Historical`) e ignition engine permanecem deferidos (sync/Phase 5+).

## Decisão

### Modelo (lite)
- **Manter `QuestStatus` atual** — sem estado `accepted` separado.
- **Campos novos em `Quest`:**
  - `acceptedAt DateTime?`
  - `acceptanceDeadline DateTime?` (opcional)
  - `acceptanceAssumptions List<String>` (premissas no aceite; trim linhas vazias)
- Aceite ocorre no fluxo **`draft → active`** e em **create + ativar imediato**.

### Fluxo UI
- **`AcceptQuestSheet`** compartilhado: lista dinâmica de premissas (≥1 obrigatória), prazo opcional, confirmar/cancelar.
- Pré-preenche com o propósito da missão como primeira premissa editável.
- **Gate ADR-016** antes do sheet: pré-requisitos incompletos bloqueiam com snackbar (sem abrir sheet).
- **`paused → active`** (retomar) **não** reabre o sheet — aceite já registrado.

### Persistência
- DB **v9**: colunas `accepted_at`, `acceptance_deadline`, `acceptance_assumptions_json` em `quests`.
- Migration v8→v9 backfill: `active`/`paused`/`completed` → `accepted_at = created_at`; `draft`/`abandoned` → `null`.

### Export / restore
- **Export v8** inclui os três campos em cada objeto `quests[]`.
- Backups v≤7 restauram com `accepted_at`/`acceptance_deadline` null e `acceptance_assumptions` `[]`.

### Evento
- `EventType.questAccepted` na Crônica ao confirmar aceite (payload: título, contagem de premissas).

## Consequências
- QUEST-001 gap “aceitar” fechado no MVP lite.
- Restore v8 round-trip preserva aceite.
- Desvio residual §61.2 documentado: sem `Rejected`/`Expired`, sem tab “Disponíveis”.

## Fora de escopo
- Ignition engine, estados §61.2 completos
- Notificações de prazo de aceite
- Board badge “Não aceita” em drafts
- Sync multi-dispositivo

## Referências
- Spec §21.3, §46.5, §61.2
- ADR-016 (pré-requisitos), ADR-015 (export v8)
- Iter 13 defer → Iter 14 (plan d2d22500)
