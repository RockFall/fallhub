# LIFE COLONY OS — Especificação de UX: Planejar Dia (Plan Day)

**Documento:** Companion spec de produto/UX/engenharia, complementar a [`docs/produto/LIFE_COLONY_OS_SPEC.md`](LIFE_COLONY_OS_SPEC.md)
**Feature:** `Planejar Dia` (nome interno curto: `Hoje`)
**Relaciona-se com:** spec §9 (Tela Colônia), §20 (Task/ColonyTask), §27 (Caixa de entrada), §46 (critérios de aceitação), §60.1–60.3 (convenções de tela, Tela Hoje, Tela Caixa de entrada), ADR-044 (home launcher)
**Não escreve por cima de:** `/pawn/review` (Daily Review), Motor de Ignição, Work Grid, Schedule

---

## 0. Decisões em uma tabela

| Pergunta em aberto | Decisão |
|---|---|
| Rota principal | `/today` |
| Título da tela | "Plano de hoje" |
| Label do mini-app / tile | "Hoje" |
| Relação com §60.2 "Tela Hoje" | Esta feature **é** o núcleo (lista do dia + captura) da futura Tela Hoje. As demais seções de §60.2 (check-in rápido, agenda, 3 próximas ações, alertas, recursos do dia, nota diária) ficam fora do escopo desta fatia e podem ser adicionadas como cards abaixo da lista na mesma rota, sem redesenho. |
| Composer compacto na Home? | **Sim.** Campo de 1 linha embutido no card de digest, sem typeahead (typeahead fica só na tela cheia). Justificativa no §4.3. |
| Toque na quick action bar da Home (4 slots fixos)? | **Não.** Mantemos os 4 slots atuais intactos; a entrada é via novo tile fixado na grelha + card de digest + paleta de comando. |
| Itens do plano têm hora do dia? | **Não.** Isso é o papel do Schedule. |
| Itens do plano têm subtarefas? | **Não.** |
| Concluir item vinculado altera o `ColonyTask` global? | **Sim, é a mesma ação.** Ver §2.9. |

---

## 1. Arquitetura de informação

### 1.1 Rotas

```text
/today                     → tela principal, mostra o dia selecionado (padrão: hoje)
/today?date=YYYY-MM-DD      → abre em outro dia (deep link, mesmo padrão do Schedule)
/today?create=1             → abre já com o composer focado e teclado aberto
```

Sem sub-rotas. Sem tela de detalhe própria: um item do plano não tem "inspect pane" dedicado — ad-hoc é renomeado inline; vinculado abre `/tasks/:id` (Task Inspect já existente).

### 1.2 Pontos de entrada

| Superfície | Elemento | Ação |
|---|---|---|
| Tela Colônia — grelha de mini-apps | Novo tile fixado **"Hoje"** (`ColonyMiniApps`, `pinned: true`, primeira posição) | `context.go('/today')` |
| Tela Colônia — feed de digest | Novo card **"Plano de hoje"**, primeiro card do feed (antes de `_NowCard`) | Ver §4.1 |
| Paleta de comando (`Ctrl/Cmd+K`) | "Ir para Plano de hoje" → `/today`; "Novo item no plano de hoje" → `/today?create=1` | Navegação direta |
| Task Inspect (`/tasks/:id`) | Chip "No plano de hoje" / botão "Adicionar a hoje" | Toggle sem navegar (§4.4) |
| Caixa de entrada (`/inbox`) | Ícone "+Hoje" por linha | Toggle sem navegar (§4.5) |
| Menu "Mais" | Entrada "Hoje" | Mesma rota |

Não entra na bottom nav de 5 destinos fixos (`Colônia · Perfil · Trabalho · Missões · Mais`) — esse conjunto é propriedade de outra decisão de produto e não é alterado por esta fatia.

### 1.3 Relação com telas vizinhas

- **Caixa de entrada / Task Inspect:** fonte dos itens "vinculados". Plan Day nunca duplica o `ColonyTask`; apenas referencia. Editar título/descrição/prazo continua em Task Inspect.
- **Daily Review (`/pawn/review`):** reflexão de fim de dia (o que aconteceu, estado atual, compromissos de amanhã). Plan Day é o oposto temporal (início do dia, execução). Daily Review pode **ler** o plano do dia para pré-popular "o que aconteceu" (ex.: "6 de 8 itens concluídos"), mas isso é opcional/futuro e não é responsabilidade desta fatia — não adicionar campo de edição do plano dentro da Daily Review.
- **Motor de Ignição / Morning Launch:** protocolo de ativação (como começar), não uma lista. Um item do plano pode ser o alvo de uma mobilização (reaproveita `activationControllerProvider.startForTask`), mas Plan Day não é substituído por ele.
- **Work Grid / Schedule:** grid de prioridade e blocos de tempo. Um item vinculado pode também estar agendado no Schedule — são camadas independentes; Plan Day não copia horário, só mostra pill "agendado" (leitura, sem edição) quando o task tem `scheduledStart` hoje (ver §3, wireframe).

