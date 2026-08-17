# Agente 1 — Usabilidade extrema dos flashcards

Pilar: **bater o olho, poucos toques, entender, agir.**  
Fonte de verdade: spec §5.2–5.7, §7, §8, ADR-012, ADR-036 §5.  
Companheiros: `AGENT_SPACED_LEARNING.md`, `AGENT_KNOWLEDGE_TAXONOMY.md`.  
Plano: [`docs/dev/KNOWLEDGE_FLASHCARDS_EVOLUTION.md`](../KNOWLEDGE_FLASHCARDS_EVOLUTION.md).

Este agente **não implementa** até o coordenador pedir. Elabora, prioriza e, quando autorizado, entrega slices de UI/UX.

---

## Missão

Tornar flashcards o gesto mais rápido do app no celular (sideload, ADR-035): capturar um cartão em segundos, estudar sem pensar na chrome, e entender o estado do conhecimento num relance — sem copiar Anki, Quizlet ou RimWorld.

## O que já existe (não reinventar)

| Superfície | Estado |
|------------|--------|
| Hub `/flashcards` | ListView: título, disclaimer, herói, busca, mapa em lista indentada, barras de previsão, lista de baralhos |
| Sessão `/flashcards/study` | Tap revela, 4 botões Again/Hard/Good/Easy com preview de intervalo, atalhos 1–4/espaço, bury/suspend/undo no menu |
| Editor | Bottom sheet com tipo, frente, verso, extra, tags, inverso, 3 intents de captura |
| Baralho | FAB “Novo cartão”, tiles de texto, menu de ações |
| Área | Painéis empilhados, chips “Também em…” **não clicáveis**, voltar sempre ao hub |
| Nav | Flashcards só no menu **Mais** — 2 toques só para chegar |
| DS | `ColonyPanel`, `ColonySurface`, tokens; **nenhum** widget de cartão/virada no design system |
| A11y | Baseline Iter 91 **não cobre** flashcards |

## Problemas a resolver

### 1. Caminho longo demais
Chegar → estudar hoje: `Mais → Flashcards → Estudar agora` (3 toques) e ainda rolar o disclaimer.  
Capturar: `Mais → Flashcards → baralho (ou criar) → FAB → preencher form → Programar/Guardar` (5–8 toques). Spec §5.6 pede captura < 10 s.

### 2. Sessão ainda é um formulário
- Sem metáfora de cartão (virada, face, sombra).
- Quatro botões iguais apertados no polegar; cores a 18% de alpha.
- Sem gesto (swipe), sem háptica, sem esconder chrome após o primeiro cartão.
- Prompt/resposta são `Text` centralizado — quebra mal em cloze longo, código, harmonia.
- Teclado 1–4 é inútil no alvo Android; o hint some no mobile, mas a sessão não ganha gesto no lugar.

### 3. Hub não é relance
- Disclaimer permanente compete com o herói.
- Mapa = `ListTile` infinito, sempre expandido, `iconKey` ignorado, calor = bolinha 8 px.
- Previsão 7 dias: barras sem rótulo de dia.
- Busca substitui o hub inteiro; resultado de cartão abre o **baralho**, não o cartão/prática.
- Empty state ok; estado “tem mapa mas zero due” ainda parece vazio de ação.

### 4. Captura parece cadastro
Editor é um formulário de 8 campos. Cloze exige `{{c1::…}}`. Tipo `exercise`/`repertoire`/`freeRecall` não mudam o layout. Área vem só do baralho — sem atalho visual.

## Direção de UX (obrigatória)

1. **Chrome mínimo na sessão.** Título de área/baralho num canto; progresso discreto; ações secundárias (adiar, suspender) atrás de um gesto longo ou menu, nunca de 4 botões extras.
2. **Cartão como objeto.** Superfície grande, tipo 28–36 sp no prompt, virada ou revelação com movimento curto (spec §7.6 — sem floreio). Frente ≠ verso na hierarquia visual (verso em accent, não o mesmo peso).
3. **Avaliar com o polegar.** Uma zona inferior estável: De novo | Difícil | Bom | Fácil, alvos ≥ 48 dp, intervalo visível **depois** de revelar, rótulo curto. Opcional: swipe esquerda = De novo, direita = Bom — nunca o único caminho (a11y).
4. **Captura em duas linhas.** Frente + verso (ou um campo cloze amigável). Resto em “Mais”: tipo, tags, inverso, área. Intents visíveis como chips: **Programar** / **Guardar** / **Praticar agora**.
5. **Relance no hub.** Herói primeiro (número grande + um CTA). Disclaimer retraído após a primeira visita. Mapa colapsável com ícone + calor de superfície, não só bullet. Previsão com D, S, T…
6. **Atalho de entrada.** CTA na Colônia (“N cartões · ~M min”) e/ou item no command palette “Estudar flashcards” / “Novo cartão”. FAB no hub = novo cartão, não só novo baralho.

## Entregáveis quando autorizado a implementar

Ordem sugerida (slices tipo D / polish, sem migration salvo captura inbox):

1. **Sessão glanceable** — widget de cartão no DS (`colony_design_system` only), revelar, 4 ratings, háptica leve, Semantics.
2. **Hub relance** — herói + CTA; disclaimer dismissível; previsão legendada; FAB captura.
3. **Editor curto** — 2 campos + 3 intents; avançado colapsado; cloze com seleção → lacuna (sem obrigar a digitação da sintaxe).
4. **Entrada no sistema** — Colônia / palette / deep link ` /flashcards/study`.
5. **A11y** — TalkBack: revelar, avaliar, progresso; não depender só de cor do calor.

## Critérios de aceitação

- Estudar o due de hoje: **≤ 2 toques** a partir da Colônia ou do hub já aberto.
- Capturar um cartão básico (frente/verso + programar): **≤ 3 toques** depois de estar no hub, teclado incluso no tempo mental (< 10 s spec).
- Com o hub na frente, em 1 segundo o usuário diz: quantos agora, se há guardados, e qual área está frágil.
- Sessão usável com uma mão no Android compacto; alvos 48 dp; undo acessível.
- Zero cópia de layout Anki/Quizlet/RimWorld; só tokens Colony.
- Strings em `lib/app/localization/`. Widget tests de hub, sessão e captura curta.
- `flutter analyze` 0 erros; testes da feature verdes.

## Fora de escopo deste agente

- Mudar SM-2, limites, digest (Agente 2).
- DAG, colocações, catálogo, pontes pesquisa (Agente 3) — **exceto** o picker visual que o Agente 3 especificar.
- Imagens/áudio no cartão, import `.apkg`, LLM.
- Widgets não acessam banco.

## Perguntas que este agente deve responder no plano (antes de codar)

1. Virada 3D vs. revelação tipográfica? (ADR-036 pede superfície tipográfica; preferir revelação, não flip de cassino.)
2. FAB do hub cria cartão em qual baralho se não houver um? Inbox vs. “caixa rápida” do próprio feature.
3. O herói cabe na Colônia sem virar segundo hub?
4. Quais peças vão para o DS (`ColonyStudyCard`, `ColonyHeatDot`) vs. ficam em `features/flashcards`?
