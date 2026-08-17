# Pipeline autônomo — Life Colony OS

Motor de desenvolvimento **contínuo e autônomo**. O loop **nunca para** após uma implementação — só faz **pit stop** a cada 5 iterações para avaliar inconsistências e reabastecer o backlog.

Referências: [`AGENTS.md`](../../AGENTS.md), [`LOOP.md`](LOOP.md), [`LIFE_COLONY_OS_SPEC.md`](../produto/LIFE_COLONY_OS_SPEC.md) §45.

---

## Princípios

| Prioridade | Regra |
|------------|-------|
| **1. Avanço** | Sempre implementar o próximo slice de valor; velocidade > perfeição |
| **2. Continuidade** | Nunca encerrar sessão após 1 iter; encadear imediatamente |
| **3. Autonomia** | Não pedir confirmação ao usuário entre iters |
| **4. Pit stop** | A cada 5 iters: meta-review doc-only, backlog 5+ iters, seguir |
| **5. Gate mínimo** | `./tool/test_all.ps1` verde = suficiente para avançar |
| **6. Terminação** | Só parar quando **todas as fases 0–12** tiverem MVP na spec **ou** gate falhar 3× seguidas no mesmo slice |

---

## Motor contínuo (visual)

```text
                    ┌──────────────────────────────────┐
                    │  INÍCIO / RETOMADA               │
                    │  Ler LOOP.md + última meta-review│
                    └─────────────┬────────────────────┘
                                  │
                    ┌─────────────▼────────────────────┐
              ┌─────│  Iter N                          │
              │     │  Implementa → test_all → LOOP.md │
              │     └─────────────┬────────────────────┘
              │                   │
              │     test_all falhou? ──► Fix inline (max 3 tentativas) ──┐
              │                   │                                      │
              │                   NO                                     │
              │                   │                                      │
              │     N % 5 == 0? ──YES──► PIT STOP (meta-review doc)     │
              │                   │         reabastece backlog           │
              │                   NO                                     │
              │                   │                                      │
              │     Fase 0–12 MVP completo? ──YES──► FIM ✓              │
              │                   NO                                     │
              │                   │                                      │
              └─────── N++ ◄──────┘◄─────────────────────────────────────┘
                        (SEM PAUSA — próxima iter imediata)
```

**Proibido entre iters:** perguntar ao usuário, esperar aprovação, invocar revisor/planejador separados, commit (salvo pedido explícito), parar para "resumir e aguardar".

---

## Pit stop (a cada 5 iters)

Único momento de **cautela concentrada**. Duração: 1 iter doc-only.

1. Rodar `./tool/test_all.ps1` — baseline
2. Criar `META_REVIEW_ITER{N}.md` (7 seções — ver prompt abaixo)
3. Reabastecer backlog com **próximas 5–10 iters** tiradas da spec §45 (fase atual + próxima)
4. Atualizar `AGENTS.md` (status de fases) e `LOOP.md`
5. **Imediatamente** iniciar Iter N+1 — pit stop não é pausa humana

Erros e inconsistências encontrados no pit stop viram **P0/P1 do backlog**, não bloqueiam o loop — corrigidos na iter seguinte se críticos, senão agendados.

---

## Mapa de fases → critério de "MVP feito"

Loop termina quando todas marcadas ✅. Pit stop recalcula fase atual.

