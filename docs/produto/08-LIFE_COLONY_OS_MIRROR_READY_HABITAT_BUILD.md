# Mirror-Ready Habitat — Build de capacidades pré-integração

**Documentos pais:**
- `05-LIFE_COLONY_OS_LIVING_PAWN_SPEC.md`
- `07-LIFE_COLONY_OS_LIVING_PAWN_VISUAL_FIRST_BUILD.md`
- `LIFE_COLONY_OS_SPEC.md`
- `03-LIFE_COLONY_OS_IGNITION_ENGINE_SPEC.md`

**Status:** guia de execução  
**Versão:** 1.0  
**Data:** 2026-08-08  
**Pré-requisito:** bloco pré-§5 do `07`, incluindo a camada de Habitat Alive / emergência já especificada na cópia de trabalho até a atual §4.14.  
**Escopo:** ampliar o Habitat como simulador autônomo e preparar primitivas que futuramente poderão espelhar dados reais, **sem integrar ainda nenhum outro módulo do Fallhub**.

---

## 0. Por que este guia existe

O `07` constrói primeiro um Habitat divertido, visual e emergente. A próxima pergunta não é ainda:

> “como ligar Health, Agenda, Relations, Inventory, Travel, Atlas e Ignition?”

A pergunta correta é:

> **“quais capacidades o Habitat precisa possuir internamente para que, quando essas integrações chegarem, os dados reais possam dirigir um mundo que já sabe o que fazer com eles?”**

Exemplo:

```text
HOJE
sleepiness é simulada
→ pawn boceja
→ reduz atividades intensas
→ inicia rotina noturna
→ vai para a cama
→ dorme
→ acorda com sleep inertia

FUTURO
Health Connect / HealthKit fornece um SleepEpisode real
→ o mesmo sistema calcula sleepiness/fatigue
→ o mesmo pawn usa as mesmas affordances
→ a mesma rotina / recuperação / representação visual continua válida
```

Outro:

```text
HOJE
PawnPreferences:
  music.jazz = 0.92

→ pawn tende a escolher discos de jazz
→ conversa sobre jazz
→ aproxima-se de outro pawn com gosto parecido
→ participa de listening session

FUTURO
o perfil real do usuário declara jazz = interesse forte
→ substitui/ajusta a fonte da preferência
→ nenhum director precisa ser reescrito
```

Outro:

```text
HOJE
SimulatedAppointment:
  20:00 jantar com pawn B

→ pawn principal se prepara
→ troca loadout
→ pega itens
→ sai
→ B aparece no site restaurante
→ atividade compartilhada
→ despedida
→ retorno

FUTURO
CalendarEvent + Person
→ adapter produz o mesmo HabitatAppointment
→ toda a simulação existente continua funcionando
```

Este documento transforma essa ideia em milestones implementáveis.

---

# 1. North Star

O Habitat deve se tornar uma **linguagem de representação da vida** antes de receber dados da vida.

Ele deve saber representar, por conta própria:

- acordar;
- sentir sono;
- ficar cansado;
- recuperar-se;
- sentir necessidade de movimento;
- querer ficar sozinho;
- querer companhia;
- ter gostos;
- possuir traços comportamentais;
- usar roupas adequadas ao contexto;
- preparar-se para sair;
- carregar itens;
- chegar e sair de lugares;
- visitar e receber pessoas;
- participar de compromissos;
- cozinhar e comer;
- ler, ouvir música, assistir e jogar;
- trabalhar em algo persistente;
- interromper e retomar atividades;
- ter locais favoritos;
- habitar múltiplos sites;
- viajar entre fusos;
- viver em ambientes com acústica, iluminação, privacidade e conectividade distintas;
- construir e editar esses ambientes com rapidez;
- sustentar tudo isso apenas com dados simulados.

Mais tarde, dados reais poderão substituir **inputs**, não a simulação.

---

# 2. Regra de ouro — simular primeiro, conectar depois

Durante **todo este documento**, é proibido criar dependência direta de:

```text
features/health
features/relations
features/inventory
features/travel
features/projects
features/tasks
features/research
features/zones
features/integrations
Google Calendar
Health Connect
HealthKit
Home Assistant
GPS/geofence
Bluetooth
wearables
APIs remotas
```

Esses módulos já existem ou são previstos no Fallhub. O Habitat deve estar preparado para recebê-los futuramente, mas não importá-los agora.

### Permitido

- contratos Dart puros;
- sources simulados;
- sources manuais locais;
- dados mock;
- snapshots locais versionados;
- UI de debug;
- editores internos;
- affordances;
- events;
- simulation clock;
- state resolvers;
- testes determinísticos.

### Proibido

```dart
import '../../health/application/health_providers.dart';
```

dentro da simulação.

Preferir:

```text
Health no futuro
      ↓
SleepSignalAdapter
      ↓
MirrorSignal<SleepEpisode>
      ↓
HabitatEffectiveStateResolver
      ↓
SleepSystem
```

Hoje:

```text
SimulatedSleepSource
      ↓
MirrorSignal<SleepEpisode>
      ↓
mesmo resolver
      ↓
mesmo SleepSystem
```

---

# 3. Relação com a arquitetura atual do repo

O repo já possui slices como:

```text
lib/features/health/
lib/features/relations/
lib/features/inventory/
lib/features/travel/
lib/features/pawn/
lib/features/zones/
lib/features/storyteller/
```

e os pacotes centrais:

```text
packages/colony_domain/
packages/colony_database/
packages/colony_design_system/
packages/living_habitat_assets/
```

A regra deste documento é:

> **não duplicar esses domínios dentro do Habitat, mas também não acoplar o Habitat a eles antes da hora.**

Criar conceitos de representação próprios do simulador:

```text
HabitatSleepState
HabitatPresenceEpisode
HabitatAppointment
HabitatItemState
HabitatInterestAffinity
```

que futuramente recebam adapters vindos dos domínios reais.

Não criar uma segunda entidade `Person` real, um segundo `Trip` real ou um segundo prontuário.

---

# 4. Vocabulário arquitetural

## 4.1 Simulated State

Estado inventado pela simulação para que o Habitat funcione sozinho.

```text
sleepPressure = 0.71
source = simulated
```

Não afirma nada sobre a pessoa real.

## 4.2 Observed State

Dado futuramente observado por fonte autorizada.

```text
SleepEpisode
23:54 → 07:11
source = externalObserved
confidence = 0.91
```

## 4.3 Declared State

Dado declarado conscientemente pelo usuário.

```text
interest.music.jazz = 0.95
source = userDeclared
```

## 4.4 Derived State

Dado calculado a partir de sinais.

```text
fatigue = derive(sleepEpisode, recentActivity)
```

Nunca deve perder provenance.

## 4.5 Effective State

Estado final que o simulador utiliza.

```text
Simulated
Declared
Observed
Derived
Override
       ↓
EffectiveStateResolver
       ↓
EffectivePawnState
```

O renderer e os directors consomem **Effective State**, não providers externos.

---

# 5. Contrato fundamental — `MirrorSignal<T>`

Todo valor que futuramente possa ser dirigido por dados externos deve poder carregar origem e confiança.

Modelo conceitual:

```dart
enum MirrorSignalSource {
  simulated,
  manual,
  userDeclared,
  externalObserved,
  externalDerived,
  systemDerived,
  unknown,
}

class MirrorSignal<T> {
  const MirrorSignal({
    required this.id,
    required this.value,
    required this.source,
    required this.observedAt,
    required this.confidence,
    this.validUntil,
    this.sourceRef,
    this.transformationChain = const [],
    this.isSensitive = false,
  });

  final String id;
  final T value;
  final MirrorSignalSource source;
  final DateTime observedAt;
  final DateTime? validUntil;
  final double confidence;
  final String? sourceRef;
  final List<String> transformationChain;
  final bool isSensitive;
}
```

### Regras

1. `confidence` sempre `0..1`.
2. `simulated` não deve fingir que é `observed`.
3. dado expirado continua historicamente existente, mas não precisa vencer resolução atual.
4. dado sensível não aparece em log comum.
5. qualquer valor derivado registra inputs ou `transformationChain`.
6. signals externos futuros são read-only para a simulação.
7. comportamento cosmético nunca reescreve silenciosamente dado declarado pelo usuário.

---

# 6. Status geral

O prefixo **M** é usado para não colidir com `V10+` do `07`.

Cada milestone deve ser implementada em ordem, salvo waiver explícito.

| Milestone | Resultado | Status |
|---|---|---|
| **M0** | MirrorSignal + provenance local | ✅ |
| **M1** | EffectiveStateResolver + overrides | ✅ |
| **M2** | Relógios + episódios temporais | ✅ |
| **M3** | Pawn embodied state skeleton | ✅ |
| **M4** | Inspect de estado + explainability | ✅ |
| **M5** | Need Engine | ✅ |
| **M6** | Capacity Engine | ✅ |
| **M7** | Condition Engine | ✅ |
| **M8** | Sono + circadiano + cansaço | ✅ |
| **M9** | Movimento + fadiga + recuperação | ✅ |
| **M10** | Social battery + solitude | ✅ |
| **M11** | Stimulation + criatividade | ✅ |
| **M12** | Ontologia de interesses | ✅ |
| **M13** | Preferências multi-source | ✅ |
| **M14** | Personalidade + estilo social | ✅ |
| **M15** | MediaItem + gostos concretos | ✅ |
| **M16** | Conversation Topic Graph | ✅ |
| **M17** | Pawn identity kinds + bindings futuros | ✅ |
| **M18** | Presence roles + visitor lifecycle | ✅ |
| **M19** | HabitatAppointment | ✅ |
| **M20** | Remote presence / calls | ✅ |
| **M21** | Shared planned activities | ✅ |
| **M22** | HabitatSite + HabitatRoom | ✅ |
| **M23** | Home / Away / Transit | ✅ |
| **M24** | Context profiles de site/zona | ✅ |
| **M25** | Conforto percebido individual | ✅ |
| **M26** | Editor estrutural de rooms | ✅ |
| **M27** | Auto-detecção + semântica de cômodo | ✅ |
| **M28** | Command stack + prefabs + blueprints | ✅ |
| **M29** | Auto-furnish + geração procedural | ✅ |
| **M30** | Scene presets + ambiente stateful | ✅ |
| **M31** | Loadouts contextuais | ✅ |
| **M32** | Storage + inventory virtual robusto | ✅ |
| **M33** | Devices + atenção + interrupções | ✅ |
| **M34** | BehaviorRoutine engine | ✅ |
| **M35** | Rotinas acordar/dormir/self-care | ✅ |
| **M36** | Leaving / arriving home | ✅ |
| **M37** | Food + cooking + shared meals | ✅ |
| **M38** | Workpieces persistentes | ✅ |
| **M39** | Preparation requirements / loadout físico | ✅ |
| **M40** | Travel context + timezone + jet lag | ✅ |
| **M41** | Abstract sites + world map | ✅ |
| **M42** | Data-driven content definitions | ✅ |
| **M43** | Custom object/activity creator | ✅ |
| **M44** | Future binding ports | ✅ |
| **M45** | Privacidade de person-proxy | ✅ |
| **M46** | Authority boundary / multiplayer-ready | ✅ |
| **M47** | Persistência versionada | ✅ |
| **M48** | Background simulation + performance | ✅ |
| **M49** | Soak tests + invariantes | ✅ |
| **M50** | Gate final Mirror-Ready | ✅ |

---

# 7. Loop de implementação

Para cada milestone:

```text
1. Ler esta milestone inteira.
2. Ler apenas as seções citadas dos docs pais.
3. Identificar o resultado observável.
4. Implementar a menor vertical slice que torna o resultado verdadeiro.
5. Não criar arquitetura de milestones futuras sem necessidade.
6. Adicionar testes.
7. flutter run.
8. Observar por pelo menos 30–60 s.
9. Capturar screenshot quando houver resultado visual.
10. Atualizar tabela de status ⬜ → ✅.
11. Marcar o próprio título com ✅.
12. Só então seguir.
```

### Gate por milestone

```text
[ ] resultado observável
[ ] fonte simulada funcional
[ ] nenhuma integração externa
[ ] nenhuma fonte simulada se apresenta como real
[ ] cancelamento/falha seguros
[ ] debug explica o estado
[ ] testes da feature
[ ] flutter analyze na fatia
[ ] screenshot se visual
```

---

# 8. Fase A — fundação de estado espelhável

---

## M0 — MirrorSignal + provenance local ✅

**Resultado:** o Habitat possui uma forma única de representar valores que hoje são simulados, mas amanhã podem vir de fontes reais.

### Implementar

Criar módulo Dart puro, por exemplo:

```text
lib/features/habitat/simulation/mirror/
  mirror_signal.dart
  mirror_provenance.dart
  mirror_value_quality.dart
```

