# Habitat Refinement Pack — Microcomportamentos, polish e sofisticação sistêmica

**Documentos pais:**
- `05-LIFE_COLONY_OS_LIVING_PAWN_SPEC.md`
- `07-LIFE_COLONY_OS_LIVING_PAWN_VISUAL_FIRST_BUILD.md`
- `08-LIFE_COLONY_OS_MIRROR_READY_HABITAT_BUILD.md`
- `LIFE_COLONY_OS_SPEC.md`

**Status:** guia de execução pós-fundações  
**Versão:** 1.0  
**Data:** 2026-08-08  
**Pré-requisito:** considerar concluídos o bloco pré-§5 do `07` (até a atual §4.14 na cópia de trabalho) e o gate `M50` do `08`.  
**Escopo:** dezenas de incrementos pequenos e independentes que sofisticam comportamento, apresentação, interação e robustez do Habitat **sem criar integrações com outros módulos do Fallhub**.

---

## 0. Por que este guia existe

Depois do `07` e do `08`, o Habitat já deve possuir as grandes peças:

```text
mundo
+ affordances
+ autonomia
+ memória
+ relações
+ atividades coletivas
+ needs/capacities/conditions
+ sono
+ interesses
+ presença/visitas
+ sites/rooms
+ rotinas
+ objetos stateful
+ editor robusto
+ story/rituals
+ persistência
```

O risco seguinte é o simulador estar **correto, porém ainda legível demais como algoritmo**.

Um pawn pode saber que quer conversar, encontrar outro pawn e iniciar uma conversa. Ainda assim a cena parece artificial se:

- os dois giram instantaneamente um para o outro;
- ficam na mesma distância rígida;
- falam em intervalos idênticos;
- encerram a conversa e se separam no mesmo frame;
- atravessam a porta ao mesmo tempo;
- escolhem sempre o assento geometricamente mais próximo;
- cada interação começa sem hesitação e termina sem aftermath;
- todos reagem a um evento na mesma velocidade;
- objetos voltam magicamente ao estado anterior;
- o mundo fica sincronizado demais.

Este documento existe para atacar essa camada.

> **A partir daqui, qualidade vem menos de adicionar novos sistemas e mais de fazer os sistemas existentes produzirem detalhes convincentes.**

O objetivo é acumular pequenas imperfeições controladas, sinais corporais, timing, contexto espacial e continuidade até que o usuário pare de enxergar `if/score/action` e comece a enxergar comportamento.

---

# 1. Regra de ouro — microfeatures devem compor, não virar scripts

Cada milestone deste guia deve preferir:

```text
estado existente
+ contexto
+ pequena regra genérica
+ apresentação
```

em vez de:

```text
script específico de cena
```

Exemplo bom:

```text
Pawn A chega a uma porta.
Pawn B já está atravessando.

DoorReservation percebe conflito
→ A reduz velocidade
→ ocupa wait spot lateral
→ olha brevemente para B
→ B atravessa
→ reserva libera
→ A continua
```

Exemplo ruim:

```text
if A == Caio && B == Giovani && door == livingRoomDoor:
  playDoorCourtesyAnimation()
```

---

# 2. O que uma milestone deste arquivo deve parecer

As milestones `R0–R119` são deliberadamente menores que as milestones do `08`.

Idealmente uma milestone:

1. altera um comportamento claramente observável;
2. pode ser implementada e validada isoladamente;
3. reutiliza arquitetura já existente;
4. adiciona no máximo uma pequena abstração nova quando necessária;
5. inclui teste lógico quando houver regra de simulação;
6. inclui uma cena/preset de reprodução;
7. não exige integração real externa;
8. não adiciona barra/HUD só para provar que existe.

### Status

Usar:

```text
⬜ não iniciado
🟨 em andamento
✅ concluído
⛔ bloqueado
```

Ao concluir, trocar o próprio heading:

```text
## R14 — Etiqueta de portas ✅
```

---

# 3. Política de implementação

## 3.1 Renderer não decide a simulação

Continua valendo:

```text
Simulation decides
→ Events describe
→ Renderer presents
```

Uma animação de olhar pode ser visual-only.

Uma reserva de porta, posse de item, entrada numa conversa ou troca de assento é estado lógico.

## 3.2 Aleatoriedade estável

Microvariação deve usar RNG derivado/determinístico quando influencia comportamento.

Não criar dezenas de `Random()` locais.

## 3.3 Não antropomorfizar estados reais ainda

Mesmo com o Mirror-Ready implementado:

```text
cansaço = estado efetivo do Habitat
```

não significa automaticamente afirmar algo sobre o usuário real enquanto nenhum source real estiver conectado.

## 3.4 Uma pequena imperfeição é melhor que jitter

Queremos:

```text
reaction delay = 180–700 ms
```

Não queremos:

```text
pawn muda de ideia a cada 200 ms
```

## 3.5 Comportamento silencioso importa

Nem todo detalhe precisa gerar bubble.

Preferir comunicar por:

- posição;
- direção;
- velocidade;
- pausa;
- distância;
- escolha de objeto;
- estado ambiental;
- pequena animação.

---

# 4. Dashboard de milestones

| Bloco | Milestones | Tema | Status |
|---|---:|---|---|
| A | R0–R9 | corpo, atenção e timing | ✅ |
| B | R10–R19 | navegação social e uso do espaço | ✅ |
| C | R20–R31 | interação física e história dos objetos | ✅ |
| D | R32–R47 | conversa e etiqueta social | ✅ |
| E | R48–R58 | atividades coletivas sofisticadas | ✅ |
| F | R59–R69 | sono, rotina e transições do dia | ✅ |
| G | R70–R81 | ambiente, áudio e atmosfera | ✅ |
| H | R82–R87 | pets mais convincentes | ✅ |
| I | R88–R103 | editor e criação de ambientes | ✅ |
| J | R104–R111 | câmera, UI e legibilidade diegética | ✅ |
| K | R112–R119 | storyteller, tuning e robustez final | ✅ |

---

# 5. Bloco A — corpo, atenção e timing

## R0 — `AttentionTarget`: o pawn olha para alguma coisa ✅

**Resultado:** pawns deixam de parecer sprites com facing puramente locomotivo e passam a possuir foco visual momentâneo.

### Implementar

Criar um estado leve:

```text
AttentionTarget
- entityId?
- worldPosition?
- reason
- priority
- expiresAt
```

Razões iniciais:

```text
conversationPartner
interactionTarget
interestingEvent
passingPawn
soundSource
ambientObject
manualInspect
```

O renderer pode resolver isso em pequena inclinação/facing quando o asset permitir; quando não permitir, basta escolher a direção cardinal mais coerente.

### Regras

- atenção não deve interromper path;
- alvo de interação vence alvo ambiente;
- parceiro de conversa vence decoração;
- eventos raros podem roubar atenção por pouco tempo;
- usar cooldown para não fazer a cabeça “pingar” entre dois alvos.

### Aceite

- pawn sentado consegue olhar para outro pawn que fala;
- pawn caminhando pode olhar brevemente para um evento sem alterar destino;
- inspect debug mostra `attentionTarget` e motivo;
- nenhum oscillation rápido entre alvos.

---

## R1 — Facing settle e orientação ao parar ✅

**Resultado:** ao terminar um deslocamento, o pawn não permanece olhando para a direção arbitrária do último passo.

### Implementar

Ao chegar:

```text
arrival
→ determineDesiredFacing()
→ settle after 80–220 ms
```

Prioridade:

1. target da affordance;
2. parceiro/grupo;
3. direção funcional do assento;
4. centro de interesse do room;
5. último facing.

### Detalhes

- uma cadeira diante da TV deve orientar para a TV;
- pawn na mesa deve orientar para o centro/atividade;
- pawn observando janela deve olhar para a janela;
- ao idle sem alvo, não reorientar continuamente.

### Aceite

- 5 tipos de interação terminam com facing coerente;
- nenhuma rotação instantânea repetitiva após arrival;
- teste unitário para prioridade de facing.

---

## R2 — Reaction latency contextual ✅

**Resultado:** diferentes pawns não reagem a tudo no mesmo frame.

### Implementar

Adicionar `reactionDelay` derivado de:

```text
base range
+ current commitment
+ attention state
+ personality modifiers
+ event salience
+ deterministic jitter
```

Faixas iniciais aproximadas:

```text
manual order:     0–120 ms
conversation beat: 120–600 ms
ambient event:    250–1400 ms
group join probe: 400–1800 ms
```

### Regra

Delay não deve tornar o app irresponsivo a comandos do usuário.

### Aceite

- três pawns percebem chuva em momentos ligeiramente diferentes;
- resposta manual continua imediata;
- mesma seed reproduz delays lógicos.

---

## R3 — Biblioteca de micro-idles ✅

**Resultado:** ficar parado deixa de significar executar exatamente o mesmo bob.

### Criar

Micro-idles curtos e visualmente discretos:

```text
weightShift
lookLeftRight
briefStretch
scratchHead
checkObject
smallSighPose
footTap
adjustSeat
lookAtWindow
```

Usar apenas animações que os assets suportarem; fallback pode ser offset/facing/tempo.

### Regras

- micro-idle não é uma activity;
- não cria memória;
- não satisfaz need;
- não começa durante fala importante;
- frequência depende de contexto e personalidade;
- nunca mais de um por pawn simultaneamente.

### Aceite

- 5 minutos de idle exibem variedade sem parecer inquietação constante;
- pelo menos 5 variantes;
- `reducedMotion` pode desativar as mais movimentadas.

