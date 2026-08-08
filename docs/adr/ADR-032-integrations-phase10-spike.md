# ADR-032: Integrações Phase 10 — spike local-first

## Status
Aceito (Iter 83 spike — doc-only; produto ICS stub Iter 86)

## Contexto
Spec §45 Phase 10 lista: calendar, Health Connect, HealthKit, finance provider adapters, import improvements. Spec exige opt-in, granular, revogável e explicável. O app já tem export/restore (ADR-015), finance CSV fingerprint (Iters 52/64) e sync outbox stub local (ADR-025 / Iter 78). **Nenhuma** integração de SO/rede está ligada.

## Decisão (spike — sem código produto nesta iter)

### Princípios (IN)
1. **Local-first permanece** — integrações são opt-in; app útil sem nenhuma
2. **Adapter pattern** — domínio não importa SDKs de SO; ports em `colony_domain` / pacote futuro `colony_integrations`
3. **Proveniência** — todo dado importado carrega `sourceType` + confiança
4. **Saúde não diagnostica; finanças não executam** — adapters só leem/importam
5. **Revogável** — desligar integração não apaga histórico local já importado (tombstone de consent)

### Escopo OUT (defer explícito)
- Health Connect / HealthKit produto
- Open Finance / banking APIs
- Calendar write-back (criar eventos no SO)
- OAuth / contas cloud obrigatórias
- Background sync agressivo

### 1ª slice produto sugerida (pós-ADR)
**Calendar ICS import stub (read-only):**
1. Domínio: `IntegrationConsent` (kind, enabled, grantedAt?, revokedAt?) + `ExternalCalendarEvent` lite **ou** mapear ICS → `ScheduleBlock` / `DomainEvent` com proveniência
2. UI: `/settings/integrations` lista + toggle + “Importar .ics”
3. Parse ICS mínimo (VEVENT title/dtstart/dtend) → preview → confirmar
4. Sem write no calendário do SO; sem conta Google/Apple
5. Export bump se persistir entidades novas; senão só consent local

### Alternativa P1 (se ICS adiado)
Finance CSV import polish já parcial — expandir mapeamento de colunas sem novo provider.

### Critérios de aceite da 1ª slice
1. Importar arquivo `.ics` offline com preview e confirmação
2. Empty/loading/error + disclaimer opt-in
3. Dados importados com proveniência; desligar integração não quebra app
4. Zero dependência de conta; strings localizadas

### Ordem recomendada
1. Pit 85 recalcula
2. ICS stub **ou** IntegrationConsent table + UI vazia
3. Só então Health Connect spike dedicado (ADR novo)

## Consequências
- Phase 10 tem ADR antes de SDKs
- Não bloqueia ContextZone E2E / Storyteller planning
- Health Connect permanece defer explícito (regulatório + OS)