Tipos:

```text
MirrorSignal<T>
MirrorSignalSource
MirrorProvenance
MirrorFreshness
MirrorConfidence
```

Não depender de Flutter.

### Freshness

Adicionar helper:

```text
fresh
aging
stale
expired
```

Não precisa persistir todos esses labels; podem ser derivados de tempo.

### Primeiro uso

Migrar uma variável não sensível já existente, como clima simulado ou phase do dia, para provar o contrato.

```text
temperature:
  value = 22.4
  source = simulated
```

### Não fazer

- Health adapter.
- Calendar adapter.
- banco real.
- UI de permissões.

### Testes

```text
confidence fora de 0..1 é rejeitada/clampada conforme decisão
expired signal não é fresh
simulated nunca vira externalObserved
transformation chain preservada
```

### Aceite

- `MirrorSignal` testado;
- ao menos 1 sinal atual do Habitat passa pelo contrato;
- debug consegue imprimir origem;
- nenhum import de módulos externos;
- screenshot opcional: `m00_signal_debug.png`.

---

## M1 — EffectiveStateResolver + overrides ✅

**Resultado:** múltiplas fontes podem existir para a mesma dimensão sem espalhar regras de precedência pelo código.

### Criar

```text
EffectiveStateResolver<T>
EffectiveValue<T>
ResolutionReason
ResolutionPolicy
```

Exemplo:

```dart
class EffectiveValue<T> {
  final T value;
  final MirrorSignal<T> winningSignal;
  final List<MirrorSignal<T>> considered;
  final String explanation;
}
```

### Precedência inicial

```text
explicit manual override
> user declared
> external observed futuro
> external derived futuro
> system derived
> simulated
> unknown
```

A policy pode variar por tipo.

Uma preferência declarada pelo usuário não deve ser substituída por preferência aprendida só dentro do Habitat.

### Conflitos

Não fazer média silenciosa entre fontes fortes divergentes.

Preferir:

```text
resolver por policy
+
registrar conflict flag
```

### Override

```text
HabitatStateOverride<T>
value
startedAt
expiresAt?
reason
```

### Aceite

- resolver recebe ≥2 sources;
- retorna valor + explicação;
- override temporário expira;
- conflito aparece no debug;
- testes de precedência;
- screenshot: `m01_effective_state.png`.

---

## M2 — Relógios + episódios temporais ✅

**Resultado:** todos os sistemas seguintes usam uma linguagem temporal comum.

A spec 05 já diferencia `RealClock`, `SceneClock` e `SimulationClock`. Formalizar essa separação no Habitat.

### Criar

```text
HabitatClockBundle
HabitatRealClock
HabitatSceneClock
HabitatSimulationClock
```

### Regras

`RealClock`:
- leitura do dispositivo;
- nunca acelera.

`SceneClock`:
- controla iluminação e hora percebida;
- hoje normalmente segue RealClock;
- debug pode fixar/comprimir.

`SimulationClock`:
- controla necessidades, cooldowns, episódios e background sim;
- em debug pode acelerar.

### Episódios

Criar primitiva:

```dart
class HabitatEpisode {
  final String id;
  final String kind;
  final double startedAtSimSeconds;
  final double? endedAtSimSeconds;
  final Map<String, Object?> data;
}
```

Será reutilizada para:

```text
sleep
visit
appointment participation
travel
activity
recovery
phone call
presence
```

### Timezone

Ainda sem travel real, já permitir `siteTimezoneId` e helpers de conversão.

### Debug

Controles apenas debug:

```text
1x
5x
30x
skip +1h
set scene hour
```

### Aceite

- Scene e Simulation clocks podem divergir em debug;
- timers não usam `DateTime.now()` espalhado;
- episódio simples inicia/encerra;
- teste com clock falso;
- screenshot: `m02_clock_debug.png`.

---

## M3 — Pawn Embodied State skeleton ✅

**Resultado:** o pawn passa a possuir um estado corporal/operacional explícito separado de aparência, memória e job.

Criar:

```text
PawnEmbodiedState
├─ needs
├─ capacities
├─ conditions
├─ circadian
├─ presence
└─ context
```

Modelo:

```dart
class PawnEmbodiedState {
  final Map<NeedKind, NeedReading> needs;
  final Map<CapacityKind, CapacityReading> capacities;
  final List<PawnCondition> conditions;
  final CircadianState circadian;
}
```

Nesta milestone, valores podem ser estáticos/mock.

### Separar

`Need` = algo cuja pressão muda com o tempo e pode ser atendido.

`Capacity` = aptidão momentânea para executar algo.

`Condition` = modificador temporário/contextual.

Exemplo:

```text
Need.social = alta
Capacity.social = baixa
Condition.tired = 0.7
```

Isso é válido.

### Aceite

- pawn inspect recebe `PawnEmbodiedState`;
- ao menos 3 needs, 3 capacities e 1 condition mock;
- nenhuma variável existe só dentro de `Flame Component`;
- screenshot: `m03_embodied_state.png`.

---

## M4 — Inspect de estado + explainability ✅

**Resultado:** antes de aumentar a complexidade, o desenvolvedor consegue entender por que o pawn está naquele estado.

Adicionar aba debug/inspect:

```text
STATE
Needs
Capacities
Conditions
Signals
Context
```

Exemplo:

```text
Sleep need: 0.72
  source: simulated
  last update: 12 s
  trend: rising

Energy capacity: 0.41
  derived from:
    sleepPressure 0.72
    physicalFatigue 0.23

Condition:
  Tired 0.58
```

### Explain chain

Permitir:

```text
tap/click valor
→ winning source
→ inputs derivados
→ policy
```

UI de produção pode continuar mínima. A explainability completa pode ficar atrás de flag debug.

### Aceite

- qualquer need/capacity mostra origem;
- valor derivado mostra inputs;
- dados sensíveis podem ser redacted;
- screenshot: `m04_state_explain.png`.

---
# 9. Fase B — necessidades, capacidades e corpo simulado

---

## M5 — Need Engine ✅

**Resultado:** pawns possuem pressões internas graduais que alteram escolhas, sem transformar o Habitat em um Tamagotchi punitivo.

### Seed inicial

Inspirada nas necessidades já previstas pela spec mestre, mas restrita ao que produz comportamento útil no Habitat:

```text
sleep
food
movement
rest
socialConnection
solitude
recreation
stimulation
creativeExpression
comfort
```

`hydration` pode ser adicionada junto de Food se houver affordances suficientes; não criar só para preencher barra.

### Modelo

```dart
enum HabitatNeedKind {
  sleep,
  food,
  movement,
  rest,
  socialConnection,
  solitude,
  recreation,
  stimulation,
  creativeExpression,
  comfort,
}

class NeedReading {
  final HabitatNeedKind kind;
  final double pressure; // 0..1
  final double trendPerSimHour;
  final MirrorSignalSource source;
}
```

Preferir `pressure`:

```text
0 = sem pressão
1 = pressão muito alta
```

em vez de “felicidade da barra”.

### Evolução

Cada need possui:

```text
baselineRiseRate
activityModifiers
environmentModifiers
satisfactionEvents
refractoryWindow
```

Não atualizar por frame.

Sugestão:

```text
need tick: 5–15 simulation seconds
```

### Exemplos

```text
sentado por muito tempo
→ movement pressure sobe

atividade social longa
→ socialConnection pressure cai
→ solitude pode subir em alguns pawns

música / boardgame
→ recreation cai

atividade criativa
→ creativeExpression cai

ambiente desconfortável
→ comfort sobe
```

### Não criar punições

Proibido nesta fase:

```text
morrer de fome
ficar doente por need
perder progressão
notificação “você abandonou seu pawn”
streak
culpa por ausência
```

Needs existem para **variar comportamento**.

### Integração com ChoiceScorer

Need deve alterar utility de affordances:

```text
sleep pressure alta
→ sleep/rest affordances ↑

movement pressure alta
→ walk/stretch/outdoor ↑

solitude alta
→ one-person activities ↑

desire social alta
→ social opportunities ↑
```

Usar caps para uma need não destruir personalidade e contexto.

### Debug

Overlay opcional com sparklines curtas.

### Aceite

- 6+ needs ativas;
- needs mudam em simulation time;
- 4+ affordances recebem modificador por need;
- nenhuma need gera obrigação ao usuário;
- teste acelera 4 h simuladas sem NaN/saturação errada;
- screenshot: `m05_needs.png`.

---

## M6 — Capacity Engine ✅

**Resultado:** o pawn diferencia “quero fazer” de “tenho capacidade momentânea para fazer”.

Capacidades previstas:

```text
energy
focus
physicalReadiness
socialTolerance
creativeCapacity
decisionCapacity
recovery
```

Não criar uma readiness global.

### Modelo

```dart
enum HabitatCapacityKind {
  energy,
  focus,
  physicalReadiness,
  socialTolerance,
  creativeCapacity,
  decisionCapacity,
  recovery,
}

class CapacityReading {
  final HabitatCapacityKind kind;
  final double value; // 0..1
  final List<String> contributors;
  final MirrorSignalSource source;
}
```

### Diferença de Need

Exemplo:

```text
creativeExpression.pressure = 0.82
creativeCapacity = 0.27
```

O pawn quer expressão criativa, mas capacidade está baixa.

ChoiceScorer pode preferir:

```text
ouvir disco
rabiscar
atividade criativa curta
```

em vez de uma atividade longa/intensa.

Outro:

```text
socialConnection.pressure = 0.74
socialTolerance = 0.21
```

Pode preferir:

```text
conversa 1:1
sentar perto de amigo
telefonema curto
```

em vez de party/group chat.

### Readiness contextual

Implementar helper:

```text
readinessFor(activityDefinition, pawn)
```

Não armazenar um único score global.

Uma atividade declara pesos:

```text
practice_piano:
  energy 0.15
  focus 0.25
  creativeCapacity 0.35
  recovery 0.05
```

Outro:

```text
watch_tv:
  energy 0.05
  focus 0.05
```

### Aceite

- 5+ capacities;
- ao menos 5 affordances declaram requirements/weights;
- mesma need produz atividade diferente com capacities distintas;
- explainability mostra contributors;
- screenshot: `m06_capacities.png`.

---

## M7 — Condition Engine ✅

**Resultado:** estados temporários conseguem alterar aparência e comportamento sem virar flags espalhadas.

### Modelo

```dart
class PawnCondition {
  final String id;
  final PawnConditionKind kind;
  final double intensity;
  final double startedAt;
  final double? expectedEndAt;
  final MirrorSignalSource source;
  final Map<HabitatCapacityKind, double> capacityModifiers;
  final Map<String, double> affordanceModifiers;
  final ConditionPresentation presentation;
}
```

### Seed inicial

```text
sleepy
 tired
wellRested
groggy
physicallyTired
mentallyFatigued
sociallyDrained
restless
relaxed
inspired
cold
hot
```

`hungry` pode ser derivado de Food Need, mas evitar duplicar estado sem razão.

### Stack

Conditions podem coexistir:

```text
Sleepy 0.7
Inspired 0.5
Cold 0.2
```

Modifiers devem ser combinados de forma limitada/clampada.

### Visual presentation

Cada condition pode declarar, sem acoplar à engine lógica:

```text
moteTag
bubbleTag
walkSpeedMultiplier
idlePoseTag
colorModulation
animationFrequencyModifier
```

Exemplo `sleepy`:

```text
rare yawn mote
slightly longer idles
sit utility ↑
```

Não representar exaustão de forma humilhante.

### Aceite

- 5 conditions funcionais;
- conditions expiram/decay;
- renderer recebe presentation state, não lê rules internas;
- combinação de duas conditions testada;
- screenshot: `m07_conditions.png`.

---

## M8 — Sono, ritmo circadiano e cansaço ✅

**Resultado:** dormir deixa de ser uma pose e vira um ciclo completo capaz de dirigir comportamento por horas simuladas.

Esta milestone é uma das fundações centrais do Mirror-Ready Habitat.

### Separar os conceitos

```text
SleepPressure
CircadianDrive
SleepEpisode
SleepDebtEstimate
SleepQuality
SleepInertia
Fatigue
```

Não reduzir tudo a `sleep = 42%`.

### Estado

```text
awake
windingDown
sleepy
goingToBed
sleeping
waking
nap
```

### `CircadianProfile`

```dart
class CircadianProfile {
  final double preferredSleepHour;
  final double preferredWakeHour;
  final double morningActivation;
  final double eveningActivation;
  final double napAffinity;
}
```

Inicialmente derivado deterministicamente de `memberId + worldSeed`, ou configurável no debug.

### Sleep pressure

Modelo simples, não clínico:

```text
awake time ↑ → sleep pressure ↑
sleeping → sleep pressure ↓
nap → redução parcial
```