---

## R4 — Transições de postura ✅

**Resultado:** sentar, levantar, deitar e voltar ao movimento ganham estado transitório em vez de snap visual.

### Pipeline

```text
standing
→ preparingToSit
→ seated
→ preparingToStand
→ standing
```

E equivalente para cama.

### Regras

- reserva do assento permanece durante a transição;
- cancelamento manual deve levar a estado consistente;
- não bloquear simulação por duração visual longa;
- se assets não possuem frames dedicados, usar offset + squash + timing.

### Aceite

- sentar/levantar não teleporta pose;
- draft durante transição termina em estado válido;
- teste de cancelamento nos dois sentidos.

---

## R5 — Estilo locomotor por estado ✅

**Resultado:** velocidade e cadência refletem contexto sem virar caricatura.

### Modificadores possíveis

```text
fatigue
sleepiness
urgency
relaxed
carryingItem
socialApproach
```

Não alterar pathfinding; alterar apresentação e, dentro de limites, velocidade lógica.

### Limites

```text
normal range: 0.90x–1.08x
states fortes: até ~0.82x / 1.15x
```

Evitar pawn “doente” visual por cansaço comum.

### Aceite

- tired e urgent são distinguíveis lado a lado;
- diferença é sutil;
- duração de activities continua correta.

---

## R6 — Start/stop locomotion easing ✅

**Resultado:** pawn não passa de velocidade zero para máxima e vice-versa sem transição.

### Implementar

Pequeno envelope:

```text
accelerate 80–180 ms
cruise
slowdown 100–220 ms
```

Não aplicar quando comando exige resposta imediata de um único tile.

### Aceite

- deslocamentos de 4+ tiles parecem menos mecânicos;
- paths curtos continuam responsivos;
- nenhuma ultrapassagem de destino.

---

## R7 — Arrival choreography ✅

**Resultado:** chegar a um alvo possui uma pequena sequência consistente.

### Sequência

```text
slowdown
→ final cell
→ facing settle
→ 80–250 ms anticipation
→ interaction start
```

Variações por affordance:

- sentar: ajustar ao slot;
- conversar: ocupar posição social;
- pegar item: olhar para item;
- janela: virar para fora;
- porta: aguardar abertura.

### Aceite

- nenhum uso de prop começa enquanto pawn ainda parece caminhar;
- cancelamento durante anticipation libera reserva;
- 4 affordances usam o pipeline.

---

## R8 — Anticipation antes de interações ✅

**Resultado:** ações importantes ganham “preparação” perceptível sem criar barras de loading.

### Exemplos

```text
piano:     olha → aproxima corpo → começa
boardgame: senta → pequena pausa → primeiro beat
book:      pega → pausa → abre
bed:       aproxima → muda postura → deita
```

### Regras

- 100–500 ms na maioria dos casos;
- não repetir em loops internos da mesma activity;
- affordance define `anticipationProfile` data-driven.

### Aceite

- pelo menos 6 affordances possuem anticipation;
- perfil pode ser alterado sem mudar director.

---

## R9 — Desincronização global de comportamento ✅

**Resultado:** múltiplos pawns deixam de parecer executados por um metrônomo global.

### Implementar

Adicionar offsets determinísticos por pawn para:

```text
idle probe
micro-idle cadence
ambient reaction probe
social probe
need reevaluation
```

### Não fazer

Não atrasar eventos que precisam ser semanticamente simultâneos, como início confirmado de activity coletiva.

### Aceite

- 4 pawns idle não fazem probe no mesmo instante;
- profiler mostra distribuição de trabalho mais suave;
- seed mantém reprodução.

---

# 6. Bloco B — navegação social e uso do espaço

## R10 — Ranking inteligente de approach slots ✅

**Resultado:** quando um objeto possui várias posições de uso, o pawn escolhe a melhor, não apenas a primeira livre.

### Score

```text
slotScore =
  distance
+ facingQuality
+ crowding
+ routeCost
+ personalSpace
+ preference
+ activityGroupFit
```

### Aceite

- TV favorece assento com linha visual melhor;
- conversa evita slot comprimido quando existe alternativa;
- teste com 4 slots concorrentes.

---

## R11 — Orientação semântica de assentos ✅

**Resultado:** cadeiras sabem “para que lado faz sentido sentar”.

### Implementar

`SeatOrientationPolicy`:

```text
fixed
faceTargetTag
faceTableCenter
faceRoomCenter
faceConversationCluster
auto
```

### Aceite

- cadeira de mesa, sofá de TV e poltrona de leitura se comportam diferentemente;
- editor mostra preview da orientação funcional.

---

## R12 — Personal space ✅

**Resultado:** pawns evitam ficar colados uns aos outros sem motivo.

### Modelo

Criar custo espacial leve em células próximas a pawns parados.

Não bloquear path; apenas tornar posições alternativas mais atraentes.

Modificar por:

```text
relationship comfort
activity type
social style
crowding tolerance
```

### Aceite

- desconhecidos escolhem distância ligeiramente maior;
- group activity ainda consegue compactar pessoas quando necessário;
- nenhum círculo visível em produção.

---

## R13 — Soft local avoidance ✅

**Resultado:** dois pawns caminhando em direções opostas reduzem clipping e sobreposição.

### Implementar

Sem substituir A* global:

```text
next 1–2 cells conflict
→ small yield / side preference / short replan
```

### Aceite

- corredor de 2 tiles suporta passagem convincente;
- não cria oscillation esquerda/direita;
- timeout garante progresso.

---

## R14 — Reserva e etiqueta de portas ✅

**Resultado:** portas se tornam gargalos coordenados.

### Criar

```text
DoorTransitReservation
- doorId
- pawnId
- direction
- expiresAt
```

Segundo pawn:

```text
approach
→ percebe reserva
→ ocupa wait spot
→ atravessa depois
```

### Aceite

- dois pawns não se sobrepõem na mesma porta;
- reserva expira em cancelamento;
- porta fechada abre/fecha pelo pipeline de stateful props.

---

## R15 — Passing etiquette / side-step ✅

**Resultado:** encontros em corredores estreitos geram pequenas concessões espaciais.

### Implementar

Quando conflito local persistir:

- pawn de menor prioridade cede;
- escolhe célula lateral segura;
- pausa curta;
- retorna ao path.

Prioridade não deve representar status social; usar fatores técnicos como carga, urgency e distância até destino.

### Aceite

- cenário de corredor não entra em deadlock;
- comportamento é reproduzível em teste.

---

## R16 — Fila e `WaitSpot` ✅

**Resultado:** recursos de capacidade 1 podem formar espera organizada.

### Exemplos

```text
coffee machine
bathroom sink
single arcade
entry checkpoint
```

Affordance pode declarar:

```text
queuePolicy
waitSpots[]
maxQueueLength
```

### Aceite

- 3 pawns conseguem esperar por uma estação;
- pawn pode desistir se utility cair;
- sair da fila libera posição.

---

## R17 — Preferência de rota ✅

**Resultado:** nem sempre o caminho de menor custo geométrico precisa ser a única rota plausível.

### Perfis

```text
shortest
quiet
scenic
social
avoidCrowd
```

Aplicar somente quando alternativas possuem custo próximo.

### Aceite

- pawn com preferência outdoor pode usar varanda/corredor agradável quando diferença é pequena;
- nunca escolher desvio absurdo;
- debug mostra modificador de rota.

---

## R18 — Room-entry scan ✅

**Resultado:** entrar num cômodo produz breve percepção do que está acontecendo ali.

### Comportamento

```text
cross portal
→ 100–500 ms context scan
→ attention target para activity/event mais saliente
→ decisão continua
```

Não pausar quando pawn está urgente ou apenas atravessando o room.

### Aceite

- pawn entrando numa sala com jam olha brevemente para ela;
- pawn em trânsito não fica parando em todas as portas.

---

## R19 — Crowding awareness e relocação ✅

**Resultado:** pawn idle pode abandonar uma área excessivamente cheia e buscar outra posição coerente.

### Implementar

`LocalCrowdingScore` por região.

Afeta:

- idle positioning;
- solitude;
- leitura;
- social capacity baixa;
- escolha de assento.

### Aceite

- pawn com baixa tolerância não permanece no centro de grupo grande sem motivo;
- não interfere em activity committed.

---

# 7. Bloco C — interação física e história dos objetos

## R20 — Pipeline genérico `reach → use → release` ✅

**Resultado:** interação com objeto deixa de ser simplesmente “cheguei, timer, terminei”.

### Fases

```text
approach
anticipate
reach
engage
useLoop
release
settle
```

Cada affordance pode pular fases.

### Aceite

- livro, copo, piano e interruptor usam combinações distintas;
- cancelamento é seguro em cada fase.

---

## R21 — Anchors consistentes para itens carregados ✅

**Resultado:** objetos na mão não pulam de posição dependendo da animação.

### Criar

`HeldItemAnchorProfile` por body/facing:

```text
handPrimary
handSecondary
frontCarry
sideCarry
```

Fallback único caso asset não permita precisão.

### Aceite

- item permanece visualmente estável em 4 direções;
- troca de facing não deixa item atrás do corpo incorretamente.

---

## R22 — Placement ranking em superfícies ✅

**Resultado:** ao largar item numa mesa, o sistema escolhe slot visualmente plausível.

### Score

```text
free
reachable
notOccludingImportantProp
nearCurrentUser
sameActivityCluster
notOvercrowded
```

### Aceite

- múltiplas canecas/livros distribuem-se na superfície;
- item nunca ocupa slot já reservado.