### 1.4 Modelo de dados — forma de referência para quem implementar

Não é schema definitivo; fixa apenas as invariantes que a UX exige. Entidade nova, fora de `ColonyTask`:

```yaml
DailyPlanItem:
  id
  profile_id
  plan_date            # dia-calendário local, sem hora (mesma normalização de scheduleCalendarDay)
  kind: linked | ad_hoc
  task_id_optional      # obrigatório quando kind == linked; nulo quando ad_hoc
  title                 # ad_hoc: texto digitado; linked: snapshot só para leitura offline
  order_index
  completed_at_optional  # só tem sentido para ad_hoc; linked deriva de ColonyTask.status
  removed_at_optional    # remoção "só de hoje", nunca apaga o task global
  added_at
  carried_over_from_item_id_optional
  source_type            # manual | derived (carry-over)
```

Invariantes:

1. Um `task_id` só pode ter **um** `DailyPlanItem` ativo (sem `removed_at`) por `plan_date`. Puxar um task já presente é no-op idempotente (chip/sugestão desaparece).
2. Para `kind == linked`, o estado "concluído" exibido na UI é **sempre** derivado de `ColonyTask.status`, nunca armazenado duplicado. Ver regra completa em §2.9.
3. Remover do plano (`removed_at`) nunca chama `TaskTransitionPolicy` nem toca `ColonyTask`.
4. Nenhum campo de hora do dia, subtarefa ou recorrência nesta entidade (ver §7).

---

## 2. Wireframe da tela principal

### 2.1 Mobile — estado com itens (visão padrão, "hoje" já aberto)

```text
┌─────────────────────────────────────────┐
│ ←  Plano de hoje              ⋯ (menu)  │  AppBar
│    seg, 24 ago · 3/7 concluídas         │  subtítulo com progresso
├─────────────────────────────────────────┤
│  ‹   Ontem  |  ●Hoje●  |  Amanhã   ›    │  seletor de dia (chevrons + hoje sempre 1 tap)
├─────────────────────────────────────────┤
│ ┌───────────────────────────────────┐   │
│ │ + Adicionar ao plano de hoje...   │   │  composer sempre visível, 1 linha
│ └───────────────────────────────────┘   │
│  [Terminar relatório]  [Ligar dentista] │  chips de sugestão (puxar 1 tap)
│  [+ mais da caixa de entrada]           │
├─────────────────────────────────────────┤
│ ☐  Revisar PR do onboarding        ⋮   │  item vinculado (ícone de link sutil)
│ ☐  Terminar relatório trimestral   ⋮   │        · 14:00 (pill "agendado", só leitura)
│ ☐  Comprar presente aniversário    ⋮   │  item ad-hoc
│ ☑  Responder e-mail do contador    ⋮   │  concluído (riscado, opacidade reduzida)
├─────────────────────────────────────────┤
│ ▸ Concluídas hoje (3)                   │  seção recolhida (ColonyPanel collapsible)
└─────────────────────────────────────────┘
```

- **Abrir o plano de hoje sem cliques extra:** tile "Hoje" / card de digest / bottom-nav "Mais → Hoje" sempre levam direto para `plan_date = hoje`. Não há tela intermediária de escolha de data.
- Botão "⋮" no AppBar abre menu: "Ver ontem", "Ver amanhã", "Ocultar sugestões".

### 2.2 Mobile — linha de item (anatomia)

```text
[grip]  [checkbox]  Título do item                    [⋮]
          ⌗ ícone pequeno "vinculado" se kind==linked
          pill "agendado 14:00" se task.scheduledStart hoje
```

- `grip` (⠿) só aparece durante drag ou ao pressionar-e-manter; em repouso, invisível para não sujar a lista (mobile). Área de toque de 44×44 preservada mesmo invisível.
- `checkbox`: `Checkbox` real do Flutter (não ícone decorativo), toque = 1 tap.
- `⋮`: abre `ContextActionMenu` com: **Remover de hoje**, **Mover para cima**, **Mover para baixo**, e se `kind == linked`: **Abrir tarefa**; se `kind == ad_hoc`: **Mover para caixa de entrada** (promove a `ColonyTask.capture`, opcional, não é fluxo obrigatório).
- Swipe para a esquerda (mobile) = **Remover de hoje** direto (1 gesto), com `SnackBar` + **Desfazer** por 6s. Swipe para a direita = completar/desfazer, espelhando o checkbox (atalho, não obrigatório para funcionar).

### 2.3 Mobile — banner de itens não concluídos de ontem

Aparece **apenas** quando `plan_date == hoje` e existem itens de ontem sem `completed_at` e sem `removed_at`, e o usuário não descartou o banner para esse par de dias.