### Circadian drive

Usar curva suave por `SceneClock`/hora local do site.

```text
sleepUtility =
  pressure component
  + circadian component
  + routine component
  + comfort component
```

### SleepEpisode

```dart
class HabitatSleepEpisode {
  final String id;
  final String pawnId;
  final double startSimTime;
  final double? endSimTime;
  final SleepEpisodeKind kind; // mainSleep | nap
  final double quality;
  final MirrorSignalSource source;
}
```

### Qualidade simulada

Pode considerar apenas fatores do próprio Habitat:

```text
bed comfort
room darkness
room noise
temperature comfort
interruptions
```

Sem alegar qualidade de sono real.

### Visual

Sleepy:
- bocejo raro;
- thought curto;
- procura sentar;
- movimento levemente mais lento.

GoingToBed:
- encerra atividades não essenciais;
- pode iniciar rotina M35 depois.

Sleeping:
- cama reservada;
- visual de dormir;
- bubbles sociais bloqueadas;
- luz/ambiente podem mudar por Ritual.

Waking:
- transição;
- condição `groggy` / sleep inertia temporária.

### Nap

Nap só se:
- sleep pressure alta;
- período permitido;
- sofá/cama disponível;
- não houver commitment forte.

### Futuro explícito

O design deve permitir que um `HabitatSleepEpisode` real substitua o simulado como source efetiva para o pawn principal, sem mudar SleepSystem.

### Não fazer

- algoritmo médico de staging REM/deep;
- diagnóstico;
- pontuação de saúde;
- recomendação clínica;
- Health Connect.

### Testes

```text
16 h awake → pressure maior que 2 h awake
7 h sleeping → pressure cai
nap reduz parcialmente
circadian late night aumenta sleep readiness
mesma seed reproduz horários simulados equivalentes
```

### Aceite

- ciclo dormir/acordar completo;
- episódio persistível;
- fatigue muda após sono curto vs adequado dentro da simulação;
- pawn altera comportamento por tiredness;
- debug pode simular 24 h em poucos minutos;
- screenshot: `m08_sleep_cycle.png`.

---

## M9 — Movimento, fadiga física e recuperação ✅

**Resultado:** ficar parado, andar e realizar atividades físicas passam a deixar consequências temporárias coerentes.

### Estados

```text
movementNeed
physicalFatigue
recoveryCapacity
sedentaryDuration
recentMovementLoad
```

### Atividades físicas cosméticas iniciais

```text
walk
stretch
shortExercise
terraceWalk
standAndMove
```

Se assets permitirem:

```text
pushup / mobility / treadmill
```

mas não bloquear milestone por animação específica.

### SedentaryDuration

Aumenta enquanto:
- sentado;
- TV;
- leitura;
- atividade longa de mesa.

Pode alimentar movementNeed.

### Physical fatigue

Aumenta com:
- long walk;
- exercise;
- algumas activities.

Reduz com:
- sit;
- rest;
- sleep;
- tempo.

### Comportamentos emergentes

```text
muito tempo na mesa
→ pawn interrompe
→ alonga
→ janela / água / caminhada
→ retorna
```

Esse ciclo será extremamente útil quando sessões reais de trabalho forem projetadas depois.

### Aceite

- sedentaryDuration existe;
- pawn ocasionalmente quebra sedentarismo;
- atividade física aumenta fatigue;
- rest/sleep recupera;
- nenhum valor se apresenta como métrica real do usuário;
- screenshot: `m09_movement_recovery.png`.

---

## M10 — Social battery + solitude ✅

**Resultado:** pawns podem querer conexão e ao mesmo tempo ter baixa tolerância social.

### Dois eixos independentes

```text
Need.socialConnection
Need.solitude
Capacity.socialTolerance
```

Isso produz perfis muito melhores do que `introvert=true`.

### Social intensity

Cada activity social declara intensidade:

```text
silent shared activity = 0.10
1:1 chat = 0.30
game = 0.40
group chat = 0.55
party = 0.80
```

Social tolerance diminui de acordo com:
- duração;
- intensidade;
- personalidade;
- tamanho do grupo.

Recupera em:
- solitude;
- sono;
- atividades quiet;
- tempo.

### Solitude affordances

```text
read alone
listen alone
sit at window
walk alone
stay in own room
creative solo activity
```

### Shared silence

Relação forte + baixa social tolerance deve permitir:

```text
pawns no mesmo cômodo
cada um fazendo algo
sem conversa obrigatória
```

Isso é vida social também.

### Anti-clumping

O SocialDirector deve respeitar:

```text
socialTolerance low
solitude pressure high
```

sem proibir encontros completamente.

### Aceite

- pawn sai naturalmente de grupo após tempo suficiente;
- outro pawn pode permanecer;
- baixa social capacity favorece 1:1/quiet;
- high affinity não derrota sempre necessidade de solitude;
- screenshot: `m10_solitude.png`.

---

## M11 — Stimulation + criatividade ✅

**Resultado:** o simulador possui motivos internos para alternar entre novidade, tranquilidade e expressão criativa.

### Stimulation Need

Não usar “bored = unhappy”.

```text
stimulation pressure alta
→ procura novidade/variedade

stimulation pressure baixa
→ atividades quiet continuam válidas
```

Fontes de novelty:

```text
new room
rare affordance
new prop
activity not used recently
visitor
story event
media item not consumed
```

### CreativeExpression Need

Satisfeita por tags:

```text
musicPerformance
drawing
writing
cookingCreative
building
decorating
crafting
```

### Creative Capacity

Influencia complexidade escolhida:

```text
low capacity + high need
→ listen / doodle / improvise curto

high capacity + high need
→ perform / create / workpiece
```

### Inspired condition

Eventos raros podem gerar `Inspired`, que:
- aumenta exploration de affordances criativas;
- não afirma inspiração real do usuário;
- expira.

### Aceite

- novelty afeta scoring;
- creative need tem ≥3 formas de satisfação;
- baixa/alta creative capacity muda atividade escolhida;
- screenshot: `m11_creativity.png`.

---

# 10. Fase C — identidade, gostos e cultura material

---

## M12 — Ontologia hierárquica de interesses ✅

**Resultado:** “gostar de jazz” deixa de ser bool solto e vira parte de uma taxonomia reutilizável por objetos, mídia, conversa, presentes e atividades.

### Estrutura

```text
InterestTaxonomy
InterestTag
InterestPath
```

Exemplo seed:

```text
music
├─ jazz
│  ├─ bebop
│  ├─ hard_bop
│  ├─ modal
│  ├─ fusion
│  └─ jazz_funk
├─ classical
├─ rock
│  └─ progressive_rock
└─ brazilian
   ├─ samba
   └─ bossa_nova

art
film
literature
games
food
cooking
technology
nature
travel
sports
learning
```

Não precisa cobrir o mundo inteiro no seed inicial.

### Herança

Afinidade em child pode contribuir parcialmente para parent:

```text
fusion 0.9
→ jazz recebe evidência parcial
→ music recebe evidência menor
```

Mas gostar do parent não implica gostar de todos os children.

### IDs estáveis

Usar chaves:

```text
music.jazz
music.jazz.fusion
food.japanese
```

Não texto localizado como ID.

### Tags compartilhadas

As mesmas IDs podem ser usadas por:
- `MediaItem`;
- props;
- activities;
- conversation topics;
- gifts;
- rooms/sites.

### Aceite

- taxonomy com 30+ tags seed;
- parent/child query;
- localized label separado do ID;
- testes de herança;
- debug browser da taxonomy;
- screenshot: `m12_interest_taxonomy.png`.

---

## M13 — Preferências multi-source + gosto aprendido ✅

**Resultado:** o Habitat distingue o que o usuário declarou, o que foi configurado, e o que emergiu apenas dentro da simulação.

### Modelo

```dart
enum PreferenceSource {
  userDeclared,
  habitatConfigured,
  habitatLearned,
  futureDomain,
  simulatedSeed,
}

class PreferenceReading {
  final String interestId;
  final double affinity; // -1..1
  final PreferenceSource source;
  final double confidence;
  final bool authoritative;
}
```

### Effective preference

Resolver regras:

```text
userDeclared authoritative
> futureDomain authoritative
> habitatConfigured
> habitatLearned
> simulatedSeed
```

`habitatLearned` nunca reduz silenciosamente `userDeclared`.

### Gosto aprendido

O Habitat pode aprender apenas preferências **do personagem dentro do Habitat**:

```text
usa chair_07 repetidamente
→ likes prop chair_07

escolhe terrace em chuva leve várias vezes
→ habitat preference context rain+terrace
```

Não concluir:

```text
“o usuário real gosta de chuva”
```

### UI

No criador/inspect, permitir opcionalmente editar alguns interesses manualmente:

```text
Jazz            muito alto
Culinária       médio
Jogos de mesa   alto
```

Sem exigir configuração para funcionar.

### Aceite

- 3 source types ativas;
- authoritative preference não é sobrescrita;
- learned preference muda lentamente;
- debug mostra source;
- screenshot: `m13_preferences.png`.

---

## M14 — Personalidade comportamental + estilo social ✅

**Resultado:** personalidade afeta como o pawn age, mas continua separada de traits reais do usuário.

### `HabitatBehaviorProfile`

Dimensões sugeridas:

```text
sociability
curiosity
playfulness
noveltySeeking
routineSeeking
neatness
competitiveness
cooperativeness
patience
spontaneity
creativeDrive
outdoorsAffinity
```

Cada `0..1`.

### `SocialStyle`

```text
talkativeness
initiationBias
listenerBias
oneOnOnePreference
groupPreference
conversationDurationPreference
proximityPreference
competitiveSocialBias
```

### Separar de identidade real

Deixar contrato futuro:

```text
DeclaredTraitProfile
      ↓
BehaviorProfileAdapter futuro
      ↓
EffectiveBehaviorProfile
```

Hoje:

```text
HabitatBehaviorProfile seeded/configured
```

### Estabilidade

Seed por `memberId` para não trocar personalidade após restart.

### Não hardcode nominal

Proibido:

```text
if pawn.name == 'Caio'
```

### Aceite

- 3 pawns com perfis claramente diferentes;
- SocialDirector usa SocialStyle;
- ActivityDirector usa pelo menos 3 traits;
- debug mostra modificadores;
- screenshot: `m14_behavior_profile.png`.

---

## M15 — `MediaItem` + gostos concretos ✅

**Resultado:** interesses passam a existir fisicamente no mundo por livros, discos, filmes, jogos e partituras.

### Modelo

```dart
enum MediaKind {
  book,
  album,
  movie,
  game,
  score,
  magazine,
}

class HabitatMediaItem {
  final String id;
  final MediaKind kind;
  final String title;
  final Set<String> interestTags;
  final double durationHint;
  final String? creator;
  final MediaProgress progress;
}
```

### Props

```text
bookshelf
record shelf
record player
TV
console
music stand
```

oferecem affordances de escolher conteúdo.

### Escolha

Score usa:

```text
interest affinity
novelty
progress
current capacity
social context
```

### Progress

Livros/filmes longos podem possuir:

```text
notStarted
inProgress
completed
```

Sem transformar consumo em checklist.

### Listening session

Exemplo:

```text
pawn A escolhe album fusion
→ record_player state muda
→ B gosta de jazz/fusion
→ join listening utility ↑
→ conversa ganha tags do media item
```

### Futuro

Atlas musical/biblioteca poderão gerar `HabitatMediaItem` via adapter.

### Aceite

- 3 media kinds;
- seleção baseada em preferência;
- media pode alimentar group activity;
- estado/progress persiste localmente;
- screenshot: `m15_media.png`.

---

## M16 — Conversation Topic Graph ✅

**Resultado:** a engine social deixa de falar apenas sobre ambiente e passa a conversar sobre interesses, objetos, atividades e memórias de forma estruturada.

### Topic model

```text
ConversationTopic
├─ id
├─ tags
├─ interestIds
├─ contextRequirements
├─ relationRequirements
├─ recentPenalty
└─ phraseSeeds
```

Seed:

```text
music.jazz
music.general
book.current
movie
food
cooking
travel
games
art
technology
currentActivity
sharedMemory
roomObject
weather
futurePlanSimulated
```

### Score

```text
topic score =
  interest(A)
  + interest(B)
  + sharedInterestBonus
  + contextualCue
  + memoryCue
  + relationFit
  - recentTopicPenalty
```

### Object cues

Props e MediaItems próximos podem adicionar topics.

Exemplo:

```text
souvenir with tag travel.china
→ travel topic candidate
```

Isso não afirma que viagem ocorreu de verdade enquanto source for simulated.

### Conversa → ação

Alguns beats podem produzir `ActivitySuggestion`:

```text
music topic
→ listen together?

boardgame topic
→ rematch?

food topic perto da cozinha
→ cook together?
```

ActivityDirector valida normalmente.

### Aceite

- 8+ topics reais;
- shared interests alteram chance;
- prop/media contextual influencia topic;
- conversa pode gerar ao menos 2 activities;
- anti-eco continua valendo;
- screenshot: `m16_topics.png`.

---
# 11. Fase D — pessoas, presença e compromissos

---

## M17 — Pawn identity kinds + binding futuro ✅

**Resultado:** o simulador distingue o pawn principal, moradores fictícios, proxies de pessoas e pets sem assumir que todos são a mesma categoria de entidade.

### Criar

```dart
enum PawnIdentityKind {
  self,
  resident,
  personProxy,
  fictional,
  pet,
}
```

E:

```dart
class HabitatIdentityBinding {
  final String pawnId;
  final PawnIdentityKind kind;
  final String? externalEntityType;
  final String? externalEntityId;
}
```

Hoje:

```text
externalEntityId = null
```

para praticamente todos.

No futuro:

```text
kind = personProxy
externalEntityType = person
externalEntityId = <Person.id>
```

### Primary pawn

Formalizar:

```text
isPrimarySelfPawn
```

como capacidade de binding, não como lógica nominal.

Somente o primary self pawn fica elegível, no futuro, para sinais pessoais como:

```text
sleep
health
current context
real presence
```

### Person proxy

Person proxy pode carregar hoje:

```text
appearance
name
known interests simulados/configurados
social style do Habitat
presence role
```

Não carregar automaticamente:

```text
health
sleep
mood real
real location
private schedule
```

### Aceite

- roster suporta identity kind;
- primary pawn é explícito;
- personProxy não ganha embodied signals pessoais por default;
- binding externo é opcional/opaque;
- testes de privacy default;
- screenshot: `m17_identity_kind.png`.

---

## M18 — Presence roles + Visitor Lifecycle ✅

**Resultado:** nem todo pawn precisa “morar” permanentemente no mesmo Habitat; visitantes entram, participam e vão embora.

### PresenceRole

```text
resident
frequentVisitor
visitor
temporaryGuest
remoteParticipant
```

### PresenceState

```text
absent
arriving
present
leaving
remote
```

### `HabitatPresenceEpisode`

```dart
class HabitatPresenceEpisode {
  final String id;
  final String pawnId;
  final String siteId;
  final double startAt;
  final double? endAt;
  final PresenceMode mode;
  final MirrorSignalSource source;
}
```

### Visitor lifecycle

Implementar evento mock/manual:

```text
visitor scheduled
→ pre-arrival window
→ arrival at entrance
→ greeting opportunity
→ normal activities
→ leaving intention
→ farewell opportunity
→ exit
→ absent
```

### Regras

- visitante não aparece por teleport no meio da sala;
- arrival reserva entrance cell brevemente;
- se entrada bloqueada, fallback seguro;
- host não é obrigado a interromper atividade se manual/drafted;
- goodbye pode ser pulado sem bloquear saída.

### FrequentVisitor

Pode desenvolver:

```text
favorite seat
room familiarity
relationship memories
```

mesmo sem ser resident.

### Resident

Pode possuir:

```text
assignedBed
assignedDesk
assignedStorage
preferredRoom
```

### Aceite

- visitor entra e sai fisicamente;
- resident continua no world;
- presence episode é registrado;
- arrival não quebra current activities;
- screenshot: `m18_visitor.png`.

---

## M19 — `HabitatAppointment` ✅

**Resultado:** o Habitat consegue representar um compromisso futuro usando apenas dados simulados.

### Modelo

```dart
class HabitatAppointment {
  final String id;
  final String title;
  final double startsAt;
  final double endsAt;
  final Set<String> participantPawnIds;
  final String siteId;
  final String activityKind;
  final AppointmentPresenceMode presenceMode;
  final double preparationWindow;
  final Set<String> requiredTags;
  final MirrorSignalSource source;
}
```

Tipos seed:

```text
dinner
hangout
meeting
study
jam
gameNight
movie
visit
coffee
party
call
```

### Scheduler interno

Criar:

```text
HabitatAppointmentDirector
```

responsável por:

```text
upcoming
preparing
due
active
ending
completed
cancelled
```

Ele não executa atividades diretamente.

Ele cria contexto/intents:

```text
PrepareForAppointment
TravelToSite
PresenceEpisode
PlannedActivityOpportunity
```

### Pontualidade imperfeita

Simulação não precisa ser robótica.

Permitir jitter pequeno configurável:

```text
arrive 2 min early
arrive 3 min late
```

mas debug deterministicamente reproduzível.

### UI de debug/demo

Criar appointment por formulário simples:

```text
Quem?
Quando?
Onde?
Tipo?
```

Isso será ferramenta central para testar os sistemas antes de agenda real.

### Aceite

- appointment futuro aparece em debug timeline;
- pre-event preparation dispara;
- participantes se tornam presentes no período;
- evento termina e pawns deixam o contexto;
- source claramente `simulated/manual`;
- screenshot: `m19_appointment.png`.

---

## M20 — Remote presence / chamadas ✅

**Resultado:** presença social pode existir sem materializar a outra pessoa fisicamente no room.

### PresenceMode

```text
physical
voiceCall
videoCall
textConversation
```

Nesta milestone implementar pelo menos `voiceCall`.

### Call affordance

Device phone/computer pode oferecer:

```text
startCall
answerCall
continueCall
endCall
```

### Representação

Pawn local:
- pega/usa phone;
- senta ou anda lentamente;
- speech bubbles;
- portrait/icon do outro participante em UI discreta.

PersonProxy remoto:
- **não** precisa existir como Flame pawn no mapa;
- pode ser representado por `RemoteParticipantState`.

### Social consequences

Call pode gerar:

```text
shared memory
relationship familiarity delta
socialConnection satisfaction
socialTolerance consumption
```

### Futuro

Um CalendarEvent de video call poderá mapear para o mesmo appointment/presence mode.

### Aceite

- call simulada funciona sem spawn físico do convidado;
- interrompível;
- social systems recebem eventos;
- screenshot: `m20_remote_presence.png`.

---

## M21 — Shared Planned Activities ✅

**Resultado:** compromissos conseguem compor atividades coletivas existentes em vez de virar cutscenes especiais.

### Definição

Criar camada fina:

```text
PlannedActivityRequest
```

Exemplo:

```text
Appointment: gameNight
→ PlannedActivityRequest(kind: boardgame, minParticipants: 2)
```

Outro:

```text
Appointment: dinner
→ prepareMeal
→ sharedMeal
→ conversation opportunities
```

### Fallbacks

Se affordance principal não estiver disponível:

```text
boardgame missing
→ social hangout fallback
```

Se seating insuficiente:

```text
partial standing formation
ou
simplified activity
```

Não travar appointment.

### Planned ≠ forced

Durante appointment:
- activity ganha utility alta;
- participants reservam tempo;
- ordens manuais continuam superiores.

### Event composition

Appointment pode possuir fases:

```text
arrival
warmup
primary activity
free social
winddown
departure
```

Cada fase usa sistemas genéricos.

### Aceite

- dinner/hangout/gameNight compostos sem cutscene;
- fallback funciona quando prop falta;
- manual command interrompe;
- screenshot: `m21_planned_activity.png`.

---

# 12. Fase E — mundo, sites, rooms e contexto

---

## M22 — `HabitatSite` + `HabitatRoom` ✅

**Resultado:** “local” deixa de significar apenas um mapa. O world distingue sites de rooms.

### Conceitos

```text
HabitatWorld
└─ HabitatSite
   └─ HabitatRoom
```

Exemplo:

```text
Site: home_apartment
├─ bedroom
├─ bathroom
├─ kitchen
├─ living_room
└─ studio

Site: generic_cafe_01
└─ main_room
```

### `HabitatSite`

```dart
class HabitatSite {
  final String id;
  final String name;
  final HabitatSiteKind kind;
  final String timezoneId;
  final Set<String> roomIds;
  final SiteEnvironmentProfile environment;
}
```

Kinds seed:

```text
home
work
university
gym
studio
cafe
restaurant
bar
park
library
hotel
airport
transport
travelDestination
friendHome
custom
```

### `HabitatRoom`

```text
id
siteId
name
semanticRole
bounds / cells
portalIds
contextProfileId
environmentProfileId
```

### Regra

`Room` é espaço navegável/semântico.

`Site` é contexto de localização maior.

Não misturar novamente.

### Migração

Os mapas atuais Quarto/Escritório/Cozinha/Terraço podem temporariamente virar:

```text
Site: Demo Home
rooms independentes
```

ou rooms do mesmo site conforme arquitetura atual permitir.

### Aceite

- world contém ≥2 sites;
- home contém ≥3 rooms;
- timezone pertence ao site;
- pawn position referencia `siteId + roomId`;
- screenshot: `m22_sites_rooms.png`.

---

## M23 — Home / Away / Transit ✅

**Resultado:** o pawn pode não estar em casa e isso é estado real da simulação.

### `PawnPresenceLocation`

```text
atSite
leaving
inTransit
arriving
away
unknown
```

### Transit episode

```dart
class HabitatTransitEpisode {
  final String originSiteId;
  final String destinationSiteId;
  final double startAt;
  final double expectedArrivalAt;
  final TransitMode mode;
}
```

Modes seed:

```text
walk
car
publicTransit
train
plane
abstract
```

Não precisa renderizar veículo.

### Saída

```text
pawn reaches exit portal
→ leaving
→ disappears from origin site
→ inTransit
```

### Chegada

```text
transit completes
→ arriving
→ pawn materializes at destination entrance
```

### Casa vazia

Quando primary pawn está away:
- não clonar ele dentro de Home;
- residents/pets podem continuar;
- ambiente Home continua simulando conforme LOD.

### Away state

Se destino não possui site materializado:

```text
away
```

é válido.

### Aceite

- pawn sai de Home e deixa de estar lá;
- transit tem duração;
- chega a outro site;
- câmera pode continuar em Home vazia;
- screenshot: `m23_home_away.png`.

---

## M24 — Context Profiles de site/zona ✅

**Resultado:** locais diferem funcionalmente, não apenas visualmente.

A spec mestre já prevê zonas com capabilities, required items, connectivity, noise e privacy. Criar equivalente representacional no Habitat.

### Modelo

```dart
class HabitatContextProfile {
  final Set<String> capabilities;
  final Set<String> unavailableActivityTags;
  final Set<String> usefulItemTags;
  final ConnectivityProfile connectivity;
  final NoiseProfile noise;
  final PrivacyProfile privacy;
  final SocialDensityProfile socialDensity;
}
```

### Capabilities seed

```text
sleep
cook
shower
workDesk
musicPractice
exercise
outdoorWalk
privateCall
groupSocial
read
internet
charging
```

### Connectivity

```text
offline
poor
normal
fast
```

Ainda puramente simulado.

### Noise

```text
silent
quiet
normal
busy
loud
```

### Privacy

```text
private
semiPrivate
shared
public
```

### Uso

ChoiceScorer pode avaliar:

```text
focus activity
+ quiet
+ privacy
```

Call pode evitar:

```text
public + loud
```

Pawns podem ter preferências diferentes.

### Exemplo avião futuro

Já deve ser representável como:

```text
connectivity = offline
noise = busy
privacy = shared
capabilities = read, offlineNotes, sleepLight
```

sem nenhum Trip real.

### Aceite

- 4 sites/rooms com context profiles diferentes;
- activity filtering usa capabilities;
- noise/privacy alteram pelo menos 3 scores;
- screenshot: `m24_context_profiles.png`.

---

## M25 — Conforto percebido individual ✅

**Resultado:** o score genérico de room continua existindo, mas diferentes pawns percebem o mesmo ambiente de forma diferente.

### Separar

```text
ObjectiveRoomMetrics
```

já existentes/derivados:

```text
beauty
space
cleanliness
light
temperature
quality
```

De:

```text
PerceivedEnvironmentFit(pawn, room)
```

### Preferências ambientais

Adicionar:

```text
lightPreference
noisePreference
privacyPreference
crowdingTolerance
outdoorPreference
warmthPreference
orderPreference
cozinessPreference
```

### Exemplo

```text
Room objective comfort = 78

Pawn A:
likes bright/open/active
→ perceived = 86

Pawn B:
likes quiet/dim/cozy
→ perceived = 67
```

### Escolhas

Perceived fit pode alterar:
- wander target;
- onde sentar;
- onde trabalhar;
- onde ficar sozinho;
- room favorite habit.

### Não duplicar beauty

A beauty objetiva existente continua sendo input.

### Aceite

- dois pawns avaliam mesmo room diferentemente;
- escolha de room muda por preference;
- debug mostra objective vs perceived;
- screenshot: `m25_perceived_comfort.png`.