---

## R23 — Estados `open / closed / active / inUse` ✅

**Resultado:** objetos de uso cotidiano conservam estados simples.

Seed:

```text
door
cabinet
book
laptop
TV
recordPlayer
boardgameBox
```

### Regra

O state deve pertencer à entidade lógica, não ao sprite.

### Aceite

- livro fica aberto durante leitura;
- TV permanece ligada enquanto activity existe;
- cancelar activity resolve estado conforme policy.

---

## R24 — Vestígios de uso recente ✅

**Resultado:** objetos comunicam que acabaram de ser usados.

### Exemplos

```text
chair.recentlyOccupied
mug.isWarm
TV.recentlyOn
book.openPage
piano.recentlyPlayed
```

Vestígios possuem decay curto e são majoritariamente visuais/contextuais.

### Aceite

- pelo menos 4 objetos mostram trace;
- trace pode influenciar pequena affordance contextual sem criar memória permanente.

---

## R25 — `HomeSlot` e devolver objetos ao lugar ✅

**Resultado:** itens portáteis podem conhecer local preferencial.

```text
book → shelf slot
mug → cabinet / counter
remote → coffee table
```

Pawn organizado recebe maior utility para `returnItemHome`.

### Aceite

- item retirado pode permanecer fora por um tempo;
- eventualmente pode ser devolvido;
- não teleportar item.

---

## R26 — Procurar item que não está onde deveria ✅

**Resultado:** uma activity pode exigir item cujo estado físico mudou.

### Pipeline

```text
resolve required item
→ lastKnownLocation
→ inspect local storage/surface
→ pickup
→ continue activity
```

Não implementar busca humana complexa; usar estado conhecido da simulação.

### Aceite

- pawn consegue buscar livro deixado em outro room;
- activity cancela com motivo se item indisponível.

---

## R27 — Preferência por exemplar específico ✅

**Resultado:** quando vários objetos equivalentes existem, pawns podem desenvolver preferência por um.

Exemplo:

```text
3 mugs equivalentes
→ pawn A tende à azul
```

Basear em:

- usage history;
- favorite object;
- estética/interesse;
- disponibilidade.

### Aceite

- preferência é tendência, não lock;
- fallback escolhe outro exemplar se necessário.

---

## R28 — Clutter por microdeslocamento ✅

**Resultado:** algumas atividades deixam pequenos deslocamentos físicos.

Exemplos:

- cadeira fica 1 offset fora do alinhamento;
- livro fica na mesa;
- copo muda de slot;
- caixa permanece aberta.

Não mover paredes/props estruturais.

### Aceite

- aftermath visual existe após atividade social/refeição;
- estado persiste conforme snapshot local.

---

## R29 — Wear/condition cosmético ✅

**Resultado:** objetos podem mostrar uso sem criar manutenção punitiva.

### Modelo

```text
conditionVisual = pristine / used / worn
```

Pode evoluir lentamente por usage count.

Não criar quebra obrigatória nesta milestone.

### Aceite

- diferença é cosmética;
- reset/replace possível no editor;
- nenhum loop de obrigação.

---

## R30 — Feedback físico/sonoro por objeto ✅

**Resultado:** interação recebe sinais específicos do alvo.

Exemplos:

```text
switch → click
book → page mote
keyboard → subtle typing ticks
boardgame → piece mote
cup → small clink
```

Áudio respeita mute e spatial audio futuro do bloco G.

### Aceite

- 6 categorias com feedback diferente;
- fallback silencioso funciona.

---

## R31 — Transações de objeto interruption-safe ✅

**Resultado:** nenhum cancelamento duplica, perde ou teleporta item.

### Invariantes

```text
item has exactly one location
holder xor surface/container/world
transfer commits atomically
```

Testar interrupção em:

```text
pickup
give
place
returnHome
```

### Aceite

- suite de cancelamento em todas as fases;
- zero item orphan/duplicado.

---

# 8. Bloco D — conversa e etiqueta social

## R32 — Greeting grammar contextual ✅

**Resultado:** primeiro contato de um encontro produz greeting coerente.

### Contexto

```text
timeSinceLastSeen
familiarity
affinity
arrivalMode
currentActivity
socialStyle
```

Variações podem ser bubble, gesto ou apenas pausa/olhar.

### Regras

- moradores não precisam se cumprimentar a cada troca de room;
- visitante recém-chegado quase sempre gera greeting;
- encontro após poucos minutos não gera novo greeting.

### Aceite

- pelo menos 4 contextos distinguíveis;
- cooldown por par.

---

## R33 — Goodbye grammar ✅

**Resultado:** saída social importante não termina em desaparecimento seco.

### Gatilhos

```text
visitor leaving
shared activity ending + participant departing site
remote call ending
```

### Comportamento

- breve facing;
- bubble opcional;
- pequena pausa;
- depois departure.

### Aceite

- visitor lifecycle possui despedida;
- despedida não bloqueia saída caso pawn seja interrompido.

---

## R34 — Posicionamento conversacional ✅

**Resultado:** participantes escolhem posições adequadas à conversa.

### Regras

- distância alvo variável;
- evitar ficar um atrás do outro;
- preferir arco/semicírculo em grupos;
- respeitar furniture;
- sentados podem conversar sem levantar.

### Aceite

- par em pé forma composição legível;
- grupo de 3 não vira pilha de sprites.

---

## R35 — Turn-taking explícito ✅

**Resultado:** conversa possui turnos e silêncio entre eles.

### Estado

```text
currentSpeaker
nextSpeakerCandidate
turnStartedAt
minimumGap
```

### Score do próximo

```text
hasResponse
socialStyle.talkative
recentTurnPenalty
topicAffinity
relationship
```

### Aceite

- mesmo pawn não monopoliza continuamente;
- silêncio curto possível;
- conversa termina naturalmente se nenhum beat surgir.

---

## R36 — Backchannels silenciosos ✅

**Resultado:** listener demonstra presença sem emitir fala completa.

Exemplos:

```text
small nod
brief facing adjust
mote "…"
short acknowledgement
```

Não registrar como ConversationBeat principal.

### Aceite

- listener reage ocasionalmente;
- frequência configurável por social style;
- sem bubble spam.

---

## R37 — Topic drift ✅

**Resultado:** conversas podem mudar de assunto organicamente.

### Pipeline

```text
current topic decays
→ adjacent topic candidates
→ context cue / interest / memory
→ transition
```

Usar Topic Graph do `08`.

### Aceite

- conversa de duração suficiente pode atravessar 2–3 tópicos relacionados;
- não saltar aleatoriamente entre assuntos sem aresta/contexto.

---

## R38 — Callbacks de memória ✅

**Resultado:** conversa ocasionalmente referencia evento compartilhado anterior.

### Regras

- memória precisa envolver ambos ou objeto/contexto relevante;
- cooldown forte;
- salience mínima;
- texto continua template/grammar validada.

### Aceite

- rematch, música e visita anterior possuem callback demonstrável;
- nenhum evento inexistente é inventado.

---

## R39 — Overhearing contextual ✅

**Resultado:** pawn próximo pode perceber uma conversa sem automaticamente entrar nela.

### Modelo

```text
ConversationAudibility
```

depende de:

- distância;
- room;
- noise profile;
- porta;
- social context.

O ouvinte pode receber apenas `attentionTarget` ou topic cue temporário.

### Aceite

- pawn próximo olha para conversa;
- não cria memória privada detalhada por padrão;
- respeita paredes/room boundaries.

---

## R40 — Entrar numa conversa em andamento ✅

**Resultado:** grupos podem crescer sem encerrar e recriar toda a conversa.

### Condições

```text
group has capacity
relationship/context permite
topic affinity
social capacity
physical access
```

### Pipeline

```text
approach
→ edge position
→ greeting/ack if needed
→ join
```

### Aceite

- par vira trio;
- turn-taking incorpora novo membro;
- nenhuma duplicação de conversation activity.

---

## R41 — Sair de conversa sem quebrar o grupo ✅

**Resultado:** um participante pode se retirar e os demais continuar.

Razões:

```text
social capacity
appointment
need
manual order
activity opportunity
```

### Aceite

- trio vira par sem resetar topic obrigatoriamente;
- saída libera slot espacial;
- memory final registra participação real.

---

## R42 — Convites e recusas leves ✅

**Resultado:** um pawn pode sugerir activity e o outro pode aceitar ou não.

### `SocialInvitation`

```text
inviter
invitee
activityKind
target?
expiresAt
```

Resposta pondera utility normal.

### Regras

Recusa não deve gerar conflito ou penalidade automática de relação.

### Aceite

- "jogar", "ouvir música" e "ir ao terraço" funcionam;
- invite expira sem travar participantes.

---

## R43 — Shared silence ✅

**Resultado:** alta familiaridade/comfort permite companhia sem conversa constante.

Exemplos:

```text
ler lado a lado
ouvir música
sentar no terraço
assistir chuva
```

### Aceite

- atividade social silenciosa conta como presença compartilhada;
- SocialDirector não tenta iniciar bubble a cada poucos segundos.

---

## R44 — Reações coordenadas sem sincronização perfeita ✅

**Resultado:** grupo reage ao mesmo acontecimento de maneira relacionada, porém com timing individual.

Exemplos:

```text
boardgame result
TV beat
pet interruption
story event
```

### Pipeline

```text
GroupReactionEvent
→ individual reaction profiles
→ reaction latency
```

### Aceite

- três pawns reagem ao resultado do jogo com variantes/timing diferentes;
- não há “onda militar” idêntica.

