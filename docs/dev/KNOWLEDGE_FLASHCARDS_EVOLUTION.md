# Plano de evolução — Flashcards, SRS e mapa de conhecimento

**Status:** planejamento. Nenhuma destas fatias foi implementada neste documento.  
**Agentes:** [UX](agents/AGENT_FLASHCARD_UX.md) · [Espaçado](agents/AGENT_SPACED_LEARNING.md) · [Taxonomia](agents/AGENT_KNOWLEDGE_TAXONOMY.md)  
**Âncoras:** spec §5.6, §22, §72; ADR-017, ADR-036, ADR-037.

---

## 1. O que já está no ar

O vertical slice de flashcards (Iters recentes, DB **v35**, export **v31**) já entrega um **núcleo de domínio maduro** e uma **UI utilizável, ainda não relanceável**.

### 1.1 Domínio e persistência (forte)

- Áreas com pai primário + colocações secundárias (DAG acíclico).
- Catálogo opt-in com os casos âncora: Tropicalismo em Música **e** História do Brasil; ODD sob Carros autônomos.
- Baralho e cartão com `areaId` canônico e `researchNodeId` no baralho.
- Tipos de cartão: básico, inverso (par com SRS separado), cloze `{{cN}}`, recordação livre, exercício, repertório.
- `scheduleMode`: na fila SM-2 vs. guardado.
- SM-2 local com learning steps, preview de intervalo, leech, bury, undo.
- Sessão de prática que **não** muta SRS (`reviewKind = practice`).
- Digest do dia: fila limitada pelos tetos do baralho, “mais tarde hoje”, adiados, feitos, guardados, ~minutos.
- Intercalação por área no estudo global.
- Pontes N:N pesquisa ↔ área (`primary` / `related` / `practice`).
- Calor de retenção agregado na subárvore (primário ∪ atalhos).

### 1.2 UI (MVP, cromada demais)

| Rota | O que a pessoa encontra |
|------|-------------------------|
| `/flashcards` | Herói “Hoje”, busca, mapa-lista, previsão muda, baralhos. Disclaimer sempre visível. Destino só em **Mais**. |
| `/flashcards/study` | Tap revela, 4 notas, menu adiar/suspender. Sem gesto, sem cartão-objeto, sem timebox. |
| `/flashcards/decks/:id` | Lista textual + FAB editor-formulário. |
| `/flashcards/areas/:id` | Filhos, atalhos, baralhos, pesquisa. “Também em…” não navega. |
| `/research/:id` | Painéis de prateleiras e de baralhos. Sem CTA “estudar due deste foco”. |

Não há flashcards na Colônia, na revisão diária, no inbox nem no digest narrativo.

### 1.3 O que está deliberadamente fora (manter)

FSRS remoto, imagens/áudio, import Anki, LLM gerando cartões ou colocações, fundir `ResearchNode` na taxonomia, vários `areaId` por cartão, notificação push, marcar domínio de pesquisa só com SRS.

---

## 2. Diagnóstico por pilar

### Pilar A — Usabilidade (Agente 1)

O modelo mental certo está no ADR (“chrome mínimo, tipo grande”). A implementação ainda é **lista + formulário + quatro botões Material**.

Gargalos de toque:

1. Abrir o feature: menu Mais.
2. Capturar: baralho existente (ou criar um) → FAB → sheet longo → intent.
3. Classificar: dropdowns de pai/colocação, não busca.
4. Relance: calor = bolinha; mapa sempre expandido; previsão sem dias; busca joga o hub fora.

Meta: **2 toques para estudar o dia; 3 para capturar um básico; 1 segundo para ler o herói.**

### Pilar B — Espaçado vs. pontual (Agente 2)

O algoritmo e o digest estão corretos; a **decisão humana** não.

- “12 agora” é `cappedForSession`, mas os chips ao lado ainda cheiram a pool cru.
- “Praticar baralho/área” no código pega só **guardados** (exceto um `cardId`) — o botão mente.
- Learning de 1/10 min vira “mais tarde hoje” sem reentrada.
- Nada no resto do SO pessoal lembra que existe fila.
- Tile não mostra a próxima data.

Meta: **uma frase de hoje, dois modos estáveis (estudar / praticar), captura com três chips iguais em todo lugar.**

### Pilar C — Áreas do saber (Agente 3)