---
# 13. Fase F — editor de mundo e criação rápida de ambientes

---

## M26 — Editor estrutural de rooms ✅

**Resultado:** criar um novo ambiente deixa de exigir montar um mapa tile por tile; o usuário desenha estrutura espacial de forma rápida.

O editor cosmético do `07` continua válido, mas esta milestone introduz ferramentas estruturais.

### Ferramentas mínimas

```text
Draw Room
Draw Wall
Erase Wall
Place Door
Place Window
Paint Floor
Resize Room
Move Room Boundary
```

### Draw Room

Usuário arrasta retângulo/polígono simples.

Sistema cria:

```text
floor cells
perimeter walls
room candidate
walkability
roof default
```

Não exigir suporte a formas arbitrárias complexas inicialmente.

### Wall tool

Permitir brush/drag horizontal/vertical.

### Door/window

Snapping obrigatório em wall segments válidos.

Door deve atualizar:
- walkability;
- portals;
- room adjacency.

Window:
- não walkable;
- afeta iluminação/ambiente;
- futura affordance lookOutside.

### Grid validation live

Ghost deve mostrar:

```text
valid
blocked
would disconnect
out of bounds
```

### UX mobile

- touch target maior que tile visual;
- drag com preview;
- dois dedos continuam reservados para câmera quando tool permitir;
- toolbar inferior clara.

### Aceite

- criar room vazio em <30 s;
- adicionar porta e janela;
- pathfinding atualiza sem reload;
- resize não corrompe props silenciosamente;
- screenshot: `m26_structural_editor.png`.

---

## M27 — Auto-detecção + semântica de cômodo ✅

**Resultado:** paredes/portas produzem rooms lógicos automaticamente e o sistema entende seu papel sem exigir configuração detalhada.

### Detecção

Após structural change:

```text
flood fill / region detection
→ enclosed regions
→ candidate HabitatRoom
```

Usar dirty update, não recalcular mapa inteiro por frame.

### Identidade de room

Tentar preservar `roomId` em pequenas edições.

Não gerar ID novo toda vez que uma parede muda um tile.

Heurística:
- maior overlap de cells;
- existing anchor;
- manual room identity vence.

### Semantic role

Expandir room roles atuais:

```text
bedroom
bathroom
kitchen
livingRoom
diningRoom
office
studio
library
gym
hallway
storage
balcony
terrace
outdoor
custom
```

Inferência por props é **sugestão**, não verdade imutável.

### UI

Quando novo room detectado:

```text
Novo cômodo
Sugestão: Escritório
[Confirmar] [Trocar]
```

ou aplicar silenciosamente suggestion e permitir rename no inspect, conforme UX.

### Semantic coverage

Mostrar opcionalmente:

```text
STUDIO
✓ sentar
✓ música
✓ iluminação
! sem storage
! sem superfície de apoio
```

Não usar como “erro”; apenas capacidade do room.

### Validação

Antes de sair do edit mode:
- entrance acessível;
- rooms importantes conectados;
- spawn válido;
- props não presos;
- station approach cells válidas.

### Aceite

- room detectado automaticamente;
- `roomId` preservado em edição simples;
- semantic role sugerido por props;
- capability coverage visível;
- screenshot: `m27_room_detection.png`.

---

## M28 — Command Stack + prefabs + blueprints ✅

**Resultado:** edição se torna robusta, reversível e reutilizável.

### Command Stack

Toda mutação estrutural/editável deve caminhar para commands:

```text
PlacePropCommand
MovePropCommand
DeletePropCommand
PaintFloorCommand
BuildWallCommand
RemoveWallCommand
PlaceDoorCommand
ResizeRoomCommand
ApplyPrefabCommand
ApplyBlueprintCommand
```

Interface:

```text
execute()
undo()
redo()
```

### Undo/redo

- múltiplos níveis;
- sessão atual;
- command composto para drag/paint longo;
- evitar 1 undo por tile em brush contínuo.

### Prefabs

Criar conjuntos:

```text
Dining Set
TV Corner
Music Corner
Workstation
Reading Nook
Bedroom Set
Conversation Area
Kitchen Basics
```

Prefab guarda:

```text
relative positions
rotations
prop definitions
optional floor patch
affordance expectations
```

### Placement

- ghost do conjunto;
- bounding box;
- collision validation;
- rotate whole group;
- depois de colocado, entidades voltam a ser independentes.

### Blueprint

Mais amplo que prefab:

```text
walls
floor
rooms
props
zones
lighting
scene configuration
```

Operações:

```text
Save as Blueprint
Duplicate
Apply to empty site
Delete
```

Export/import de arquivo pode ficar para M42/M43.

### Aceite

- undo/redo de 10 ações;
- prefab coloca grupo coerente;
- blueprint duplica room/site;
- IDs internos remapeados sem colisão;
- screenshot: `m28_prefab_blueprint.png`.

---

## M29 — Auto-furnish + geração procedural de sites ✅

**Resultado:** o Habitat consegue gerar lugares funcionais rapidamente usando constraints, sem IA generativa.

### Auto-furnish

Entrada:

```text
roomRole
bounds
style seed
budget/density simbólicos
required capabilities
```

Saída:

```text
valid prop layout
```

### Regras espaciais

Exemplos:

```text
bed requires free approach cell
TV needs viewer slots
chairs around table need path
work desk should not block door
window should retain approach cell if lookOutside exists
kitchen counter needs working side
```

### Solver

Não precisa solver matemático sofisticado inicialmente.

Pipeline possível:

```text
1. place anchors
2. reserve circulation
3. place required capability props
4. place complementary props
5. decorate
6. validate paths
7. retry with seed N+1 if invalid
```

Seed determinística.

### Gerar site

Wizard:

```text
Tipo: Café
Tamanho: Médio
Estilo: Warm
Capacidade social: 6
Seed: random
```

Template define rooms mínimos.

Exemplos:

```text
cafe:
  mainRoom
  counterZone

hotel:
  bedroom
  bathroom

apartment:
  bedroom
  bathroom
  livingKitchen
```

### Variação

Variar:
- palette;
- prop variants;
- room proportions;
- decoration;
- light preset.

Não criar layout impraticável só por variedade.

### Regenerate

Usuário pode:

```text
Regenerate
Keep layout, change decor
Keep rooms, rearrange furniture
```

### Aceite

- gerar 3 site kinds;
- 10 seeds válidas por kind em teste;
- A* alcança todas stations obrigatórias;
- regenerate é determinístico por seed;
- screenshot: `m29_generated_site.png`.

---

## M30 — Scene Presets + ambiente stateful ✅

**Resultado:** o mesmo site pode assumir configurações contextuais diferentes sem duplicar mapa.

### `ScenePreset`

```dart
class ScenePreset {
  final String id;
  final String siteId;
  final Map<String, Object?> propStates;
  final String lightingPreset;
  final String? ambientAudioPreset;
  final Set<String> enabledDecorIds;
  final Map<String, double> affordanceModifiers;
}
```

Presets seed:

```text
normal
quietEvening
movieNight
gameNight
guests
party
sleepMode
morning
```

### Aplicação

Não teletransportar props grandes por default.

Preferir alterar:
- lights;
- screens;
- music;
- small decor;
- table setup;
- available affordances;
- ambience.

Se preset mover mobília, deve usar commands/state transitions explícitos.

### Stateful environment

Formalizar estados:

```text
door open/closed
window open/closed
lamp on/off
TV on/off
speaker playing/stopped
computer active/sleep
shower on/off
stove on/off
curtain open/closed
```

### Vestígios

Não resetar tudo ao terminar activity.

Exemplo:

```text
movie night termina
→ TV pode permanecer ligada
→ cups permanecem na mesa
→ chairs permanecem onde foram movidas, se activity moveu
```

Aftermath é parte da sensação de vida.

### Futuro

Appointment real poderá apenas solicitar `ScenePreset.guests` ou `party`.

### Aceite

- 4 presets;
- preset altera ao menos luz + 2 props;
- environment states persistem durante a sessão;
- ritual pode acionar preset/estado sem integração externa;
- screenshot: `m30_scene_preset.png`.

---

# 14. Fase G — roupa, objetos, dispositivos e rotinas

---

## M31 — Loadouts contextuais ✅

**Resultado:** roupas e pequenos equipamentos visuais acompanham o contexto da simulação.

A spec 05 já prevê loadouts; aqui implementamos a versão autônoma antes de qualquer agenda real.

### `HabitatLoadout`

```text
id
label
visualLayers
held/visibleEquipmentTags
contextTags
weatherTags
siteTags
priority
```

Seed:

```text
home
sleep
work
study
exercise
socialCasual
socialFormal
travel
outsideCold
outsideHot
```

### Resolver

```text
current Context
+ Site
+ Environment
+ Appointment type
+ Condition
→ suggested loadout
```

### Auto-apply policy

```text
off
suggest
autoSimulated
```

Dentro do Habitat autônomo, `autoSimulated` pode ser default para NPCs. Primary pawn pode ser configurável.

### Troca de roupa

Não fazer instantaneamente em qualquer lugar.

Preferir:

```text
go to wardrobe / bedroom
→ short change pose
→ layer swap
```

Fallback debug instantâneo permitido.

### Aceite

- 5 loadouts;
- bedtime muda para sleep loadout;
- leaving context pode mudar roupa;
- loadout visual não altera identity;
- screenshot: `m31_loadouts.png`.

---

## M32 — Storage + inventory virtual robusto ✅

**Resultado:** objetos pequenos possuem localização lógica e podem viver em storage, superfície, pawn ou chão.

Esta milestone aprofunda stateful objects do Habitat Alive para preparar representação futura de Inventory sem importar `features/inventory`.

### `HabitatItemLocation`

```text
heldByPawn
storageSlot
surfaceSlot
floorCell
transit
unknown
```

### Containers

Props podem declarar:

```text
StorageComponent
capacity
acceptedItemTags
slots
```

Seed:

```text
wardrobe
drawer
bookshelf
recordShelf
fridge
cabinet
chest
deskDrawer
bag
```

### Operações

```text
pickUp
putIn
removeFrom
placeOn
giveTo
returnToPreferredStorage
```

Todas via intents/events.

### Preferred home

Um item pode possuir:

```text
preferredStorageId
```

Pawn organized/neat tem maior chance de devolver.

### Bag

Bag é container carregável.

Isso prepara saída de casa.

### Consistência

Invariantes:

```text
item em exatamente 1 location
slot contém no máximo 1 item se single-slot
holder existente
no duplicated item IDs
```

### Aceite

- item vai shelf → hand → table → bag;
- restart local futuro-ready;
- item nunca duplica;
- screenshot: `m32_storage.png`.

---

## M33 — Devices + atenção + interrupção/retomada ✅

**Resultado:** phone/computer/TV/speaker deixam de ser props genéricos e atividades longas conseguem ser interrompidas e retomadas.

### Device component

```text
phone
computer
tablet
TV
speaker
headphones
console
```

Estado comum:

```text
power
activeMode
currentMediaId?
currentUserPawnId?
```

### Affordances

```text
usePhone
call
watch
listen
playGame
workAtComputer
browseSimulated
```

`browseSimulated` é flavor — não acessar internet.

### Attention capacity

Adicionar componente operacional:

```text
sustainedAttention
```

pode ser parte de Focus capacity.

Atividade longa declara:

```text
attentionLoad
naturalBreakInterval
interruptibility
resumeToken
```

### Pausar/retomar

Estados:

```text
active
paused
interrupted
resumable
abandoned
completed
```

Exemplo:

```text
reading
→ visitor arrives
→ bookmark/progress preserved
→ greet
→ later resume
```

Outro:

```text
piano
→ call arrives
→ stop
→ call
→ optionally return
```

### Resume candidate

Após interrupção, guardar por janela limitada:

```text
ResumeIntentCandidate
```

ChoiceScorer recebe bônus para retornar, sem obrigar.

### Aceite

- leitura interrompe e retoma;
- device possui estado;
- call interrompe atividade elegível;
- manual draft continua superior;
- screenshot: `m33_interrupt_resume.png`.

---

## M34 — `BehaviorRoutine` Engine ✅

**Resultado:** comportamentos compostos deixam de ser scripts especiais e viram grafos reutilizáveis de passos.

### Motivação

Ações isoladas não bastam para representar:

```text
acordar
preparar-se para dormir
sair de casa
chegar em casa
receber visita
cozinhar refeição
```

Criar engine de rotinas.

### Modelo

```dart
class BehaviorRoutineDefinition {
  final String id;
  final List<RoutineNode> nodes;
  final List<RoutineEdge> edges;
  final Set<String> tags;
}
```

Node types:

```text
affordance
wait
condition
branch
reserve
changeLoadout
collectItem
travel
emitEvent
```

### Runtime

```text
RoutineInstance
currentNode
status
startedAt
context
completedNodes
```

Status:

```text
pending
running
paused
cancelled
completed
failed
```

### Delegação

Routine não move pawn diretamente.

```text
Routine node: use shower
→ cria intent/affordance request
→ ActionSystem executa
→ event completa node
```

### Branch

Exemplo:

```text
if shower unavailable
→ washFace fallback
```

### Cancelamento

Manual order:
- pausa ou cancela conforme routine policy.

Nunca prender pawn.

### Debug

Visualizar grafo simples + current node.

### Aceite

- rotina com 5+ steps;
- branch/fallback;
- pause/resume;
- timeout por step;
- screenshot: `m34_routine_engine.png`.

---

## M35 — Rotinas acordar, dormir e self-care ✅

**Resultado:** o pawn começa e termina o dia através de sequências físicas convincentes.

### Morning routine

Seed:

```text
wake
→ sleep inertia
→ sit on bed
→ bathroom
→ wash face / shower optional
→ change clothes
→ kitchen / drink
→ natural light / window optional
→ first free activity
```

Não precisa ser sempre idêntica.

Traits/preferences podem alterar:
- banho imediato;
- café;
- janela;
- silêncio;
- música.

### Bedtime routine

```text
notice sleep readiness
→ wind down
→ stop stimulating activity
→ bathroom/self-care optional
→ sleep loadout
→ dim personal lights
→ bed
→ sleep episode
```

### Bathroom affordances

Adicionar conforme assets permitirem:

```text
shower
washFace
brushTeeth
mirror
changeClothes
```

Não criar “hygiene shame bar”.

### Self-care state

Pode ser apenas rotina e affordance; não exige Need `hygiene`.

### Relação futura com Ignition

Essas sequências são representação física compatível com futuras rotas de morning launch/banho, mas não importam Ignition.

### Aceite

- morning routine executa ponta a ponta;
- bedtime routine termina em sleep;
- bathroom existe como semantic room/capability;
- variação entre pawns;
- screenshot: `m35_morning_bedtime.png`.

---

## M36 — Leaving / Arriving Home ✅

**Resultado:** sair e voltar viram sequências físicas compostas, base para metade das integrações futuras.

### `PrepareToLeaveRoutine`

```text
appointment/context chosen
→ choose loadout
→ collect required items
→ optional last check
→ go to entrance
→ exit
→ transit
```

### `ArriveHomeRoutine`

```text
enter
→ optional greeting resident/pet
→ place bag
→ place keys/items
→ change context
→ optional change clothes
→ short decompression
→ autonomous activity
```

### Door/entry station

Formalizar:

```text
PrimaryEntrance
DropZone
```

DropZone pode aceitar:

```text
keys
wallet
bag
coat
```

### Departure failure

Se item requerido não existe:

```text
mark missing
continue if optional
cancel/ask fallback only if required by simulated appointment
```

Sem modal infinito.

### Aceite

- appointment dispara prepare-to-leave;
- pawn coleta item + troca loadout + sai;
- return executa drop-zone;
- manual cancel recupera estado;
- screenshot: `m36_departure.png`.

---

## M37 — Food + cooking + shared meals ✅

**Resultado:** cozinha vira um sistema social/material completo, não apenas room role.

### Food need

Usar `Need.food` da M5.

### Entidades

```text
FoodItem
Ingredient
Dish
RecipeDefinition
MealInstance
```

Não precisa nutricionalmente preciso.

### Recipe

```text
id
title
requiredStationTags
ingredientTags
steps
duration
interestTags
servings
```

### Stations

```text
fridge
counter
stove
sink
table
```

### Cooking activity

```text
collect ingredients
→ prep counter
→ cook
→ dish ready
→ serve/place
```

Simplificar visualmente conforme assets.

### Shared cooking

Possível group activity:
- cook together;
- one cooks, others wait/talk;
- someone sets table.

### Meal

```text
MealActivity
participants
servings
seating
conversation context
```

Food preference usa InterestTaxonomy:

```text
food.italian
food.japanese
coffee
```

### Cleanup

Aftermath:
- dishes/cups aparecem;
- filth/cleaning existing systems podem reagir;
- não obrigar limpeza imediata.

### Aceite

- pawn prepara ao menos 2 dishes simulados;
- meal satisfaz food need;
- shared meal suporta 2+ pawns;
- aftermath físico;
- screenshot: `m37_shared_meal.png`.

---

## M38 — Workpieces persistentes ✅

**Resultado:** pawns podem trabalhar em algo por várias sessões, criando continuidade de longo prazo sem Projects reais.

### `HabitatWorkpiece`

```text
id
kind
title
progress 0..1
stage
stationRequirement
interestTags
ownerPawnId?
collaborators[]
state data
```

Kinds seed:

```text
painting
songComposition
model
craft
gardenPlot
writingPiece
puzzle
```

### Stages

Exemplo painting:

```text
blank
sketch
base
-detail
finished
```

### Activity

```text
workOn(workpiece)
```

usa:
- creative need;
- focus capacity;
- interests;
- station.

### Visual progress

Sempre que possível, prop muda sprite/tint/overlay por stage.

### Collaboration

Alguns workpieces podem aceitar 2 pawns, mas não obrigatório no MVP.

### Futuro

Um Project real poderá possuir representation binding para workpiece, mas essa integração não existe agora.

### Aceite

- progress sobrevive a múltiplas activities;
- stage visual muda;
- pawn pode abandonar e voltar;
- finished gera Chronicle/Memory candidate;
- screenshot: `m38_workpiece.png`.

---

## M39 — Preparation Requirements / loadout físico ✅

**Resultado:** compromissos e contextos conseguem declarar o que deve acompanhar o pawn, usando o inventory virtual.

### `PreparationRequirement`

```text
itemTag
required / optional
quantity
preferredStorage
reasonTag
```

Exemplos:

```text
work:
  laptop
  bag

music:
  instrument
  score

travel:
  passport
  suitcase

exercise:
  trainingClothes
  waterBottle
```

### Resolver

```text
Appointment/Site/Activity
→ RequiredPreparationSet
→ find matching HabitatItems
→ build collection plan
```

### Collection plan

Ordenar por path cost simples para evitar andar aleatoriamente pela casa.

### Missing

Representar:

```text
found
missing
optionalMissing
alreadyPacked
```

### Não duplicar Inventory real

Esses são itens virtuais do Habitat.

Futuro adapter poderá mapear item real para representation.

### Aceite

- departure recolhe 3 itens de storages diferentes;
- bag recebe itens;
- missing não crasha;
- inspect mostra por que item foi selecionado;
- screenshot: `m39_preparation.png`.

---
# 15. Fase H — viagem, mundo abstrato e mudança de contexto

---

## M40 — Travel Context + timezone + jet lag ✅

**Resultado:** o Habitat consegue representar deslocamento entre fusos e estadias temporárias sem depender do módulo Travel.

A spec mestre já prevê trips com sequência de timezones; esta milestone implementa apenas a capacidade representacional.

### `HabitatTravelContext`

```dart
class HabitatTravelContext {
  final String id;
  final String originSiteId;
  final List<String> destinationSiteIds;
  final List<String> timezoneSequence;
  final double startsAt;
  final double endsAt;
  final Set<String> participantPawnIds;
  final MirrorSignalSource source;
}
```

Hoje criado manualmente/debug.

### Site timezone

Ao entrar em site de outro timezone:
- SceneClock usa hora local do site;
- appointments daquele site usam timezone explicitamente;
- circadian system mantém uma referência corporal separada para permitir transição.

### Circadian offset / jet lag

Modelo simples:

```text
bodyClockOffset
siteClockOffset
adaptationProgress
```

Não criar modelo médico.

Consequências cosméticas:
- sleepiness em horários estranhos;
- wake time deslocado;
- nap utility ↑;
- fatigue condition;
- adaptação gradual.

### Travel loadout

Pode solicitar:

```text
travel loadout
suitcase
passport-like virtual item
```

Apenas simulado.

### Hotel

Site temporário pode ser `hotel` com:
- bed;
- bathroom;
- limited storage;
- temporary ownership semantics.

### Transit longo

Plane/Train podem usar abstract Site `transport`:
- seats;
- noise;
- limited capabilities;
- offline connectivity;
- sleep/read/listen affordances.

### Aceite

- troca São Paulo → timezone distante em debug;
- SceneClock muda;
- body clock não salta instantaneamente;
- pawn exibe jet-lag behavior leve;
- hotel/transit site funcional;
- screenshot: `m40_travel_jetlag.png`.

---

## M41 — Abstract Sites + World Map ✅

**Resultado:** o Habitat não precisa de um mapa artesanal para cada lugar possível.

### Três níveis de site

```text
Custom Site
  feito/editado pelo usuário

Generated Site
  gerado por template/seed

Abstract Site
  representação mínima de um contexto
```

### Abstract Site

Pode possuir apenas:

```text
kind
name
contextProfile
environmentProfile
small generic room/layout
```

Exemplos:

```text
Generic Café
Generic Restaurant
Generic Office
Generic Classroom
Generic Airport Lounge
Generic Hotel
Generic Train
```

### World Map

Criar UI diegética simples:

```text
HOME
├─ WORK
├─ UNIVERSITY
├─ GYM
├─ CAFÉ
├─ PARK
└─ OTHER
```

Não precisa mapa geográfico.

### Viagem manual

No debug/produção sandbox:
- selecionar site;
- `Go here`;
- pawn prepara/sai/transita/chega.

Isso ajuda a testar toda a cadeia sem agenda/location real.

### Site materialization

Se appointment aponta para kind sem site existente:

```text
SiteFactory
→ generated/abstract site
```

Persistir se usuário personalizar depois.

### Aceite

- 6 abstract site kinds;
- world map navegável;
- appointment pode materializar site automaticamente;
- customização promove generated/abstract para saved custom site;
- screenshot: `m41_world_map.png`.

---

# 16. Fase I — conteúdo data-driven e extensibilidade

---

## M42 — Data-driven content definitions ✅

**Resultado:** adicionar objetos, atividades, mídia e recipes não exige editar switch statements espalhados.

### Definitions separadas de instances

```text
PropDefinition
ItemDefinition
AffordanceDefinition
ActivityDefinition
MediaDefinition
RecipeDefinition
SiteTemplateDefinition
ScenePresetDefinition
RoutineDefinition
```

Instances possuem IDs e state.

### Fonte

Inicialmente:
- Dart const;
- JSON assets locais somente se simplificar hot content.

Não criar plugin engine completa.

### Registry

```text
HabitatContentRegistry
```

APIs:

```text
getPropDefinition(id)
getAffordancesForTags(tags)
getActivityDefinition(id)
validateDefinition(...)
```

### Validation

No boot/test:
- IDs únicos;
- tags conhecidas ou registradas;
- asset path existente;
- referenced affordance existe;
- required slots coerentes;
- localization key existe quando obrigatório.

### Exemplo: saxophone

Idealmente adicionar um novo instrumento exige algo próximo de:

```yaml
id: saxophone_alto
kind: prop
asset: ...
tags: [music, instrument, saxophone]
affordances: [practice_instrument, perform_music]
interest_tags: [music, music.jazz]
```

sem código `if saxophone`.

### Aceite

- adicionar novo prop funcional via definition;
- validation detecta reference quebrada;
- registry usado por editor + sim;
- screenshot opcional: `m42_content_registry.png`.

---

## M43 — Custom Object / Activity Creator ✅

**Resultado:** o usuário consegue criar conteúdo seguro compondo primitivas existentes, sem scripting arbitrário.

### Custom object

Wizard:

```text
Nome
Sprite/visual disponível
Categoria
Tags
Cor/tint
Affordances compatíveis
Interest tags
```

Exemplo:

```text
Minha Guitarra
Tags: music, instrument, guitar, personal
Affordance: practiceInstrument
Interest: music
```

### Segurança

Usuário não escreve Dart/JS.

Seleciona de capabilities registradas.

### Custom Activity

Composer:

```text
Nome
Target tags
Duração
Participants
Need effects
Capacity requirements
Interest tags
Presentation preset
```

Exemplo:

```text
Ouvir vinil
requires: recordPlayer
participants: 1..4
tags: music, listening
satisfies: recreation, creativeExpression(light)
```

### Validação

Bloquear:
- duration inválida;
- efeito fora de range;
- recursive activity;
- missing target;
- direct mutation insegura.

### Export futuro

Guardar definitions locais em formato versionado. Sharing multiplayer fica fora.

### Aceite

- usuário cria 1 prop custom funcional;
- cria 1 activity custom;
- restart preserva;
- invalid definition mostra erro recuperável;
- screenshot: `m43_custom_content.png`.