---

## R45 — Teasing/rematch leve ✅

**Resultado:** relações playful podem gerar continuidade em jogos e desafios.

### Contexto

```text
previousResult
playfulness
familiarity
recentRematchCooldown
```

Sem hostilidade.

### Aceite

- derrota pode gerar invite de revanche;
- bubble é opcional e localizada;
- nenhuma afinidade negativa automática.

---

## R46 — Agradecimento e acknowledgement ✅

**Resultado:** pequenas transferências sociais têm aftermath.

Gatilhos:

```text
receiveItem
someonePreparedSharedActivity
someoneMadeMeal
visitorGift
```

Resposta pode ser gesto, olhar ou fala curta.

### Aceite

- giveItem não termina seco;
- não repetir acknowledgement para cada microação interna.

---

## R47 — Retomada social após interrupção ✅

**Resultado:** uma conversa interrompida por evento curto pode continuar.

### Estado

```text
SuspendedConversation
participants
topic
expiresAt
reason
```

Exemplo:

```text
pet atravessa
→ reação
→ 2 s
→ conversation resumes
```

Não retomar depois de manual order ou longa ausência.

### Aceite

- interrupção breve mantém continuidade;
- timeout limpa estado suspenso.

---
# 9. Bloco E — atividades coletivas sofisticadas

## R48 — Papéis internos de activity ✅

**Resultado:** atividades coletivas deixam de tratar todos os participantes como equivalentes.

### Criar

```text
ActivityRole
host
participant
listener
spectator
helper
performer
```

Cada `HabitatActivityDefinition` declara papéis possíveis e capacidade.

### Regras

- role não representa hierarquia social;
- pode mudar durante a activity;
- join opportunity pode procurar role específico;
- apresentação usa o role para escolher slots/behaviors.

### Aceite

- listening session distingue performer/listener;
- cooking pode distinguir cook/helper;
- inspect debug mostra roles.

---

## R49 — Boardgame microbeats ✅

**Resultado:** jogar deixa de ser apenas sentar por N segundos e sortear vencedor.

### Beat loop

```text
consider
→ movePiece
→ opponentReaction
→ pause
→ nextTurn
```

Não criar regras reais de xadrez/boardgame nesta milestone.

### Variações

- jogador competitivo pensa menos/mais conforme profile;
- espectadores podem olhar para o tabuleiro;
- último beat produz outcome.

### Aceite

- 30 s de boardgame exibem vários beats;
- outcome continua vindo do estado lógico, não da animação;
- cancelamento entre beats funciona.

---

## R50 — TV / movie session microbeats ✅

**Resultado:** assistir algo possui ritmo interno.

### Eventos internos cosméticos

```text
quietBeat
interestingBeat
funnyBeat
endingBeat
```

Podem produzir:

- mudança de atenção;
- pequena reação;
- comentário raro;
- olhar compartilhado.

### Regras

Não gerar conteúdo real de filme/TV. `MediaItem` fornece apenas tags/contexto.

### Aceite

- sessão não parece pose congelada;
- reaction beats possuem budget para não virar conversa contínua.

---

## R51 — Listening session sofisticada ✅

**Resultado:** ouvir música possui comportamento próprio separado de TV.

### Comportamentos

```text
settle
listen quietly
subtle beat/finger/foot response
look at player/record occasionally
comment between tracks/beats
```

Influenciar por:

```text
music affinity
specific genre affinity
familiarity with media
creative profile
```

### Aceite

- pawn altamente interessado apresenta sinais sutis diferentes;
- shared silence é a norma, não bubble constante.

---

## R52 — Jam session com turnos e liderança dinâmica ✅

**Resultado:** múltiplos performers parecem colaborar em vez de executar loops simultâneos desconectados.

### Modelo leve

```text
JamBeat
leadPerformer
supportPerformers
listeners
```

A liderança pode alternar a cada poucos beats.

### Não fazer

Não sincronizar áudio musical real ou simular teoria/harmonia nesta etapa.

### Aceite

- dois performers alternam foco visual;
- listener direciona atenção ao lead atual;
- role changes não recriam activity.

---

## R53 — Etiqueta de mesa / shared meal ✅

**Resultado:** refeições coletivas têm início, consumo e encerramento menos mecânicos.

### Comportamentos

- esperar alguns participantes quando contexto pede;
- sentar em vagas coerentes;
- começar com pequena tolerância de atraso;
- alternar eating beats e social beats;
- alguns terminam antes;
- pratos/copos permanecem como aftermath.

### Aceite

- 3+ pawns não começam/terminam no mesmo frame;
- activity pode continuar enquanto um participante sai.

---

## R54 — Handoffs em cooking activity ✅

**Resultado:** cozinhar em dupla pode dividir pequenas subtarefas.

### Exemplo abstrato

```text
prepare
→ helper gets ingredient/item
→ cook uses station
→ helper places item/table
→ meal ready
```

Não simular receita detalhada além do `Recipe` existente.

### Aceite

- helper possui ação útil distinta;
- se helper sai, cook consegue continuar ou simplificar;
- nenhum item duplica.

---

## R55 — Pausas e retorno dentro de activity ✅

**Resultado:** activities longas suportam pequenas quebras sem serem encerradas.

### Exemplos

```text
movie → pegar bebida → voltar
workpiece → alongar → voltar
reading → olhar janela → continuar
```

Criar `ActivityBreak` com timeout curto.

### Aceite

- assento/role pode permanecer reservado quando apropriado;
- pausa longa libera recurso;
- `resume` usa continuidade já implementada no `08`.

---

## R56 — Activity migration ✅

**Resultado:** uma atividade pode naturalmente levar a outra sem StoryDirector roteirizar a sequência inteira.

### `ActivityAftermathOpportunity`

Exemplos:

```text
movie ended
→ snack / conversation / leave

meal ended
→ coffee / conversation / cleanup

jam ended
→ listen / talk / solitude
```

### Regra

Opportunity entra no scorer normal; não força sequência.

### Aceite

- pelo menos 3 activity types geram aftermath candidates;
- cada pawn pode escolher resultado diferente.

---

## R57 — Spectator behavior ✅

**Resultado:** pawn pode assistir uma atividade interessante sem se tornar participante formal.

Exemplos:

```text
boardgame
jam
pet playing
cooking
```

Spectator:

- ocupa posição periférica;
- attention target acompanha activity;
- não reserva role principal;
- pode converter em participant se surgir vaga.

### Aceite

- spectator não bloqueia activity;
- sair não gera memória forte por padrão.

---

## R58 — Dispersão natural de grupo ✅

**Resultado:** ao final de uma activity, participantes não se afastam todos simultaneamente para destinos aleatórios.

### Pipeline

```text
activity ends
→ small windDown window
→ individual next-choice stagger
→ some remain
→ some talk
→ some leave
```

### Aceite

- final de jantar/TV forma aftermath legível;
- stagger respeita manual orders imediatamente.

---

# 10. Bloco F — sono, rotina e transições do dia

## R59 — Sinais corporais graduais de sono ✅

**Resultado:** `sleepiness` passa a ser percebida antes do pawn decidir dormir.

### Cues possíveis

```text
yawn
longer idle pause
brief stretch
sit preference
lower movement cadence
look toward bed/quiet room
```

### Bandas

```text
mild
noticeable
strong
```

Aplicar histerese já prevista no `08`.

### Aceite

- observador consegue perceber progressão sem HUD;
- cues não são disparados todos ao mesmo tempo.

---

## R60 — Wind-down espontâneo ✅

**Resultado:** antes de bedtime routine formal, o pawn começa a reduzir intensidade do ambiente/comportamento.

### Possíveis ações

- evitar iniciar activity longa;
- preferir luz mais baixa;
- encerrar música/TV após beat apropriado;
- guardar item atual;
- escolher atividade silenciosa;
- migrar para room próximo do quarto.

### Aceite

- 10–30 min simulados antes do sono possuem mudança perceptível;
- nenhum script fixa uma sequência única.

---

## R61 — Entrada e saída da cama refinadas ✅

**Resultado:** cama possui side/slot e sequência coerente.

### Implementar

```text
bedApproachSide
enterBedSlot
sleepAnchor
exitBedSlot
```

Evitar atravessar cabeceira ou parede.

### Aceite

- pawn entra pelo lado disponível;
- cama dupla futura pode reservar lados independentemente;
- path valida approach.

---

## R62 — Variações de pose durante sono ✅

**Resultado:** dormir por muito tempo não é um sprite perfeitamente imóvel.

### Eventos raros

```text
turn
small reposition
brief wake-like movement
```

Visual-only, sem alterar SleepEpisode.

### Regras

- baixa frequência;
- reduced motion reduz/desativa;
- não gerar bubble.

### Aceite

- sono de vários minutos possui 1–3 mudanças discretas;
- nenhuma alteração de need por pose.

---

## R63 — Wake inertia mais expressiva ✅

**Resultado:** despertar não retorna instantaneamente ao comportamento normal.

### Durante `sleepInertia`

- sentar na cama por pouco tempo;
- reaction latency maior;
- movimento levemente mais lento;
- activities cognitivamente intensas recebem pequeno penalty;
- luz muito forte pode ser menos preferida.

### Aceite

- janela dura poucos minutos simulados;
- desaparece gradualmente;
- manual order continua possível.

---

## R64 — Nap diferente de sono noturno ✅

**Resultado:** cochilo é visual e comportamentalmente distinto.

### Diferenças

