# ADR-023: Health local MVP (Phase 7 spike)

## Status
Aceito (Iter 29 spike; Iter 34 — HealthCondition MVP + export v13 / DB v14; Iter 36 edit UI; Iter 37 SymptomEntry + export v14 / DB v15)

## Contexto
Spec §13 define um módulo de saúde amplo (sintomas, condições, medicações, exames, sono, treino, integrações Health Connect/HealthKit). Spec §0.1 e AGENTS.md: **saúde não diagnostica, não prescreve, não substitui profissionais**. Phase 7 roadmap: “saúde local”. Check-in/needs (Phase 2) já cobrem humor/energia/tensão/foco — saúde clínica deve ser domínio **separado**.

## Decisão (MVP mínimo utilizável offline)

### Escopo IN
1. **`HealthCondition`** (subset §13.4)
   - Campos: `id`, `profileId`, `title`, `type` (`symptom` | `diagnosisReported` | `injury` | `recovery` | `context`), `status` (`active` | `monitoring` | `resolved` | `archived`), `onsetAt?`, `resolvedAt?`, `severityUserReported?` (1–5), `bodyRegions[]` (strings livres no MVP), `clinicianConfirmed` (bool), `notes?`, `createdAt`, `updatedAt`
   - Sem attachments, measurements ou red-flag engine no MVP
2. **Symptom check-in lite** (registro pontual, não diagnóstico)
   - Entidade opcional `SymptomEntry`: `id`, `profileId`, `conditionId?`, `occurredAt`, `intensity` (1–5), `note?`, `bodyRegion?`
   - Alternativa aceitável na 1ª slice: só `HealthCondition` + notas, sem entries
3. **UI**
   - Rota `/resources/health` (ou `/pawn/health`) — lista condições + criar/editar
   - Disclaimer persistente (espelhar finance): não diagnostica / buscar profissional
4. **Export**
   - Nova versão export (v13+) com `health_conditions[]` (+ `symptom_entries[]` se existir)
   - DB schema bump dedicado
5. **Camada**
   - `features/health/application|presentation`
   - Domínio em `colony_domain`; SQL só em `colony_database`

### Escopo OUT (defer explícito)
- Body map visual (§13.3)
- Exames/PDF pipeline (§13.5)
- Health Connect / HealthKit (§13.6)
- Motor de red flags clínicos (§13.7) — exige revisão clínica
- Correlações exploratórias (§13.8)
- Medicações, consultas, treino, nutrição como entidades
- Qualquer linguagem de diagnóstico, prescrição ou urgência automática

### Políticas
- **`HealthSafetyPolicy` (stub):** UI só mostra disclaimer + link genérico “procure atendimento se sintomas graves”; **sem** matching de termos urgentes no MVP
- Intensidade/severidade = **auto-relato do usuário**; nunca inferida
- `clinicianConfirmed` é flag do usuário; não valida profissional

### Relação com Pawn/needs
- Needs/check-in continuam em `features/pawn` (humor/energia)
- Health conditions **não** alimentam automaticamente need snapshots no MVP
- Link futuro opcional via tab Relações / chronicle — fora do spike

### Eventos propostos
- `healthConditionCreated`, `healthConditionUpdated`, `healthConditionStatusChanged`
- `symptomEntryLogged` (se entries existirem)

### Critérios de aceite da 1ª slice (Iter 34+ pós-ADR)
1. Criar/editar/arquivar condição local offline
2. Lista vazia/carregando/erro
3. Disclaimer visível
4. Export/restore round-trip da nova versão
5. Zero cópia de assets RimWorld; strings localizadas

## Consequências
- Phase 7 tem ADR antes de código — alinha protocolo AGENTS.md
- Iter seguinte de produto health deve referenciar este ADR e **não** expandir para exames/integrações
- Red-flag engine permanece bloqueada até revisão clínica explícita

## Addendum — Appointment stub (Iter 111)

- **`HealthAppointment`** (lembrete local, §13 appointments lite): `id`, `profileId`, `title`, `scheduledAt`, `locationLabel?`, `clinicianLabel?`, `notes?`, `status` (`scheduled` | `done` | `cancelled`), `createdAt`, `updatedAt`
- UI painel na tela de saúde; disclaimer reforçado — **não** diagnostica, não agenda com clínica externa
- DB **v32** / export **v28** com `health_appointments[]`
- Fora: notificações push, sync com calendário OS, exames/PDF