| Fase | Spec §45 | Status | Próximo slice típico |
|------|----------|--------|----------------------|
| 0 | Fundação | ✅ | — |
| 1 | Captura, tarefas, crônica | ✅ | — |
| 2 | Pawn e necessidades | ✅ | — |
| 3 | Trabalho e agenda | ✅ | — |
| 4 | Missões e projetos | ✅ | — |
| 5 | Pesquisa e skills | ✅ MVP | rubricas, trilhas (defer) |
| 6 | Finanças locais | ✅ MVP avançado+ | budget+CSV ✅; polish → 59/63 |
| 7 | Saúde local | ✅ MVP utilizável | exams/appointments defer |
| 8 | Inventário, relações, casa | ✅ MVP utilizável | Packing trip↔inv ✅; flashcards+SRS ✅ (DB v34 / export v30) |
| 9 | Sync e backup | ⏳ MVP stub | outbox+noop+snackbar ✅ Iter 114; remote defer |
| 10 | Integrações | ✅ MVP stub ICS | Iter 86; Health Connect/Open Finance defer |
| 11 | IA e Storyteller | ✅ MVP rules digest | Iter 87 NarrativeDigest rules_v1; LLM defer |
| 12 | Maturidade | ✅ MVP utilizável | a11y+beta+L10N (91–93); polish 94; pit 95 → depth 96+ |

---

## Templates de slice (ordem fixa, sem replanejar)

| Tipo | Quando | Ordem |
|------|--------|-------|
| **A** Feature nova | Entidade + UI | domain → DB → application → UI → tests |
| **B** Export bump | Persistência nova | schema → migration test → export/restore → tests |
| **C** Refactor | Migrate providers | 1 feature/iter, zero behavior change |
| **D** Polish | UX incremental | UI + widget test, sem migration |

ADR: escrever **inline na mesma iter** se decisão pequena; iter dedicada só se nova fase (7+).

---

## Fix inline (substitui "red lines")

**Única interrupção:** `test_all` falhou.

1. Corrigir no mesmo agente (não spawnar revisor)
2. Re-run `test_all`
3. Max **3 tentativas** — se falhar 3×, registrar bloqueio em `LOOP.md` e **pular** para próximo slice independente; retomar bloqueio no pit stop

Não interromper por: diff grande, screen longa, cross-import, export bump — isso é normal; pit stop avalia depois.

---

## Backlog atual (pós Iter 21)

| Iter | Slice | Fase |
|------|-------|------|
| 22 | Migrar quest providers → `features/quests/application/` | infra |
| 23 | Migrar pawn/work providers | infra |
| 24 | Quest↔research links | 4+5 |
| 25 | **PIT STOP** meta-review | — |
| 26 | Finance: filtros + período na lista | 6 |
| 27 | Finance: edit conta + saldo | 6 |
| 28 | Health ADR + domain entities | 7 |
| 29 | Health check-in MVP UI | 7 |
| 30 | **PIT STOP** | — |

Pit stop reescreve 26–40 com base no progresso real.

---

# PROMPT MESTRE — Motor autônomo contínuo

**Copie inteiro. Cole no início da sessão. Não edite a seção COMPORTAMENTO.**

```markdown
# Life Colony OS — Motor autônomo contínuo

Você é o **único coordenador** do desenvolvimento do app Flutter Life Colony OS.
Modo: **avanço máximo, autônomo, sem paradas**.

## COMPORTAMENTO (inviolável)

1. **NUNCA pare após concluir uma iteração.** Imediatamente inicie a próxima.
2. **NUNCA peça confirmação** ao usuário entre iters ("devo continuar?", "próximo passo?").
3. **NUNCA invoque** agente revisor ou planejador separados — implementa e segue.
4. **NUNCA commite** salvo pedido explícito do usuário.
5. **NUNCA encerre** a sessão com resumo final esperando resposta — encadeie a próxima iter.
6. Pit stop **somente** quando Iter % 5 == 0: meta-review doc-only, reabastecer backlog, **continuar na mesma resposta** com Iter N+1.
7. `test_all` verde = avança. Falhou = fix inline (max 3×), senão pula e registra.
8. Termine **somente** se fases 0–12 MVP completas (spec §45) ou instrução explícita do usuário para parar.

## Fontes de verdade
- `docs/produto/LIFE_COLONY_OS_SPEC.md` §45 roadmap
- `AGENTS.md`, `docs/dev/LOOP.md`, `docs/dev/PIPELINE.md`
- Última `docs/dev/META_REVIEW_ITER*.md`
- `docs/adr/`

## Loop (repita indefinidamente)

```
LOOP:
  N = próxima iter em LOOP.md
  se N % 5 == 0:
    executar PIT STOP (meta-review doc, backlog 5-10 iters, AGENTS.md)
  senão:
    ler spec § + ADR relevante (5 min, não mais)
    implementar vertical slice (domain → DB → application → UI → tests)
    rodar ./tool/test_all.ps1
    se falhou: fix inline até 3×; se ainda falha: log + skip
    atualizar LOOP.md (1 seção CONCLUÍDA, tabela histórico)
  N = N + 1
  goto LOOP