```text
shorter wind-down
may use sofa/recliner
no full bedtime routine
lighter wake inertia
shorter duration
```

### Aceite

- nap não troca necessariamente para sleep loadout;
- night sleep continua preferindo bed.

---

## R65 — Quiet hours comportamentais ✅

**Resultado:** o Habitat muda de ritmo à noite sem bloquear ações.

### Modificadores

- atividades barulhentas ligeiramente menos atraentes;
- micro-idles mais longos;
- iluminação ambiente mais quente/baixa;
- social encounters tendem a ser menores;
- objetos sonoros têm volume ambiente menor quando apropriado.

### Aceite

- noite parece diferente mesmo com pawn acordado;
- usuário ainda pode ordenar jam/TV manualmente.

---

## R66 — Morning micro-routine variável ✅

**Resultado:** acordar não dispara sempre a mesma sequência rígida.

### Candidate pool

```text
bathroom
water/coffee
window
stretch
change clothes
brief phone/device
breakfast
```

`BehaviorRoutine` define dependências mínimas, mas choice scorer escolhe opcionais.

### Aceite

- três mornings com seeds diferentes variam mantendo coerência;
- passos obrigatórios configurados continuam respeitados.

---

## R67 — Last-check antes de sair ✅

**Resultado:** `PrepareToLeaveRoutine` termina com verificação curta antes da porta.

### Checagens internas

```text
requiredItems collected?
loadout resolved?
appointment still valid?
exit clear?
```

Visual:

- breve pausa;
- olhar para bag/item;
- opcionalmente voltar para buscar algo faltante.

### Aceite

- missing required item pode provocar retorno;
- sem item obrigatório, saída não ganha atraso excessivo.

---

## R68 — Arrival decompression ✅

**Resultado:** chegar em casa não lança imediatamente uma nova activity intensa.

### Janela curta

```text
enter
→ place carried items
→ change context/loadout optional
→ settle
→ next decision
```

Possíveis microações:

- sentar;
- beber água fictícia;
- cumprimentar resident/pet;
- ir ao banheiro;
- trocar roupa.

### Aceite

- arrival possui 1–3 beats;
- urgency pode pular decompression.

---

## R69 — Waiting behavior para appointment ✅

**Resultado:** pawn pronto cedo não fica em wander aleatório até a hora de sair/encontrar alguém.

### `PreAppointmentWaiting`

Activities compatíveis:

```text
sit
phone
window
short media
small talk
```

Evitar iniciar algo cuja duração esperada ultrapassa compromisso.

### Aceite

- readiness considera `timeToAppointment`;
- activity curta pode ser interrompida perto da hora.

---

# 11. Bloco G — ambiente, áudio e atmosfera

## R70 — Footsteps por material de piso ✅

**Resultado:** caminhar em madeira, carpete, concreto e exterior possui resposta sonora diferente.

### Implementar

`FloorAcousticProfile` data-driven.

Campos:

```text
footstepSet
volume
pitchJitterRange
reverbHint
```

### Regras

- respeitar mute;
- limitar vozes simultâneas;
- não tocar cada frame, apenas footfall cadence.

### Aceite

- 3 materiais distinguíveis;
- áudio não satura com 4 pawns caminhando.

---

## R71 — Áudio espacial simples ✅

**Resultado:** som possui origem e distância.

### Modelo

```text
source position
listener camera position
maxRadius
falloff
```

Não precisa HRTF.

### Aceite

- piano fica mais baixo ao afastar câmera;
- som some fora do radius;
- comportamento funciona em mobile/desktop.

---

## R72 — Oclusão por room/porta ✅

**Resultado:** uma atividade sonora em outro cômodo não possui o mesmo volume.

### Heurística

```text
same room = 1.0
connected open door = 0.55–0.8
closed door = 0.15–0.4
unconnected room = very low/zero
```

### Aceite

- fechar porta reduz áudio sem cortar abruptamente;
- transição usa fade curto.

---

## R73 — Ambient sound zones ✅

**Resultado:** sites/rooms podem possuir paisagem sonora leve.

Exemplos:

```text
terrace: distant city / birds
kitchen: fridge hum
rain: window rain
café: low murmur
hotel: HVAC
```

### Regras

- layers com volume baixo;
- fade ao mudar room/site;
- nenhum loop invasivo.

### Aceite

- pelo menos 4 ContextProfiles com ambient diferente;
- mute global funciona.

---

## R74 — Uso contextual de luzes ✅

**Resultado:** pawns podem ligar/desligar luz por necessidade local em vez de Story/Ritual apenas.

### Condições

```text
room perceived too dark
activity requires light
leaving empty room + neat/energy-conscious profile optional
sleep wind-down
```

### Regras

Não criar obsessão por apagar luz. Cooldown forte.

### Aceite

- reading/work pode ligar luminária;
- bedtime pode apagar luz;
- stateful light permanece consistente.

---

## R75 — Cortinas e janelas como props funcionais ✅

**Resultado:** janela deixa de ser só destino de `watchRain`.

### Estados

```text
curtain open/closed
window open/closed
```

Efeitos simulados leves:

- light contribution;
- sound contribution;
- weather affordances;
- privacy/context.

### Aceite

- abrir cortina muda light score;
- chuva + janela aberta pode alterar ambient sound;
- não simular física de vento complexa.

---

## R76 — Variantes individuais de reação ao clima ✅

**Resultado:** chuva, frio/calor cosmético e pôr do sol não geram a mesma response em todos.

### Exemplos

```text
likesRain → window utility ↑
outdoorsAffinity high → terrace even in mild rain possible
sleepy → cozy indoor ↑
curious → inspect event ↑
```

### Aceite

- dois pawns escolhem respostas diferentes ao mesmo WeatherEvent;
- comportamento usa preferences existentes.

---

## R77 — Microanimações ambientais stateful ✅

**Resultado:** objetos/ambiente possuem ciclos discretos independentes dos pawns.

Seed:

```text
plant sway
curtain movement
TV subtle flicker
clock tick
record spin
fan rotation
lamp tiny variation
```

### Regra

Classificar como Tier 0 visual; não alimentar event bus sem necessidade.

### Aceite

- 5 elementos;
- pausam fora da viewport/LOD apropriado.

---

## R78 — Atmosphere presets por daypart ✅

**Resultado:** manhã, tarde, noite e madrugada mudam mais do que apenas tint global.

### `DaypartAtmosphere`

```text
light temperature
ambient intensity
window contribution
audio layer mix
micro-idle cadence
```

### Aceite

- mesma sala possui identidade diferente em 4 dayparts;
- transição é gradual.

---

## R79 — Propagação limitada de reação a microeventos ✅

**Resultado:** um acontecimento pode chamar atenção de quem realmente poderia percebê-lo.

### Exemplo

```text
object falls
→ nearby pawn hears/sees
→ looks
→ second pawn farther away maybe hears
→ others ignore
```

### Budget

- radius;
- salience;
- max reactors;
- reaction delay.

### Aceite

- evento não faz todos os pawns do site reagirem;
- paredes/ruído reduzem alcance.

---

## R80 — Lived-in markers de cômodo ✅

**Resultado:** rooms ganham sinais derivados de uso recente.

Exemplos:

```text
recentlyUsed
quiet
sociallyActive
musicRecentlyPlayed
mealRecentlyOccurred
```

Esses markers:

- possuem decay;
- podem influenciar small talk/attention;
- não são necessidades.

### Aceite

- inspect debug mostra markers;
- pelo menos duas affordances usam marker como modificador leve.

---

## R81 — `QuietnessController`: ritmo ambiental global ✅

**Resultado:** o simulador protege períodos de baixa intensidade para que eventos tenham contraste.

### Modelo

Calcular `sceneActivityLevel` por:

```text
active conversations
activities
story events
movement
bubbles
sound sources
```

Quando alto por muito tempo:

- StoryDirector reduz probes;
- autonomia favorece atividades silenciosas levemente;
- bubble budget cai.

Não forçar pawns a parar.

### Aceite

- 20 min simulados não permanecem em máxima atividade o tempo inteiro;
- usuário/manual continua capaz de criar caos.

---

# 12. Bloco H — pets mais convincentes

> Este bloco assume que o pet/autonomia básica da camada Habitat Alive já existe. Se pets ainda forem opcionais na build, estas milestones podem ficar para depois sem bloquear os demais blocos.

## R82 — Pet attention target ✅

**Resultado:** pet também percebe movimento, objetos e pessoas.

Prioridades possíveis:

```text
moving toy
favorite pawn
sound source
window
food-like cosmetic prop
other pet
```

### Aceite

- pet olha/segue visualmente estímulo antes de agir;
- target possui timeout e anti-jitter.

---

## R83 — Favorite spots do pet ✅

**Resultado:** animal desenvolve lugares reconhecíveis para dormir/observar.

Score:

```text
comfort
warmth
quiet
height/tag if supported
usage habit
proximity to favorite pawn
```

### Aceite

- favorite spot emerge por uso;
- indisponibilidade leva a segunda opção.

---

## R84 — Brincar com objetos ✅

**Resultado:** pet pode interagir com um pequeno conjunto de props/itens.

Seed:

```text
toy
box
smallLooseItem
rug
```

### Regras

- não destruir item;
- pode deslocar apenas entidades permitidas;
- aftermath é stateful.

### Aceite

- 3 affordances pet-specific;
- item deslocado continua consistente.

---

## R85 — Follow / avoid contextual ✅

**Resultado:** pet alterna entre acompanhar e buscar independência.

### Modificadores

```text
favorite pawn
recent attention
noise
crowding
sleepiness
current pet need
```