---

# 17. Fase J — portas explícitas para integrações futuras

---

## M44 — Future Binding Ports ✅

**Resultado:** as futuras integrações possuem interfaces claras para entregar sinais ao Habitat, mas nenhuma implementação externa existe ainda.

### Regra

Criar **ports**, não adapters.

### Ports sugeridos

```dart
abstract interface class HabitatSleepSignalPort {
  List<MirrorSignal<HabitatSleepEpisode>> readSleepSignals(String pawnId);
}

abstract interface class HabitatPresenceSignalPort {
  List<MirrorSignal<HabitatPresenceObservation>> readPresence(String pawnId);
}

abstract interface class HabitatAppointmentPort {
  List<MirrorSignal<HabitatAppointment>> readAppointments(String pawnId);
}

abstract interface class HabitatInterestPort {
  List<MirrorSignal<PreferenceReading>> readPreferences(String pawnId);
}

abstract interface class HabitatEnvironmentPort {
  EnvironmentSignalBundle readEnvironment(String siteId);
}
```

Outros possíveis:

```text
ActivitySignalPort
InventoryRepresentationPort
MediaCatalogPort
TravelContextPort
DeclaredTraitPort
```

### Implementações nesta milestone

Somente:

```text
Simulated*
ManualDebug*
Null*
```

Exemplo:

```text
SimulatedSleepSignalPort
NullAppointmentPort
ManualInterestPort
```

### Não importar módulos reais

O port pertence à fronteira Habitat.

Futuro adapter pode existir em integration layer:

```text
HealthConnectSleepAdapter implements HabitatSleepSignalPort
```

mas **não agora**.

### Contract tests

Cada port possui contract tests para:
- provenance;
- timestamps;
- invalid signal;
- duplicates;
- sensitive flag.

### Aceite

- ports compilam sem módulos externos;
- Habitat roda somente com simulated/null implementations;
- trocar source no debug não muda consumer code;
- screenshot opcional: `m44_binding_ports.png`.

---

## M45 — Privacidade e consentimento de `personProxy` ✅

**Resultado:** a arquitetura impede que um pawn de outra pessoa seja tratado como fonte de dados íntimos do usuário principal.

### Princípio

O Fallhub pode saber coisas **sobre a relação do usuário com alguém** sem fingir saber o estado privado da outra pessoa.

### `ProxyDataScope`

```text
identity
appearance
knownInterests
relationshipContext
scheduledPresence
sharedMemories
publicNotes
```

Sensíveis/proibidos por default:

```text
realHealth
realSleep
realMood
realLocation
privateCalendar
privateDeviceState
```

### Consent scope futuro

Criar campo conceitual:

```text
consentScopes[]
```

mas nenhum fluxo multiplayer ainda.

### Person-proxy embodied state

Por default usa **simulação ficcional** apenas para comportar-se como NPC.

UI/debug deve ser capaz de dizer:

```text
Sleepiness: simulated character state
```

Nunca:

```text
“Fulano dormiu mal”
```

### Relationship simulation

RelationshipGraph do Habitat continua sendo mecânica interna, não “qualidade real da amizade”.

### Logging

Sensitive MirrorSignals:
- não em logs;
- debug redacted por default;
- snapshots de screenshot não exibem detalhes.

### Aceite

- tests impedem signal pessoal em proxy sem scope;
- labels distinguem simulated proxy state;
- relacionamento não é exportado como fato real;
- screenshot: `m45_proxy_privacy.png`.

---

## M46 — Authority Boundary / multiplayer-ready ✅

**Resultado:** tudo que foi adicionado continua compatível com uma futura simulação autoritativa remota, sem implementar networking.

Esta milestone revisa a arquitetura inteira.

### Pipeline obrigatório

```text
UI / AI local / routine / director
          ↓
      HabitatIntent
          ↓
  SimulationAuthority
          ↓
     World State
          ↓
    HabitatEvents
          ↓
Renderer / Chronicle / Memory
```

### Intents novos que devem estar cobertos

```text
SetStateOverrideIntent
UseAffordanceIntent
JoinActivityIntent
StartRoutineIntent
CreateAppointmentIntent
TravelToSiteIntent
PlaceItemIntent
EquipLoadoutIntent
EditWorldIntent
ApplyScenePresetIntent
```

### Authority

Hoje:

```text
LocalHabitatAuthority
```

Futuro:

```text
ServerHabitatAuthority
```

### Ownership / permissions fields

Adicionar apenas onde fizer sentido:

```text
ownerId?
interactionPolicy
visibility
```

Papéis conceituais:

```text
owner
resident
guest
visitor
```

### Não fazer

- websocket;
- server;
- auth;
- CRDT;
- sync real;
- matchmaking.

### Determinismo

Revalidar:
- same snapshot;
- same seed;
- same ordered intents;
- same relevant event sequence.

### Aceite

- renderer não muta truth state;
- major UI actions passam por intent;
- source IDs/actor IDs explícitos;
- snapshot serializável;
- zero networking;
- screenshot opcional: `m46_authority_debug.png`.

---

# 18. Fase K — persistência, performance e robustez

---

## M47 — Persistência local versionada ✅

**Resultado:** toda a camada Mirror-Ready sobrevive a restart sem obrigar integração prematura com schemas de domínio.

### Política

A arquitetura final do app é local-first e Drift existe no repo, mas este guia não deve criar dezenas de tabelas acopladas antes de estabilizar o modelo.

Opções aceitáveis nesta milestone:
- snapshot JSON local versionado;
- repository local específico do Habitat;
- Drift somente se já houver decisão arquitetural aprovada/ADR e o modelo estiver suficientemente estável.

### Snapshot conceitual

```text
MirrorReadyHabitatSnapshot
schemaVersion
worldSeed
clockState
pawnEmbodiedStates
preferences
behaviorProfiles
sites
rooms
itemStates
appointments
presenceEpisodes
workpieces
customContent
sceneStates
routineStates resumíveis quando seguro
```

### Não persistir

```text
animation frame
particle
bubble visível
A* open set
transient hover
camera shake
short-lived reservation expirada
```

### Migrations

Obrigatório:

```text
v1 -> v2
v2 -> v3
```

Fallback:
- dado cosmético inválido pode resetar isoladamente;
- nunca impedir app de abrir.

### Save strategy

Evitar write por frame.

Usar:
- dirty flag;
- debounce;
- lifecycle save;
- explicit save after editor commit.

### Aceite

- restart mantém estado essencial;
- migration test existe;
- snapshot corrompido tem fallback;
- write frequency medida;
- screenshot após restart: `m47_persistence.png`.

---

## M48 — Background Simulation + performance ✅

**Resultado:** múltiplos sites, needs, clocks e routines não transformam o Habitat em um consumidor de bateria.

### Regra

**Nada desta camada precisa de 60 decisões por segundo.**

### Cadências sugeridas

| Processo | Cadência |
|---|---:|
| render visible room | frame |
| movement visible | frame |
| action FSM visible | frame/timer |
| choice probe | 0.8–2.2 s |
| needs | 5–15 sim s |
| capacities derivadas | event-driven / 5–15 s |
| social probe | ~0.5–1 s |
| appointment scheduler | 5–30 s |
| story | 5–15 s |
| background room | 5–30 s |
| background site inactive | 30 s–5 min coarse |
| persistence | debounced |

### LOD

```text
LOD0 visible room
  full movement/presentation

LOD1 same active site off-camera
  coarse movement/activity

LOD2 inactive site
  event/episode approximation

LOD3 dormant
  next-interesting-time scheduling
```

### Next-interesting-time

Para sleeping pawn em site invisível:

Não:

```text
tick a cada segundo por 8 horas
```

Preferir:

```text
nextEvent = wakeCandidateAt
```

processar intervalo matematicamente.

### Need integration

Need engine deve suportar:

```text
advance(deltaSimTime)
```

sem loop de cada tick perdido.

### Performance metrics

Debug:

```text
simulation ms
choice ms
active pawns
active activities
background sites
events/sec
allocations estimate
```

### Battery principle

Quando app não está ativo:
- não manter Flame loop em background;
- reconciliar por elapsed time ao voltar.

### Aceite

- 1 home + 5 inactive generated sites;
- 8 pawns simulados;
- sem loop full-rate em sites invisíveis;
- foreground reconciliation determinística;
- profile documentado;
- screenshot: `m48_sim_profiler.png`.

---

## M49 — Soak tests + invariantes sistêmicos ✅

**Resultado:** o mundo continua coerente após dias simulados e milhares de interações.

### Headless simulator

Criar harness Dart puro:

```text
HabitatSimulationHarness
```

Capaz de:

```text
simulate 1 h
simulate 24 h
simulate 7 days
simulate 30 days coarse
```

### Invariantes

Além das já definidas no Habitat Alive:

```text
Need sempre finite e 0..1
Capacity sempre finite e 0..1
Condition intensity válida
SleepEpisode não sobrepõe outro main sleep do mesmo pawn
Pawn em no máximo 1 site físico por vez
Remote presence não duplica pawn físico
Appointment status transitions válidas
Item possui exatamente 1 localização
Bag item não existe simultaneamente no shelf
Room pertence a exatamente 1 site
Portal referencia rooms/sites existentes
Timezone válido/fallback seguro
Routine current node existe
Workpiece progress não regride sem regra explícita
PersonProxy não recebe sensitive signal sem scope
MirrorSignal winning source explicável
No reservation leak
No activity leak
No transit eterno sem fallback
```

### Distribution tests

Não testar só casos exatos.

Exemplo:

```text
music affinity alta
→ ao longo de 100 escolhas, music ocorre mais que baseline
→ mas < 90% se outras affordances válidas
```

### Scenario suites

#### 1. Sleep-deprived simulated day

```text
short sleep
→ tired
→ low energy
→ nap/rest more likely
→ next sleep earlier
```

#### 2. Social weekend

```text
3 appointments
→ visitors
→ social capacity drops
→ solitude afterwards
```

#### 3. Travel

```text
timezone jump
→ hotel
→ jet lag
→ return home
→ body clock adapts
```

#### 4. Editor stress

```text
100 random valid edit commands
→ 70 undo
→ 30 redo
→ world validates
```

#### 5. Inventory stress

```text
500 transfers
→ no duplicated/lost IDs
```

### Aceite

- 7 days simulated sem crash;
- zero invariant failure;
- seed de falha é reportada;
- suite rápida entra no CI se custo aceitável;
- suite longa pode ser tool manual.

---

## M50 — Gate final Mirror-Ready ✅

**Resultado:** o Habitat está pronto para começar a receber integrações reais **uma fonte por vez** sem remodelar suas capacidades fundamentais.

### Critérios obrigatórios

#### Estado

```text
[ ] MirrorSignal/provenance
[ ] EffectiveStateResolver
[ ] simulated/manual sources
[ ] explainability
```

#### Corpo

```text
[ ] needs
[ ] capacities
[ ] conditions
[ ] sleep/circadian
[ ] fatigue/recovery
[ ] social tolerance/solitude
[ ] stimulation/creative expression
```

#### Identidade

```text
[ ] hierarchical interests
[ ] preference source separation
[ ] behavior profile
[ ] social style
[ ] primary pawn distinction
[ ] personProxy privacy
```

#### Sociedade

```text
[ ] visitor lifecycle
[ ] presence episodes
[ ] appointments
[ ] physical + remote presence
[ ] planned shared activities
```

#### Mundo

```text
[ ] site != room
[ ] context profiles
[ ] home/away/transit
[ ] timezone
[ ] generated/abstract sites
[ ] advanced room editor
[ ] prefabs/blueprints
```

#### Materialidade

```text
[ ] loadouts
[ ] storage
[ ] bag/held items
[ ] media
[ ] devices
[ ] food
[ ] workpieces
[ ] preparation requirements
```

#### Rotina

```text
[ ] BehaviorRoutine engine
[ ] morning
[ ] bedtime
[ ] self-care
[ ] leave home
[ ] arrive home
```

#### Engenharia

```text
[ ] data-driven definitions
[ ] future binding ports
[ ] authority boundary
[ ] versioned persistence
[ ] background simulation
[ ] soak tests
```

### Demonstração final obrigatória — “Um dia sem integrações”

Criar scenario determinístico de demonstração:

```text
07:30
pawn acorda após noite simulada curta
→ groggy
→ bathroom
→ troca roupa
→ café da manhã

09:00
vai para atividade de workpiece no escritório
→ depois de muito tempo sentado sente movement pressure
→ levanta / anda / volta

12:30
cozinha e come

15:00
visitor appointment
→ prepara sala
→ visitante chega
→ conversa usa shared interests
→ ambos ouvem um álbum
→ visitante vai embora

17:30
social tolerance baixa
→ pawn escolhe ficar sozinho

19:00
movement / creative expression
→ piano ou walk conforme perfil

22:40
sleep pressure alta
→ rotina noturna
→ sleep loadout
→ cama
→ novo SleepEpisode
```