O DAG cobre Tropicalismo e ODD nos testes. A experiência de **categorizar e percorrer** não.

- Colocação secundária é um segundo formulário; não se remove na UI.
- Cartão não especializa a folha (herda o baralho).
- Estudo por área ignora cartões que só têm área no **deck**.
- Mapa não comunica profundidade nem pontes.
- Pesquisa e prateleira ligam-se à mão, sem estudar a partir do foco.

Meta: **mesmo nó, dois caminhos, folha tão específica quanto ODD, captura com typeahead, pesquisa e cartões no mesmo gesto de prateleira.**

---

## 3. Princípios para a evolução

1. **Não redesenhar o domínio** salvo a regra de visibilidade cartão↔área (deck como fallback).
2. **Um algoritmo de “hoje”** — Colônia, herói, revisão diária consomem `FlashcardTodayDigest`.
3. **Prática ≠ revisão ≠ evidência de pesquisa.**
4. **Taxonomia ≠ research tree.** Pontes explícitas, nunca fusão.
5. **Celular primeiro** (sideload). Atalhos de teclado são extra.
6. **DS só em `colony_design_system`.** Lógica em domain/database/application.
7. **Poucos toques nas ações comuns; fricção só em suspender em massa / apagar.**
8. **Slices verticais pequenos** (tipo D polish; migration só se a regra de visibilidade exigir — preferir zero schema bump).

---

## 4. Pontos de evolução (ainda não implementar)

Ordem = dependência e impacto no uso diário, não calendário. Cada fatia deve fechar analyze + testes da feature.

### Fatia 0 — Contratos entre agentes (doc only)

Alinhar as três respostas pendentes:

| Tema | Recomendação do plano |
|------|------------------------|
| Practice de baralho/área | Inclui **todos** os não suspensos; hub “Praticar guardados” fica o atalho do conjunto unscheduled |
| Cartão vs. área do baralho | Cartão pode especializar **descendente** da área do baralho; estudo/calor usam `card.areaId ?? deck.areaId` |
| Revelação na sessão | Tipográfica (ADR-036), não flip 3D de cassino |
| Trilha §22.7 | Pesquisa + prateleira; **sem** entidade nova |
| Schema | Sem bump se o fallback deck resolver visibilidade |

### Fatia 1 — Herói honesto e dois modos (Agente 2, apoio UX)

- Chips = números da **sessão** limitada.
- Copy único: Estudar (espaçado) / Praticar (sem fila).
- Corrigir `StudySessionScreen` para practice de baralho/área não filtrar só unscheduled.
- Teste: practice de cartão scheduled não muda SRS; estudo capped respeita limites.

**Por quê primeiro:** hoje o botão “Praticar área” pode abrir vazio. Isso quebra confiança antes de qualquer visual.

### Fatia 2 — Sessão glanceable (Agente 1)

- Peça de cartão no DS (prompt / verso / extra).
- Alvos 48 dp, hierarquia de tipo, chrome que recua.
- Semantics + háptica leve.
- Opcional: swipe como atalho de Bom/De novo, nunca exclusivo.

### Fatia 3 — Captura curta (Agentes 1 + 3)

- Sheet: frente, verso, três chips de intent; avançado fechado.
- Cloze: selecionar texto → lacuna, sem obrigar `{{c1::}}` na cabeça.
- Typeahead de área (folha sob o baralho).
- FAB no hub: novo cartão (baralho recente ou “Caixa rápida” do feature — **não** misturar com inbox de tarefas até fatia 7).

### Fatia 4 — Relance do mapa (Agentes 1 + 3)

- Ramos colapsáveis; `iconKey`; calor no row; filtro due / frágil.
- Previsão 7 dias com iniciais de dia.
- Disclaimer dismissível (preferência local).
- Busca: path da área + permanecer com herói visível ou resultados como overlay.

### Fatia 5 — Multi-caminho na pele (Agente 3)

- Chips “Também em…” roteáveis.
- Remover colocação.
- Back respeita `via`.
- Indicador de ponte no mapa sem duplicar o nó.
- Criar folha “aqui” (caminho ODD sem semear o catálogo inteiro).
- Seed: deixar óbvio que um ramo puxa ancestrais (`expandKeys` já faz).

### Fatia 6 — Visibilidade cartão ↔ prateleira (Agente 3, domínio)