### Aceite

- pet não cola no pawn 100% do tempo;
- pode sair de grupo barulhento.

---

## R86 — Interrupção de activity com etiqueta ✅

**Resultado:** pet pode entrar numa cena sem destruí-la.

Exemplo:

```text
cat approaches boardgame
→ participant notices
→ short reaction
→ cat passes / settles
→ activity resumes
```

### Aceite

- interruption usa sistema suspenso já existente;
- cooldown impede repetição irritante.

---

## R87 — Zoomies / sleep pacing ✅

**Resultado:** pet possui contraste de energia.

### Regras

- zoomies raros e curtos;
- não durante quiet hours com frequência alta;
- long sleep periods possíveis;
- não transformar pet em centro constante da cena.

### Aceite

- 30 min simulados mostram variedade de energia;
- budget global limita eventos intensos.

---
# 13. Bloco I — editor e criação de ambientes

## R88 — Smart snapping contextual ✅

**Resultado:** placement no editor ajuda a produzir layouts funcionais sem tirar controle do usuário.

### Snaps possíveis

```text
wall edge
room grid
surface slot
furniture alignment
center on rug
seat around table
prop against wall
```

### UX

- snap preview antes do drop;
- `Alt`/gesto equivalente desativa temporariamente;
- não mover objeto depois de colocado sem comando.

### Aceite

- cadeira alinha com mesa;
- quadro prefere parede;
- usuário consegue ignorar snap.

---

## R89 — Rotation/orientation preview inteligente ✅

**Resultado:** antes de colocar um prop, o editor mostra não apenas sprite rotacionado, mas também direção funcional.

### Preview

```text
front/facing arrow
approach slots
affordance target direction
blocked footprint
```

### Aceite

- TV, cadeira, cama e porta têm orientação legível;
- rotate shortcut funciona durante ghost placement.

---

## R90 — Multi-select / marquee ✅

**Resultado:** editar vários elementos deixa de exigir operação individual.

### Suportar

```text
shift-click desktop
marquee drag
mobile multi-select mode
```

A seleção pode mover, duplicar, apagar e salvar como prefab.

### Regras

- seleção não inclui floor/wall por padrão quando modo é props;
- confirmação para delete grande.

### Aceite

- selecionar 10 props e mover preserva offsets;
- undo reverte como uma operação.

---

## R91 — Align / distribute ✅

**Resultado:** layouts intencionais podem ser produzidos rapidamente.

Ferramentas:

```text
align left/right/top/bottom
align horizontal center
align vertical center
distribute horizontal/vertical
```

Respeitar grid e footprint.

### Aceite

- funciona com 3+ objetos;
- preview mostra posição final;
- operação inválida não cria overlap bloqueado.

---

## R92 — Duplicate / copy-paste preservando semântica ✅

**Resultado:** copiar prop mantém definição/tint/configuração, mas recebe nova identidade.

### Regra crítica

```text
copy instance
→ new entityId
→ same definitionId
→ clone editable properties
→ clear runtime reservations/state that must not clone
```

### Aceite

- duplicar objeto stateful não duplica holder/activity;
- undo/redo seguro.

---

## R93 — Quick replace ✅

**Resultado:** trocar um sofá/cadeira/mesa por variante equivalente preserva layout quando possível.

### Pipeline

```text
select entity
→ Replace
→ compatible definitions filtered by tags/footprint
→ preview
→ migrate compatible state
```

### Aceite

- seat → seat mantém orientation;
- footprint incompatível exige validação/reposition;
- entityId policy explícita: substituir cria nova instance e registra command.

---

## R94 — Busca, filtros e favoritos do catálogo ✅

**Resultado:** catálogo continua utilizável com centenas de definitions.

### Filtros

```text
category
tags
room role
size
interaction capability
style/material
custom/built-in
```

Usuário pode marcar favorites.

### Aceite

- busca por “music” encontra instrumento e media furniture relevantes;
- filtros combináveis;
- favorites persistem localmente.

---

## R95 — Recently used no editor ✅

**Resultado:** construir várias unidades semelhantes fica rápido.

Manter lista MRU por:

```text
prop definitions
materials
floor styles
wall styles
```

### Aceite

- últimas 8–12 escolhas acessíveis em um clique;
- MRU não substitui favorites.

---

## R96 — Affordance preview no editor ✅

**Resultado:** usuário consegue ver o que um objeto realmente adiciona ao Habitat antes de colocá-lo.

### Mostrar de forma compacta

```text
Seats: 1
Activities: read, relax
Tags: cozy, seat
Needs supported: rest/recreation
Group capacity: —
```

Não expor fórmula interna de utility em UI normal.

### Aceite

- pelo menos todas as props interativas mostram capabilities;
- custom objects usam o mesmo preview.

---

## R97 — Navigation preview / reachability live ✅

**Resultado:** editor detecta instantaneamente quando placement cria problemas de navegação.

### Visual

- spawn connectivity;
- door connectivity;
- station approach slots;
- unreachable cells/props.

### Performance

Recalcular incrementalmente/dirty, não A* completo por frame para tudo.

### Aceite

- bloquear porta gera warning imediato;
- warning desaparece ao corrigir;
- save pode exigir confirmação para layout degradado.

---

## R98 — Semantic coverage hints ✅

**Resultado:** editor ajuda a entender quais tipos de vida o room suporta sem impor score de “casa correta”.

### Exemplo

```text
ESTÚDIO
✓ música
✓ sentar
✓ escuta
~ conversa
— storage
```

### Regras

- hints, não checklist obrigatório;
- sem pontuação moral;
- derivar de affordances existentes.

### Aceite

- cobertura muda em tempo real ao colocar/remover props;
- custom activity entra automaticamente se tags/capability indicarem.

---

## R99 — Room bounds e portals visualization ✅

**Resultado:** estrutura multi-room fica depurável e editável visualmente.

Toggle de editor mostra:

```text
roomId
bounds
portal links
door direction
site boundary
```

### Aceite

- usuário consegue entender por que duas áreas são rooms diferentes;
- overlay nunca aparece no modo normal.

---

## R100 — Blueprint preview/diff antes de aplicar ✅

**Resultado:** aplicar blueprint não destrói layout sem clareza.

### Mostrar

```text
+ props que entram
~ props que mudam
- props removidos/conflitantes
wall/floor changes
reachability result
```

### Aceite

- cancel não altera estado;
- apply vira um único compound command;
- conflito possui resolução clara.

---

## R101 — History pane de edição ✅

**Resultado:** command stack fica visível e navegável.

Exemplo:

```text
Move Sofa
Place Lamp
Paint 14 floor tiles
Delete Plant
```

### Capacidades

- undo/redo pelos botões;
- selecionar entrada mostra highlight do alvo quando possível;
- não editar histórico antigo arbitrariamente nesta milestone.

### Aceite

- 50 commands continuam legíveis;
- compound command aparece como uma entrada.

---

## R102 — Keyboard shortcuts desktop ✅

**Resultado:** editor desktop ganha fluidez profissional.

Seed:

```text
V select/move
B build/place
R rotate
D duplicate
Delete remove
Ctrl/Cmd+Z undo
Ctrl/Cmd+Shift+Z redo
F focus selection
Esc cancel
```

### Aceite

- shortcuts não disparam quando text field possui foco;
- cheatsheet acessível.

---

## R103 — Gestos mobile refinados ✅

**Resultado:** editor não depende de equivalentes ruins de mouse/teclado.

### Definir claramente

```text
tap select
long press context
one-finger drag move selected prop
two-finger pan camera
pinch zoom
rotate button / two-finger rotate only if reliable
```

### Regras

- evitar conflito com Flame camera gestures;
- haptic leve opcional em snap/drop válido.

### Aceite

- placement, rotate, multi-select, undo e camera são possíveis sem precisão excessiva;
- gesture conflict tests em tela pequena.

---

# 14. Bloco J — câmera, UI e legibilidade diegética

## R104 — Tooltips contextuais de affordance ✅

**Resultado:** hover/long-press explica rapidamente o que pode ser feito sem abrir inspect completo.

### Conteúdo

```text
nome
principal affordance
estado/reserva
atalho contextual
```

Exemplo:

```text
Piano
Tocar · livre
```

### Aceite

- tooltip some rápido e não cobre alvo;
- mobile usa long-press ou pequena callout.

---

## R105 — Explicar por que uma ação está indisponível ✅

**Resultado:** menu contextual não mostra apenas botão cinza.

Exemplos:

```text
Jogar — precisa de mais 1 participante
Sentar — assento reservado
Dormir — cama inacessível
Dar item — mãos ocupadas
```

### Regras

Usar validation result estruturado da simulação.

### Aceite

- principais affordances possuem reason code localizado;
- UI não reimplementa regras.

---

## R106 — Camera focus transitions ✅

**Resultado:** seguir evento/pawn/room usa movimento suave em vez de teleporte seco.

### Perfis

```text
short focus: 180–300 ms
room focus: 250–500 ms
site transition: existing fade + framing
```

### Regras

- input do usuário cancela imediatamente;
- reduced motion pode usar cut/fade.

### Aceite

- follow pawn e “focus event” agradáveis;
- nunca lutar contra pan manual.

---

## R107 — Observer / cinematic mode ✅

**Resultado:** usuário pode deixar o Habitat rodando como pequena cena viva.

### Modo

- chrome reduzido;
- câmera escolhe ocasionalmente activity/event interessante;
- movimentos lentos;
- nunca toma controle durante edição/draft;
- qualquer input retorna ao modo normal.