```text
┌─────────────────────────────────────────┐
│ ⚠ 3 itens de ontem não foram concluídos │
│                                          │
│  [Adicionar os 3 a hoje]   [Escolher]  ✕│
└─────────────────────────────────────────┘
```

- **"Adicionar os 3 a hoje"** — 1 tap, copia todos (cria novos `DailyPlanItem` com `plan_date = hoje`, `carried_over_from_item_id` apontando para o item de ontem). Os itens de ontem **não são alterados** — permanecem no histórico de ontem como estavam.
- **"Escolher"** — expande a lista inline com um "+" por item (1 tap por item escolhido); o banner encolhe conforme os itens são adicionados e desaparece quando zero restam.
- **✕** — descarta o banner só para hoje (reaparece no próximo dia se ainda houver pendências de ontem naquele momento; nunca adiciona nada sem esse toque explícito).
- Nunca é automático: sem o toque em "Adicionar" ou no "+", nada é copiado.

### 2.4 Wide (≥ 840px, dentro do corpo do `ColonyShell`, rail de navegação já visível à esquerda)

```text
┌───────────────────────────────┬───────────────────────────────┐
│ Plano de hoje · 3/7           │  Sugestões da caixa de entrada │
│ ‹ Ontem  ●Hoje●  Amanhã ›     │  ┌───────────────────────────┐ │
├───────────────────────────────┤  │ Terminar relatório     [+]│ │
│ [+ Adicionar ao plano...    ] │  │ Ligar dentista         [+]│ │
├───────────────────────────────┤  │ Revisar orçamento       [+]│ │
│ ⠿ ☐ Revisar PR onboarding  ⋮  │  └───────────────────────────┘ │
│ ⠿ ☐ Terminar relatório     ⋮  │  Ontem: 3 pendentes            │
│ ⠿ ☐ Comprar presente       ⋮  │  [Adicionar os 3 a hoje]       │
│ ⠿ ☑ Responder e-mail       ⋮  │                                 │
├───────────────────────────────┤                                 │
│ ▸ Concluídas hoje (3)          │                                 │
└───────────────────────────────┴───────────────────────────────┘
   coluna principal (largura ~640, centrada se a tela for maior)     rail de contexto persistente
```

No wide, o grip (⠿) fica sempre visível (mouse, sem custo de densidade) e as sugestões vivem numa coluna persistente à direita em vez de chips — mesma ação (1 clique adiciona), mais espaço para mostrar até 8 itens em vez de 5.

### 2.5 Interações detalhadas

| Ação | Como |
|---|---|
| **Adicionar novo item** | Focar composer (já visível) → digitar título → `Enter`/tocar em enviar → item ad-hoc aparece no topo da lista ativa, composer limpa e mantém o foco para o próximo item. |
| **Puxar tarefa global (chip)** | Tocar num chip de sugestão acima do composer → item vinculado aparece na lista, chip desaparece das sugestões. |
| **Puxar tarefa global (typeahead)** | Digitar no composer → se houver `ColonyTask` com título parecido (`inbox`/`next`/`scheduled`/`doing`, ainda não no plano de hoje), aparece dropdown com até 3 resultados acima do composer → tocar num resultado adiciona o vinculado e limpa o campo. Se o usuário apertar Enter **sem** tocar num resultado, cria-se sempre um item ad-hoc com o texto exato digitado — nunca um vínculo "adivinhado". |
| **Puxar tarefa global (lista completa)** | Ícone "🔍 Adicionar da lista" ao lado do composer → abre bottom sheet com busca + filtro por status → tocar num item adiciona (sheet continua aberto para adicionar vários) → fechar. |
| **Completar item** | Tocar no checkbox. Ad-hoc: marca `completed_at`. Vinculado: dispara a mesma transição de `TaskInspect` (`ColonyTask.withStatus(done, agora)`). Item some da seção ativa e entra em "Concluídas hoje" (recolhida). `SnackBar` "Concluído · Desfazer" por 6s. |
| **Descompletar** | Tocar no checkbox de um item já concluído (dentro da seção recolhida, expandida). Ad-hoc: limpa `completed_at`. Vinculado: se dentro da janela de undo, restaura o status exato anterior; fora da janela, volta para `next` (regra fixa e documentada, ver §2.9). |
| **Remover de hoje sem apagar o task global** | Swipe (mobile) ou menu "⋮ → Remover de hoje" (2 taps). `SnackBar` "Removido de hoje · Desfazer". `ColonyTask` não é tocado — continua com o status que tinha. |
| **Reordenar** | Arrastar pelo grip (drag-and-drop, ordem persistida em `order_index`) **ou** menu "⋮ → Mover para cima / Mover para baixo" (1 tap por posição, acessível sem gesto). |
| **Trocar de dia** | Tocar `‹`/`›` junto ao seletor (1 tap = ±1 dia). Quando `plan_date != hoje`, aparece pill **"Hoje"** clicável no lugar do rótulo "●Hoje●" ativo — 1 tap sempre volta. |
| **Ver plano de ontem/amanhã** | Mesmo seletor; composer continua disponível em qualquer dia (permite pré-planejar amanhã à noite); banner de carry-over só aparece na visão de hoje. |
| **Completar task vinculado vs ad-hoc** | Ver regra completa abaixo (§2.9). |