- `areaId` efetivo = cartão ou deck.
- Recalcular heat, estudo por área, busca.
- Testes Tropicalismo / ODD + cartão só com área no deck.

### Fatia 7 — Hoje no sistema operacional pessoal (Agente 2, apoio UX)

- Painel na Colônia: `N agora · ~M min` → `/flashcards/study`.
- Command palette: Estudar flashcards / Novo cartão.
- Revisão diária: atalho + contagem `completedToday` (não auto-texto narrativo obrigatório).
- Chip “mais tarde hoje” reabre a fila de learning due (sem furar limite de novos; sem push).

### Fatia 8 — Pesquisa integrada (Agente 3 + 2)

- Do nó: estudar due das prateleiras `primary`/`practice` e/ou baralhos ligados.
- Da área: nós agrupados por kind.
- Criar cartão a partir do nó sem obrigar a pensar “baralho” (criar baralho implícito do nó se não houver).
- Disclaimer intacto: SRS não demonstra o nó.

### Fatia 9 — Timebox e tile humano (Agente 2)

- `?minutes=` ou chip 5 / 10 / 20; para entre cartões; resumo do que restou.
- Tile: “próxima em 3 d” / “guardado” / “sanguessuga”.
- Busca do hub: praticar este cartão (deep link `cardId` + mode).

### Fatia 10 — A11y e densidade (Agente 1)

- Identifiers Semantics na sessão e no herói (padrão Iter 91).
- Dynamic type: prompt não estoura o cartão (scroll interno).
- Área e mapa usáveis com TalkBack (ramo, atalho, calor em texto — chip já tem “Firme/Frágil”).

### Backlog consciente (depois deste plano)

- Inbox §5.6 “aprendizado” → cartão (classificar depois).
- Imagem/áudio no cartão.
- Import Anki.
- FSRS.
- Notificação local do passo de 10 min (só com preferência explícita).
- Biblioteca §72 (fontes, notas atômicas) ligada à prateleira.
- Rubricas / trilhas como entidade.

---

## 5. Como os três agentes trabalham juntos

```text
        ┌─────────────────┐
        │  Taxonomia (3)  │  prateleira, path, pontes, visibilidade
        └────────┬────────┘
                 │ areaId efetivo, typeahead, CTAs pesquisa
        ┌────────▼────────┐
        │  Espaçado (2)   │  digest único, estudar vs praticar, hoje
        └────────┬────────┘
                 │ números e modos estáveis
        ┌────────▼────────┐
        │     UX (1)      │  cartão, toques, relance, a11y
        └─────────────────┘
```

- **3 define o objeto** (onde o conhecimento mora).  
- **2 define o tempo** (quando pratica vs. quando espaça).  
- **1 define o gesto** (como isso cabe no polegar).

Conflitos típicos a arbitrar no Fatia 0:

- O herói da Colônia é do Agente 2 (conteúdo) com layout do 1.
- O picker de área na captura é do 3 com chrome do 1.
- “Estudar esta área” usa a fila do 2 e o conjunto de ids do 3.

---

## 6. Critérios de pronto do ciclo (quando alguém implementar)

Não é “parecido com Anki”. É:

1. Da Colônia, estudar o dia em dois toques.
2. Capturar “ODD = …” numa folha profunda, programar ou só guardar, em uma folha de captura curta.
3. Abrir Tropicalismo por Música e por História do Brasil e ver **os mesmos** cartões e o mesmo calor.
4. Praticar um cartão agora sem adiar a revisão espaçada.
5. Do nó de pesquisa em foco, puxar a prática da prateleira sem marcar domínio.

Definition of Done spec §50: empty/loading/error, strings, testes, aceite §46 onde couber pesquisa/aprendizado.

Gate: `./tool/test_all.sh`.

---

## 7. Referência rápida de arquivos atuais

```text
docs/adr/ADR-036-flashcards-srs.md
docs/adr/ADR-037-knowledge-area-dag.md
packages/colony_domain/lib/src/flashcard*.dart
packages/colony_domain/lib/src/knowledge_area*.dart
lib/features/flashcards/presentation/   hub, study, area, deck, widgets
lib/features/research/presentation/research_node_detail_screen.dart
test/flashcards_*.dart
packages/colony_domain/test/knowledge_area_dag_test.dart
```