```

## Regras de implementação
- Android-first, local-first, offline, sem conta
- Vertical slice completo por iter
- Providers novos em `features/<name>/application/`
- Strings em `app_strings.dart`; SQL só em `colony_database`
- MVP mínimo da spec — deferir polish/refactor para pit stop backlog P3+
- ADR inline se decisão pequena; não bloquear iter por documentação excessiva

## Estado inicial
- Última iter concluída: 30
- Próxima iter: **31**
- Próximo slice: Finance net-worth lite / sensitive polish (META_REVIEW_ITER25)
- Testes: 247 | Export v12 | DB v13
- Fase atual: **6** (Finance MVP avançado); Phase 7 ADR pronto

## Critério de MVP por fase (spec §45)
Implementar o **mínimo utilizável offline** de cada fase antes de avançar:
- Fase 6: entidades, contas, transações manuais, categorias, edit/delete ✅ parcial → falta filtros/período, edit conta
- Fase 7: sintomas/check-in local, sem diagnóstico
- Fase 8–12: primeiro slice vertical de cada (1 entidade + 1 tela + persistência)

## Saída por iter (máx 10 linhas)
Iter N concluída → testes X→Y → **iniciando Iter N+1: [slice]** → [implementar]

## AGORA
Executar Iter 22. Ao terminar, **sem pausa**, executar Iter 23. Continuar até pit stop (Iter 25) ou falha do sistema.
```

---

# PROMPT — Pit stop (Iter % 5 == 0)

```markdown
# Pit stop — Meta-review Iter N (cobre N-4 … N-1)

Doc-only. **Máx 1 iter.** Ao terminar, iniciar Iter N+1 imediatamente.

1. `./tool/test_all.ps1` → baseline na doc
2. Criar `docs/dev/META_REVIEW_ITER{N}.md`:
   - Layering, export matrix, test counts, MVP vs spec, UX hubs, checklist anterior
   - **Backlog P0–P4** + **plano Iters N+1 … N+10** (1 linha cada, tirado spec §45)
3. Atualizar `LOOP.md` + `AGENTS.md` fases
4. Listar inconsistências → P0 se bloqueante, P2 se cosmético
5. **Não implementar correções** salvo gate vermelho (test_all falhando no repo)
6. Continuar loop: Iter N+1
```

---

# PROMPT — Fix inline (gate vermelho)

```markdown
# Fix inline — Iter N

test_all falhou. Corrigir **no mesmo contexto**, sem expandir escopo.
1. Identificar erro (analyze / test / build_runner)
2. Corrigir mínimo necessário
3. Re-run test_all
4. Se verde: retomar loop
5. Se 3ª falha: registrar em LOOP.md § Bloqueios, pular slice, próxima iter
```

---

## Métricas (avaliadas só no pit stop)

| Métrica | OK | Ação no pit stop |
|---------|-----|------------------|
| test_all | verde | — |
| Testes totais | subindo | se flat 3 iters → alerta no doc |
| Analyze errors | 0 | P0 imediato |
| Fase spec | avançando | recalcular backlog |
| Bloqueios | 0 | retomar P0 |

---

## Referências

- Histórico: `LOOP.md`
- Protocolo legado (3 agentes): substituído por este doc
- ADRs: `docs/adr/`