### 2.6 Sketch de árvore de widgets (mobile, resumido)

```text
Scaffold
  AppBar(title: "Plano de hoje", subtitle: progresso, actions: [OverflowMenuButton])
  Column
    DayPlanDaySwitcher(day, onPrev, onNext, onJumpToday)
    if (carryOverBanner != null) CarryOverBanner(...)
    DailyPlanComposer(controller, suggestions, onSubmitAdHoc, onPickSuggestion)
    if (suggestionChips.isNotEmpty) SuggestionChipRow(chips, onPick)
    Expanded(
      ReorderableListView(
        header: activeItems.map(DailyPlanItemTile),
        footer: ColonyPanel(collapsible: true, title: "Concluídas hoje ($n)",
          child: Column(children: doneItems.map(DailyPlanItemTile))),
      ),
    )
    if (activeItems.isEmpty && doneItems.isEmpty) EmptyPlanState()
```

---

## 3. Orçamento de cliques (happy path)

Contagem de toques **depois** da tela `/today` já estar aberta em "hoje". Digitação de texto não conta como "tap".

| Ação | Toques | Observação |
|---|---|---|
| Abrir o plano de hoje (a partir da Home) | 1 | Toque no tile/card — 0 se já estiver na tela |
| Adicionar item novo (ad-hoc) | 1 | `Enter`/botão enviar após digitar |
| Puxar tarefa existente via chip | 1 | Toque no chip |
| Puxar tarefa existente via typeahead | 1 | Toque no resultado do dropdown |
| Puxar tarefa existente via lista completa | 2 | Abrir sheet (1) + tocar no item (1) |
| Completar item | 1 | Toque no checkbox |
| Descompletar item | 1 | Toque no checkbox (dentro de "Concluídas") |
| Desfazer última ação | 1 | Toque em "Desfazer" no snackbar |
| Remover de hoje (swipe) | 1 gesto | Alternativa sem gesto: 2 toques (menu → remover) |
| Reordenar (drag) | 1 gesto | Alternativa sem gesto: 1 toque por posição movida |
| Ir para ontem / amanhã | 1 | Toque no chevron |
| Voltar para hoje | 1 | Toque na pill "Hoje" |
| Carry-over — adicionar todos | 1 | Botão do banner |
| Carry-over — adicionar um item específico | 1 | "+" na linha expandida |
| Marcar "na plano de hoje" a partir do Task Inspect | 1 | Toggle do chip |
| Adicionar a hoje a partir da Inbox | 1 | Ícone "+Hoje" na linha |

Nenhuma ação do caminho feliz passa de 2 toques.

---

## 4. Superfícies secundárias

### 4.1 Card de digest na Home (`ColonyHomeDigest`)

Novo card **"Plano de hoje"**, primeiro item do feed (antes de `_NowCard`), reutilizando `ColonyHomeCard`:

```text
ColonyHomeCard(icon: Icons.checklist_outlined, title: "Plano de hoje", action: "3/7")
  Row: TextField compacto "Adicionar rápido..." + IconButton(enviar)
  --- (se houver itens) ---
  ListTile: checkbox + próximo item não concluído + "toque para abrir o plano"
  --- (se vazio) ---
  Text("Nada planejado ainda hoje.")
  Align: FilledButton.tonal("Planejar o dia") → context.go('/today')
```

- O `TextField` compacto **adiciona diretamente** (ad-hoc) sem navegar: `Enter`/enviar → `SnackBar("Adicionado ao plano de hoje", action: "Abrir")`. Não tem typeahead nem chips — isso fica reservado para a tela cheia, mantendo o card pequeno e a decisão de "single source of truth" para a experiência de puxar tarefas globais.
- Tocar no corpo do card (fora do campo/checkbox) navega para `/today`.
- O checkbox da linha "próximo item" permite completar sem abrir a tela — mesma regra de §2.9 aplicada.

### 4.2 Tile do mini-app

- Id: `today`; label: **"Hoje"**; ícone: `Icons.checklist_outlined` (não confundir com `Icons.today`, que sugere calendário); cor: novo `ColonyMiniAppColors.today` (sugestão: `Color(0xFF3D9A6B)`, verde-oliva distinto de `pawn`/`work`).
- `pinned: true`, posicionado logo após `habitat` (primeira posição do grid fixo) — é a superfície de maior frequência de uso esperada do app.
- Badge numérico: quantidade de itens **ativos** (não concluídos, não removidos) do plano de hoje — mesmo padrão do badge de inbox (`inboxBadge`).