### Framing score

```text
salience
group size
novelty
visual spread
camera distance
```

### Aceite

- 5 minutos alternam 2–5 focos sem frenesi;
- períodos quietos mantêm enquadramento estável.

---

## R108 — Event focus hint sem roubar câmera ✅

**Resultado:** acontecimento interessante fora da viewport pode ser indicado discretamente.

### Exemplos

- pequeno edge marker;
- portrait pulse;
- mini icon de room.

Não auto-pan por padrão.

### Aceite

- evento raro em outro room é descobrível;
- usuário pode ignorar sem popup.

---

## R109 — Bubble pacing / typography refinement ✅

**Resultado:** fala fica legível e menos intrusiva em cenas movimentadas.

### Melhorias

```text
reading-time based duration
max width
short line wrapping
speaker anchor collision avoidance
priority
fade hierarchy
```

### Budget

- limite global;
- limite por cluster;
- mote perde para speech importante.

### Aceite

- 4 pawns conversando não cobrem a cena inteira;
- texto longo indevido é truncado/rejeitado pelo assembler.

---

## R110 — Gramática visual de motes/thoughts ✅

**Resultado:** ícones rápidos têm semântica consistente.

Categorias:

```text
need cue
attention
reaction
activity
environment
social
```

Cada categoria define shape/duration/priority; não depender apenas de cor.

### Aceite

- usuário consegue distinguir thought de status rápido;
- acessibilidade não depende exclusivamente de hue.

---

## R111 — Debug HUD por presets ✅

**Resultado:** tanta sofisticação continua depurável sem dezenas de toggles soltos.

Presets:

```text
Behavior
Navigation
Social
Activities
Needs
Objects
Performance
Story
```

Cada preset liga overlays relevantes.

### Aceite

- alternar preset em runtime debug;
- release build não carrega UI pesada de debug.

---

# 15. Bloco K — storyteller, tuning e robustez final

## R112 — Foreshadowing de microeventos ✅

**Resultado:** alguns eventos têm pequenos sinais prévios e deixam de parecer RNG instantâneo.

Exemplos:

```text
rain → céu/luz muda antes
visitor arrival → door/notification cue antes
power flicker → lamp flicker antes de breve outage
pet zoomies → attention/stance antes
```

### Regras

- foreshadow não garante reação;
- eventos surpresa continuam possíveis quando apropriado.

### Aceite

- 3 StoryEvents possuem prelude;
- cancelamento do evento limpa prelude.

---

## R113 — Causality chain debug ✅

**Resultado:** qualquer cena emergente importante pode ser explicada como cadeia de eventos/decisões.

### Exemplo debug

```text
RainStarted
→ watchRain affordance +0.35
→ Caio chose watchRain (0.81)
→ Giovani noticed Caio
→ SocialOpportunity created
→ ConversationStarted
→ MemoryCreated(sharedRain)
```

### Implementar

IDs correlacionáveis:

```text
causeEventId
parentDecisionId
activityId
```

### Aceite

- inspect de evento abre cadeia curta;
- não persistir logs infinitamente.

---

## R114 — Snapshot auto-framing refinado ✅

**Resultado:** snapshots do Chronicle enquadram a cena relevante automaticamente.

### Framing

- bounding box dos participantes;
- incluir target prop;
- padding;
- respeitar room bounds;
- evitar UI chrome;
- escolher zoom máximo/mínimo seguro.

### Aceite

- jam, jantar e pet interruption produzem imagens úteis;
- grupo espalhado não gera zoom extremo ilegível.

---

## R115 — `SinceLastVisit` digest local ✅

**Resultado:** ao voltar depois de tempo suficiente, o usuário pode ver 1–3 mudanças interessantes sem receber relatório burocrático.

### Seleção

```text
high salience chronicle entries
new discovery
meaningful object state change
visitor/activity rare
```

### UX

Opcional, discreto e descartável.

### Aceite

- não aparece após ausência curta;
- não lista eventos banais;
- nenhum dado é inventado.

---

## R116 — Cooldown families + habituation ✅

**Resultado:** anti-repetição deixa de depender apenas de cooldown específico por action.

### Famílias

```text
music
screen
social
quiet
movement
creative
food
outdoor
```

Uma ação reduz temporariamente novidade da família, com intensidades diferentes.

### `HabituationState`

- cresce com repetição;
- recupera com tempo/alternância;
- não altera preferências permanentes.

### Aceite

- pawn que gosta muito de piano ainda alterna atividades;
- gosto continua reconhecível em janela longa.

---

## R117 — Stable stochasticity / close-call chooser ✅

**Resultado:** decisões próximas variam; decisões obviamente melhores permanecem estáveis.

### Política

```text
top score much higher
→ choose top almost always

scores close
→ weighted stochastic choice
```

Introduzir `decisionTemperature` contextual, com limites.

### Aceite

- mesma personalidade não vira coin flip constante;
- diferentes seeds produzem variedade em empates;
- mesma seed reproduz sequência.

---

## R118 — Anti-loop detector ✅

**Resultado:** simulação detecta padrões patológicos que cooldown normal não pegou.

### Assinatura curta por pawn

```text
last N actionKinds / targets / rooms
```

Detectar padrões como:

```text
A→B→A→B→A→B
chair1→chair2→chair1→chair2
roomA→roomB→roomA→roomB
```

Ao detectar:

- aplicar temporary penalty;
- limpar intenção não committed;
- registrar debug warning.

### Aceite

- cenário artificial de loop se recupera;
- atividade legítima repetitiva committed não é interrompida.

---

## R119 — Gate final de refinamento ✅

**Resultado:** o Habitat passa por uma bateria de observação, regressão e soak específica para microcomportamentos.

### Gate visual — 10 minutos sem input

Deve ser possível observar:

- variação de atenção;
- micro-idles não sincronizados;
- movement start/stop suave;
- uso coerente de portas;
- escolha espacial não trivial;
- pelo menos uma interação social com turn-taking;
- atividades com microbeats;
- objetos deixando vestígios;
- quiet periods;
- nenhum spam de bubbles;
- nenhuma fila/reserva presa;
- nenhuma sobreposição grotesca recorrente.

### Gate social

Executar cenário com 4 pawns por 30 min simulados:

```text
unique pairs > 1
conversation durations varied
groups can grow/shrink
shared silence possible
same topic not dominant
same pair not monopolizing all encounters
```

### Gate espacial

Cenário com:

```text
3 rooms
2 doors estreitas
6 seats
2 shared stations
4 pawns
```

Verificar:

- sem deadlock;
- sem duas reservations no mesmo slot;
- espera/side-step funcionam;
- 100% dos pawns continuam capazes de alcançar spawn/exit.

### Gate de objetos

Stress de 500 operações:

```text
pickup
place
give
return
interrupt
```

Invariantes:

```text
zero duplicated item
zero item without location
zero stale reservation
```

### Gate de editor

Em uma sessão:

1. criar room;
2. colocar prefab;
3. duplicar grupo;
4. substituir props;
5. quebrar reachability de propósito;
6. corrigir;
7. undo/redo 20 passos;
8. salvar blueprint;
9. aplicar em site vazio.

Nenhum estado lógico inválido.

### Gate de soak

Headless:

```text
24 h simuladas
seed fixa
4 pawns
1 pet
4 rooms
```

Verificar:

- nenhum action state preso;
- nenhum crescimento ilimitado de history;
- decision entropy dentro de banda configurada;
- actions mais usadas não monopolizam 90% do tempo salvo perfil/configuração extrema explícita;
- StoryDirector respeita quiet windows;
- memória/Chronicle dentro de budgets;
- performance estável.

### Critério perceptivo final

O refinamento está pronto quando uma gravação curta do Habitat pode ser assistida sem debug e o comportamento contém detalhes suficientes para que seja difícil apontar exatamente onde termina uma activity e começa outra.

A cena deve parecer composta por continuidade:

```text
olhar
→ aproximar
→ esperar
→ agir
→ reagir
→ deixar vestígio
→ mudar de contexto
→ seguir a vida
```

em vez de:

```text
chooseAction()
→ playAnimation()
→ chooseAction()
```

---

# 16. Matriz de efeitos combinatórios

As milestones acima não valem apenas pelo resultado isolado. O retorno real vem das combinações.

| Combinação | Cena emergente possível |
|---|---|
| R0 + R2 + R39 + R40 | pawn ouve conversa, olha, espera um pouco e decide entrar |
| R10 + R12 + R34 | grupo se forma com espaçamento e orientação plausíveis |
| R14 + R15 + R68 | dois pawns se encontram na porta durante chegada sem clipping |
| R20 + R24 + R28 | uso de objeto deixa estado visual e pequena bagunça |
| R25 + R26 + R27 | pawn procura e prefere um exemplar específico de objeto |
| R35 + R36 + R37 + R38 | conversa ganha ritmo, resposta, mudança de assunto e callback |
| R43 + R51 + R81 | dois pawns ouvem música juntos por bastante tempo sem spam |
| R48 + R52 + R57 | jam possui performers, listeners e espectador periférico |
| R53 + R56 + R58 | jantar termina em café/conversa e grupo se dispersa gradualmente |
| R59 + R60 + R65 + R74 | pawn cansado diminui o ritmo, reduz luz e inicia noite organicamente |
| R66 + R70 + R78 | manhã comunica outro ritmo por ações, som e atmosfera |
| R75 + R76 + R79 | chuva altera janela, áudio e attention de apenas quem percebe |
| R82 + R86 + R47 | pet interrompe conversa e participantes retomam depois |
| R88 + R96 + R97 + R98 | editor permite construir room funcional sem tentativa-e-erro cega |
| R107 + R114 + R115 | Habitat pode ser observado e depois recordar cenas relevantes |
| R116 + R117 + R118 | autonomia ganha variedade sem virar aleatoriedade ou loop |