A demo precisa funcionar com:

```text
ZERO Health Connect
ZERO Agenda real
ZERO Relations real
ZERO Inventory real
ZERO GPS
ZERO API
```

Se isso for convincente, então o Habitat sabe representar a vida.

Só depois vale começar a trocar:

```text
simulated source
```

por:

```text
real authorized source
```

uma dimensão por vez.

---

# 19. Matriz de binding futuro

Esta tabela **não autoriza integração agora**. Ela documenta por que cada capacidade existe.

| Capacidade Habitat agora | Fonte atual | Fonte futura possível | O que NÃO deve mudar no futuro |
|---|---|---|---|
| SleepEpisode | simulação | Health Connect / HealthKit / manual | SleepSystem, routines, bed affordances |
| sleepPressure/fatigue | derivado local | sono observado + check-in | ChoiceScorer contracts |
| capacities | simulação | check-in / health / context | activity readiness API |
| interests | seed/manual | profile / Atlas / user declared | InterestTaxonomy |
| personality behavior | Habitat profile | traits declarados | behavior modifiers interface |
| social style | Habitat profile | configuração explícita | SocialDirector interface |
| personProxy | roster | Relations `Person` | visitor/presence lifecycle |
| appointment | manual/simulated | Agenda / Event | AppointmentDirector |
| presence | simulação | location/calendar/explicit confirmation | PresenceEpisode |
| site | editor/generated | Location / Trip | Site/Room model |
| context profile | simulação | Zone / device context | capability filtering |
| weather | simulado | weather integration | environment reactions |
| lighting | virtual | Home Assistant opt-in | lighting state / affordances |
| loadout | context simulado | agenda/travel/context | LoadoutResolver |
| HabitatItem | virtual | Inventory representation | held/storage mechanics |
| MediaItem | local seed | Atlas / Knowledge / library | media affordances |
| workpiece | simulado | Project representation | persistent activity mechanics |
| departure requirements | simulated | event/trip/inventory | preparation planner |
| TravelContext | manual | Trip | timezone / transit / jetlag representation |
| call | simulated appointment | calendar/relations | remote presence system |
| current context | simulation | agenda/location/session | ContextResolver |
| scene preset | manual/ritual | event/automation | environment state machine |

---

# 20. Arquitetura-alvo consolidada

```text
                         FUTURAS FONTES REAIS

  Health      Agenda      Relations      Atlas      Inventory
     │           │            │            │            │
     │           │            │            │            │
     └───────────┴────────────┴──────┬─────┴────────────┘
                                    │
                            FUTURE ADAPTERS
                          (NÃO IMPLEMENTAR AGORA)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     MIRROR SIGNAL LAYER                     │
│                                                             │
│ MirrorSignal<T>                                             │
│ provenance · confidence · freshness · sensitivity          │
│                                                             │
│ simulated/manual sources NOW                                │
│ external adapters LATER                                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 EFFECTIVE STATE RESOLUTION                  │
│                                                             │
│ overrides · conflict policies · declared authority         │
│                                                             │
│ EffectivePawnState                                          │
│ EffectiveEnvironmentState                                   │
│ EffectiveContext                                            │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    EMBODIED / IDENTITY                      │
│                                                             │
│ Needs        Capacities       Conditions                    │
│ Sleep        Circadian        Recovery                      │
│ Interests    Behavior         Social Style                  │
│ Presence     Context          Loadout                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    HABITAT SIMULATION                       │
│                                                             │
│ Affordances         ChoiceScorer        BehaviorRoutines    │
│ SocialDirector      ActivityDirector    StoryDirector       │
│ AppointmentDirector PresenceDirector    Rituals             │
│ Memory              Relationships       Workpieces          │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         WORLD                               │
│                                                             │
│ Sites → Rooms → Context Profiles                            │
│ Props → Items → Storage                                     │
│ Environment → Scene Presets                                 │
│ Visitors → Appointments → Transit                           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
                        FLAME / FLUTTER
```

---

# 21. Regras de resolução — o que pode espelhar o real e o que deve permanecer ficção

Nem toda variável do Habitat precisa algum dia ter uma contraparte real.

## Bons candidatos a mirror

```text
sleep episode
current timezone
calendar appointment
presence at broad site/context
weather
user-declared interests
user-declared traits
known relationship participant
active trip
selected loadout context
explicit active session
```

## Candidatos apenas derivados com cautela

```text
fatigue
energy
focus
recovery
social tolerance
readiness
```

Precisam de:
- provenance;
- confidence;
- explicação;
- possibilidade de unknown;
- sem causalidade inventada.

## Devem permanecer principalmente mecânica do Habitat

```text
favorite chair
favorite virtual room
fictional hunger timing
NPC simulated sleep
random story events
fictional pet behavior
workpiece artístico fictício
micro-habits emergentes do pawn
relationship affinity da simulação
```

Não tentar transformar toda ficção em tracking real.

---

# 22. Anti-padrões específicos

## 22.1 Criar integração antes da capacidade

Errado:

```text
Health Connect
→ temos dado de sono
→ agora inventamos o que o pawn faz com isso
```

Certo:

```text
SleepSystem já existe
→ simulated source prova comportamento
→ depois Health Connect troca source
```

---

## 22.2 Confundir inferência com fato

Errado:

```text
usuário dormiu 5h
→ usuário está cansado = fato
```

Certo:

```text
sono observado curto
→ fatigue estimate com confidence
→ representação leve
→ usuário pode corrigir no futuro
```

---

## 22.3 Deixar o pawn principal especial por `if`

Errado:

```text
if (pawn.isPlayer) health...
```

espalhado em toda engine.

Certo:

```text
IdentityBinding + eligible signal scopes
```

---

## 22.4 Modelar terceiros como se o app os monitorasse

Proibido por default:

```text
“seu amigo está cansado”
“ele está triste”
“ele está em casa”
```

PersonProxy é representação limitada da relação e presença conhecida.

---

## 22.5 Criar 50 needs

Need só entra se:
- muda escolhas;
- possui affordances de satisfação;
- produz cenas interessantes;
- tem semântica distinta.

---

## 22.6 Traits sem efeito

Se `curiosity = 0.8` não altera nenhuma decisão observável, remover até existir uso.

---

## 22.7 Transformar tudo em barra de HUD

Need/Capacity são principalmente **motor de comportamento**.

O usuário deve perceber:

```text
pawn está bocejando e indo dormir
```

antes de precisar ler:

```text
Sleep 83%
```

---

## 22.8 Fazer rotina como cutscene

Rotina deve usar affordances reais e poder falhar/interromper.

---

## 22.9 Gerador procedural sem validação

Nunca aceitar layout bonito porém sem path.

---

## 22.10 Custom content com código arbitrário

Creator compõe primitivas seguras.

Sem `eval`, script remoto ou plugins executáveis nesta fase.

---

## 22.11 Fazer background sim com Flame invisível

Sites invisíveis usam simulação lógica coarse.

---

## 22.12 Persistir componentes de renderer

Persistir state lógico, não `Component`.

---

# 23. Estrutura de arquivos sugerida — somente quando necessária

Não criar tudo antecipadamente.

Arquitetura eventual possível:

```text
lib/features/habitat/
  simulation/
    mirror/
      mirror_signal.dart
      effective_state_resolver.dart
      future_binding_ports.dart

    embodied/
      pawn_embodied_state.dart
      need_engine.dart
      capacity_engine.dart
      condition_engine.dart
      sleep_system.dart
      circadian_model.dart
      recovery_system.dart

    identity/
      interest_taxonomy.dart
      preferences.dart
      behavior_profile.dart
      social_style.dart
      identity_binding.dart

    presence/
      presence_episode.dart
      visitor_director.dart
      appointment.dart
      appointment_director.dart
      transit.dart

    world/
      habitat_world.dart
      habitat_site.dart
      habitat_room.dart
      context_profile.dart
      environment_profile.dart
      scene_preset.dart

    routines/
      behavior_routine.dart
      routine_runtime.dart
      routine_library.dart

    content/
      content_registry.dart
      prop_definition.dart
      activity_definition.dart
      media_definition.dart
      recipe_definition.dart
      site_template.dart

    inventory/
      habitat_item.dart
      storage_component.dart
      preparation_planner.dart

    debug/
      simulation_harness.dart
      state_explain.dart
      sim_profiler.dart
```

O `HabitatGame` deve apenas fazer wiring/presentation bridge, não concentrar toda essa lógica.

---

# 24. Eventos adicionais esperados

A camada do Habitat Alive já deve possuir event grammar. Esta expansão adiciona eventos como:

```text
NeedPressureChanged
CapacityChanged
ConditionApplied
ConditionExpired

SleepinessChanged
SleepRoutineStarted
SleepEpisodeStarted
SleepEpisodeEnded
PawnWoke

PresenceEpisodeStarted
VisitorArrived
VisitorLeft
AppointmentPreparationStarted
AppointmentStarted
AppointmentEnded

TransitStarted
TransitCompleted
SiteEntered
SiteLeft

LoadoutChanged
ItemPacked
ItemUnpacked
DeviceStateChanged

RoutineStarted
RoutineStepCompleted
RoutinePaused
RoutineCompleted
RoutineFailed

MealPrepared
MealStarted
MealEnded

WorkpieceProgressed
WorkpieceCompleted

ScenePresetApplied
RoomDetected
SiteGenerated

MirrorSignalReceived
EffectiveValueChanged
SignalConflictDetected
```

### Regra

Não criar evento para cada frame de need.

Emitir quando:
- banda muda;
- threshold relevante cruza;
- source muda;
- comportamento precisa reagir.

---

# 25. Threshold bands para reduzir ruído

Em vez de directors reagirem a qualquer mudança de `0.001`:

```text
0.00–0.24 low
0.25–0.49 moderate
0.50–0.74 high
0.75–1.00 veryHigh
```

Podem variar por need.

Events surgem ao cruzar bandas com histerese.

Exemplo:

```text
sleep pressure entra high em 0.60
só sai high abaixo de 0.54
```

Evita flicker decisório.

---

# 26. Histerese e estabilidade

Qualquer estado derivado que altere comportamento deve considerar histerese.

Exemplos:

```text
sleepy
hot
cold
sociallyDrained
readyForSleep
```

Sem isso:

```text
0.599 ↔ 0.601
→ condition entra/sai continuamente
```

Testes obrigatórios para thresholds importantes.

---

# 27. Filosofia visual — mostrar por comportamento

Preferir:

```text
pawn reduz luz
boceja
vai para cama
```

em vez de:

```text
⚠ SONO 82%
```

Preferir:

```text
pawn sai de grupo e vai ler
```

em vez de:

```text
SOCIAL BATTERY LOW
```

Preferir:

```text
pawn coloca disco de jazz
```

em vez de:

```text
TRAIT: LIKES JAZZ
```

Inspect existe para explicar. A cena existe para comunicar.

---

# 28. Critério de sucesso de produto

O Mirror-Ready Habitat não está pronto quando possui “todos os modelos”.

Está pronto quando o usuário consegue observar uma situação como:

> O pawn acordou tarde e ainda parecia sonolento. Fez uma rotina curta, tomou algo na cozinha e foi trabalhar num objeto que já vinha construindo. Depois de ficar muito tempo sentado, levantou e caminhou um pouco. À tarde, se arrumou porque alguém iria chegar. O visitante entrou, os dois colocaram música porque compartilham um gosto, fizeram uma refeição e conversaram. Depois que a visita foi embora, o pawn ficou um tempo sozinho no estúdio. À noite começou a diminuir o ritmo, trocou de roupa e foi dormir.

E tecnicamente isso precisa ter sido produzido por:

```text
SleepSystem
+ NeedEngine
+ CapacityEngine
+ Conditions
+ BehaviorProfile
+ Interests
+ Media
+ Presence
+ Appointment
+ ActivityDirector
+ Relationship/Memory
+ Site/Room
+ Inventory
+ Loadout
+ RoutineEngine
+ Food
```

não por:

```text
DemoDayScript.run()
```

---

# 29. Regra final

> **O Habitat deve estar preparado para refletir a vida real sem depender dela para ser vivo.**

Antes das integrações:

```text
simulação cria contexto
→ mundo reage
→ pawn parece vivo
```

Depois das integrações:

```text
vida fornece alguns sinais verdadeiros
→ o mesmo mundo reage
→ representação fica pessoal
```

A arquitetura correta é aquela em que conectar sono real, calendário, pessoas, viagens, inventário ou música **reduz a quantidade de ficção dos inputs**, mas não exige reinventar o comportamento do Habitat.