### 4.3 Composer compacto na Home — decisão

**Sim, existe**, conforme §4.1. Justificativa:

1. O norte é "mínimo de cliques"; forçar navegação para cada item digitado contradiz isso quando o usuário já está na Home (superfície mais visitada).
2. Mantendo o composer da Home **sem** sugestões/typeahead, evitamos duplicar a lógica de busca de tarefas globais em dois lugares — reduz superfície de bugs e mantém a tela cheia como único lugar para "puxar" itens existentes.
3. Não substitui a tela cheia: reordenar, remover, ver concluídas e puxar tarefas continuam exigindo abrir `/today`, o que é aceitável porque essas ações são menos frequentes que "adicionar rapidamente".

### 4.4 Task Inspect — chip "No plano de hoje"

Em `/tasks/:id`, no `InspectPane.actions` (ou como chip logo abaixo do título, ao lado do `DataProvenanceBadge`):

```text
[✓ No plano de hoje]   ← chip toggle, preenchido quando task está em today's plan
```

- Toque quando **fora** do plano → adiciona (`DailyPlanItem` `linked`, `plan_date = hoje`) → chip preenche, `SnackBar` "Adicionado ao plano de hoje".
- Toque quando **dentro** → remove **de hoje** (não altera status do task) → chip esvazia, `SnackBar` "Removido do plano de hoje · Desfazer".
- Se o task já estiver `done`/`cancelled`/`archived`, o chip mostra estado mas fica desabilitado para "adicionar" (não faz sentido planejar algo já terminado) — ainda pode ser removido se estiver presente.

### 4.5 Inbox — "adicionar a hoje" sem sair da tela

Em `InboxScreen`, cada linha ganha um `IconButton` leve à direita (antes do `chevron_right` ou substituindo-o em favor de um menu):

```text
ListTile(title: task.title, trailing: Row([
  IconButton(icon: Icons.today_outlined, tooltip: "Adicionar a hoje", onPressed: ...),
  Icon(Icons.chevron_right),
]))
```

- 1 toque → adiciona (idempotente: se já estiver no plano de hoje, o ícone aparece preenchido/"check" e o toque remove).
- `SnackBar` de confirmação com "Abrir plano de hoje" como ação, sem navegação forçada.

---

## 5. Estados

| Estado | Condição | Tratamento |
|---|---|---|
| **Vazio** | `plan_date` sem itens ativos nem concluídos | Composer continua visível no topo; abaixo, texto "O plano de hoje está vazio." +, se houver tarefas puxáveis, chips de sugestão; se não houver nada em toda a caixa de entrada/próximas, microcópia extra "Nada para puxar ainda — crie o primeiro item acima." |
| **Carregando** | Primeira leitura do dia ainda não resolvida | 3 linhas placeholder (`shimmer`/skeleton) no lugar da lista; composer já renderiza (não depende do carregamento da lista para existir) |
| **Erro** | Falha ao ler/escrever localmente | Painel com ícone de alerta + "Não foi possível carregar o plano de hoje." + botão "Tentar novamente"; composer fica desabilitado até recuperar |
| **Offline** | Sem rede (irrelevante para a lógica local-first, mas o app mostra indicador global) | Nenhum bloqueio — Plan Day funciona 100% offline. Mantém o pill "Local · offline" já existente no topo do app (§ app-wide), sem estado próprio adicional |
| **Tudo concluído** | Há ≥1 item e todos ativos estão concluídos/removidos | Linha calma acima do composer: "Tudo concluído por hoje." Sem confete, sem pontuação. Composer continua ativo para caso surja algo novo. Seção "Concluídas hoje (N)" mostra tudo, recolhida por padrão |
| **Pendências de ontem** | Ver §2.3 | Banner, nunca automático |
| **Nada para puxar** | Nenhum `ColonyTask` elegível (`inbox`/`next`/`scheduled`/`doing`, ainda não no plano) | Chips e typeahead simplesmente não renderizam; o ícone "Adicionar da lista" abre sheet com estado vazio próprio: "Nada na caixa de entrada ou em Próximas para trazer para hoje." + botão "Abrir caixa de entrada" |

---

## 6. Acessibilidade

