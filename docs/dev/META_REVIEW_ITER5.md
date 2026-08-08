# Meta-review — Iteração 5 (Day 0)

Revisão arquitetural após cinco iterações de vertical slices (Fases 0–4c). Documento de registro; **sem refactor-only code** nesta iteração.

## 1. Layering: `core/` vs `features/`

### Estado atual

| Camada | Conteúdo observado | Avaliação |
|--------|-------------------|-----------|
| `packages/colony_domain` | Entidades puras, enums, ExportSnapshot | Correto |
| `packages/colony_database` | Drift, mappers, repositórios concretos | Correto |
| `lib/core/providers` | StreamProviders, AsyncNotifiers (controllers) | Transversal; aceitável no MVP |
| `lib/core/widgets` | Command palette, quick capture | Transversal |
| `lib/features/<name>/` | Screens, sheets, widgets de apresentação | Correto |

### Desvios menores

- **Controllers em `core/`**: `quest_controllers`, `project_controllers`, `work_controllers` vivem em `core/providers/` em vez de `features/<name>/application/`. Funciona para slices pequenos, mas concentra dependências cross-feature (ex.: `quest_controllers` importa `project_providers`).
- **Repositórios no pacote DB, não interfaces no domínio**: alinhado ao roadmap atual; extrair ports fica para fase de sync/test doubles.
- **Widgets de feature referenciados cross-feature**: quest detail importa sheets de `projects/` e (agora) `decisions/` — acoplamento de apresentação tolerável no MVP; alternativa futura: seções genéricas + callbacks.

### Recomendações (próximas iterações, não bloqueantes)

1. Manter regra: widgets nunca acessam Drift; apenas `repositoriesProvider`.
2. Quando uma feature passar de 3+ controllers, mover para `features/<name>/application/`.
3. Documentar em ADR quando um provider `core/` passa a ser usado por ≥2 features.

## 2. Export versioning (v1 → v3 → v4)

| Versão export | Schema DB | Novos campos JSON | Restore |
|---------------|-----------|-------------------|---------|
| 1 (implícita) | ≤ v2 | profile, preferences, tasks, events, needs, check-ins | Não |
| 2 | v4 | `quests`, `tasks[].quest_id` | Não |
| 3 | v5 | `projects`, `quest_project_links`, `quests.pause_reason` | Não |
| 4 | v6 | `decision_records`, `quest_decision_links` | Não |

### Regras adotadas

1. **`ExportSnapshot.version`** é independente de **`schemaVersion`**; incrementa apenas quando o JSON ganha chaves novas.
2. Export é **append-only**: versões antigas permanecem legíveis; import futuro deve aceitar v≤N.
3. **`buildSnapshot()`** sempre emite a versão mais recente (atualmente **4**).
4. Listas vazias serializam como `[]`; campos opcionais omitidos no JSON quando null.
5. Restore/import continua **fora de escopo** até ADR dedicado (risco de merge parcial).

### Lacuna

- Testes cobrem export v3/v4 em repo tests; não há golden file nem round-trip import. Adicionar quando restore entrar no roadmap.

## 3. Test pyramid — gaps

```
        /\
       /  \  E2E / integration (quase zero)
      /----\
     / widget \  ~10 testes (board, schedule, project, quest link)
    /----------\
   / repo + mig  \  colony_database tests (forte)
  /----------------\
 /  domain unit     \  lifecycle, priority, schedule_day
/--------------------\
```

| Camada | Cobertura | Lacunas |
|--------|-----------|---------|
| Domain unit | Quest lifecycle, work priority, needs | Sem testes de `Project`, `DecisionRecord` factories |
| Repository | CRUD, export, migrations v3→v4→v5→v6 | Sem teste de concorrência/transação |
| Widget | Fluxos felizes por feature | Poucos estados erro/offline; sem golden |
| Integration | Nenhum teste `flutter drive` | Bootstrap + routing + DB real |
| Export | Assert `contains` em JSON | Sem validação de schema JSON |

Prioridade P1 pós-iteração 6: widget test para create decision + link; migration v5→v6 (incluído na iter. 6).

## 4. Confirmação MVP vs spec §61.2 (Quest lifecycle)

A spec §61.2 define máquina de estados rica:

`Draft → Available → Accepted → Active → Paused → Completed/Failed/Abandoned → Historical`

### Implementação atual (iter. 5)

Estados: **`draft`, `active`, `paused`, `completed`, `abandoned`**.

| Spec | MVP | Decisão |
|------|-----|---------|
| Available / Accepted | Omitidos | Ativação direta `draft → active` |
| Expired / Rejected | Omitidos | Fora do escopo local-first |
| Failed | Omitido | Conclusão/abandono cobrem saídas |
| Historical | Representado por `completed`/`abandoned` no board “Histórico” | OK para UI |
| Accepted registra premissas | Parcial via purpose/criteria no create | OK |
| Abandoned motivo opcional neutro | `exitReason` / `pauseReason` | OK |

**Confirmação**: o desvio é **intencional** para vertical slice utilizável. Reintroduzir estados intermediários só quando houver UX de “missão disponível” (ignition engine) ou sync multi-dispositivo. Documentado aqui para evitar drift silencioso.

## 5. Ações sugeridas (iter. 6+)

- [x] Iter. 6: decision log MVP + export v4 + migration v6
- [ ] Iter. 7+: restore ADR; mover controllers grandes para features
- [ ] Adicionar teste de schema export (json_schema ou fixture golden)
- [ ] Reavaliar quest lifecycle quando ignition/sync entrarem no roadmap
