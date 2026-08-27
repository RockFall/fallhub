# Habitat — seeds e catálogos para rechear

Lista prática do que está **parametrizado / seedado** no Mirror-Ready Habitat (MD 08) e que você precisa lembrar de **preencher com conteúdo real** depois.

Não é checklist de código — é **conteúdo**. Cada item: o que existe hoje → o que falta montar.

Fonte: `lib/features/habitat/` (simulation + flame).

---

## 1. Ações e readiness

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Affordances** (ações possíveis) | `simulation/embodied/affordance_catalog.dart` | 13 (sleep, sit, goToTable, wander, clean, recreate, stretch, terraceWalk, socialChat, listenMusic, creativeShort, watchTv, rest) | Mais ações + pesos need/capacity/satisfação |
| **Jobs** (execução no mapa) | `flame/components/pawn_job_controller.dart` | 7 (wander, sleep, sit, goToTable, goTo, clean, recreate) | Mapear cada affordance → job + duração/alvo |
| **Capacities / readiness** | `pawn_embodied_state.dart`, `capacity_engine.dart` | 7 (energy, focus, physicalReadiness, socialTolerance, creativeCapacity, decisionCapacity, recovery) | Curvas reais + o que cada ação exige |
| **Needs** | `need_engine.dart` | 10 (sleep, food, movement, rest, socialConnection, solitude, recreation, stimulation, creativeExpression, comfort) | Needs extras + taxas de crescimento |

---

## 2. Conditions (estados no pawn)

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Condition kinds** | `condition_engine.dart` / `pawn_embodied_state.dart` | ~12 (sleepy, exhausted, hungry, restless, sociallyDrained, inspired, bored, cold, hot, …) | Biblioteca completa + mote/bubble/efeito em walk |
| **Presentation** (ícone, bolha, speed) | `ConditionEngine` | Poucos mapeados | Tags visuais por condition |

---

## 3. Gostos, mídia e conversa

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Interest taxonomy** | `simulation/identity/identity.dart` | ~32 tags (music/jazz/…, film, food, travel, learning…) | Árvore grande + labels PT/EN |
| **Preferências** | `PreferenceStore.seedSimulated` | 3 prefs simuladas/pawn | Preferências reais do usuário / proxies |
| **Personalidade / estilo social** | `BehaviorProfile`, `SocialStyle` | Big-5-ish + 3 estilos | Perfis por personagem |
| **MediaItem library** | `simulation/content/habitat_media.dart` | 8 itens (álbuns, livro, filme, jogo…) | Biblioteca pessoal / Atlas |
| **Conversation topics** | `conversation_topic_graph.dart` | 14 topics + frases curtas | Corpus de tópicos + sugestões de atividade |
| **Diálogo social (SpeakUp-lite)** | `habitat_social_dialogue_pack.dart` | ~200 rules + ~50 threads | Pack grande de falas PT |
| **Tópicos/venues sociais** | `habitat_social_dialogue.dart` | 16 topics, 5 venues | Mais venues e contextos |

---

## 4. Pessoas, presença, compromissos

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Identity kinds** | `pawn_identity.dart` | self, resident, personProxy, fictional, pet | Bindings Fallhub (Person, Pet…) |
| **Presence roles** | `presence_lifecycle.dart` | resident, frequentVisitor, visitor, temporaryGuest, remoteParticipant | Padrões de visita, assento favorito |
| **Appointment kinds** | `habitat_appointment.dart` / `planned_activity.dart` | dinner, hangout, gameNight, movie (+ demo) | Catálogo: study, jam, party, call, coffee… |
| **Planned activities** | `planned_activity.dart` | Mapeamento fino dinner→mesa etc. | Fases + fallbacks por tipo |
| **Remote call modes** | `remote_call.dart` | voice / video / text | Scripts e fitness por context |
| **Transit modes** | `habitat_transit.dart` | walk, car, publicTransit, train, plane, abstract | Tempos reais entre sites |

---

## 5. Mundo, sites, cômodos, contexto

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Site kinds** | `habitat_world.dart` | 16 kinds (home, work, cafe, gym…) | Instâncias reais de sites |
| **Demo world** | `demoSites` / `demoRooms` | 2 sites, 5 rooms | Grafo multi-site completo |
| **Mapas jogáveis** | `habitat_locations.dart` | 4 (bedroom, office, kitchen, terrace) | Mais layouts |
| **Context profiles** | `context_profile.dart` | 5 (bedroom…cafe) | Profile por cômodo real |
| **Capabilities de zona** | mesmos profiles | sleep, cook, privateCall, workDesk… | Matriz capability × local |
| **Noise / privacy / density / connectivity** | enums em `context_profile.dart` | 4–5 níveis cada | Tunar por site |
| **Room roles (detecção)** | `habitat_room_stats.dart` | bedroom, dining, office, exterior, generic | Heurísticas prop→papel |
| **Conforto percebido (eixos)** | `perceived_comfort.dart` | 8 eixos (light, noise, privacy…) | Preferências ambientais do usuário |

---

## 6. Props, prefabs, estética

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Prop kinds** | `habitat_prop_catalog.dart` | 14 (bed, table, chair, lamp, plant, tv…) | Catálogo de móveis + sprites |
| **Prefabs / blueprints** | `habitat_commands.dart` | 3 (readingNook, deskSet, diningSet) | Kits de cômodo para autofurnish |
| **Floors** | `habitat_map.dart` | wood, carpet, concrete | Mais materiais |
| **Prop quality** | `HabitatPropQuality` | normal / good / excellent | Ligar a itens reais |
| **Beauty emit** | `habitat_beauty.dart` | scores por kind | Tabela de beleza/conforto |
| **Loadouts visuais** | `habitat_tint.dart` / living_habitat_assets | 3 loadouts + hair/body/apparel | Wardrobe completo |
| **Palettes** | `habitat_tint.dart` | skin/hair/stuff swatches | Swatches cosméticos |

---

## 7. Clima / ambiente / bolhas

| Seed | Onde | Hoje | Rechear depois |
|------|------|------|----------------|
| **Clima base por locale** | `habitat_climate.dart` | °C base nos 4 mapas | Clima por site + outdoor |
| **Bolhas de job / idle** | `app_strings.dart` (pools habitat) | Poucas frases por job | Mais pensamentos/falas localizadas |
| **Impressiveness** | `habitat_room_stats.dart` | mediocre → glorious | Labels / thresholds |

---

## Ordem sugerida para rechear (alto impacto)

1. **Media library** + **interest taxonomy** — gostos concretos  
2. **Conversation topics** + **dialogue pack** — vida social  
3. **Affordances / readiness / conditions** — comportamento crível  
4. **Props + prefabs** — casa parecer viva  
5. **Sites / context profiles / appointments** — mundo além do quarto  
6. **Identity bindings** — espelhar pessoas reais (quando for a hora)

---

## Como usar este arquivo

- Ao implementar conteúdo novo: marque o item e anote o arquivo.  
- Ao aceitar um marco do MD 08: confira se o seed correspondente não é só “demo de 3 linhas”.  
- Não misturar aqui decisões de arquitetura (isso fica em ADR / MD 08).