- **Checkbox real:** usar `Checkbox`/`CheckboxListTile` do Flutter (não ícone decorativo tocável) para que leitores de tela anunciem papel "caixa de seleção" e estado marcado/desmarcado nativamente. Rótulo semântico por item: `"Tarefa: {título}, {concluída|pendente}"` (inclui "vinculada à caixa de entrada" quando `kind == linked`).
- **Composer:** `TextField` com `labelText`/`hintText` = "Adicionar ao plano de hoje" (nunca só `hintText` sem rótulo persistente — manter acessível mesmo com o campo preenchido). Botão de enviar com `tooltip`/`Semantics.label` = "Adicionar item".
- **Reordenar sem gesto:** toda linha expõe, via `ContextActionMenu`/menu de overflow, as ações **"Mover para cima"** e **"Mover para baixo"**, sempre presentes (não só como fallback escondido) — usuários de teclado/switch/leitor de tela nunca dependem de drag-and-drop. Adicionalmente, expor `SemanticsAction` customizada (`CustomSemanticsAction`) equivalente, para gestos de acessibilidade nativos (rotor do VoiceOver / TalkBack).
- **Chips de sugestão e itens do dropdown de typeahead:** `Semantics(button: true, label: "Adicionar '{título}' ao plano de hoje")`.
- **Swipe actions:** sempre com equivalente por menu (nunca a única forma de executar a ação) — já coberto por "Remover de hoje" existir também no menu "⋮".
- **Contraste e foco:** seguir tokens existentes (`ColonyColors.borderFocus` para foco de teclado no composer e nas linhas; nunca depender só de cor para indicar "concluído" — usar também riscado + ícone diferente, ver §2.9 para itens cancelados/arquivados).
- **Anúncio de mudanças de lista:** ao completar/remover/adicionar, usar `SemanticsService.announce` (ou equivalente) com a frase da confirmação do snackbar, para quem não vê a UI mas ouve o toast.

---

## 7. O que NÃO construir nesta fatia

- Subtarefas dentro de um item do plano.
- Hora do dia / horário em item do plano (isso é Schedule).
- Recorrência de item do plano (um item ad-hoc não "repete"; se o usuário quiser algo recorrente, isso é uma `Bill`/task recorrente no sistema global, não uma feature do Plan Day).
- Pontuação, streak ou qualquer indicador de "performance" do dia — a barra "3/7" é contagem neutra, não nota.
- Sugestões geradas por IA sobre o que colocar no plano.
- Notificações/lembretes deste slice (nenhum push "você não planejou o dia ainda").
- Tela de detalhe própria para item ad-hoc — editar é inline (tap-and-hold no texto ou duplo tap no título abre edição inline simples); não criar um "Ad-hoc Inspect".
- Multi-seleção em massa (marcar 5 itens de uma vez) — fora do MVP; reavaliar só se o uso real mostrar necessidade.
- Compartilhamento do plano do dia com outro perfil.

---

## 8. Critérios de aceitação (Given/When/Then)

### 8.1 Abrir o plano de hoje

- **Dado** que o usuário está na Home, **quando** toca no tile "Hoje" ou no card "Plano de hoje", **então** a tela `/today` abre já em `plan_date = hoje`, sem etapa intermediária.
- **Dado** que o usuário já está em `/today` vendo hoje, **quando** navega para a Home e volta, **então** a tela continua mostrando hoje (não reabre em outro dia).

### 8.2 Adicionar item novo

- **Dado** o composer visível e vazio, **quando** o usuário digita um título e pressiona Enter/toca em enviar, **então** um `DailyPlanItem` `ad_hoc` é criado com `plan_date = hoje`, aparece no topo da lista ativa, e o composer é limpo mantendo o foco.
- **Dado** um título vazio/só espaços, **quando** o usuário tenta enviar, **então** nada é criado (botão de enviar desabilitado ou submissão ignorada, sem erro visível).

### 8.3 Puxar tarefa existente (chip)

- **Dado** que existe um `ColonyTask` em `next` com título "Terminar relatório" e ele não está no plano de hoje, **quando** o chip correspondente aparece e o usuário toca nele, **então** um `DailyPlanItem` `linked` é criado apontando para esse task, o chip desaparece das sugestões, e o item aparece na lista ativa.
- **Dado** que o mesmo task já está no plano de hoje, **quando** a lista de sugestões é recalculada, **então** ele não aparece mais como chip nem no typeahead (idempotência).

### 8.4 Puxar tarefa existente (typeahead)

- **Dado** o composer com foco, **quando** o usuário digita um trecho que casa com o título de um task elegível, **então** até 3 resultados aparecem num dropdown acima do composer.
- **Dado** o dropdown visível, **quando** o usuário toca num resultado, **então** o item vinculado é adicionado e o composer é limpo (nenhum item ad-hoc é criado com esse texto).
- **Dado** o mesmo dropdown visível, **quando** o usuário ignora os resultados e pressiona Enter, **então** um item **ad-hoc** é criado com o texto exatamente digitado (nunca um vínculo implícito).

### 8.5 Completar item

- **Dado** um item ad-hoc ativo, **quando** o usuário toca no checkbox, **então** `completed_at` é definido, o item some da seção ativa e aparece em "Concluídas hoje", e um snackbar com "Desfazer" aparece por 6s.
- **Dado** um item vinculado ativo cujo task está em `next`/`doing`/etc., **quando** o usuário toca no checkbox, **então** `ColonyTask.status` transiciona para `done` (mesma regra usada em Task Inspect), o item reflete o novo estado, e o mesmo `ColonyTask` aparece como concluído em qualquer outra tela que o exiba (Inbox, Work Grid, Task Inspect).