---

# 17. Perfis de timing recomendados

Não hardcode os números abaixo em vários lugares. Centralizar em tuning data.

```text
TIMING PROFILE — initial guidance

attention settle        120–450 ms
ambient reaction        250–1400 ms
conversation gap        300–1500 ms
backchannel             150–600 ms after cue
arrival anticipation    80–300 ms
object anticipation     100–500 ms
standing micro-idle     4–18 s between candidates
seat adjustment         15–60 s
room-entry scan         100–500 ms
activity wind-down      500–2500 ms
door wait tolerance     300–3000 ms
```

Esses valores são **pontos de partida**, não design final.

Usar:

- seed determinística;
- personality/state modifiers;
- bounds fortes;
- tuning por cenário.

---

# 18. Hierarquia de interrupção refinada

O `08` já deve possuir prioridade de ação. Este documento acrescenta microações.

Sugestão:

```text
1. safety / invariant recovery
2. manual user order / draft
3. hard presence transition / departure
4. committed main activity
5. committed social/activity beat
6. object transaction critical section
7. story reaction
8. invitation response
9. micro-action
10. attention / micro-idle
```

Micro-idle **nunca** deve bloquear uma ação de nível superior.

---

# 19. Budgets globais de polish

Sem budgets, cada sistema local pode estar correto e a cena final virar ruído.

Criar `HabitatPresentationBudget` ou equivalente.

### Bubbles

```text
max global speech bubbles
max thought/motes
max per cluster
```

### Reações

```text
max simultaneous ambient reactors
max synchronized group reactions
```

### Áudio

```text
max concurrent one-shot sounds
max ambient layers
max footstep voices
```

### Micro-idles

```text
max visually salient micro-idles in viewport
```

### Camera hints

```text
max edge markers
cooldown between suggested focuses
```

Budgets devem degradar graciosamente por prioridade.

---

# 20. Personalidade deve aparecer no timing também

O profile comportamental não deve afetar apenas qual activity é escolhida.

Pode afetar levemente:

```text
reaction speed
conversation turn length
frequency of initiation
willingness to join group
idle motion frequency
route preference
crowding tolerance
object neatness
activity persistence
```

Exemplo:

```text
playful pawn
→ mais chance de spectator virar participant
→ mais rematch
→ mais reaction beats

quiet pawn
→ menos backchannels visuais
→ mais shared silence
→ maior crowding penalty
```

Nunca aplicar diferenças tão grandes que virem estereótipos rígidos.

---

# 21. “Não fazer” — anti-padrões desta fase

## 21.1 Não adicionar emoção geral por barra

Não criar:

```text
HAPPY 72%
SAD 18%
```

para justificar microcomportamentos.

Contexto, needs, capacities, relationships e conditions já são suficientes.

## 21.2 Não animar tudo

Uma cena onde todos:

- balançam;
- olham;
- falam;
- gesticulam;
- produzem mote;

é menos viva que uma cena com contraste.

## 21.3 Não transformar etiquette em bloqueio

Personal space, queue e door courtesy devem ceder a:

- emergência lógica;
- manual order;
- timeout;
- ausência de alternativa.

## 21.4 Não criar animação obrigatória sem fallback

Todo polish deve possuir fallback lógico/visual caso um body type ou asset não cubra a pose.

## 21.5 Não usar áudio como informação única

Toda informação funcional precisa continuar acessível com mute.

## 21.6 Não criar diálogo procedural irrestrito

Continuar grammar/tags/templates validados.

## 21.7 Não transformar traces em sujeira infinita

Vestígios devem possuir budget, decay e cleanup.

## 21.8 Não fazer todos os pawns “educados” da mesma maneira

Etiqueta espacial é prevenção de clipping/deadlock. Personalidade ainda pode variar timing e escolha.

## 21.9 Não deixar camera AI tomar controle

Observer mode é opt-in e cancelável instantaneamente.

## 21.10 Não criar microfeature que exija integração real

Se Rxx parece precisar de Health, Agenda, Relations, GPS ou Home Assistant, usar o estado simulado/port já criado no `08`.

---

# 22. Estratégia de testes

## 22.1 Unit tests

Priorizar regras como:

```text
slot ranking
door reservation
queue ordering
conversation turn selection
join/leave group
object transaction
cooldown family
anti-loop
```

## 22.2 Deterministic scenario tests

Cada bloco deve possuir uma scene seed.

Sugestão:

```text
refine_body_lab
refine_corridor_lab
refine_object_lab
refine_social_lab
refine_group_lab
refine_sleep_lab
refine_ambient_lab
refine_pet_lab
refine_editor_lab
```

## 22.3 Golden / screenshot

Não precisa screenshot para **cada** micro-milestone se o resultado é temporal.

Mas cada 3–5 milestones relacionadas deve possuir captura/gif/video curto de evidência.

## 22.4 Video regression

Para comportamentos de timing, manter gravações curtas de referência é mais útil que golden estático.

Exemplos:

```text
corridor_passage_15s
conversation_three_pawns_30s
bedtime_45s
boardgame_30s
visitor_arrival_30s
```

---

# 23. Métricas locais úteis

Adicionar apenas em debug/profiling.

```text
attention switches / min
micro-idles / pawn / min
reaction latency distribution
path replans / min
door wait duration
queue abandon rate
conversation turns / participant
conversation topic transitions
join/leave rates
shared silence duration
activity role changes
object orphan count
average trace count / room
bubble occupancy %
audio voice count
scene activity level
decision entropy
action family distribution
loop detector triggers
stuck recovery count
```

Essas métricas servem para detectar comportamento ruim, não para otimizar usuário real.

---

# 24. Ordem recomendada de implementação

Apesar de `R0–R119` serem pequenos, a ordem recomendada preserva dependências.

### Primeiro: corpo e espaço

```text
R0–R19
```

Porque todo o resto parece melhor quando pawns se posicionam, olham e se movem corretamente.

### Depois: objetos

```text
R20–R31
```

Porque social/activity depende de objetos não parecerem props estáticos.

### Depois: social + atividades

```text
R32–R58
```

Aqui aparece o maior ganho de emergência percebida.

### Depois: rotina + ambiente

```text
R59–R81
```

Isso adiciona ritmo de longo prazo.

### Pets

```text
R82–R87
```

Pode entrar em paralelo depois dos fundamentos de atenção/espaço.

### Editor

```text
R88–R103
```

Pode ser desenvolvido em paralelo com simulação se não houver conflito de arquitetura.

### UI + tuning final

```text
R104–R119
```

Aplicar depois que houver comportamento suficiente para realmente afinar.

---

# 25. Checkpoint a cada 10 milestones

A cada aproximadamente 10 milestones concluídas:

1. rodar `flutter analyze`;
2. rodar testes do Habitat;
3. executar pelo menos um scenario seed por 5 min;
4. revisar profiler;
5. gravar 30–60 s;
6. assistir sem debug;
7. listar os 3 comportamentos mais artificiais ainda visíveis;
8. evitar criar abstração nova se o problema for apenas tuning.

Esse passo é importante porque polish sistêmico pode sofrer de **diminishing returns**. O roadmap deve ser ajustado pela cena, não seguido cegamente.

---

# 26. Critério de sucesso deste documento

O `09` não está pronto quando `R119` está marcado ✅ por burocracia.

Está pronto quando detalhes pequenos começam a se combinar sem chamar atenção individual para si mesmos.

Uma boa cena pode parecer assim:

```text
O pawn entra na sala e percebe que duas pessoas estão jogando.
Ele olha por um momento, mas segue até a estante porque está cansado de socializar.
Pega um livro que costuma usar, senta numa cadeira orientada para a luminária e a liga.

Um dos jogadores termina a partida e faz uma pequena reação.
O outro comenta algo; eles continuam conversando por alguns segundos.
Um terceiro pawn atravessa a porta, espera o jogador que está saindo passar e entra.

Começa a chover.
Só quem está perto da janela percebe imediatamente.
O pawn lendo olha depois, mas não levanta.
A música que vinha de outro cômodo fica abafada quando a porta fecha.

Mais tarde, o leitor devolve o livro à mesa em vez da estante, apaga a luminária e vai para o quarto.
A sala fica um pouco mais silenciosa.
```

Nenhuma parte isolada é extraordinária.

O efeito vem de:

```text
attention
+ timing
+ spatial etiquette
+ preferences
+ social capacity
+ object state
+ audio occlusion
+ weather perception
+ activity pacing
+ quietness
```

Essa é a finalidade do documento.

---

# 27. Regra final

> **A grande simulação faz o pawn saber o que fazer. O refinamento faz parecer que ele realmente fez aquilo.**

Depois do `07` e do `08`, evitar a tentação de responder a toda sensação de artificialidade com uma feature enorme.

Muitas vezes o salto de qualidade virá de algo como:

```text
esperar 300 ms
olhar para o alvo
ceder passagem
escolher a cadeira certa
continuar a conversa
não falar
deixar a caneca na mesa
apagar a luz ao sair
```

É essa camada de pequenas consequências e pequenas decisões que deve fazer o Habitat parecer menos como uma lista de sistemas e mais como um lugar onde algo está sempre, discretamente, acontecendo.