### 8.6 Descompletar

- **Dado** um item recém-completado dentro da janela de 6s do snackbar, **quando** o usuário toca em "Desfazer", **então** o item volta ao estado exato anterior (para vinculado: status exato anterior à conclusão, não necessariamente `next`).
- **Dado** um item concluído fora da janela de undo, **quando** o usuário toca no checkbox dentro de "Concluídas hoje", **então**: ad-hoc → `completed_at` é limpo e o item volta para a lista ativa; vinculado → `ColonyTask.status` vai para `next` (regra fixa, documentada, sem tentativa de "adivinhar" o status anterior).

### 8.7 Remover de hoje sem apagar o task global

- **Dado** um item vinculado a um `ColonyTask` em `next`, **quando** o usuário faz swipe ou usa o menu "Remover de hoje", **então** o `DailyPlanItem` recebe `removed_at`, some da lista de hoje, e o `ColonyTask` permanece com status `next` inalterado (verificável em `/tasks/:id` ou na Inbox).

### 8.8 Reordenar

- **Dado** uma lista com 3+ itens ativos, **quando** o usuário arrasta um item para outra posição (ou usa "Mover para cima/baixo" no menu), **então** a nova ordem persiste (`order_index` atualizado) e sobrevive a reabrir o app.

### 8.9 Trocar de dia sem enterrar hoje

- **Dado** a tela mostrando hoje, **quando** o usuário toca em `‹` (anterior), **então** a tela mostra o plano de ontem e um controle "Hoje" fica disponível para 1 toque de retorno.
- **Dado** a tela mostrando ontem ou amanhã, **quando** o usuário toca no controle "Hoje", **então** a tela volta a mostrar hoje em 1 toque, sem passar por nenhuma outra tela.

### 8.10 Carry-over de pendências de ontem

- **Dado** que ontem ficaram 3 itens sem `completed_at`/`removed_at`, **quando** o usuário abre hoje pela primeira vez, **então** o banner de carry-over aparece automaticamente (é leitura, não escrita) mostrando a contagem.
- **Dado** o banner visível, **quando** o usuário toca em "Adicionar os 3 a hoje", **então** 3 novos `DailyPlanItem`s são criados para hoje (cada um com `carried_over_from_item_id` apontando para o item de ontem) e os itens de ontem **não são alterados**.
- **Dado** o banner visível, **quando** o usuário não toca em nada, **então** nenhum item é copiado automaticamente, em nenhum momento.

### 8.11 Completar task vinculado a partir de outra tela

- **Dado** um task no plano de hoje como item vinculado, **quando** o usuário o marca como `done` em Task Inspect (não em Plan Day), **então**, ao reabrir `/today`, o item aparece automaticamente em "Concluídas hoje" — sem exigir nenhuma ação dentro do Plan Day.

### 8.12 Task inspect — chip "no plano de hoje"

- **Dado** um task que não está no plano de hoje, **quando** o usuário toca no chip "No plano de hoje" em Task Inspect, **então** ele passa a aparecer em `/today` como item vinculado, sem navegar para lá.
- **Dado** o mesmo chip já ativo, **quando** o usuário toca de novo, **então** o item é removido de hoje (sem alterar o status do task).

### 8.13 Inbox — adicionar a hoje

- **Dado** a tela de Inbox, **quando** o usuário toca no ícone "+Hoje" de uma linha, **então** o task é adicionado ao plano de hoje e um snackbar com ação "Abrir plano de hoje" aparece, sem navegação forçada e sem alterar o status do task na Inbox.

### 8.14 Estados vazios/erro/offline

- **Dado** nenhum item hoje e nenhuma tarefa elegível para puxar, **quando** a tela carrega, **então** aparece a mensagem de vazio com composer ainda ativo (não é um bloqueio, é convite a digitar).
- **Dado** uma falha de leitura local, **quando** a tela tenta carregar, **então** aparece o estado de erro com "Tentar novamente", e o composer fica desabilitado até a leitura ser bem-sucedida.
- **Dado** o dispositivo sem rede, **quando** o usuário usa qualquer ação do Plan Day, **então** tudo funciona normalmente (local-first), sem nenhum spinner ou bloqueio relacionado a rede.

---

## 9. Copy (pt-BR) e nomes sugeridos em `AppStrings`

| Constante sugerida | Texto pt-BR |
|---|---|
| `todayTitle` | `Hoje` |
| `todayScreenTitle` | `Plano de hoje` |
| `todayComposerHint` | `Adicionar ao plano de hoje…` |
| `todayComposerLabel` | `Adicionar ao plano de hoje` |
| `todayComposerSubmit` | `Adicionar item` |
| `todayComposerHomeHint` | `Adicionar rápido…` |
| `todayProgress(int done, int total)` | `$done/$total concluídas` |
| `todayAllDone` | `Tudo concluído por hoje.` |
| `todayEmpty` | `O plano de hoje está vazio.` |
| `todayEmptyNoSuggestions` | `Nada para puxar ainda — crie o primeiro item acima.` |
| `todaySuggestionsTitle` | `Sugestões da caixa de entrada` |
| `todayNoSuggestions` | `Nada na caixa de entrada ou em Próximas para trazer para hoje.` |
| `todayAddFromList` | `Adicionar da lista` |
| `todayOpenInbox` | `Abrir caixa de entrada` |
| `todayCompletedSection(int n)` | `Concluídas hoje ($n)` |
| `todayItemAddedSnack` | `Adicionado ao plano de hoje` |
| `todayItemCompletedSnack` | `Concluído` |
| `todayItemRemovedSnack` | `Removido de hoje` |
| `todayOpenPlan` | `Abrir plano de hoje` |
| `todayRemoveFromPlan` | `Remover de hoje` |
| `todayMoveUp` | `Mover para cima` |
| `todayMoveDown` | `Mover para baixo` |
| `todayOpenTask` | `Abrir tarefa` |
| `todayPromoteToInbox` | `Mover para caixa de entrada` |
| `todayOnPlanChip` | `No plano de hoje` |
| `todayAddToPlan` | `Adicionar a hoje` |
| `todayAddToPlanTooltip` | `Adicionar a hoje` |
| `todayLinkedBadge` | `Vinculada` |
| `todayScheduledPill(String time)` | `agendado $time` |
| `todayCancelledLabel` | `cancelada` |
| `todayArchivedLabel` | `arquivada` |
| `todayYesterday` | `Ontem` |
| `todayToday` | `Hoje` |
| `todayTomorrow` | `Amanhã` |
| `todayBackToToday` | `Voltar para hoje` |
| `todayCarryOverBanner(int n)` | `$n ${n == 1 ? 'item' : 'itens'} de ontem não ${n == 1 ? 'foi concluído' : 'foram concluídos'}` |
| `todayCarryOverAddAll(int n)` | `Adicionar ${n == 1 ? 'o item' : 'os $n'} a hoje` |
| `todayCarryOverChoose` | `Escolher` |
| `todayCarryOverDismiss` | `Ignorar por hoje` |
| `todayErrorLoad` | `Não foi possível carregar o plano de hoje.` |
| `todayRetry` | `Tentar novamente` (reaproveitar `AppStrings` genérico se já existir equivalente) |
| `todayHideSuggestions` | `Ocultar sugestões` |
| `todayShowSuggestions` | `Mostrar sugestões` |
| `todayHomeCardTitle` | `Plano de hoje` |
| `todayHomeCardCtaPlan` | `Planejar o dia` |
| `todayHomeCardEmpty` | `Nada planejado ainda hoje.` |
| `todayCommandGoTo` | `Ir para Plano de hoje` |
| `todayCommandNewItem` | `Novo item no plano de hoje` |
| `todayAdHocSemanticsLabel(String title, bool done)` | `Tarefa: $title, ${done ? 'concluída' : 'pendente'}` |
| `todayLinkedSemanticsLabel(String title, bool done)` | `Tarefa vinculada à caixa de entrada: $title, ${done ? 'concluída' : 'pendente'}` |
| `todaySuggestionSemanticsLabel(String title)` | `Adicionar '$title' ao plano de hoje` |

Reaproveitar constantes existentes onde já cobrem o caso: `AppStrings.save`, `AppStrings.cancel`, `AppStrings.undo`, `AppStrings.loading`, `AppStrings.errorGeneric`, `AppStrings.archive`, `AppStrings.status`, `AppStrings.offlineReady`.

---

## 10. Notas para quem for implementar (fora do escopo desta spec de UX, mas relevantes)

- Nova entidade `DailyPlanItem` fica em `colony_domain` (imutável, sem Flutter/Drift) + DAO/repositório em `colony_database`, seguindo a mesma separação de camadas de `ColonyTask`.
- `application/today_providers.dart` e `today_controllers.dart` na feature `lib/features/today/` (nome de pasta sugerido, para não colidir com o significado mais amplo de "home"/"colony").
- Reaproveitar `TaskTransitionPolicy` existente para a transição de itens vinculados — não recriar lógica de status em paralelo.
- Migração de schema (`colony_database`) e bump de versão de export, seguindo o padrão já usado nas fases anteriores (ex.: "DB v35 / export v31" citados no roadmap).
- Este documento não substitui a necessidade de um ADR se a implementação divergir de alguma decisão aqui (ex.: trocar `ColonyMiniAppColors.today`, mudar a regra de "volta para `next`" na descompletação tardia).
