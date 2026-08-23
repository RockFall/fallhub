# LIFE COLONY OS — ATLAS MUSICAL PESSOAL
## Especificação funcional, experiencial e técnica do sistema de cartografia de descobertas musicais

**Documento:** Feature Specification + UX Specification + Domain Model + AI Implementation Guide  
**Produto pai:** `Life Colony OS`  
**Módulo pai:** `Pesquisa`, com integrações profundas em `Flashcards`, `Integrações`, `Habitat`, `Home`, `Pawn`, `Skills`, `Biblioteca`, `Crônica`, `Missões`, `Agenda`, `Relações`, `Viagens` e `Storyteller`  
**Nome funcional:** `Atlas Musical`  
**Codinome interno:** `Music Frontier`  
**Status:** Especificação v1.1 — revisão de encaixe no app real  
**Data de referência:** 23 de agosto de 2026  
**Origem v1.0:** 6 de agosto de 2026  
**Plataforma:** Flutter — Android, iOS e desktop; experiência plenamente utilizável offline  
**Escopo desta versão:** descoberta, escuta, contextualização, comparação, memória, prática, planejamento de explorações, importação JSON com prompt para IA externa, conector Spotify opt-in e pontes com Pesquisa/Flashcards  
**Fora de escopo:** streaming próprio, download não autorizado de áudio, reprodução integral de conteúdo protegido, substituição de Spotify/Apple Music, LLM remoto obrigatório e “nota objetiva” sobre gosto musical  

**Delta v1.1 (23 ago 2026):** a v1.0 descrevia o continente cartográfico. Esta revisão **encaixa** o módulo no app que já existe (home de mini-programas, Pesquisa, Flashcards+SRS+import JSON, Integrações ICS, Habitat, Storyteller `rules_v1`) e **puxa para cedo** duas fatias que estavam implícitas ou tardias: prompt copiável + JSON (canal A) e conector Spotify opt-in. Capítulos novos: §2.4, §36.5–36.6, §45.5–45.7, §46.2, §75–§80. Roadmap M0–M13 na §67. O ensaio cartográfico das §3–§34 permanece; não foi reescrito por cosmética.

---

# Índice

- [0. Instrução soberana para a IA desenvolvedora](#0-instrução-soberana-para-a-ia-desenvolvedora)
- [1. Síntese da funcionalidade](#1-síntese-da-funcionalidade)
- [2. Encaixe natural no Life Colony OS](#2-encaixe-natural-no-life-colony-os)
- [3. Problema de produto](#3-problema-de-produto)
- [4. Tese de experiência](#4-tese-de-experiência)
- [5. O que torna o Atlas diferente](#5-o-que-torna-o-atlas-diferente)
- [6. Princípios absolutos](#6-princípios-absolutos)
- [7. Vocabulário de domínio](#7-vocabulário-de-domínio)
- [8. Modelo conceitual em cinco camadas](#8-modelo-conceitual-em-cinco-camadas)
- [9. A unidade fundamental: o Encontro Musical](#9-a-unidade-fundamental-o-encontro-musical)
- [10. Estados de descoberta](#10-estados-de-descoberta)
- [11. Dimensões de conhecimento musical](#11-dimensões-de-conhecimento-musical)
- [12. Territórios e fronteiras](#12-territórios-e-fronteiras)
- [13. Correntes históricas como rios](#13-correntes-históricas-como-rios)
- [14. Rede de influências e relações](#14-rede-de-influências-e-relações)
- [15. Névoa de guerra pessoal](#15-névoa-de-guerra-pessoal)
- [16. Marcos, portais e pontes](#16-marcos-portais-e-pontes)
- [17. Expedições musicais](#17-expedições-musicais)
- [18. Tipos de rota](#18-tipos-de-rota)
- [19. Acampamento atual](#19-acampamento-atual)
- [20. Sistema de bússola](#20-sistema-de-bússola)
- [21. Tela Atlas](#21-tela-atlas)
- [22. Projeções do mapa](#22-projeções-do-mapa)
- [23. Tela de inspeção de território](#23-tela-de-inspeção-de-território)
- [24. Tela de inspeção de nó](#24-tela-de-inspeção-de-nó)
- [25. Pawn musical](#25-pawn-musical)
- [26. Diário de campo](#26-diário-de-campo)
- [27. Modo de escuta guiada](#27-modo-de-escuta-guiada)
- [28. Laboratório de comparação](#28-laboratório-de-comparação)
- [29. Linha do tempo e River View](#29-linha-do-tempo-e-river-view)
- [30. Cartografia geográfica e cenas](#30-cartografia-geográfica-e-cenas)
- [31. Biblioteca, caixas e coleções](#31-biblioteca-caixas-e-coleções)
- [32. Repertório e prática instrumental](#32-repertório-e-prática-instrumental)
- [33. Conceitos musicais e escuta ativa](#33-conceitos-musicais-e-escuta-ativa)
- [34. Descoberta social](#34-descoberta-social)
- [35. Integração com a Crônica](#35-integração-com-a-crônica)
- [36. Integração com Skills e Pesquisa](#36-integração-com-skills-e-pesquisa)
- [37. Integração com Missões, Agenda e Foco](#37-integração-com-missões-agenda-e-foco)
- [38. Integração com Viagens, Locais e Eventos](#38-integração-com-viagens-locais-e-eventos)
- [39. Integração com Recursos e Finanças](#39-integração-com-recursos-e-finanças)
- [40. Storyteller musical](#40-storyteller-musical)
- [41. Assistente de IA musical](#41-assistente-de-ia-musical)
- [42. Recomendação explicável](#42-recomendação-explicável)
- [43. Proteção contra bolhas e canonização](#43-proteção-contra-bolhas-e-canonização)
- [44. Modelo de dados de domínio](#44-modelo-de-dados-de-domínio)
- [45. Relação com entidades existentes](#45-relação-com-entidades-existentes)
- [46. Schema relacional inicial](#46-schema-relacional-inicial)
- [47. Eventos de domínio](#47-eventos-de-domínio)
- [48. Máquinas de estado](#48-máquinas-de-estado)
- [49. Algoritmos e índices](#49-algoritmos-e-índices)
- [50. Geração de mapas e layout](#50-geração-de-mapas-e-layout)
- [51. Arquitetura Flutter](#51-arquitetura-flutter)
- [52. Estado, repositories e casos de uso](#52-estado-repositories-e-casos-de-uso)
- [53. Integrações externas](#53-integrações-externas)
- [54. Resolução de identidade musical](#54-resolução-de-identidade-musical)
- [55. Importação e reconciliação](#55-importação-e-reconciliação)
- [56. Local-first, sync e cache](#56-local-first-sync-e-cache)
- [57. Direitos autorais e conteúdo protegido](#57-direitos-autorais-e-conteúdo-protegido)
- [58. Privacidade](#58-privacidade)
- [59. Acessibilidade](#59-acessibilidade)
- [60. Performance](#60-performance)
- [61. Estados vazios, erros e edge cases](#61-estados-vazios-erros-e-edge-cases)
- [62. Onboarding](#62-onboarding)
- [63. Seeds pessoais iniciais](#63-seeds-pessoais-iniciais)
- [64. Cenários end-to-end](#64-cenários-end-to-end)
- [65. Critérios de aceitação](#65-critérios-de-aceitação)
- [66. Estratégia de testes](#66-estratégia-de-testes)
- [67. Roadmap de implementação](#67-roadmap-de-implementação)
- [68. Backlog inicial](#68-backlog-inicial)
- [69. Definition of Done](#69-definition-of-done)
- [70. ADRs obrigatórios](#70-adrs-obrigatórios)
- [71. Patch de integração no spec mestre](#71-patch-de-integração-no-spec-mestre)
- [72. Prompt de execução para a IA](#72-prompt-de-execução-para-a-ia)
- [73. Resultado esperado](#73-resultado-esperado)
- [74. Referências técnicas](#74-referências-técnicas)
- [75. Spotify — conector local-first](#75-spotify--conector-local-first)
- [76. Importação JSON com prompt para IA](#76-importação-json-com-prompt-para-ia)
- [77. Flashcards, tags e mapa de conhecimento](#77-flashcards-tags-e-mapa-de-conhecimento)
- [78. Superfície no app atual](#78-superfície-no-app-atual)
- [79. Contrato JSON v1 do Atlas](#79-contrato-json-v1-do-atlas)
- [80. Critérios de aceite das fatias novas](#80-critérios-de-aceite-das-fatias-novas)

---

# 0. Instrução soberana para a IA desenvolvedora

Esta especificação é uma extensão normativa de `LIFE_COLONY_OS_SPEC.md`. Ela não descreve um aplicativo separado. A implementação deve preservar os princípios, o design system, a arquitetura local-first, as convenções de dados, a privacidade e os padrões de interação do produto pai.

A IA desenvolvedora deve interpretar a funcionalidade como um **sistema de cartografia pessoal do conhecimento musical**, e não como:

- uma lista de álbuns;
- um clone de Spotify;
- uma árvore fixa de gêneros;
- um quiz de trivia;
- um sistema de XP vazio;
- um ranking moral de “bom gosto”;
- uma coleção de recomendações geradas sem contexto;
- uma tentativa de representar toda a história da música como uma hierarquia única e incontroversa.

A implementação deve começar pelo núcleo local, manual e explicável. **Importação JSON com prompt copiável** (padrão já enviado em Flashcards, ADR-038) entra cedo: a IA corre *fora* do app. **Spotify** entra como adapter opt-in assim que o núcleo gravar encontros e nós — não espera a Fase 11. LLM remoto *dentro* do app permanece defer (ADR-033).

## 0.1 Regras absolutas

1. Nenhuma porcentagem deve afirmar quanto de “toda a música” o usuário conhece.
2. Cobertura só pode ser calculada dentro de um escopo explicitamente delimitado.
3. Gêneros e correntes não formam uma taxonomia única; relações podem ser múltiplas, temporais, geográficas e contestadas.
4. Um álbum ouvido não equivale a um gênero compreendido.
5. Uma obra não deve ser marcada como “conhecida” apenas porque apareceu no histórico de reprodução.
6. Escuta casual, escuta atenta, contextualização, comparação, prática e articulação são evidências diferentes.
7. O sistema não deve punir pausas, mudanças de gosto ou abandono de uma rota.
8. Recomendações precisam explicar por que foram sugeridas.
9. A IA não pode inventar créditos, influências ou fatos históricos.
10. Relações históricas contestáveis devem registrar fonte, confiança e possibilidade de interpretações alternativas.
11. O usuário pode corrigir qualquer inferência de gosto ou conhecimento.
12. O mapa pessoal deve refletir a memória do usuário, não apenas o histórico de streaming.
13. O app não hospeda nem distribui áudio protegido.
14. Letras integrais não devem ser armazenadas ou reproduzidas automaticamente.
15. Integrações são opcionais, isoladas por adapter e revogáveis.
16. O modo offline deve permitir registrar, explorar, revisar e planejar.
17. A estética deve ser uma extensão original do “terminal de colônia civil” do Life Colony OS, sem copiar assets de RimWorld.

---

# 1. Síntese da funcionalidade

O `Atlas Musical` transforma a exploração musical do usuário em um mundo navegável.

Ele representa:

- gêneros e subgêneros como **territórios**;
- movimentos e transformações históricas como **correntes e rios**;
- artistas, obras, cenas, conceitos, instrumentos e técnicas como **nós inspecionáveis**;
- relações de influência, oposição, fusão e continuidade como **rotas**;
- o conhecimento pessoal como **névoa de guerra parcialmente revelada**;
- a exploração intencional como **expedições**;
- obras decisivas como **marcos**;
- pontos que ligam gostos já consolidados a regiões desconhecidas como **portais**;
- notas, comparações e memórias como **diário de campo**;
- conhecimento incorporado como um perfil multidimensional do **Pawn musical**.

O objetivo não é “completar o mapa”. O objetivo é produzir uma percepção cada vez mais rica de:

- onde o usuário já esteve;
- o que realmente entendeu;
- quais conexões consegue perceber;
- o que o marcou;
- onde existem lacunas relevantes;
- quais próximos caminhos têm maior potencial de surpresa, prazer ou aprendizado.

---

# 2. Encaixe natural no Life Colony OS

## 2.1 Localização na arquitetura de informação

O Atlas deve aparecer como uma subárea de primeiro nível dentro de `Pesquisa`:

```text
Pesquisa
├── Visão geral
├── Trilhas
├── Atlas Musical
├── Sessões
├── Evidências
└── Biblioteca
```

Ele também deve ser acessível por atalhos contextuais:

- `Pawn > Skills > Música > Abrir Atlas`;
- `Biblioteca > Álbuns > Ver no Atlas`;
- `Crônica > Descobertas musicais`;
- `Missões > Expedições musicais`;
- `Agenda > Sessão de escuta`;
- `Relações > Recomendações recebidas`;
- `Viagens > Cenas e locais musicais`;
- command palette: `Abrir Atlas Musical`.

Deep links:

```text
/research/music-atlas
/research/music-atlas/map/:projectionId
/research/music-atlas/territories/:territoryId
/research/music-atlas/nodes/:nodeId
/research/music-atlas/expeditions/:expeditionId
/research/music-atlas/listening/:sessionId
/research/music-atlas/compare
/pawn/me/music
/chronicle?domain=music
```

## 2.2 Entidades compartilhadas

O Atlas não cria cópias desnecessárias. Ele estende entidades existentes:

| Necessidade musical | Entidade base do Life Colony | Extensão |
|---|---|---|
| álbum, livro, vídeo, podcast | `KnowledgeSource` | metadata e identidade musical |
| trilha de aprendizado | `LearningPath` | `MusicMapScope` e projeções |
| gênero, conceito, obra | `ResearchNode` | `MusicNodeProfile` |
| sessão de estudo/escuta | `LearningSession` | `MusicListeningSession` |
| evidência | `Evidence` | tipo e rubrica musical |
| repertório | `RepertoireItem` | ligação ao Atlas e evidência |
| marco pessoal | `DomainEvent` | eventos musicais |
| objetivo | `Quest` ou `Project` | expedição longa ou projeto musical |
| pessoa | `Person` | recomendador, professor, músico conhecido |
| local/viagem | `Location`, `Trip` | cena, show, festival, loja, museu |
| gasto | `Transaction` | álbum, show, instrumento, aula |
| nota | `AtomicNote` | observação musical e comparação |

## 2.3 Integração sem fragmentação

O Atlas é a representação espacial e histórica de dados que já pertencem ao sistema:

- ouvir um álbum cria ou atualiza um `Encounter`;
- registrar uma sessão cria `LearningSession` e `DomainEvent`;
- escrever uma nota cria `AtomicNote`;
- praticar uma peça cria evidência em `RepertoireItem` e `SkillProfile`;
- aceitar uma rota pode criar `Quest` ou agenda;
- assistir a um show entra na `Crônica`;
- comprar um disco pode ligar `Transaction`, `InventoryItem` e `KnowledgeSource`;
- viajar a uma cidade pode revelar cenas e locais relacionados;
- o Storyteller usa esses dados para sugerir reflexões, não para gerar um segundo sistema paralelo.

## 2.4 Mapa do app real (agosto 2026)

O Atlas não pode ser especificado como se o produto ainda fosse só o PRD. O repositório já tem superfícies que o módulo deve *usar*, não reinventar:

| Superfície existente | Como o Atlas entra |
|---|---|
| Home launcher (mini-programas) | tile `Música` / `Atlas` + atalho “O que estou ouvindo” |
| Menu Mais e command palette | destinos `/research/music-atlas`, captura, import JSON, Spotify |
| `/research` + detalhe de nó | ponte N:N `ResearchKnowledgeLink` + evidência de escuta/prática |
| `/flashcards` + SRS (ADR-036/037/038/039) | baralhos `repertoire` / teoria; import JSON pode criar cartões |
| `/settings/integrations` (ADR-032, ICS stub) | toggle Spotify + MusicBrainz + import JSON; mesmo consentimento |
| Storyteller `rules_v1` (ADR-033) | bullets de expedição/encontros; sem LLM |
| Habitat / piano (spec living pawn) | objeto abre prática, repertório ou Atlas — sem autoplay |
| Agenda (`/work/schedule`) | blocos `escuta`, `prática`, `show`; deep link para sessão |
| Pessoas / compromissos | recomendador, aula, show combinado |
| Viagens / zonas / casa | cena, festival, disco na estante |
| Ledger | gasto de disco/show/aula com proveniência, sem “ROI cultural” |
| Export/restore | entidades musicais no snapshot; **tokens Spotify nunca entram** |
| Parse streaming (ADR-042 / ADR-038 §6) | dumps JSON/Spotify grandes: path + isolate, sem teto, sem colar MB no TextField |

Rotas canónicas (além das da §2.1):

```text
/research/music-atlas
/research/music-atlas/import
/research/music-atlas/import?source=json
/research/music-atlas/import?source=spotify
/settings/integrations
/flashcards?area=musica
/flashcards/study?deckId=…
/quests?tag=music-expedition
```

---

# 3. Problema de produto

Exploração musical normalmente se fragmenta entre:

- histórico de streaming;
- playlists sem contexto;
- listas de “melhores álbuns”;
- notas soltas;
- vídeos;
- livros;
- recomendações de amigos;
- repertório instrumental;
- memória subjetiva;
- vontade vaga de conhecer um gênero;
- referências históricas nunca conectadas.

Serviços de streaming respondem principalmente “o que tocar agora?”. Eles raramente respondem:

- O que eu já conheço de jazz, de fato?
- Como bebop, hard bop, modal jazz e fusion se conectam?
- Em que sentido o funk dialoga com jazz, soul, disco e hip-hop?
- Que ponte existe entre rock progressivo e música contemporânea?
- Quais movimentos brasileiros conheço apenas superficialmente?
- Que álbuns mudaram minha percepção?
- Quais conceitos consigo reconhecer pelo ouvido?
- Que corrente histórica estou explorando?
- Qual é o próximo passo que expande meu mapa sem parecer aleatório?
- O que eu ouvi há cinco anos e hoje compreenderia de outra forma?

O problema central não é falta de música. É falta de **estrutura de memória, orientação e significado**.

---

# 4. Tese de experiência

A experiência deve produzir a sensação de explorar um continente cultural vivo.

O usuário não recebe uma trilha escolar rígida. Ele:

1. avista territórios;
2. escolhe uma fronteira;
3. monta uma expedição;
4. encontra obras e conceitos;
5. registra impressões;
6. compara sinais;
7. descobre relações históricas;
8. revisita obras;
9. transforma encontros em memória;
10. vê o mapa pessoal ganhar definição.

A unidade de progresso não é quantidade consumida, mas **densidade de conexão**.

Um território se torna mais nítido quando o usuário consegue:

- reconhecer traços;
- nomear diferenças;
- relacionar obras;
- localizar historicamente;
- explicar o que percebe;
- associar a experiências próprias;
- tocar, analisar ou criar algo quando isso fizer sentido.

---

# 5. O que torna o Atlas diferente

## 5.1 Não é apenas histórico de escuta

Histórico é uma fonte. Conhecimento exige confirmação ou evidência.

## 5.2 Não é apenas árvore de pesquisa

Música tem genealogias divergentes, fusões, cenas paralelas e relações controversas. O grafo precisa aceitar multiplicidade.

## 5.3 Não é apenas mapa de gêneros

O usuário pode explorar por:

- período;
- região;
- cena;
- instrumento;
- compositor;
- tecnologia;
- ritmo;
- linguagem harmônica;
- forma;
- tema;
- produção;
- prática instrumental;
- corrente estética;
- relação social.

## 5.4 Não é apenas recomendador

Toda sugestão deve estar conectada a uma intenção:

- aprofundar;
- criar ponte;
- desafiar;
- contextualizar;
- revisar;
- comparar;
- preparar repertório;
- entender uma influência;
- acompanhar uma viagem;
- responder uma pergunta.

## 5.5 Não é “gamificação de consumo”

Não haverá prêmio por ouvir conteúdo em velocidade, manter streak ou completar listas sem assimilação. O prazer de escutar permanece válido mesmo sem registro.

---

# 6. Princípios absolutos

## 6.1 Curiosidade acima de completude

O Atlas deve estimular perguntas melhores, não ansiedade de catálogo.

## 6.2 Conexões acima de contagem

“Você percebeu como estes dois discos tratam ritmo de formas distintas” é mais valioso que “37 álbuns concluídos”.

## 6.3 Múltiplos cânones

O sistema deve permitir:

- cânones críticos;
- cânones locais;
- cânones pessoais;
- listas de professores;
- recortes por país, cena, época e perspectiva;
- obras essenciais para uma pergunta específica.

Nenhum cânone é a verdade final.

## 6.4 Subjetividade explícita

Ressonância, prazer e impacto são pessoais. Importância histórica, influência e pioneirismo são claims que exigem fontes.

## 6.5 Escuta sem obrigação

O usuário pode marcar:

- “não quero analisar”;
- “escuta casual”;
- “apenas curtir”;
- “voltar depois”;
- “não me interessa agora”.

## 6.6 Fronteiras vivas

O mapa pode ser reorganizado quando novas relações forem descobertas. Alterar a interpretação histórica não destrói os encontros pessoais.

## 6.7 Conhecimento situado

Toda observação pode ter contexto:

- idade/fase da vida;
- equipamento;
- companhia;
- local;
- humor;
- objetivo;
- familiaridade anterior;
- versão, gravação ou master específica.

---

# 7. Vocabulário de domínio

| Termo | Definição |
|---|---|
| `Atlas` | conjunto de mapas, projeções, escopos e estados pessoais |
| `Território` | agrupamento coerente, como gênero, cena, movimento ou tradição |
| `Nó` | entidade explorável: artista, obra, gênero, conceito, instrumento etc. |
| `Relação` | conexão tipada entre nós |
| `Claim` | afirmação histórica ou analítica com fonte e confiança |
| `Encontro` | contato do usuário com um nó |
| `Escuta` | evento de reprodução ou sessão declarada |
| `Descoberta` | mudança significativa no estado pessoal de um nó |
| `Expedição` | sequência intencional de encontros com pergunta ou propósito |
| `Rota` | caminho reutilizável entre nós |
| `Parada` | etapa de uma expedição |
| `Marco` | nó especialmente orientador dentro de um escopo |
| `Portal` | nó próximo ao gosto atual que abre acesso a outro território |
| `Ponte` | conjunto de relações que explica passagem entre territórios |
| `Fronteira` | borda entre regiões conhecidas e pouco exploradas |
| `Névoa` | representação de conhecimento ausente, incerto ou não revisado |
| `Acampamento` | conjunto pequeno de explorações atualmente ativas |
| `Diário de campo` | notas, perguntas e evidências de uma expedição |
| `Projeção` | forma de visualizar o mesmo grafo |
| `Bússola` | sistema de orientação baseado na intenção atual |
| `Ressonância` | impacto subjetivo declarado pelo usuário |
| `Internalização` | capacidade de reconhecer, conectar e usar conhecimento |
| `Revisita` | novo encontro com obra previamente conhecida |
| `Cena` | comunidade musical situada em tempo, lugar e relações sociais |
| `Corrente` | continuidade histórica ou estética, sem exigir fronteira rígida |
| `Linhas de escuta` | aspectos sugeridos para atenção durante uma obra |

---

# 8. Modelo conceitual em cinco camadas

O sistema deve separar cinco camadas que frequentemente são confundidas.

## 8.1 Camada factual

Metadados verificáveis:

- título;
- artista;
- data;
- créditos;
- duração;
- edição;
- país;
- gravadora;
- instrumentos;
- relações documentadas;
- identificadores externos.

## 8.2 Camada historiográfica

Interpretações com fonte:

- influenciou;
- reagiu contra;
- inaugurou;
- popularizou;
- representa;
- faz parte de;
- dialoga com;
- é controversamente classificado como.

Toda afirmação deve poder carregar divergências.

## 8.3 Camada estrutural

Traços musicais:

- ritmo;
- harmonia;
- melodia;
- forma;
- instrumentação;
- timbre;
- produção;
- improvisação;
- performance;
- texto;
- dinâmica.

## 8.4 Camada pessoal

- ouvi;
- reconheço;
- gosto;
- não gosto;
- marcou;
- quero revisitar;
- consigo explicar;
- consigo tocar;
- associo a algo;
- mudei de opinião.

## 8.5 Camada operacional

- próximo passo;
- rota ativa;
- sessão agendada;
- pergunta em aberto;
- evidência faltante;
- comparação pendente;
- revisão futura.

As camadas não devem ser colapsadas em um score único.

---

# 9. A unidade fundamental: o Encontro Musical

Um `MusicEncounter` representa um contato significativo entre o usuário e um nó musical.

Exemplos:

- ouviu um álbum;
- viu um show;
- estudou um movimento;
- assistiu a uma entrevista;
- leu sobre um compositor;
- tocou uma peça;
- transcreveu um solo;
- comparou duas gravações;
- recebeu uma recomendação;
- reconheceu uma influência;
- ouviu casualmente uma faixa marcante.

```yaml
MusicEncounter:
  id
  profile_id
  node_id
  occurred_at
  encounter_type:
    passive_listen
    attentive_listen
    album_session
    live_performance
    rehearsal
    performance
    study
    reading
    watching
    conversation
    comparison
    transcription
    composition
    discovery
    revisit
  context:
    location_id_optional
    trip_id_optional
    people_ids[]
    device_or_setup_optional
    mood_optional
    energy_optional
    activity_optional
  duration_seconds_optional
  completion_ratio_optional
  attention_quality_optional
  resonance_optional
  familiarity_before_optional
  familiarity_after_optional
  note_optional
  questions[]
  evidence_ids[]
  source
  provenance
```

## 9.1 Regras

- Um listen importado não deve automaticamente virar encontro significativo.
- O sistema pode agregar reproduções em uma sugestão de encontro: “Você ouviu este álbum em três dias diferentes. Registrar descoberta?”
- O usuário pode registrar um encontro em menos de cinco segundos.
- Campos analíticos são opcionais.
- Reescutas devem preservar cada contexto.
- O usuário pode marcar “não registrar automaticamente esta obra/artista”.

---

# 10. Estados de descoberta

Os estados descrevem relação pessoal, não qualidade da obra.

```text
0 Não mapeado
1 Rumor — apareceu em conversa, lista ou relação
2 Avistado — usuário reconhece nome/contexto mínimo
3 Amostrado — contato curto ou parcial
4 Visitado — experiência completa ou deliberada
5 Cartografado — usuário registrou traços e contexto
6 Conectado — usuário relaciona a outros nós
7 Internalizado — reconhecimento e explicação consistentes
8 Vivo — conhecimento mantido por revisitas, prática ou uso criativo
9 Adormecido — já foi forte, mas pode estar desatualizado
10 Arquivado — fora do foco atual, preservado no histórico
```

## 10.1 Estado não é linear obrigatório

Um músico pode:

- tocar uma peça sem conhecer seu contexto histórico;
- conhecer profundamente uma corrente sem gostar dela;
- reconhecer um estilo por ouvido sem nomear artistas;
- ter forte ressonância com uma obra sem conseguir analisá-la.

Por isso, o estado é um resumo editável; as dimensões detalhadas permanecem separadas.

## 10.2 Transições sugeridas

- `rumor -> avistado`: usuário abriu o nó e confirmou reconhecimento;
- `avistado -> amostrado`: escuta parcial;
- `amostrado -> visitado`: escuta deliberada completa;
- `visitado -> cartografado`: nota ou prompts respondidos;
- `cartografado -> conectado`: comparação ou relações confirmadas;
- `conectado -> internalizado`: evidência de reconhecimento/articulação;
- `internalizado -> vivo`: revisita, repertório ou criação;
- qualquer estado -> `adormecido`: confiança caiu por recência;
- qualquer estado -> `arquivado`: decisão explícita.

Nenhuma transição regressiva apaga evidência.

---

# 11. Dimensões de conhecimento musical

Cada nó pode ter um `MusicKnowledgeProfile` com sete dimensões independentes, de 0 a 4, sempre acompanhadas por confiança.

| Dimensão | Pergunta |
|---|---|
| Exposição | Quanto contato real ocorreu? |
| Reconhecimento | Consigo identificar ou distinguir traços? |
| Contextualização | Sei onde isso se situa histórica e culturalmente? |
| Escuta analítica | Consigo perceber elementos estruturais relevantes? |
| Articulação | Consigo explicar com minhas palavras? |
| Conexão | Consigo relacionar a outras obras/correntes? |
| Incorporação | Consigo tocar, transcrever, compor ou aplicar algo? |

Escala:

```text
0 Sem evidência
1 Indício
2 Evidência básica
3 Evidência consistente
4 Evidência forte para o objetivo atual
```

## 11.1 Ressonância não entra no conhecimento

`resonance` é outra dimensão:

```text
-2 rejeição forte
-1 pouco interesse
 0 neutro/incerto
+1 interesse
+2 forte ressonância
+3 obra ou corrente formativa
```

Não gostar não reduz conhecimento.

## 11.2 Confiança

Cada dimensão possui:

- valor declarado;
- valor inferido opcional;
- evidências;
- data da última confirmação;
- cobertura de contexto;
- confiança.

A UI deve mostrar divergência entre declaração e inferência, nunca substituir a declaração silenciosamente.

---

# 12. Territórios e fronteiras

Um `MusicTerritory` é um recorte navegável.

Tipos:

- gênero;
- subgênero;
- movimento;
- tradição;
- cena;
- período;
- região;
- escola;
- corrente estética;
- linguagem instrumental;
- prática;
- tecnologia;
- recorte curatorial pessoal.

Exemplos:

- bebop;
- jazz modal;
- samba de roda;
- bossa nova;
- Clube da Esquina;
- rock progressivo italiano;
- Canterbury scene;
- zeuhl;
- goth rock;
- jazz-funk;
- fusion;
- música espectral;
- piano stride;
- produção dub;
- improvisação livre;
- harmonia quartal.

## 12.1 Escopo explícito

Cada território declara:

```yaml
MusicTerritory:
  title
  description
  scope_statement
  inclusion_rules[]
  exclusion_notes[]
  parent_relations[]
  overlapping_territories[]
  time_range_optional
  geographic_scope_optional
  canonical_views[]
  user_goal_optional
```

“Conhecer jazz” é amplo demais. O sistema deve permitir subescopos:

- “uma primeira cartografia de jazz de 1940 a 1975”;
- “piano em trio no jazz moderno”;
- “relações entre modal jazz, spiritual jazz e fusion”;
- “jazz brasileiro e diálogos com samba e bossa”.

## 12.2 Fronteira pessoal

Uma fronteira é calculada dentro de um escopo:

- nós próximos a regiões conhecidas;
- relações ainda não exploradas;
- períodos com pouca cobertura;
- lacunas entre correntes;
- obras frequentemente citadas em notas, mas ainda não visitadas;
- conceitos que aparecem em várias rotas.

Fronteira não significa obrigação.

---

# 13. Correntes históricas como rios

A projeção `River View` representa continuidades e transformações ao longo do tempo.

Regras visuais:

- eixo horizontal: tempo;
- largura do rio: importância dentro do recorte, não popularidade global;
- divisões: diferenciação;
- fusões: encontros;
- afluentes: influências;
- desaparecimento visual: redução de atividade dentro do recorte;
- continuidade pontilhada: legado posterior;
- linhas tracejadas: relação discutida ou indireta;
- intensidade pessoal: revelação pela névoa, não alteração da história.

## 13.1 Não implicar evolução linear

O layout não deve sugerir que estilos posteriores são “mais avançados”. A direção temporal é cronologia, não progresso.

## 13.2 Claims históricos

Toda bifurcação ou fusão relevante pode abrir:

- descrição;
- fontes;
- interpretações alternativas;
- obras representativas;
- confiança;
- notas pessoais;
- pergunta orientadora.

---

# 14. Rede de influências e relações

Tipos de relação mínimos:

```text
historical:
  emerged_from
  influenced_by
  influenced
  reacted_against
  revived
  popularized
  regional_variant_of
  parallel_development
  contemporaneous_with

structural:
  shares_rhythmic_language
  shares_harmonic_language
  shares_instrumentation
  shares_form
  shares_production_method
  shares_performance_practice
  contrasts_with

social:
  member_of
  scene_member
  collaborated_with
  studied_with
  mentored
  performed_with
  label_affiliation

work:
  performed_by
  composed_by
  arranged_by
  produced_by
  recorded_at
  samples
  sampled_by
  covers
  interpolates
  quotes
  adaptation_of

personal:
  reminds_user_of
  discovered_through
  recommended_by
  compared_with
  bridge_for_user
  personal_influence
```

## 14.1 Relação como claim

Uma relação histórica não deve ser apenas uma aresta booleana.

```yaml
MusicRelationClaim:
  relation_type
  from_node_id
  to_node_id
  directionality
  valid_from_optional
  valid_to_optional
  description
  evidence_sources[]
  confidence
  status: asserted | disputed | inferred | user_defined
  competing_claim_ids[]
  reviewed_at
```

## 14.2 Relações pessoais separadas

A associação “este álbum me lembra uma viagem” não deve contaminar a ontologia histórica. Ela vive em camada pessoal.

---

# 15. Névoa de guerra pessoal

A névoa é o principal mecanismo visual de orientação.

## 15.1 Estados visuais

- `oculto`: nó não aparece, salvo se necessário para topologia;
- `silhueta`: nome ou forma geral visível;
- `rumor`: aparece por recomendação ou relação;
- `revelado`: usuário teve contato;
- `cartografado`: detalhes pessoais visíveis;
- `conectado`: arestas pessoais destacadas;
- `vivo`: atividade recente e evidência forte;
- `adormecido`: aparência dessaturada, sem punição.

## 15.2 A névoa não deve esconder história por padrão

Modos:

- `Mapa pessoal`: enfatiza conhecimento do usuário;
- `Mapa completo do escopo`: mostra estrutura conhecida pelo sistema;
- `Exploração`: revela apenas o suficiente para orientar;
- `Comparação`: sobrepõe pessoal e historiográfico.

## 15.3 Revelação gradual

Ao abrir um território desconhecido, mostrar:

1. descrição curta;
2. três marcos;
3. uma pergunta;
4. um portal próximo ao gosto;
5. opção de expandir contexto.

Evitar despejar centenas de nós.

---

# 16. Marcos, portais e pontes

## 16.1 Marco

Um `Landmark` é um nó escolhido por uma curadoria ou pelo usuário como orientador.

Tipos:

- obra seminal;
- obra representativa;
- obra de transição;
- obra contestadora;
- obra acessível;
- obra extrema;
- registro ao vivo;
- documento histórico;
- artista-chave;
- conceito-chave.

“Seminal” exige fonte. “Formativo para mim” é pessoal.

## 16.2 Portal

Um portal aproxima desconhecido e conhecido.

Exemplo conceitual:

```text
território conhecido: jazz fusion
sinal pessoal: gosto por timbres elétricos, métricas complexas e improvisação
território-alvo: Canterbury / zeuhl
portal: obra com improvisação jazzística e arquitetura progressiva
explicação: compartilha X e Y, difere em Z
```

## 16.3 Ponte

Uma ponte contém de dois a sete passos e explica a transformação entre extremos.

Exemplos de formato:

- `Miles Davis elétrico -> jazz-rock -> Canterbury`;
- `blues elétrico -> hard rock -> heavy metal`;
- `samba-canção -> bossa nova -> MPB`;
- `post-punk -> goth rock -> darkwave`;
- `funk -> jazz-funk -> fusion -> neo-soul`;
- `minimalismo -> ambient -> post-rock`;
- `música impressionista -> jazz modal -> third stream`.

Esses exemplos são seeds curatoriais; a implementação não deve tratá-los como genealogias exaustivas.

---

# 17. Expedições musicais

Uma `MusicExpedition` é uma jornada com propósito explícito.

```yaml
MusicExpedition:
  title
  question
  purpose
  expedition_type
  scope_id
  status
  difficulty
  expected_duration
  stop_count
  pacing
  constraints:
    max_album_length_optional
    available_services[]
    languages[]
    explicit_content_policy_optional
    offline_availability_optional
  success_definition
  stops[]
  journal_entries[]
  started_at
  completed_at
  abandoned_at
  abandonment_reason_optional
```

## 17.1 Exemplos de perguntas

- Como o jazz passou do bebop ao modal?
- O que distingue fusion de jazz-funk?
- Como o samba aparece dentro da bossa nova sem desaparecer?
- Onde o rock progressivo toca jazz, música erudita e folk?
- Que caminhos ligam goth rock a jazz ou prog sem depender apenas de estética?
- Como o baixo elétrico mudou funk, fusion e rock?
- Como diferentes pianistas tratam espaço e acompanhamento?
- O que a produção de estúdio faz no dub, ambient e trip-hop?
- Como uma mesma composição muda em quatro interpretações?

## 17.2 Estrutura de parada

```yaml
ExpeditionStop:
  order
  node_id
  role:
    orientation
    landmark
    contrast
    bridge
    deep_dive
    context
    practice
    reflection
    wildcard
  reason
  listening_cues[]
  prerequisite_stop_ids[]
  optional
  estimated_minutes
  completion_rule
  completion_state
```

## 17.3 Sucesso

Uma expedição pode ser concluída por:

- encontros mínimos;
- pergunta respondida;
- comparação registrada;
- mapa atualizado;
- artefato produzido;
- decisão de que o tema não interessa.

“Descobri que não quero aprofundar agora” é resultado válido.

---

# 18. Tipos de rota

## 18.1 Genealogia reversa

Parte de algo amado e busca antecessores.

## 18.2 Descendentes

Parte de uma obra/corrente e acompanha desdobramentos.

## 18.3 Ponte entre gostos

Liga dois territórios já relevantes ao usuário.

## 18.4 Diálogo transatlântico ou transcultural

Mostra trocas entre regiões, com cuidado para não reduzir culturas a influência unilateral.

## 18.5 Linha instrumental

Segue um instrumento, técnica ou papel:

- piano de acompanhamento;
- baixo elétrico;
- órgão Hammond;
- guitarra de sete cordas;
- sax alto;
- bateria quebrada;
- síntese modular.

## 18.6 Linha rítmica

Segue clave, swing, backbeat, polirritmia, métricas ímpares ou células específicas.

## 18.7 Linha harmônica

Segue linguagem tonal, modal, quartal, cromática, funcional, não funcional ou espectral.

## 18.8 Linha de produção

Segue tecnologias e estéticas de gravação.

## 18.9 Cena local

Explora cidade, clube, selo, estúdio, festival ou comunidade.

## 18.10 Um ano em música

Recorte de obras, acontecimentos e cenas de um ano.

## 18.11 Uma obra em muitas versões

Compara interpretações, arranjos, gravações e contextos.

## 18.12 Rota de estranhamento

Escolhe deliberadamente algo distante do perfil atual, com preparação contextual.

## 18.13 Rota de recuperação

Revisita obras formativas de uma fase da vida.

## 18.14 Rota de criação

Termina em artefato:

- playlist comentada;
- ensaio;
- performance;
- arranjo;
- composição;
- mapa anotado;
- aula para outra pessoa.

---

# 19. Acampamento atual

O `Camp` limita WIP sem impedir curiosidade.

Configuração padrão:

- 1 expedição principal;
- 2 explorações secundárias;
- até 7 rumores salvos;
- sessões avulsas ilimitadas, sem compromisso.

Tela do acampamento:

```text
EXPEDIÇÃO PRINCIPAL
Jazz elétrico: de In a Silent Way a Canterbury
Pergunta: como improvisação e composição longa se fundem?
Próxima parada: ...
Tempo estimado: 46 min
[Iniciar escuta] [Ver mapa]

EXPLORAÇÕES
- Piano brasileiro moderno
- Goth, noir e jazz escuro

RUMORES NO MAPA
- Zeuhl
- Spiritual jazz
- Samba-jazz
```

## 19.1 Pausa sem dívida

Pausar não cria atraso. O sistema registra:

- motivo;
- ponto de retorno;
- pergunta ainda aberta;
- última parada;
- contexto recomendado para retomada.

---

# 20. Sistema de bússola

Antes de recomendar, o Atlas pergunta ou infere a intenção atual.

Modos:

- `Aprofundar`: mais densidade no território atual;
- `Conectar`: construir ponte;
- `Expandir`: território adjacente;
- `Estranhar`: alta novidade;
- `Contextualizar`: história e fontes;
- `Treinar ouvido`: reconhecimento;
- `Praticar`: ligação instrumental;
- `Criar`: gerar material;
- `Revisitar`: memória e mudança de percepção;
- `Relaxar`: baixa exigência analítica;
- `Preparar`: show, aula, viagem ou conversa.

A bússola usa também:

- tempo disponível;
- energia declarada;
- ambiente;
- disponibilidade de áudio;
- tamanho desejado;
- tolerância a desafio;
- objetivo ativo.

---

# 21. Tela Atlas

## 21.1 Desktop/tablet

Layout de três áreas:

1. **barra superior**:
   - projeção;
   - escopo;
   - período;
   - busca;
   - modo de névoa;
   - bússola;
   - salvar vista;

2. **mapa central**:
   - grafo/river/timeline;
   - pan e zoom;
   - camadas;
   - trilha ativa;
   - minimapa;
   - breadcrumbs;

3. **inspect pane**:
   - nó selecionado;
   - estado pessoal;
   - resumo histórico;
   - relações;
   - próxima ação;
   - iniciar encontro.

Barra inferior contextual, em linguagem original inspirada em gestão de colônia:

```text
[Atlas] [Expedições] [Acampamento] [Diário] [Comparar] [Coleções] [Pawn Musical]
```

## 21.2 Mobile

- mapa em tela cheia;
- painel inspecionável por bottom sheet;
- chips de projeção;
- botão de bússola;
- botão de encontro rápido;
- mini-rota no topo quando expedição ativa;
- modo lista equivalente;
- zoom com gestos;
- seleção preservada ao alternar mapa/lista.

## 21.3 Interações

- toque: selecionar;
- toque duplo: focar;
- long press/clique direito: menu contextual;
- arrastar nó apenas em mapa pessoal editável;
- `Shift + click`: selecionar comparação;
- `Alt + click`: abrir sem mudar contexto;
- `Space`: preview;
- `E`: adicionar à expedição;
- `L`: registrar escuta;
- `N`: nota;
- `R`: relação pessoal;
- `/`: busca.

## 21.4 Menu contextual

- abrir inspeção;
- iniciar escuta;
- marcar encontro;
- adicionar à expedição;
- salvar como rumor;
- comparar com;
- mostrar antecessores;
- mostrar descendentes;
- mostrar pontes;
- ver na linha do tempo;
- ver cena/local;
- criar nota;
- corrigir metadata;
- ocultar recomendação.

---

# 22. Projeções do mapa

O mesmo grafo deve suportar projeções distintas.

## 22.1 Frontier Map

Mapa pessoal com névoa. Responde: “onde estou e quais bordas posso explorar?”.

## 22.2 River View

Correntes ao longo do tempo. Responde: “como isso se transformou?”.

## 22.3 Influence Graph

Rede de influência e colaboração. Responde: “o que se conecta a quê e por qual relação?”.

## 22.4 Scene Map

Tempo + geografia + comunidade. Responde: “onde e entre quem isso aconteceu?”.

## 22.5 Concept Map

Agrupa por traços musicais. Responde: “que linguagens aparecem em contextos distintos?”.

## 22.6 Personal Constellation

Organiza por relações pessoais, ressonância e memória. Responde: “como minha história musical se estruturou?”.

## 22.7 Expedition View

Mostra apenas rota, alternativas e desvios.

## 22.8 Canon Comparison

Compara listas curatoriais e mapa pessoal, sem declarar vencedora.

## 22.9 Instrument Lens

Filtra por instrumento, performer, técnica, papel e repertório.

## 22.10 Accessibility List View

Lista hierárquica/relacional completa, com equivalência funcional.

---

# 23. Tela de inspeção de território

A tela deve lembrar uma ficha detalhada de sistema, com abas densas e legíveis.

Abas:

1. `Resumo`;
2. `Mapa`;
3. `História`;
4. `Linguagem`;
5. `Marcos`;
6. `Cenas`;
7. `Conexões`;
8. `Meu percurso`;
9. `Expedições`;
10. `Fontes`.

## 23.1 Resumo

- definição com escopo;
- período e geografia;
- descritores;
- nível de consenso da classificação;
- estado pessoal;
- últimas descobertas;
- perguntas abertas;
- portal recomendado;
- cobertura dentro do escopo salvo.

## 23.2 Linguagem

Dimensões:

- ritmo;
- harmonia;
- forma;
- instrumentação;
- timbre;
- improvisação;
- produção;
- performance;
- temas.

Cada dimensão pode ter:

- descrição;
- exemplos;
- cues;
- conceitos relacionados;
- evidência pessoal de reconhecimento.

## 23.3 Meu percurso

- primeiro encontro;
- encontros decisivos;
- obras formativas;
- mudanças de opinião;
- associações pessoais;
- lacunas;
- revisitas;
- artefatos produzidos.

---

# 24. Tela de inspeção de nó

Tipos de nó mudam conteúdo, mas compartilham a estrutura.

## 24.1 Cabeçalho

- título;
- tipo;
- aliases;
- imagem opcional com provenance;
- período;
- local;
- estado pessoal;
- ressonância;
- ações rápidas;
- qualidade de metadata.

## 24.2 Abas universais

- `Overview`;
- `Relations`;
- `History`;
- `My Encounters`;
- `Notes`;
- `Evidence`;
- `Sources`.

## 24.3 Álbum/obra

Campos adicionais:

- release group/edição;
- tracklist;
- créditos;
- duração;
- sessão/estúdio;
- conceitos;
- território;
- gravações comparáveis;
- cues por faixa;
- edições possuídas;
- serviços externos;
- repertório relacionado.

## 24.4 Artista

- períodos/fases;
- grupos;
- colaboradores;
- instrumentos;
- obras;
- cenas;
- influências com claims;
- linhagem pessoal;
- shows vistos.

## 24.5 Conceito

- definição;
- exemplos contrastantes;
- exercícios de reconhecimento;
- relações teóricas;
- evidências;
- aplicação em repertório.

## 24.6 Gênero/movimento

- escopo;
- debates de classificação;
- antecedentes;
- desdobramentos;
- cenas;
- marcos;
- rotas de entrada;
- rotas avançadas.

---

# 25. Pawn musical

`Pawn > Música` consolida a identidade musical pessoal sem reduzi-la a “top artists”.

Abas:

1. `Overview`;
2. `Affinities`;
3. `Knowledge`;
4. `Ear`;
5. `Practice`;
6. `History`;
7. `Artifacts`;
8. `Values`.

## 25.1 Overview

Painel:

```text
PAWN MUSICAL — CAIO

Fase atual
Explorar conexões entre jazz, fusion, música brasileira e rock progressivo

Acampamento
1 expedição principal · 2 secundárias

Territórios vivos
Jazz · Funk · Fusion · Bossa nova · Samba · Rock progressivo

Fronteiras próximas
Spiritual jazz · Canterbury · Zeuhl · Samba-jazz · Third stream

Perguntas abertas
- O que distingue jazz-funk de fusion?
- Como a harmonia impressionista chega ao jazz modal?
- Onde goth e jazz se encontram além da estética “dark”?

Últimos marcos
...
```

## 25.2 Affinities

Não usar apenas gênero. Mostrar padrões declarados/inferidos:

- timbres;
- densidade;
- improvisação;
- duração;
- contraste;
- groove;
- complexidade;
- forma;
- atmosfera;
- produção;
- tradição/ruptura;
- voz/instrumental.

Cada afinidade responde “por que acreditamos nisso?” e permite corrigir.

## 25.3 Knowledge

Matriz por território e dimensão, com confiança e recência.

## 25.4 Ear

Capacidades auditivas autocadastradas ou testadas:

- reconhecimento de instrumentos;
- forma;
- compasso;
- groove;
- intervalos;
- cadências;
- linguagem harmônica;
- técnicas de produção;
- identificação de correntes.

Não deve virar prova obrigatória.

## 25.5 Practice

Integra piano, guitarra, composição, repertório e transcrição.

## 25.6 History

Linha do tempo pessoal:

- fases de escuta;
- artistas formativos;
- primeiras descobertas;
- shows;
- instrumentos;
- álbuns que mudaram opinião;
- projetos criativos.

## 25.7 Values

Perguntas:

- O que procuro em música?
- O que valorizo numa performance?
- Prefiro conhecer profundamente ou explorar amplamente neste momento?
- Que tradições quero respeitar e contextualizar melhor?
- Que vieses do meu repertório quero contrariar?

---

# 26. Diário de campo

O diário é organizado por expedição, nó, período e pergunta.

Tipos de entrada:

- impressão livre;
- observação por faixa;
- comparação;
- pergunta;
- hipótese;
- citação curta com fonte;
- associação;
- mudança de opinião;
- insight técnico;
- memória;
- desenho/mapa;
- áudio próprio;
- foto de show/disco;
- decisão de próxima rota.

## 26.1 Template leve

```text
O que chamou atenção?
O que eu reconheci?
O que parece novo?
A que isso se conecta?
Que pergunta ficou?
```

Todos opcionais.

## 26.2 Template analítico

```text
Ritmo:
Harmonia:
Melodia:
Forma:
Timbre/instrumentação:
Improvisação:
Produção:
Performance:
Contexto:
Comparações:
```

## 26.3 Fragmentos durante a escuta

Notas podem carregar timestamp relativo, mas não devem depender de acesso ao áudio.

```yaml
TimedObservation:
  session_id
  work_id
  position_seconds
  note
  cue_type
```

## 26.4 Síntese posterior

Ao final, o usuário pode:

- manter fragmentos;
- gerar rascunho de síntese por IA;
- escrever síntese;
- marcar perguntas;
- criar relações;
- atualizar conhecimento;
- agendar revisita.

---

# 27. Modo de escuta guiada

O app atua como companion, não player obrigatório.

## 27.1 Antes

Mostrar no máximo:

- pergunta da sessão;
- três cues;
- contexto mínimo;
- duração estimada;
- opção “sem spoilers analíticos”.

## 27.2 Durante

Interface reduzida:

- título;
- progresso manual ou vindo da integração;
- cue atual opcional;
- captura rápida;
- marcar momento;
- pausar guia;
- sair sem perder.

## 27.3 Depois

Perguntas adaptativas:

- O que mais permaneceu?
- Que trecho você revisitaria?
- O que pareceu familiar?
- Que relação ficou mais clara?
- Qual é o próximo passo?

## 27.4 Modos

- `Casual`: apenas início/fim e ressonância opcional;
- `Atento`: três cues;
- `Analítico`: estrutura detalhada;
- `Comparativo`: A/B;
- `Instrumentista`: foco em execução;
- `Histórico`: contexto e fontes;
- `Revisita`: compara com encontro anterior.

---

# 28. Laboratório de comparação

Comparação é um dos mecanismos mais fortes de aprendizagem.

Permitir 2 a 5 itens:

- gravações da mesma obra;
- álbuns próximos;
- gêneros;
- artistas;
- versões ao vivo/estúdio;
- fases do mesmo artista;
- interpretações;
- mixes/masters quando metadata permitir.

## 28.1 Matriz

Linhas configuráveis:

- forma;
- andamento;
- groove;
- dinâmica;
- timbre;
- instrumentação;
- harmonia;
- espaço;
- improvisação;
- produção;
- emoção declarada;
- contexto histórico.

Colunas = itens.

## 28.2 Blind mode

Opcionalmente ocultar identidade para treino auditivo. O usuário deve fornecer áudio/serviço externamente; o app apenas controla o experimento.

## 28.3 Resultado

- diferenças;
- semelhanças;
- preferência e motivo;
- confiança;
- relações criadas;
- conhecimento atualizado;
- nota reutilizável.

---

# 29. Linha do tempo e River View

## 29.1 Escalas

- décadas;
- anos;
- meses para cenas recentes;
- linha pessoal sobreposta;
- linha de vida do usuário;
- fase de carreira de artista;
- história de uma obra.

## 29.2 Eventos

- lançamentos;
- formações;
- dissoluções;
- gravações;
- mudanças tecnológicas;
- festivais;
- movimentos sociais relevantes;
- encontros pessoais;
- shows;
- aquisições;
- início de prática.

## 29.3 Overlays

- história global;
- Brasil;
- território selecionado;
- instrumento;
- tecnologia;
- vida pessoal;
- expedição.

## 29.4 Cuidado historiográfico

Eventos sociais e políticos devem ser contextualizados por fontes. O sistema não deve afirmar causalidade simplista.

---

# 30. Cartografia geográfica e cenas

Uma cena é mais que coordenada. Ela combina:

- período;
- cidade/região;
- locais;
- pessoas;
- selos;
- estúdios;
- instituições;
- redes;
- condições sociais;
- obras.

## 30.1 Scene profile

```yaml
MusicScene:
  title
  location_ids[]
  active_period
  description
  participants[]
  venues[]
  labels[]
  studios[]
  works[]
  territories[]
  historical_claims[]
  sources[]
```

## 30.2 Viagem

Ao planejar viagem:

- cenas relacionadas;
- casas de show;
- museus;
- lojas;
- estúdios históricos;
- concertos;
- obras para preparar;
- diário posterior.

Dados atuais de locais e eventos exigem integração específica e verificação recente; o Atlas não deve depender deles para o núcleo.

---

# 31. Biblioteca, caixas e coleções

A biblioteca pessoal representa posse, acesso e significado.

Tipos de coleção:

- álbuns formativos;
- próximos portais;
- obras para piano;
- discos para ouvir com atenção;
- favoritos de produção;
- “não entendi ainda”;
- versões de uma composição;
- jazz brasileiro;
- capas;
- vinis possuídos;
- recomendações de pessoas;
- trilha de uma viagem;
- obras para o álbum autoral do usuário.

## 31.1 Coleção não é playlist

Uma coleção pode conter:

- nós heterogêneos;
- ordem;
- justificativa;
- notas;
- relações;
- critérios;
- história;
- artefato externo opcional.

## 31.2 Caixa física

Integra `InventoryItem`:

- formato;
- edição;
- condição;
- local;
- valor pago;
- data;
- fotos;
- MusicBrainz/Discogs IDs;
- empréstimo;
- assinatura;
- desejo de compra.

---

# 32. Repertório e prática instrumental

O Atlas conecta escuta e execução.

## 32.1 Da obra ao repertório

Ação `Adicionar ao repertório` cria ou liga `RepertoireItem`.

Relacionamentos:

- obra original;
- gravação de referência;
- arranjo;
- instrumento;
- seção;
- conceito;
- território;
- dificuldade;
- evidência.

## 32.2 Linhas de prática

- transcrever;
- tirar de ouvido;
- analisar harmonia;
- estudar voicing;
- acompanhar;
- improvisar;
- memorizar forma;
- tocar com gravação;
- criar variação;
- gravar versão.

## 32.3 Efeito no mapa

Prática pode aumentar incorporação, mas não contextualização automaticamente.

## 32.4 Composição

Um projeto autoral pode declarar influências conscientes:

```yaml
CreativeInfluence:
  project_id
  node_id
  aspect
  intention
  evidence_note
  ethical_or_cultural_note_optional
```

O app deve diferenciar influência declarada de semelhança inferida.

## 32.5 Flashcards de repertório — ver §77

`FlashcardKind.repertoire` já existe no app. O Atlas **propõe** cartões a partir de uma peça, de uma sessão de prática ou de um laboratório de comparação; o utilizador confirma. O SRS continua em `/flashcards`. Não se cria um cartão por cada álbum ouvido.

---

# 33. Conceitos musicais e escuta ativa

`MusicConcept` pode ser nó próprio.

Categorias:

- ritmo;
- harmonia;
- melodia;
- forma;
- textura;
- timbre;
- técnica;
- improvisação;
- produção;
- performance;
- estética;
- sociologia/história.

## 33.1 Cue

```yaml
ListeningCue:
  concept_id
  prompt
  difficulty
  target_node_ids[]
  expected_observation_optional
  spoiler_level
  source
```

## 33.2 Evidência de reconhecimento

- autoavaliação;
- comparação;
- quiz opcional;
- anotação em timestamp;
- execução;
- explicação;
- identificação em obra não vista.

## 33.3 Não transformar tudo em teoria

Um usuário pode explorar historicamente sem estudar harmonia. O sistema adapta profundidade.

---

# 34. Descoberta social

## 34.1 Recomendações recebidas

```yaml
MusicRecommendation:
  from_person_id_optional
  raw_text
  parsed_node_ids[]
  reason_optional
  received_at
  context
  status
  response_note_optional
```

## 34.2 Linhagem de descoberta

O Atlas mostra:

```text
amigo -> artista -> entrevista -> álbum -> território -> expedição
```

## 34.3 Compartilhamento

Exportar:

- rota;
- mapa recortado;
- coleção comentada;
- diário selecionado;
- retrospectiva;
- cartão de descoberta.

Privacidade granular. Não compartilhar automaticamente histórico completo.

## 34.4 Conversa como evidência

Uma conversa pode:

- revelar rumor;
- criar nota;
- registrar pessoa;
- criar pergunta;
- atualizar articulação se o usuário desejar.

---

# 35. Integração com a Crônica

Eventos musicais relevantes entram na timeline:

- `MusicTerritoryDiscovered`;
- `MusicLandmarkVisited`;
- `MusicExpeditionStarted`;
- `MusicExpeditionCompleted`;
- `MusicOpinionChanged`;
- `MusicWorkRevisited`;
- `MusicConnectionMade`;
- `LivePerformanceAttended`;
- `RepertoirePiecePerformed`;
- `MusicArtifactCreated`.

## 35.1 Resumo semanal

Se houver atividade:

```text
Música
- Você visitou 3 obras na rota de jazz elétrico.
- A conexão entre improvisação modal e texturas de estúdio foi registrada em duas notas.
- “Obra X” passou de visitada para conectada.
- Ficou aberta a pergunta: ...
```

## 35.2 Retrospectiva anual

- territórios vivos;
- novas fronteiras;
- obras formativas;
- mudanças de gosto;
- shows;
- repertório;
- criações;
- pessoas que abriram caminhos;
- mapa antes/depois.

A IA redige apenas a partir de evidências selecionadas.

---

# 36. Integração com Skills e Pesquisa

## 36.1 Skills

Skills possíveis:

- escuta crítica;
- história da música;
- teoria musical;
- análise;
- piano;
- guitarra;
- composição;
- arranjo;
- improvisação;
- produção;
- curadoria;
- escrita sobre música.

O Atlas fornece evidências, mas não define nível sozinho.

## 36.2 ResearchNode

Todo `MusicNode` pode opcionalmente mapear para um `ResearchNode`.

Exemplo:

```text
MusicNode: Jazz modal
ResearchNode: Reconhecer e contextualizar linguagem modal no jazz
Goal rubric:
- distinguir de bebop/hard bop em exemplos;
- explicar contexto mínimo;
- reconhecer três estratégias;
- comparar duas obras;
```

## 36.3 LearningPath

Uma trilha como “História do jazz” pode usar o Atlas como interface visual, sem duplicar sessões.

## 36.4 Perguntas de pesquisa

O usuário pode criar perguntas independentes:

- “Por que este disco soa tão espacial?”
- “De onde vem esta célula rítmica?”
- “Qual a relação real entre X e Y?”
- “Como este pianista constrói voicings?”

Perguntas se conectam a expedições e notas.

## 36.5 Pesquisa como está no app (não um clone)

A árvore de pesquisa já existe (`/research`, sessões, evidência, WIP, links quest↔research). O Atlas **não** cria uma segunda árvore.

Contrato:

| Atlas | Pesquisa |
|---|---|
| `MusicNode` (obra, artista, território, conceito) | opcionalmente ligado a `ResearchNode` |
| Encontro / sessão de escuta | `LearningSession` + `ResearchEvidence` quando o usuário **afirma** evidência |
| Expedição curta | fica no Atlas |
| Expedição longa com propósito | pode promover a `Quest` ligada a um ou mais nós |
| “Cartografado” | **não** marca o ResearchNode como demonstrado |

Um álbum ouvido não demonstra o nó “Reconhecer linguagem modal”. Demonstrar exige rubrica + evidência (comparar duas obras, explicar, tocar um trecho, cartão SRS estável — à escolha do usuário).

`ResearchKnowledgeLink.kind`:

- `primary` — o nó de pesquisa *é* este território/conceito;
- `related` — contexto;
- `practice` — baralho ou repertório que treina o nó.

## 36.6 Flashcards — ver §77

Ponte obrigatória com ADR-036/037/038/039. Resumo: Atlas gera *candidatos* a cartão; o usuário confirma; SRS vive em `/flashcards`. Detalhe normativo na §77.

---

# 37. Integração com Missões, Agenda e Foco

## 37.1 Quest

Uma exploração curta é `MusicExpedition`. Uma iniciativa maior vira `Quest`.

Exemplo:

```text
Quest: Cartografar jazz de 1940 a 1975
Projetos:
- bebop e hard bop;
- modal e avant-garde;
- fusion;
- piano;
- Brasil.
```

## 37.2 Agenda

Tipos:

- escuta casual reservada;
- sessão analítica;
- prática;
- show;
- aula;
- leitura;
- revisão de mapa.

Eventos podem abrir diretamente no modo correspondente.

`WorkType.music` já existe na grelha. Um `ScheduleBlock` com este tipo deep-linka para o Atlas, para a sessão de escuta ou para `/flashcards?area=musica` — não para um quarto calendário.

## 37.3 Focus Session

Sessão de foco musical mostra:

- pergunta;
- obra;
- cues;
- notas;
- referências;
- condição de saída.

## 37.4 Bills

Bills opcionais:

- “manter uma sessão de descoberta por semana”;
- “revisitar repertório a cada 30 dias”;
- “processar rumores salvos”.

Nunca criar streak punitivo.

---

# 38. Integração com Viagens, Locais e Eventos

Viagem pode ter uma `MusicLayer`:

- trilha de preparação;
- história local;
- cenas;
- shows;
- lojas;
- obras associadas;
- gravações para deslocamento;
- diário pós-viagem.

Exemplo de fluxo:

1. criar viagem;
2. ativar camada musical;
3. escolher interesses;
4. Atlas propõe escopo;
5. usuário agenda uma sessão de preparação;
6. registra show/local;
7. evento entra na Crônica;
8. território ganha encontro geográfico.

Informações atuais sobre eventos e estabelecimentos devem ser buscadas por adapters externos no momento do uso.

---

# 39. Integração com Recursos e Finanças

Categorias vinculáveis:

- streaming;
- discos;
- instrumentos;
- manutenção;
- aulas;
- cursos;
- shows;
- viagens;
- livros;
- software;
- equipamentos.

O Atlas pode mostrar custo associado a um projeto ou prática, mas não deve transformar valor cultural em retorno financeiro.

Exemplos:

- custo anual de assinaturas musicais;
- orçamento para shows;
- patrimônio de instrumentos e coleção;
- gastos de uma expedição presencial;
- decisão de comprar instrumento.

---

# 40. Storyteller musical

O Storyteller musical observa padrões e oferece intervenções raras.

## 40.1 Tipos de carta

- `Portal avistado`;
- `Território adormecido`;
- `Conexão recorrente`;
- `Revisita oportuna`;
- `Pergunta sem resposta`;
- `Marco da expedição`;
- `Gravado sem encontro` (sinal Spotify / inbox);
- `Prática à espera` (cartões de Música vencidos);
- `Contraste útil`;
- `Memória musical`;
- `Obra para o momento`;
- `Viagem musical próxima`.

## 40.2 Exemplos

```text
PORTAL AVISTADO
Você registrou forte interesse por improvisação elétrica, formas longas e texturas de estúdio.
Uma rota curta até Canterbury pode começar por três obras que compartilham esses traços.
[Inspecionar rota] [Agora não]
```

```text
REVISITA OPORTUNA
Há três anos você descreveu este álbum como “interessante, mas opaco”.
Desde então, você cartografou duas correntes que podem mudar essa escuta.
[Planejar revisita] [Arquivar sugestão]
```

## 40.3 Regras

- máximo configurável;
- sem culpa;
- sem fake urgency;
- não interromper sessão;
- explicar evidência;
- feedback ajusta frequência;
- nenhuma inferência emocional invasiva.

Até existir LLM no app (ADR-033), as cartas musicais são **templates `rules_v1`** no `NarrativeDigest` já enviado — não um segundo Storyteller. Inputs: expedições activas, encontros recentes, inbox Spotify, cartões vencidos na área Música, blocos `WorkType.music`. Evidências são ids clicáveis.

---

# 41. Assistente de IA musical

Há **dois** canais. Confundi-los reproduz o erro que o app já evitou em Flashcards.

| Canal | Onde corre | Quando entra |
|---|---|---|
| **A. Prompt copiável + JSON** | IA *externa* (ChatGPT, Claude, etc.) | Fatia cedo — §76 e §79 |
| **B. LLM remoto dentro do app** | opt-in, defer ADR-033 | Só depois do núcleo + import + Spotify |

O canal A **não** é “IA do Colony”. É o mesmo padrão de `flashcardsImportPromptLive`: o mapa atual vira um prompt; a pessoa cola o JSON; o app valida, pré-visualiza e aplica.

## 41.1 Funções permitidas (canal B, futuro)

- sugerir escopo;
- montar expedição;
- gerar cues;
- resumir notas;
- propor relações pessoais;
- comparar observações do usuário;
- criar perguntas;
- explicar metadata;
- sugerir fontes;
- localizar lacunas;
- converter texto livre em entidades;
- gerar visão de mapa;
- identificar duplicatas prováveis;
- redigir retrospectiva;
- produzir rascunho de playlist comentada.

## 41.2 Funções restritas

- afirmar influência sem fonte;
- inventar créditos;
- citar letra extensamente;
- inferir identidade ou estado mental por gosto;
- alterar perfil de gosto silenciosamente;
- recomendar apenas pelo que maximiza engajamento;
- tratar popularidade como qualidade;
- gerar biografia fictícia;
- confundir edição, gravação, release e obra.

## 41.3 Pipeline

1. identificar intenção;
2. selecionar escopo e dados autorizados;
3. resolver entidades;
4. recuperar relações factuais e claims;
5. recuperar encontros pessoais;
6. separar fatos, interpretações e preferências;
7. gerar saída estruturada;
8. validar IDs e fontes;
9. apresentar preview;
10. salvar apenas com confirmação.

## 41.4 Contrato de saída de rota

```json
{
  "title": "string",
  "question": "string",
  "scope": "string",
  "rationale": "string",
  "stops": [
    {
      "node_id": "uuid-or-unresolved",
      "role": "bridge",
      "reason": "string",
      "cues": ["string"],
      "source_refs": ["id"]
    }
  ],
  "uncertainties": ["string"],
  "alternatives": []
}
```

Se `node_id` não resolver, a rota fica em draft e exige reconciliação.

---

# 42. Recomendação explicável

## 42.1 Objetivos de recomendação

- proximidade;
- ponte;
- novidade;
- diversidade;
- contexto;
- revisão;
- prática;
- oportunidade temporal;
- pedido explícito.

## 42.2 Cartão

```text
POR QUE ESTE NÓ?

Objetivo: criar uma ponte entre fusion e Canterbury.
Sinais usados:
- ressonância alta com improvisação elétrica;
- interesse em formas longas;
- três encontros recentes com teclados e timbres de estúdio;
- ausência de contato registrado com a cena de Canterbury.

O que será diferente:
- humor mais pastoral;
- estruturas menos centradas em virtuosismo;
- influência de rock britânico e composição coletiva.

Confiança: média
[Adicionar à rota] [Ver evidências] [Não sugerir por este motivo]
```

## 42.3 Feedback

- já conheço;
- não me interessa;
- bom portal;
- distante demais;
- factualidade incorreta;
- não usar este sinal;
- sugerir depois;
- ocultar nó.

---

# 43. Proteção contra bolhas e canonização

## 43.1 Diversity budget

O usuário pode configurar equilíbrio de recomendações:

- aprofundamento;
- adjacência;
- alta novidade;
- regiões subrepresentadas;
- artistas menos conhecidos;
- cânones alternativos;
- obras recentes;
- obras históricas.

Não usar cotas ocultas.

## 43.2 Bias report

Por escopo, mostrar:

- cobertura geográfica;
- períodos;
- proporção de fontes;
- concentração em poucos artistas;
- lacunas declaradas;
- dependência de um único cânone;
- confiabilidade da metadata.

Sem julgamento moral.

## 43.3 Cânones comparáveis

Uma obra pode aparecer em várias listas. Mostrar:

- lista;
- critério;
- autor/instituição;
- data;
- recorte;
- posição opcional;
- divergências.

## 43.4 Sair do algoritmo

Ação `Me surpreenda fora do meu perfil` exige:

- escopo;
- distância;
- preparação;
- limite;
- motivo curatorial.

---

# 44. Modelo de dados de domínio

## 44.1 MusicNode

```yaml
MusicNode:
  id
  node_type:
    artist
    group
    person
    work
    recording
    release_group
    release
    track
    territory
    genre
    movement
    scene
    label
    venue
    studio
    instrument
    concept
    technique
    technology
    event
    source
  canonical_name
  sort_name
  aliases[]
  description_optional
  begin_at_optional
  end_at_optional
  location_ids[]
  external_identities[]
  metadata_quality
  provenance
  created_at
  updated_at
  deleted_at
```

## 44.2 PersonalMusicNodeState

```yaml
PersonalMusicNodeState:
  profile_id
  node_id
  discovery_state
  resonance
  interest_phase
  first_encounter_at
  last_encounter_at
  encounter_count
  knowledge_dimensions
  declared_affinity_tags[]
  personal_summary_optional
  next_action_optional
  revisit_at_optional
  visibility
  version
```

## 44.3 MusicMapScope

```yaml
MusicMapScope:
  id
  profile_id
  title
  scope_statement
  root_node_ids[]
  inclusion_rules[]
  exclusions[]
  time_range_optional
  region_ids[]
  relation_types[]
  projection_defaults
  curator_refs[]
  user_goal
  status
```

## 44.4 SavedProjection

```yaml
SavedMusicProjection:
  id
  scope_id
  projection_type
  filters
  layout_version
  pinned_nodes[]
  hidden_nodes[]
  manual_positions[]
  camera_state
  layer_config
```

## 44.5 AffinitySignal

```yaml
AffinitySignal:
  profile_id
  dimension
  value
  polarity
  evidence_refs[]
  source: declared | derived | ai_proposed
  confidence
  valid_from
  valid_to_optional
  user_review_status
```

---

# 45. Relação com entidades existentes

## 45.1 KnowledgeSource

`KnowledgeSource` permanece a entidade de material consumível. Um álbum pode ser:

- `KnowledgeSource(type=album)`;
- ligado a `MusicNode(type=release_group/release)`;
- ligado a `MusicWork` quando necessário;
- enriquecido por identifiers.

## 45.2 ResearchNode

`MusicNode` representa objeto do mundo musical. `ResearchNode` representa objetivo de aprendizado.

Exemplo:

```text
MusicNode = bebop
ResearchNode = reconhecer características fundamentais do bebop
```

## 45.3 Evidence

Tipos musicais:

```text
attentive_listen
comparison_note
historical_summary
recognition_check
performance_recording
transcription
analysis
playlist_with_rationale
essay
teaching
composition
concert_reflection
```

## 45.4 DomainEvent

Toda descoberta relevante gera evento, mas reproduções brutas não precisam gerar eventos individuais na Crônica.

## 45.5 KnowledgeArea, tags e Flashcard

O mapa de conhecimento (ADR-036/037/039) já tem o ramo canónico `arts.music` (`Artes / Música`), com filhos `Teoria musical` e `Tropicalismo` (este último também em `História / Brasil`). O Atlas **não** cria um segundo mapa.

| Entidade existente | Papel no Atlas |
|---|---|
| `KnowledgeArea` (`arts.music*`, `arts.harmony`, `arts.piano`) | prateleira; `areaPath` do import JSON |
| `Flashcard` / `FlashcardDeck` | prática; kinds `repertoire`, `cloze`, `basic` |
| `FlashcardTag` | classificação cruzada (`Jazz`, `Música / Harmonia`) |
| `ResearchKnowledgeLink` | `primary` / `related` / `practice` entre nó de pesquisa e área |
| `Flashcard.researchNodeId` / `FlashcardDeck.researchNodeId` | foco primário do baralho, se houver |

Candidatos a cartão gerados pelo Atlas são *rascunhos*. Só entram no SRS depois de confirmação (mesmo ritual do import de flashcards).

## 45.6 IntegrationConsent

`IntegrationKind` hoje tem `calendarIcs` e `notificationListener`. O Atlas acrescenta kinds, sem novo ecrã de permissões:

- `spotify` — OAuth PKCE; tokens em secure storage;
- `musicbrainz` — User-Agent + cache; sem conta;
- `musicJsonImport` — consentimento de aplicar um documento (opcional; o picker já é explícito).

Revogar Spotify **não** apaga nós, encontros nem expedições já gravados. Apaga tokens, cursors e cache bruto do provider.

## 45.7 WorkType.music e Habitat

`WorkType.music` já existe na grelha de trabalho. Blocos de agenda e sessões de foco com este tipo deep-linkam para o Atlas, para uma sessão de escuta ou para `/flashcards?area=musica`.

O Habitat (spec living pawn) pode ter um objecto piano/estante: inspecionar abre prática, repertório ou Atlas. **Sem autoplay.** Sem SDK de reprodução.

---

# 46. Schema relacional inicial

Referência conceitual para Drift. Ajustar naming ao projeto pai.

```sql
CREATE TABLE music_nodes (
  id TEXT PRIMARY KEY,
  node_type TEXT NOT NULL,
  canonical_name TEXT NOT NULL,
  sort_name TEXT NOT NULL,
  description TEXT,
  begin_at INTEGER,
  end_at INTEGER,
  metadata_quality REAL,
  provenance_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  version INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_music_nodes_type_name
  ON music_nodes(node_type, sort_name);

CREATE TABLE music_node_aliases (
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  alias TEXT NOT NULL,
  locale TEXT,
  alias_type TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(node_id, alias, locale)
);

CREATE TABLE music_external_identities (
  id TEXT PRIMARY KEY,
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  provider TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  external_id TEXT NOT NULL,
  external_url TEXT,
  confidence REAL NOT NULL,
  reviewed_by_user INTEGER NOT NULL DEFAULT 0,
  metadata_json TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE UNIQUE INDEX idx_music_external_identity
  ON music_external_identities(provider, entity_type, external_id);

CREATE TABLE music_relation_claims (
  id TEXT PRIMARY KEY,
  from_node_id TEXT NOT NULL REFERENCES music_nodes(id),
  to_node_id TEXT NOT NULL REFERENCES music_nodes(id),
  relation_type TEXT NOT NULL,
  directionality TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  confidence REAL,
  valid_from INTEGER,
  valid_to INTEGER,
  provenance_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_music_rel_from
  ON music_relation_claims(from_node_id, relation_type);
CREATE INDEX idx_music_rel_to
  ON music_relation_claims(to_node_id, relation_type);

CREATE TABLE music_relation_sources (
  relation_id TEXT NOT NULL REFERENCES music_relation_claims(id),
  knowledge_source_id TEXT NOT NULL,
  locator TEXT,
  note TEXT,
  PRIMARY KEY(relation_id, knowledge_source_id)
);

CREATE TABLE personal_music_node_states (
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  discovery_state TEXT NOT NULL,
  resonance INTEGER,
  interest_phase TEXT,
  first_encounter_at INTEGER,
  last_encounter_at INTEGER,
  encounter_count INTEGER NOT NULL DEFAULT 0,
  personal_summary TEXT,
  next_action TEXT,
  revisit_at INTEGER,
  visibility TEXT NOT NULL DEFAULT 'normal',
  declared_dimensions_json TEXT NOT NULL,
  inferred_dimensions_json TEXT,
  confidence_json TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY(profile_id, node_id)
);

CREATE TABLE music_encounters (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  encounter_type TEXT NOT NULL,
  occurred_at INTEGER NOT NULL,
  duration_seconds INTEGER,
  completion_ratio REAL,
  attention_quality INTEGER,
  resonance INTEGER,
  familiarity_before INTEGER,
  familiarity_after INTEGER,
  context_json TEXT NOT NULL,
  note TEXT,
  source_type TEXT NOT NULL,
  provenance_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_music_encounter_node_time
  ON music_encounters(profile_id, node_id, occurred_at);
CREATE INDEX idx_music_encounter_time
  ON music_encounters(profile_id, occurred_at);

CREATE TABLE music_map_scopes (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL,
  scope_statement TEXT NOT NULL,
  user_goal TEXT,
  status TEXT NOT NULL,
  inclusion_rules_json TEXT NOT NULL,
  exclusions_json TEXT NOT NULL,
  time_range_json TEXT,
  projection_defaults_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE music_scope_nodes (
  scope_id TEXT NOT NULL REFERENCES music_map_scopes(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  role TEXT NOT NULL,
  inclusion_reason TEXT,
  display_weight REAL,
  PRIMARY KEY(scope_id, node_id)
);

CREATE TABLE music_saved_projections (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  scope_id TEXT NOT NULL REFERENCES music_map_scopes(id),
  title TEXT NOT NULL,
  projection_type TEXT NOT NULL,
  filter_json TEXT NOT NULL,
  layout_json TEXT NOT NULL,
  camera_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE music_expeditions (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  scope_id TEXT REFERENCES music_map_scopes(id),
  quest_id TEXT,
  title TEXT NOT NULL,
  question TEXT NOT NULL,
  purpose TEXT,
  expedition_type TEXT NOT NULL,
  status TEXT NOT NULL,
  difficulty TEXT,
  expected_minutes INTEGER,
  pacing TEXT,
  success_definition TEXT,
  constraints_json TEXT NOT NULL,
  started_at INTEGER,
  completed_at INTEGER,
  abandoned_at INTEGER,
  abandonment_reason TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE music_expedition_stops (
  id TEXT PRIMARY KEY,
  expedition_id TEXT NOT NULL REFERENCES music_expeditions(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  display_order INTEGER NOT NULL,
  role TEXT NOT NULL,
  reason TEXT,
  cues_json TEXT NOT NULL,
  prerequisite_stop_ids_json TEXT NOT NULL,
  is_optional INTEGER NOT NULL DEFAULT 0,
  estimated_minutes INTEGER,
  completion_rule_json TEXT NOT NULL,
  completion_state TEXT NOT NULL,
  completed_at INTEGER
);
CREATE INDEX idx_music_expedition_stops
  ON music_expedition_stops(expedition_id, display_order);

CREATE TABLE music_timed_observations (
  id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL REFERENCES music_encounters(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  position_seconds INTEGER,
  cue_type TEXT,
  note TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE music_affinity_signals (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  dimension TEXT NOT NULL,
  value TEXT NOT NULL,
  polarity REAL NOT NULL,
  source TEXT NOT NULL,
  confidence REAL NOT NULL,
  evidence_refs_json TEXT NOT NULL,
  user_review_status TEXT NOT NULL,
  valid_from INTEGER NOT NULL,
  valid_to INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE music_recommendations (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  node_id TEXT NOT NULL REFERENCES music_nodes(id),
  recommendation_goal TEXT NOT NULL,
  rationale_json TEXT NOT NULL,
  evidence_refs_json TEXT NOT NULL,
  confidence REAL NOT NULL,
  status TEXT NOT NULL,
  generated_by TEXT NOT NULL,
  generated_at INTEGER NOT NULL,
  acted_at INTEGER,
  feedback_json TEXT
);

CREATE TABLE music_recommendations_received (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  from_person_id TEXT,
  raw_text TEXT NOT NULL,
  parsed_node_ids_json TEXT NOT NULL,
  reason TEXT,
  received_at INTEGER NOT NULL,
  status TEXT NOT NULL,
  response_note TEXT,
  provenance_json TEXT NOT NULL
);
```

## 46.1 Full-text search

Criar FTS para:

- nomes;
- aliases;
- notas;
- descrições;
- perguntas;
- cues;
- títulos de expedição.

## 46.2 Tabelas de importação e Spotify

Acrescentar na mesma família de migrations (ou na imediata a seguir ao núcleo):

```sql
CREATE TABLE music_import_runs (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL REFERENCES profiles(id),
  source_kind TEXT NOT NULL, -- json | spotify_library | spotify_recent
                             -- | spotify_playlist | listenbrainz | csv
  status TEXT NOT NULL,      -- preview | applied | rolled_back | failed
  document_version INTEGER,
  item_count INTEGER NOT NULL DEFAULT 0,
  created_count INTEGER NOT NULL DEFAULT 0,
  skipped_count INTEGER NOT NULL DEFAULT 0,
  conflict_count INTEGER NOT NULL DEFAULT 0,
  provenance_json TEXT NOT NULL,
  report_json TEXT,
  created_at INTEGER NOT NULL,
  applied_at INTEGER,
  rolled_back_at INTEGER
);

CREATE TABLE music_import_staging (
  id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES music_import_runs(id),
  raw_json TEXT NOT NULL,
  normalized_title TEXT,
  normalized_artist TEXT,
  external_provider TEXT,
  external_id TEXT,
  proposed_node_id TEXT,
  resolution TEXT NOT NULL, -- create | link | skip | conflict
  user_decision TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_music_staging_run ON music_import_staging(run_id);

CREATE TABLE music_spotify_sync_state (
  profile_id TEXT PRIMARY KEY REFERENCES profiles(id),
  consent_id TEXT NOT NULL,
  granted_scopes_json TEXT NOT NULL,
  library_cursor TEXT,
  recent_cursor TEXT,
  last_library_at INTEGER,
  last_recent_at INTEGER,
  last_playlist_at INTEGER,
  capability_probe_json TEXT NOT NULL,
  last_error TEXT,
  updated_at INTEGER NOT NULL
);

-- Tokens NUNCA nesta tabela nem no export. Secure storage apenas.
```

Identidades Spotify reutilizam `music_external_identities` com `provider='spotify'` (`album`, `artist`, `track`, `playlist`, `show`). ISRC, MusicBrainz ID e Spotify ID convivem no mesmo nó.

## 46.3 Migração

A primeira migration do Atlas deve:

1. criar tabelas;
2. criar indexes;
3. registrar feature flag;
4. migrar álbuns existentes de `KnowledgeSource` para links, sem duplicar;
5. criar estado pessoal mínimo para repertório já existente;
6. produzir relatório de reconciliação.

---

# 47. Eventos de domínio

Eventos mínimos:

```text
MusicNodeCreated
MusicNodeResolved
MusicNodeMerged
MusicNodeStateChanged
MusicEncounterRecorded
MusicEncounterCorrected
MusicTerritoryDiscovered
MusicRelationClaimAdded
MusicRelationClaimDisputed
MusicExpeditionDrafted
MusicExpeditionStarted
MusicExpeditionPaused
MusicExpeditionCompleted
MusicExpeditionAbandoned
MusicStopCompleted
MusicConnectionMade
MusicOpinionChanged
MusicWorkRevisited
MusicRecommendationGenerated
MusicRecommendationAccepted
MusicRecommendationRejected
MusicAffinitySignalProposed
MusicAffinitySignalConfirmed
MusicAffinitySignalRejected
MusicMapScopeCreated
MusicProjectionSaved
MusicArtifactCreated
MusicAtlasJsonImported
MusicAtlasJsonRolledBack
FlashcardCandidateProposed
FlashcardCandidateAccepted
SpotifyLinked
SpotifyRevoked
SpotifyLibraryPulled
SpotifyRecentStaged
SpotifyPlaylistDrafted
SpotifyNowPlayingCaptured
SpotifyCapabilityDegraded
```

Payloads devem conter somente IDs e mudanças necessárias, não blobs completos.

---

# 48. Máquinas de estado

## 48.1 Expedition

```text
draft
  -> ready
  -> active
  -> paused
  -> completed

active/paused
  -> abandoned

completed/abandoned
  -> archived

paused
  -> active
```

Regras:

- `ready` exige pergunta, ao menos uma parada e success definition;
- `completed` aceita resultado reflexivo, não exige todas as paradas opcionais;
- `abandoned` exige motivo opcional, nunca negativo por padrão;
- retomada pode clonar ou reabrir conforme configuração.

## 48.2 Stop

```text
locked -> available -> active -> completed
                    -> skipped
                    -> deferred
```

## 48.3 Recommendation

```text
generated -> viewed -> accepted
                    -> dismissed
                    -> snoozed
                    -> rejected
                    -> invalid
```

## 48.4 Entity resolution

```text
unresolved -> candidate_found -> user_review
           -> resolved
           -> intentionally_local
           -> conflict
```

## 48.5 Personal discovery

Transições descritas na seção 10, com ações explícitas e sugestões reversíveis.

---

# 49. Algoritmos e índices

## 49.1 Regra geral

Nenhum índice deve se chamar “nível musical geral”.

## 49.2 Coverage dentro de escopo

```text
weighted_coverage =
  Σ(node_scope_weight * state_weight * confidence)
  / Σ(node_scope_weight)
```

Obrigatório exibir:

- nome do escopo;
- quantos nós definidos;
- fonte da seleção;
- nós fora do escopo;
- qualidade da metadata;
- dimensão usada.

Nunca mostrar coverage na home global sem escopo.

## 49.3 Density of connection

```text
connection_density =
  confirmed_personal_relations
  / possible_relevant_relations_in_scope
```

Usar apenas para reflexão e com intervalo.

## 49.4 Frontier score

Para nós candidatos:

```text
frontier_score =
  0.25 * graph_proximity
+ 0.20 * goal_alignment
+ 0.15 * bridge_strength
+ 0.15 * information_gain
+ 0.10 * affinity_fit
+ 0.10 * diversity_contribution
+ 0.05 * practical_availability
- fatigue_penalty
- repetition_penalty
```

Todos os pesos configuráveis/versionados.

## 49.5 Bridge strength

Considera:

- relações estruturais compartilhadas;
- relações históricas;
- artistas/obras intermediárias;
- familiaridade com ponto inicial;
- distância do alvo;
- qualidade das fontes.

## 49.6 Information gain

Prioriza nós que:

- conectam clusters;
- resolvem pergunta;
- explicam várias referências;
- preenchem lacuna temporal;
- oferecem contraste.

## 49.7 Revisit opportunity

```text
revisit_score =
  prior_resonance
* knowledge_growth_since_last_visit
* contextual_relevance
* recency_window
```

Não sugerir revisita apenas porque passou tempo.

## 49.8 Affinity inference

Inferência deve ser robusta a repetição automática e playlists.

Sinais:

- encontros atentos > listens passivos;
- notas e comparações > duração;
- revisitas voluntárias > autoplay;
- declaração explícita > inferência;
- rejeição explícita bloqueia sinal.

## 49.9 Knowledge confidence

```text
dimension_confidence =
  evidence_quality
* recency_factor
* context_diversity
* user_confirmation_factor
```

Recência não deve apagar marcos históricos pessoais.

---

# 50. Geração de mapas e layout

## 50.1 Grafo

Requisitos:

- layout determinístico por seed;
- posições persistidas;
- clustering progressivo;
- level-of-detail;
- edge bundling opcional;
- labels sem colisão;
- seleção estável;
- renderização em isolate quando necessário;
- fallback lista.

## 50.2 Layouts

- force-directed para rede;
- layered DAG para genealogia aproximada;
- Sankey modificado para River View;
- timeline lanes;
- radial ego network;
- geographic map com camada temporal;
- manual curated layout.

## 50.3 Não confiar em DAG puro

O grafo musical contém ciclos, relações paralelas e timestamps incertos. A projeção histórica deve:

- selecionar tipos de relação;
- quebrar ciclos apenas visualmente;
- preservar relação na inspeção;
- indicar incerteza.

## 50.4 Level of detail

Zoom distante:

- territórios;
- rios;
- marcos.

Zoom médio:

- artistas;
- obras-chave;
- portais.

Zoom próximo:

- gravações;
- conceitos;
- relações;
- encontros pessoais.

## 50.5 Layout pessoal

Usuário pode fixar posições e criar regiões próprias, sem alterar grafo canônico.

---

# 51. Arquitetura Flutter

Feature-first:

```text
features/
  music_atlas/
    domain/
      entities/
      value_objects/
      repositories/
      services/
      policies/
      events/
    application/
      use_cases/
      queries/
      commands/
      projections/
      recommendations/
      resolution/
    data/
      drift/
      mappers/
      repositories/
      importers/
      adapters/
      cache/
    presentation/
      routes/
      screens/
      widgets/
      controllers/
      painters/
      accessibility/
```

## 51.1 Packages internos sugeridos

```text
packages/
  music_domain/
  graph_layout/
  music_metadata_adapters/
  music_import_pipeline/
```

Não separar em packages prematuramente. Extrair quando houver dependência clara.

## 51.2 Componentes visuais

- `MusicNodeGlyph`;
- `FogLayer`;
- `RelationEdge`;
- `RiverBand`;
- `MapViewport`;
- `MusicInspectPane`;
- `KnowledgeDimensionBars`;
- `ExpeditionStrip`;
- `ListeningCueCard`;
- `ProvenanceBadge`;
- `ClaimConfidenceChip`;
- `PersonalHistoryLane`;
- `BridgeExplanationCard`.

## 51.3 CustomPainter vs engine

Começar com Flutter Canvas/CustomPainter e spatial index. Avaliar engine separado apenas se benchmarks reais falharem.

---

# 52. Estado, repositories e casos de uso

## 52.1 Repositories

```dart
abstract interface class MusicNodeRepository {}
abstract interface class MusicEncounterRepository {}
abstract interface class MusicMapRepository {}
abstract interface class MusicExpeditionRepository {}
abstract interface class MusicRelationRepository {}
abstract interface class MusicRecommendationRepository {}
abstract interface class MusicIdentityRepository {}
abstract interface class MusicAffinityRepository {}
```

## 52.2 Queries

- `GetAtlasProjectionQuery`;
- `GetNodeInspectQuery`;
- `GetTerritorySummaryQuery`;
- `GetPersonalMusicProfileQuery`;
- `GetFrontierCandidatesQuery`;
- `GetExpeditionProgressQuery`;
- `GetChronicleMusicSummaryQuery`;
- `GetMetadataConflictQuery`.

## 52.3 Commands

- `RecordMusicEncounter`;
- `UpdatePersonalMusicState`;
- `CreateMusicMapScope`;
- `DraftMusicExpedition`;
- `StartMusicExpedition`;
- `CompleteExpeditionStop`;
- `AddMusicRelationClaim`;
- `ConfirmAffinitySignal`;
- `ResolveMusicIdentity`;
- `MergeMusicNodes`;
- `CreateComparison`;
- `SaveMusicProjection`.

## 52.4 Transação

Registrar encontro deve, em uma transação:

1. inserir encontro;
2. atualizar contagem e datas;
3. recalcular sugestões de estado;
4. anexar evidências;
5. emitir evento;
6. atualizar parada ativa;
7. invalidar projeções afetadas;
8. enfileirar sync.

---

# 53. Integrações externas

Todas atrás de adapters e feature flags.

## 53.1 MusicBrainz

Uso:

- artistas;
- recordings;
- releases;
- release groups;
- works;
- labels;
- places;
- genres;
- relationships;
- identifiers.

O MusicBrainz oferece API REST em JSON/XML e um modelo rico de relações. Respeitar User-Agent, rate limits e termos.

## 53.2 ListenBrainz

Uso opcional:

- importar listens;
- enviar listens se o usuário desejar;
- feedback;
- recomendações como sinal, nunca fonte de verdade;
- estatísticas.

Tokens em secure storage. Respeitar headers de rate limit.

## 53.3 Apple Music

Uso opcional:

- catálogo;
- biblioteca autorizada;
- ratings;
- histórico recente;
- links de reprodução;
- playlists.

Exige developer token e autorização adequada.

## 53.4 Spotify

Uso opcional e **não** requisito do produto. A especificação normativa do conector está na **§75**.

Resumo: OAuth PKCE no dispositivo, scopes incrementais, importar biblioteca/recents/playlists como *sinais* (não conhecimento), “abrir no Spotify”, captura do que está tocando, reconciliação MusicBrainz. Tokens **fora** do export. Development Mode 2026: capacidades consultadas em runtime.

Sem SDK de playback no MVP. Sem substituir o cliente Spotify. Sem baixar áudio.

## 53.5 Discogs

Uso:

- edições;
- mídia física;
- catálogo;
- marketplace apenas como link, não compra automática;
- detalhes de release.

## 53.6 Wikidata

Uso:

- contexto histórico;
- locais;
- pessoas;
- datas;
- external IDs;
- consultas estruturadas.

Claims importados mantêm provenance e não são automaticamente verdade final.

## 53.7 Cover Art Archive

Uso:

- capas ligadas a MusicBrainz IDs;
- cache respeitando direitos e políticas;
- fallback sem imagem.

## 53.8 Adapters locais

- CSV;
- JSON;
- Last.fm export;
- ListenBrainz export;
- histórico fornecido pelo usuário;
- scrobbler local futuro;
- playlists exportadas;
- arquivos de biblioteca local, mediante permissão.

---

# 54. Resolução de identidade musical

O sistema precisa distinguir:

- obra;
- recording;
- release group;
- release;
- track;
- edição;
- artista;
- credit string.

## 54.1 Matching

Sinais:

- external ID;
- ISRC;
- barcode;
- artist credit;
- título normalizado;
- duração;
- tracklist;
- data;
- edição;
- país;
- medium.

## 54.2 Nunca fundir silenciosamente

Tela de conflito:

```text
“Blue in Green” pode se referir a:
1. composição;
2. recording do álbum X;
3. faixa de edição Y;
4. cover por artista Z.

Escolha o nível desejado.
```

## 54.3 Merge reversível

- manter IDs antigos como aliases;
- redirecionar links;
- registrar evento;
- permitir split;
- preservar provenance.

## 54.4 Entidade local

Se metadata externa não existir, permitir nó local completo.

---

# 55. Importação e reconciliação

## 55.1 Pipeline

1. escolher fonte;
2. validar autorização;
3. importar raw staging;
4. normalizar;
5. resolver identidade;
6. detectar duplicatas;
7. pré-visualizar;
8. confirmar;
9. gravar transacionalmente;
10. gerar relatório.

## 55.2 Histórico não é conhecimento

Após importar:

```text
Foram encontrados 18.402 listens.
- 7.190 nós resolvidos;
- 314 conflitos;
- 2.110 itens com contato recorrente;
- nenhum foi marcado automaticamente como cartografado.
```

## 55.3 Sugestões pós-importação

- obras muito revisitadas;
- artistas formativos por período;
- fases de escuta;
- candidatos a estado “visitado”;
- obras para confirmação;
- ruído/autoplay detectável.

## 55.4 Importação JSON com prompt — ver §76 e §79

Mesmo ritual dos flashcards (ADR-038): copiar prompt vivo → IA externa → colar ou escolher ficheiro → preview → aplicar. Parse em streaming. Sem teto. Sem LLM no dispositivo.

---

# 56. Local-first, sync e cache

## 56.1 Fonte de verdade

Banco local.

## 56.2 Dados externos

Guardar:

- payload bruto necessário;
- data;
- provider;
- etag/last modified;
- parser version;
- licença/uso;
- confidence;
- expiration.

## 56.3 Projeções

Mapas são derivados e cacheáveis:

```yaml
MusicProjectionCache:
  scope_hash
  graph_version
  personal_state_version
  layout_version
  viewport_bucket
  payload
```

## 56.4 Sync

Entidades pessoais sincronizam. Metadata pública pode ser reconstruída, mas IDs e overrides pessoais precisam sincronizar.

## 56.5 Offline

Offline permite:

- abrir mapas cacheados;
- registrar encontros;
- notas;
- concluir paradas;
- editar expedições;
- comparar;
- criar nós locais;
- usar capas já cacheadas;
- enfileirar resolução externa.

---

# 57. Direitos autorais e conteúdo protegido

## 57.1 Áudio

- não baixar áudio de serviços;
- não contornar DRM;
- não hospedar streaming;
- usar deep links;
- arquivos locais apenas por seleção explícita;
- análise de áudio futura exige consentimento e processamento local preferencial.

## 57.2 Letras

- não importar letras integrais por padrão;
- permitir citações curtas, fornecidas pelo usuário e ligadas a fonte;
- IA não deve gerar trechos extensos;
- resumos temáticos são permitidos quando legalmente adequados.

## 57.3 Capas

- armazenar URL/provenance;
- cache técnico limitado;
- respeitar provider;
- exportações públicas devem permitir omitir arte.

## 57.4 Notas

Notas pessoais pertencem ao usuário, mas podem conter material de terceiros; export deve alertar.

---

# 58. Privacidade

## 58.1 Classes

- metadata pública;
- gosto pessoal;
- histórico de escuta;
- notas privadas;
- relações sociais;
- áudio próprio;
- localização;
- integrações.

## 58.2 Defaults

- IA remota off;
- importação manual;
- compartilhamento off;
- localização off;
- histórico detalhado privado;
- inferências exigem revisão quando persistentes.

## 58.3 Perfil de gosto

Não exportar para publicidade. Não compartilhar com terceiros por padrão.

## 58.4 Modo privado

Vault musical separado opcional para:

- letras/notas sensíveis;
- gravações próprias;
- projetos inéditos;
- opiniões privadas;
- colaborações.

---

# 59. Acessibilidade

- modo lista equivalente a todo mapa;
- labels de nós e relações;
- navegação por teclado;
- zoom de texto;
- contraste;
- não depender de cor;
- padrões/espessura para tipos de relação;
- descrição textual da projeção;
- reduzir movimento;
- foco visível;
- cues sem áudio obrigatório;
- timestamps editáveis por teclado;
- leitor de tela anuncia estado pessoal e ação.

Exemplo de descrição:

```text
Território “Jazz modal”.
12 nós revelados de um escopo de 31.
Conecta-se a hard bop, third stream, spiritual jazz e fusion.
Sua última atividade ocorreu há 8 dias.
```

---

# 60. Performance

Metas iniciais:

- abrir Atlas cacheado em < 800 ms em desktop médio e < 1,5 s em celular alvo;
- interação de pan a 60 fps com 1.000 nós visíveis via LOD;
- nunca renderizar 10.000 labels;
- consulta de inspect < 150 ms local;
- registrar encontro < 300 ms;
- layout grande cancelável;
- importação em isolate;
- memória controlada para capas.

Benchmarks:

- 10 anos de listens;
- 100 mil encounters importados;
- 50 mil nós;
- 200 mil relações;
- mapa visível 500/1.000/2.000 nós;
- desktop e Android intermediário.

---

# 61. Estados vazios, erros e edge cases

## 61.1 Primeiro uso

```text
Seu Atlas ainda não tem território revelado.
Comece por:
[Uma obra que me marcou]
[Um gênero que quero entender]
[Importar histórico]
[Explorar sem conta]
```

## 61.2 Metadata conflitante

Mostrar conflito e preservar registro.

## 61.3 Obra indisponível

- marcar indisponível;
- sugerir alternativa;
- manter rota;
- permitir parada por contexto sem áudio.

## 61.4 Gênero controverso

Mostrar múltiplas classificações e fontes.

## 61.5 Usuário não gostou

Registrar sem penalidade e sugerir:

- parar;
- entender contexto;
- tentar obra contrastante;
- arquivar território.

## 61.6 Escuta interrompida

Salvar progresso e não marcar visitado automaticamente.

## 61.7 Reprodução em loop/autoplay

Não inflar afinidade sem confirmação.

## 61.8 Nó duplicado

Resolver com merge preview.

## 61.9 Mudança de gosto

Preservar snapshots históricos.

## 61.10 Sem internet

Usar cache e nós locais.

## 61.11 Mapa grande demais

Sugerir subescopo.

## 61.12 Claim sem fonte

Rotular como nota pessoal/inferência.

---

# 62. Onboarding

O onboarding deve durar de 3 a 8 minutos, com skip.

## 62.1 Etapa 1 — intenção

```text
O que você quer que o Atlas faça primeiro?
- entender melhor o que já amo;
- explorar novos gêneros;
- acompanhar história da música;
- ligar escuta e instrumento;
- organizar álbuns;
- preparar um projeto criativo.
```

## 62.2 Etapa 2 — âncoras

Pedir de 3 a 10:

- artistas;
- álbuns;
- gêneros;
- peças;
- shows;
- conceitos.

## 62.3 Etapa 3 — fronteira

Uma pergunta atual.

## 62.4 Etapa 4 — estilo de exploração

- livre;
- guiado;
- histórico;
- técnico;
- misto.

## 62.5 Etapa 5 — primeiro mapa

Gerar scope pequeno, revisável.

## 62.6 Etapa 6 — primeira expedição

3 a 5 paradas, 60 a 120 minutos totais.

## 62.7 Sem integração obrigatória

Conectar streaming somente depois de demonstrar valor.

---

# 63. Seeds pessoais iniciais

Seeds são sugestões editáveis baseadas em interesses já declarados. Nunca assumir domínio.

## 63.1 Territórios de origem

- jazz;
- funk;
- fusion;
- blues;
- bossa nova;
- samba;
- rock;
- rock progressivo;
- goth rock;
- piano;
- guitarra;
- teoria musical;
- composição.

## 63.2 Fronteiras candidatas

- spiritual jazz;
- third stream;
- jazz brasileiro;
- samba-jazz;
- jazz-funk;
- Canterbury scene;
- zeuhl;
- Rock in Opposition;
- dark jazz/noir jazz como rótulos curatoriais, com cuidado classificatório;
- post-punk e darkwave;
- música impressionista e relações com harmonia modal;
- música minimalista e ambient;
- música brasileira instrumental;
- jazz de vanguarda;
- produção dub;
- neo-soul.

## 63.3 Expedição seed 1

**Título:** Do jazz elétrico ao progressivo de fronteira  
**Pergunta:** como improvisação, timbres elétricos e formas longas atravessam jazz fusion, Canterbury e outras correntes progressivas?  
**Formato:** 7 paradas, 2 semanas, comparação final.  
**Resultado:** mapa anotado e playlist comentada.

## 63.4 Expedição seed 2

**Título:** O eixo samba — bossa — jazz brasileiro  
**Pergunta:** que elementos permanecem, mudam ou são reinterpretados nesses encontros?  
**Formato:** corrente histórica + linha rítmica + piano/guitarra.  
**Resultado:** três comparações e um repertório curto.

## 63.5 Expedição seed 3

**Título:** Escuridão sem caricatura  
**Pergunta:** onde jazz, pós-punk, goth, ambient e música de câmara realmente se encontram em linguagem, produção ou atmosfera?  
**Regra:** diferenciar genealogia histórica de afinidade estética.  
**Resultado:** mapa de pontes com relações classificadas por tipo e confiança.

## 63.6 Expedição seed 4

**Título:** Piano como voz de acompanhamento  
**Pergunta:** como pianistas de tradições diferentes criam espaço, condução e groove?  
**Resultado:** cues, transcrições curtas e aplicação prática.

---

# 64. Cenários end-to-end

## 64.1 Descoberta espontânea

1. usuário ouve álbum;
2. quick capture;
3. resolve identidade;
4. marca ressonância;
5. cria pergunta;
6. nó aparece como visitado;
7. relação “descoberto através de” é registrada;
8. Crônica recebe evento;
9. Storyteller não interrompe.

## 64.2 Expedição guiada

1. usuário escolhe território;
2. seleciona bússola `Conectar`;
3. sistema propõe rota;
4. usuário inspeciona explicações;
5. edita paradas;
6. inicia;
7. registra sessões;
8. compara dois marcos;
9. responde pergunta;
10. conclui;
11. mapa atualiza;
12. síntese entra na Crônica.

## 64.3 Importação

1. conecta ListenBrainz;
2. prévia;
3. reconciliação;
4. grava listens;
5. gera candidatos;
6. usuário confirma obras formativas;
7. cria Personal Constellation;
8. nenhuma obra vira cartografada automaticamente.

## 64.4 Prática

1. abre álbum;
2. seleciona faixa;
3. adiciona peça ao repertório;
4. inicia sessão de transcrição;
5. grava evidência própria;
6. atualiza incorporação;
7. liga conceito;
8. agenda revisão.

## 64.5 Mudança de opinião

1. revisita obra;
2. vê nota antiga;
3. compara percepção;
4. registra mudança;
5. preserva ambas;
6. gera `MusicOpinionChanged`;
7. retrospectiva anual inclui transformação.

## 64.6 Viagem

1. viagem futura;
2. ativa camada musical;
3. escolhe cena;
4. prepara rota;
5. registra local/show;
6. cria memória;
7. liga fotos e transações;
8. território geográfico ganha encontro.

## 64.7 Importação JSON com prompt

1. abre `/research/music-atlas/import?source=json` (ou o sheet a partir do Atlas);
2. copia o prompt vivo (territórios, nós, áreas `Artes / Música`, baralhos, tags);
3. cola num LLM externo com um pedido (“cartografa o tropicalismo a partir do que já tenho”);
4. recebe JSON; cola o texto **ou** escolhe um ficheiro;
5. o parser em streaming produz um plano (criar / ligar / saltar / conflito);
6. o utilizador confirma;
7. nós, claims e encontros entram com `source_type=imported_json`;
8. cartões embutidos opcionais passam pelo mesmo plano de `FlashcardJsonImportPolicy`;
9. nenhum nó fica “cartografado” só porque veio no JSON.

## 64.8 Constelação Spotify

1. em `/settings/integrations`, activa Spotify e concede `user-library-read`;
2. pull-to-refresh importa álbuns gravados como *contacto* (não “conhecido”);
3. a projecção “Constelação Spotify” mostra gravados ∩ cartografados, gravados sem encontro, e cartografados sem Spotify;
4. o utilizador escolhe três álbuns gravados sem encontro e cria uma expedição curta;
5. “Abrir no Spotify” lança `spotify:` / `open.spotify.com`;
6. revogar o consentimento apaga tokens e cursors; os nós locais permanecem.

## 64.9 Da escuta ao cartão

1. termina uma sessão de escuta atenta ou um laboratório de comparação;
2. o Atlas sugere 1–5 candidatos (ano, crédito, conceito ouvido, peça de repertório);
3. o utilizador aceita dois; recusa o resto;
4. os cartões nascem em `/flashcards` com `areaPath` `Artes / Música / …` e tag opcional;
5. o nó de pesquisa ligado recebe `ResearchKnowledgeLink.practice` se o utilizador afirmar a ponte.

---

# 65. Critérios de aceitação

## 65.1 Criar mapa

- usuário define escopo;
- adiciona nós;
- vê projeção;
- salva;
- abre offline;
- alterna para lista;
- entende fonte dos nós.

## 65.2 Registrar encontro

- menos de 10 segundos no modo rápido;
- campos opcionais;
- offline;
- desfazer;
- corrige;
- timeline;
- atualização de estado é preview ou regra explícita.

## 65.3 Criar expedição

- pergunta obrigatória;
- ao menos uma parada;
- justificativa por parada;
- ordem editável;
- paradas opcionais;
- pausa;
- conclusão reflexiva;
- abandono sem punição.

## 65.4 Inspecionar recomendação

- motivo;
- sinais;
- diferenças esperadas;
- confiança;
- ação;
- feedback;
- desligar sinal.

## 65.5 Comparar

- selecionar 2 a 5;
- definir dimensões;
- salvar observação;
- criar relação;
- acessível sem canvas;
- exportar.

## 65.6 Importar histórico

- preview;
- consentimento;
- duplicatas;
- conflicts;
- rollback;
- relatório;
- não inferir domínio automaticamente.

## 65.7 Resolver identidade

- candidatos;
- diferença entre work/recording/release;
- entidade local;
- merge reversível;
- provenance.

## 65.8 Privacidade

- IA remota off;
- export;
- delete;
- revoke;
- vault;
- sem telemetry de gosto por default.

Critérios das fatias novas (JSON, Spotify, Flashcards, superfície) estão na **§80**.

---

# 66. Estratégia de testes

## 66.1 Unit

- transições;
- coverage;
- frontier ranking;
- confidence;
- identity matching;
- dedup;
- import;
- relation claims;
- permission policy;
- `MusicAtlasJsonCodec` / prompt builder;
- dedup por ID externo e título+artista;
- mapeamento Spotify → Encounter(contact);
- capability probe (scope em falta ≠ crash).

## 66.2 Property tests

- coverage entre 0 e 1 dentro de escopo;
- merge não perde links;
- sync idempotente;
- state suggestion não reduz explicit state;
- ranking respeita bloqueios;
- cache hash muda com inputs.

## 66.3 Widget

- Atlas;
- inspect;
- bottom sheet;
- expeditions;
- listening mode;
- comparison;
- conflict;
- empty/error/offline;
- large text;
- screen reader.

## 66.4 Golden

- projeções;
- névoa;
- claims;
- River View;
- Personal Constellation;
- high contrast;
- mobile/desktop.

## 66.5 Integration

- encounter -> state -> event -> chronicle;
- expedition -> session -> completion;
- import -> resolve -> rollback;
- repertoire -> evidence -> skill;
- trip -> scene -> event;
- sync conflict;
- JSON apply -> flashcards plan -> research link;
- Spotify library pull -> constellation overlay -> revoke tokens.

## 66.6 Factuality tests for AI

Fixtures com:

- entidades ambíguas;
- relações falsas;
- créditos conflitantes;
- gênero controverso;
- fontes ausentes.

A IA deve recusar certeza indevida.

---

# 67. Roadmap de implementação

A ordem abaixo **substitui** a tentação de fazer mapa-grafo + LLM + Spotify ao mesmo tempo. O app já tem inbox, import JSON, pesquisa, flashcards e `/settings/integrations`: o Atlas **enche** esses canos antes de inventar UI nova. JSON com prompt e o conector Spotify **não** esperam a Fase 10/11 do spec mestre.

## Fase M0 — Fundação

- tabelas do núcleo (`music_nodes`, estados, encontros);
- models e repositories;
- feature flag;
- FTS;
- domain events;
- testes de migration.

## Fase M1 — Núcleo manual

- criar nós locais;
- estado pessoal;
- encontros;
- notas;
- lista + inspect;
- Crônica.

Produto útil sem mapa complexo e **sem rede**.

## Fase M2 — Importação JSON + prompt para IA

Entra **antes** do grafo. Replica o ritual já enviado em Flashcards (ADR-038):

- `MusicAtlasJsonCodec` + `MusicAtlasJsonPromptBuilder`;
- sheet em `/research/music-atlas/import?source=json`;
- parse streaming (ADR-038 §6 / ADR-042);
- preview → apply → relatório;
- cartões embutidos delegam a `FlashcardJsonImportPolicy`;
- evento `musicAtlasJsonImported`.

Ver §76, §79 e §80.1.

## Fase M3 — Atlas básico

- scope;
- graph;
- Frontier Map;
- névoa;
- pan/zoom;
- list fallback;
- saved projection.

## Fase M4 — Expedições e superfície no app

- planner, stops, camp, listening mode;
- tile na home (ADR-044);
- command palette e menu Mais;
- `WorkType.music` / blocos de agenda;
- digest `rules_v1` (expedição activa, gravados sem encontro).

Ver §78.

## Fase M5 — Conhecimento, flashcards e pesquisa

- dimensões e evidence;
- comparison lab;
- conceitos;
- repertório → candidatos `FlashcardKind.repertoire`;
- `ResearchKnowledgeLink` (`primary` / `related` / `practice`);
- prateleiras `arts.music*`.

Ver §36.5, §77 e §80.3.

## Fase M6 — River View e cenas

- temporal model;
- relation claims;
- River View;
- scene profile;
- geographic links.

## Fase M7 — Metadata pública

- MusicBrainz;
- Cover Art Archive;
- identity resolution;
- import staging;
- conflitos de metadata.

## Fase M8 — Spotify (conector local-first)

**Não espera** Apple Music, Discogs nem LLM. Assim que M1+M2 gravarem encontros:

- `IntegrationKind.spotify` em `/settings/integrations`;
- OAuth PKCE no dispositivo;
- scopes incrementais;
- biblioteca / recents / playlists / currently-playing;
- Constelação Spotify;
- “abrir no Spotify”;
- tokens fora do export;
- capability probe (Development Mode / quotas 2026).

Ver §75 e §80.2. ListenBrainz pode chegar na mesma fase ou logo a seguir, com o mesmo pipeline de staging.

## Fase M9 — Histórico de escuta e constelação pessoal

- agregação de listens (Spotify recents + ListenBrainz + CSV);
- confirmação de candidatos;
- Personal Constellation;
- nenhum listen marca “cartografado”.

## Fase M10 — Recomendação local

- frontier algorithm;
- bridges;
- explanation;
- feedback;
- diversity controls.

## Fase M11 — Outros serviços

- Apple Music;
- Discogs;
- Wikidata;
- adapters adicionais.

## Fase M12 — LLM *dentro* do app (defer)

Canal B da §41. ADR-033. Só depois do núcleo, do JSON e do Spotify. Structured outputs + confirmação. Não substitui o prompt copiável.

## Fase M13 — Maturidade

- performance grande;
- accessibility audit;
- sync;
- vault;
- export visual;
- desktop polish;
- long-term migrations.

---

# 68. Backlog inicial

## Epic A — Domain core

- enums;
- value objects;
- entities;
- policies;
- events;
- repositories;
- fixtures.

## Epic B — Encounter capture

- quick capture;
- identity picker;
- resonance;
- note;
- undo;
- event.

## Epic C — Node inspect

- header;
- tabs;
- personal state;
- provenance;
- relations;
- encounters.

## Epic D — Map scope

- create/edit;
- inclusion;
- source;
- filters;
- persistence.

## Epic E — Graph viewport

- painter;
- spatial index;
- camera;
- LOD;
- selection;
- accessibility list.

## Epic F — Fog

- state styles;
- mode switch;
- reveal animation reduzível;
- legend.

## Epic G — Expedition

- model;
- planner;
- camp;
- stops;
- route line;
- completion.

## Epic H — Listening

- session;
- cues;
- timed notes;
- after flow;
- offline.

## Epic I — Comparison

- selection;
- matrix;
- blind mode;
- result.

## Epic J — Knowledge

- dimensions;
- evidence;
- confidence;
- Pawn musical.

## Epic K — Metadata

- staging;
- MusicBrainz adapter;
- identity;
- merge/split;
- Cover Art.

## Epic L — Recommendation

- candidate generation;
- ranking;
- explainability;
- feedback;
- bias report.

## Epic M — JSON import + prompt

- codec + prompt builder vivo;
- sheet clone dos flashcards;
- streaming parse;
- plan/apply/rollback;
- flashcards embutidos;
- testes de dedup.

## Epic N — Spotify connector

- IntegrationKind + consent UI;
- PKCE + secure storage;
- capability probe;
- library / recent / playlist / now-playing adapters;
- Constelação overlay;
- revoke sem apagar nós;
- deep links `spotify:`.

## Epic O — Pontes Pesquisa / Flashcards / Home

- ResearchKnowledgeLink;
- candidatos a cartão;
- tile e quick action;
- digest rules_v1;
- Habitat piano sem autoplay.

---

# 69. Definition of Done

Uma vertical slice só está pronta quando:

- domínio testado;
- migration testada;
- repository local;
- offline;
- undo quando aplicável;
- event log;
- sync-ready;
- estados empty/loading/error;
- acessibilidade;
- keyboard;
- golden;
- integração;
- provenance;
- privacy review;
- docs;
- critérios demonstrados.

A feature completa só está madura quando:

- pode ser usada sem integração;
- mapas grandes permanecem usáveis;
- relações históricas têm provenance;
- recomendações são explicáveis;
- import não confunde listens com conhecimento;
- o usuário consegue corrigir tudo;
- export preserva dados;
- nenhum score global de valor pessoal existe;
- a experiência parece parte do Life Colony OS.

---

# 70. ADRs obrigatórios

1. `ADR-MUSIC-001`: separação entre MusicNode e ResearchNode;
2. `ADR-MUSIC-002`: work vs recording vs release;
3. `ADR-MUSIC-003`: representação de relações como claims;
4. `ADR-MUSIC-004`: graph rendering;
5. `ADR-MUSIC-005`: layout determinístico e posições pessoais;
6. `ADR-MUSIC-006`: metadata provider priority;
7. `ADR-MUSIC-007`: direitos de capa/cache;
8. `ADR-MUSIC-008`: listens importados vs encounters;
9. `ADR-MUSIC-009`: recommendation weights;
10. `ADR-MUSIC-010`: IA remota e factuality;
11. `ADR-MUSIC-011`: vault de gravações próprias;
12. `ADR-MUSIC-012`: sync de metadata pública;
13. `ADR-MUSIC-013`: Spotify local-first (PKCE, scopes incrementais, tokens fora do export, listens ≠ conhecimento, capability probe);
14. `ADR-MUSIC-014`: importação JSON do Atlas com prompt para IA externa (clone ADR-038; parse streaming; cartões embutidos delegam ao codec de flashcards).

ADRs de produto já existentes que o Atlas **deve citar e não duplicar**:

- ADR-017 / 019 / 021 / 022 — grafo de pesquisa, evidência, canvas, links quest↔research;
- ADR-032 — integrações opt-in;
- ADR-033 — Storyteller `rules_v1`; LLM remoto defer;
- ADR-036 / 037 / 038 / 039 — flashcards, mapa de áreas, import JSON, tags;
- ADR-042 — parse streaming de dumps;
- ADR-044 — home de mini-programas;
- ADR-005 / 015 — local-first e export/restore.

---

# 71. Patch de integração no spec mestre

Aplicar as seguintes alterações em `LIFE_COLONY_OS_SPEC.md`.

## 71.1 Índice

Adicionar após `72. Conhecimento e biblioteca pessoal`:

```text
72A. Atlas Musical Pessoal
```

Ou manter este documento como spec vinculada:

```text
Anexo A — Atlas Musical Pessoal
Fonte: LIFE_COLONY_OS_MUSIC_ATLAS_SPEC.md
```

A segunda opção é preferível para evitar inflar o spec mestre.

## 71.2 Seção 6 — navegação

Adicionar `Atlas Musical` como subdestino de `Pesquisa`.

## 71.3 Seção 15 — Skills

Adicionar:

- escuta crítica;
- história da música;
- curadoria musical;
- transcrição;
- improvisação;
- arranjo;
- produção musical.

## 71.4 Seção 22 — Pesquisa

Adicionar:

```text
Trilhas musicais podem usar o Atlas Musical como projeção especializada do grafo de ResearchNodes.
```

## 71.5 Seção 28 — Crônica

Adicionar tipos de evento da seção 47.

## 71.6 Seção 30 — Storyteller

Adicionar cartas musicais da seção 40.

## 71.7 Seção 31 — IA

Adicionar ferramentas:

```text
draft_music_expedition
explain_music_bridge
summarize_music_encounters
propose_music_relation
resolve_music_entity
```

## 71.8 Seção 32 — ERD

Adicionar:

```mermaid
PROFILE ||--o{ PERSONAL_MUSIC_NODE_STATE : has
MUSIC_NODE ||--o{ MUSIC_ENCOUNTER : receives
MUSIC_NODE ||--o{ MUSIC_RELATION_CLAIM : connects
MUSIC_MAP_SCOPE }o--o{ MUSIC_NODE : includes
MUSIC_EXPEDITION ||--o{ MUSIC_EXPEDITION_STOP : contains
MUSIC_EXPEDITION_STOP }o--|| MUSIC_NODE : visits
MUSIC_ENCOUNTER ||--o{ EVIDENCE : creates
MUSIC_NODE }o--o| KNOWLEDGE_SOURCE : describes
MUSIC_NODE }o--o| RESEARCH_NODE : supports
```

## 71.9 Seção 45 — roadmap

Inserir após Fase 5:

```text
Fase 5A — Atlas Musical
- nós e encontros;
- scopes;
- mapa e névoa;
- expedições;
- comparação;
- integração com repertório e Crônica.
```

Metadata externa entra em Fase 10 do spec mestre **excepto** JSON (Fase 1 do app, já existe o padrão) e Spotify (Fase 10 do mestre, Fase M8 deste anexo — pode avançar assim que o núcleo gravar encontros). IA *dentro* do app permanece Fase 11 / ADR-033. O prompt copiável não é Fase 11.

## 71.10 Seção 60 — telas

Adicionar:

- Atlas;
- Territory Inspect;
- Music Node Inspect;
- Expedition Planner;
- Listening Mode;
- Comparison Lab;
- Pawn Musical.

## 71.11 Seção 62 — schema

Referenciar a seção 46 deste anexo.

## 71.12 Seção 72 — biblioteca

Adicionar:

```text
Álbuns e obras podem ser ligados ao Atlas Musical sem duplicação de KnowledgeSource.
```

## 71.13 Home (ADR-044)

Não editar o spec mestre só por isto. No anexo: tile `Música` / `Atlas` no catálogo de mini-programas; atalho “O que estou ouvindo”; digest abaixo da grelha pode citar expedição activa e flashcards de `Artes / Música`.

## 71.14 Flashcards

Nenhuma alteração normativa no spec mestre. O Atlas consome ADR-036/037/038/039: candidatos, `areaPath`, tags, `repertoire`. Import JSON do Atlas *pode* embutir o mesmo schema de cartões.

## 71.15 Integrações

Acrescentar `IntegrationKind.spotify` (e opcionalmente `musicbrainz`) à lista de `/settings/integrations`. Mesmo padrão ICS: opt-in, revogável, proveniência, app útil sem a integração.

## 71.16 Catálogo de conhecimento

O ramo `arts.music` já existe. Novas folhas (jazz, piano popular, produção, etc.) só se o utilizador as semear ou o import JSON as criar. Não despejar 50 áreas vazias.

---

# 72. Prompt de execução para a IA

```text
Você está implementando o módulo Atlas Musical do Life Colony OS.

Antes de escrever código:
1. leia LIFE_COLONY_OS_SPEC.md;
2. leia LIFE_COLONY_OS_MUSIC_ATLAS_SPEC.md (v1.1, sobretudo §0, §2.4, §36.5,
   §41, §75–§80);
3. leia ADR-005, 015, 017, 032, 033, 036, 037, 038, 039, 042, 044;
4. identifique a vertical slice actual (M0→M1→M2→…; não salte para o grafo
   nem para LLM in-app);
5. escreva plano e ADRs MUSIC-00x em falta;
6. não implemente Spotify antes de o núcleo gravar encontros e o JSON apply
   funcionar; não implemente LLM remoto.

Regras:
- MusicNode não substitui ResearchNode;
- listen / álbum gravado no Spotify não equivale a conhecimento;
- relações históricas são claims com provenance;
- nenhuma pontuação representa conhecimento musical global;
- cobertura exige scope explícito;
- toda recomendação precisa de explicação;
- o usuário pode corrigir inferências;
- offline é obrigatório;
- IA *dentro* do app é defer (ADR-033); o prompt copiável é a fatia cedo;
- tokens Spotify nunca entram no export;
- não armazenar áudio ou letras protegidas;
- não copiar RimWorld;
- strings em lib/app/localization/; widgets não acedem ao banco.

Ordem de implementação (não inverter):
1. M0/M1 — migration music_nodes, personal_music_node_states, music_encounters;
   domain; repositories; RecordMusicEncounter; inspect; capture; Crônica;
2. M2 — MusicAtlasJsonCodec + PromptBuilder + sheet (clone flashcards);
   streaming parse; preview/apply; testes de dedup;
3. M4 superfície — tile home, palette, WorkType.music, digest rules_v1;
4. M5 — candidatos a flashcard + ResearchKnowledgeLink;
5. M8 — IntegrationKind.spotify, PKCE, library/recent/playlist/now-playing,
   Constelação, revoke;
6. mapa-grafo, River View, recomendação local, outros providers, LLM in-app
   só depois.

Primeira slice (critério de saída):
o usuário cria um álbum/artista/gênero local, registra um encontro, atribui
ressonância, escreve uma nota, vê o estado pessoal e encontra o evento na
Crônica — sem internet e sem conta.

Segunda slice:
copia o prompt vivo, cola um JSON (ou escolhe ficheiro), pré-visualiza e
aplica nós/claims sem marcar nada como cartografado. Cartões embutidos
passam pelo FlashcardJsonImportPolicy.

Terceira slice (quando M1+M2 existirem):
liga Spotify opt-in, puxa a biblioteca, vê a Constelação, abre um álbum no
cliente Spotify, revoga tokens sem perder os nós locais.
```

---

# 73. Resultado esperado

Quando madura, a funcionalidade deve permitir que o usuário abra o app e perceba algo como:

> “Minha exploração musical não é uma pilha de álbuns esquecidos. É um território vivo. Consigo ver de onde vim, quais obras formaram meu ouvido, que correntes já conectei, onde minhas ideias ainda são vagas e quais caminhos podem me levar a descobertas realmente novas.”

A sensação de jogo deve vir de:

- revelar;
- conectar;
- planejar;
- investigar;
- revisitar;
- formar uma história pessoal.

Não deve vir de:

- acumular XP;
- competir;
- manter streak;
- completar música como checklist;
- otimizar cada minuto de prazer.

O Atlas é bem-sucedido quando facilita simultaneamente:

- descoberta;
- memória;
- compreensão;
- prática;
- identidade;
- curiosidade;
- criação.

---

# 74. Referências técnicas

Fontes técnicas para adapters e decisões de integração. Verificar novamente no momento da implementação, pois APIs e termos mudam.

- MusicBrainz API: <https://musicbrainz.org/doc/MusicBrainz_API>
- MusicBrainz Relationships: <https://musicbrainz.org/doc/Relationships>
- ListenBrainz API: <https://listenbrainz.readthedocs.io/en/latest/users/api/>
- Apple Music API: <https://developer.apple.com/documentation/applemusicapi/>
- Spotify Web API: <https://developer.spotify.com/documentation/web-api/>
- Spotify Web API changelog: <https://developer.spotify.com/documentation/web-api/references/changes/>
- Discogs API: <https://www.discogs.com/developers>
- Wikidata Query Service: <https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service>
- Cover Art Archive: <https://coverartarchive.org/>
- Spotify Authorization (PKCE): <https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow>
- Spotify scopes: <https://developer.spotify.com/documentation/web-api/concepts/scopes>
- Flashcards no repo: `packages/colony_domain/lib/src/flashcard_json_import.dart`, ADR-038
- Integrações no repo: `lib/features/integrations/`, ADR-032
- Home mini-programas: `lib/features/colony/presentation/colony_mini_apps.dart`, ADR-044

---

# 75. Spotify — conector local-first

Spotify é o sítio onde muita gente *já* guarda discos, playlists e o que está a tocar. O Atlas não compete com isso. Usa o Spotify como **sensor e atalho**: o que a pessoa já marcou ou ouviu vira sinal no mapa; o que ela quer ouvir de novo abre o cliente Spotify.

O app continua útil com Spotify desligado. Sem conta Colony. Sem sync remoto obrigatório.

## 75.1 Porque é interessante (e não só um import)

Um dump de biblioteca sem contexto é uma lista. O conector ganha sentido quando responde perguntas que o cliente Spotify não faz:

| Pergunta | Superfície no Atlas |
|---|---|
| O que eu gravei e ainda nunca encontrei de propósito? | Inbox “gravado sem encontro” |
| O que eu já cartografei e o Spotify ainda não tem? | Constelação, lado local-only |
| Esta playlist conta uma história? | “Transformar em expedição” |
| O que está a tocar agora merece um encontro? | Captura na home / Habitat |
| Que artistas eu sigo cuja névoa ainda está fechada? | Candidatos de território |
| Qual o próximo passo a partir *deste* disco gravado? | Ponte / expedição curta |

Isto não é um clone de Wrapped, nem um ranking de minutos. Minutos de reprodução são um sinal fraco de conhecimento (regra §0.1.5).

## 75.2 Consentimento e ecrã

Vive em `/settings/integrations`, no mesmo padrão ICS (ADR-032):

1. cartão **Spotify** com disclaimer: “Lê a tua biblioteca e o histórico recente. Não toca música no Colony. Não marca discos como conhecidos.”;
2. toggle → `IntegrationConsent(kind: spotify)`;
3. botão **Ligar conta** dispara OAuth PKCE no dispositivo;
4. scopes **incrementais** — cada família de dados pede o seu scope quando o utilizador toca nessa acção;
5. estado visível: ligado / scopes concedidos / última sincronização / último erro / **Revogar**.

Revogar:

- apaga tokens, refresh, PKCE verifiers, cursors e `music_spotify_sync_state`;
- **não** apaga `MusicNode`, encontros, expedições, claims nem flashcards já criados;
- o overlay “Constelação Spotify” passa a vazio com empty state honesto.

## 75.3 OAuth PKCE

- Authorization Code com PKCE no dispositivo. Sem client secret no binário.
- Redirect: app scheme (`colony://integrations/spotify/callback`) ou o padrão da plataforma.
- Tokens em **secure storage** (Keychain / EncryptedSharedPreferences / equivalente desktop). Nunca Drift, nunca `shared_preferences` em claro, **nunca export JSON** (ADR-015).
- Refresh silencioso enquanto o consentimento estiver activo. Falha de refresh → cartão de erro + “Ligar de novo”, sem crash.
- Sem conta Colony no meio. Sem proxy obrigatório. Se um redirect HTTPS for necessário para o registo da app Spotify, o servidor só troca o código; **não** guarda o histórico musical.

Documentar no ADR-MUSIC-013 o `client_id`, o redirect e o procedimento de Development Mode (utilizadores de teste).

## 75.4 Scopes incrementais

Pedir o mínimo. Cada linha é uma capacidade, não um pack.

| Scope | Capacidade | O que o Atlas faz |
|---|---|---|
| `user-library-read` | Álbuns/faixas gravados | Nós + Encounter(`contact`) + inbox |
| `user-read-recently-played` | Recentes (~50) | Staging de *listen*; não é encontro atento |
| `playlist-read-private` + `playlist-read-collaborative` | Playlists | Draft de expedição; não auto-aplica |
| `user-read-currently-playing` e/ou `user-read-playback-state` | O que está a tocar | Captura de um toque |
| `user-follow-read` | Artistas seguidos | Candidatos de névoa |
| `user-library-read` (shows) | Podcasts, se útil | Só se o nó `show` existir no domínio |

Fora do MVP, e só com segundo consentimento explícito:

- `playlist-modify-private` — gravar uma expedição como playlist **comentada** (título + descrição com a pergunta da expedição). Nunca silencioso.

**Não dependemos**, como requisito, de endpoints que a Spotify já restringiu ou pode restringir (Recommendations, Audio Features). Se um probe de capacidade os encontrar, podem ser sinal *opcional* no laboratório de comparação. Se não existirem, o produto não degrada.

## 75.5 Capability probe (2026)

Apps Spotify começam em Development Mode, com quota e lista de testers. Quotas, scopes e endpoints mudam.

Na ligação e no pull:

1. ler scopes realmente concedidos;
2. chamar um endpoint barato da família que o utilizador pediu;
3. gravar `capability_probe_json` (scope, HTTP status, `retry-after`, data);
4. UI: “Biblioteca indisponível nesta app / nesta conta” ≠ crash ≠ empty fingido.

Testes unitários cobrem 401, 403, 429 e body vazio. Nunca assumir Extended Quota.

## 75.6 Mapeamento de dados

Tudo passa pelo pipeline da §55 (staging → resolver → preview → confirm), excepto a captura de “agora a tocar”, que pode criar um encontro *rápido* com undo.

### Biblioteca gravada (`saved albums`)

Cada álbum:

- `KnowledgeSource(type=album)` se ainda não existir;
- `MusicNode` (release group / release, conforme resolução);
- `music_external_identities(provider='spotify', entity_type='album')`;
- Encounter do tipo **`contact`** (a pessoa marcou; não afirmou escuta atenta);
- `source_type=spotify_library`;
- **não** sobe `discovery_state` para visitado/cartografado.

Faixas gravadas isoladas ligam-se ao release group quando o resolver tiver confiança; senão ficam nó `recording` local.

### Recently played

- entram em `music_import_staging` como listens;
- agregação: contagem, primeira/última reprodução, burst vs. disperso;
- o utilizador **confirma** candidatos a Encounter(`listen`) ou ignora;
- autoplay / repetição curta aparece no relatório como ruído possível;
- nenhum listen sozinho marca “conhecido”.

### Playlists

Por playlist, um cartão:

```text
«Madrugada de piano» · 41 faixas · 12 já no Atlas · 29 só no Spotify
[Abrir no Spotify]  [Pré-visualizar nós]  [Transformar em expedição]
```

“Transformar em expedição” cria um **draft** (`MusicExpedition`) com:

- `question` editável (obrigatória antes de activar);
- uma parada por faixa/álbum resolvido, `is_optional=true` por defeito;
- `reason` inicial = posição na playlist + nome da playlist;
- `provenance` = Spotify playlist id + snapshot.

O utilizador corta, reordena e escreve a pergunta. Uma playlist não é uma expedição até confirmação.

### Currently playing

Da home, do Habitat, do command palette ou do Atlas:

1. lê o playback actual (se o scope existir e houver algo a tocar);
2. resolve álbum/artista/faixa;
3. sheet de captura rápida (nota, ressonância, atenção) — mesmo fluxo da §9;
4. “Abrir no Spotify” permanece disponível se a API falhar.

Sem playback no Colony. Sem waveform. Sem letra.

### Artistas seguidos

- nós `artist` com Encounter(`contact`) se ainda não existirem;
- se o território do artista estiver no scope e sem encontros de obra, o artista entra na névoa como **portal avistado**, não como território cartografado.

## 75.7 Constelação Spotify

Projecção derivada (cacheável como as outras):

```text
gravados ∩ com encontro atento     → “já trabalho isto”
gravados ∩ só contact              → inbox
cartografados ∩ sem id Spotify     → “só no Colony”
seguidos ∩ território sem obras    → portais
playlists → drafts de expedição
```

Lista acessível obrigatória. Canvas opcional. Sem percentagem “do Spotify” ou “de toda a música”.

Acção primária da inbox: **Encontrar** (criar encontro) ou **Expedição curta com N itens**.

## 75.8 Abrir no Spotify

Todo `MusicNode` com identidade Spotify mostra:

- `spotify:album:{id}` / `spotify:artist:{id}` / `spotify:track:{id}` / `spotify:playlist:{id}`;
- fallback `https://open.spotify.com/…`.

Se o cliente não estiver instalado, o fallback HTTPS chega. Não embutir Web Playback SDK no MVP.

## 75.9 Partilha de entrada (Android / desktop)

O Colony pode declarar-se destino de partilha para `text/plain` e URIs `open.spotify.com` / `spotify:`.

Fluxo: recebe URI → resolve → sheet de captura ou “adicionar à inbox”. Mesmo domínio que a captura manual. Sem criar conta. Sem rede para *gravar* o encontro (a resolução do catálogo, se online, é enriquecimento).

## 75.10 Reconciliação

Ordem de sinais (não fundir em silêncio — §54):

1. Spotify ID já ligado;
2. ISRC → MusicBrainz recording → release group;
3. UPC/EAN se existir;
4. título+artista normalizados + ano;
5. conflito → ecrã da §54.2.

MusicBrainz continua a ser o identificador *canónico* público quando existir. Spotify é um alias.

## 75.11 Sync

- Pull-to-refresh no Atlas, na Constelação e em Integrações.
- Sem background agressivo. Sem work periódico que acorde a rede de hora a hora.
- Incremental: cursors / `after` / `limit` conforme o endpoint.
- Respeitar `429` / `Retry-After`.
- Offline: a última Constelação cacheada continua legível; pull falha com empty/error honesto.

## 75.12 Privacidade e export

No snapshot de export (ADR-015):

- entram nós, identidades (ids públicos), encontros, expedições, runs de import **sem** tokens;
- **não** entram access/refresh tokens, PKCE verifiers, cookies, nem o blob bruto de `/me` para além do necessário já normalizado.

Telemetry de gosto: off por defeito. Nada é enviado a um servidor Colony.

## 75.13 Fora de escopo (explícito)

- SDK de playback / áudio no processo Colony;
- download ou cache de áudio;
- lyrics;
- social graph Spotify (amigos, activity feed);
- “Daily Mix” como fonte de verdade;
- escrever na biblioteca (`user-library-modify`) no MVP;
- substituir o cliente Spotify;
- exigir Spotify para usar o Atlas.

## 75.14 Eventos

```text
SpotifyLinked
SpotifyRevoked
SpotifyLibraryPulled
SpotifyRecentStaged
SpotifyPlaylistDrafted
SpotifyNowPlayingCaptured
SpotifyCapabilityDegraded
```

---

# 76. Importação JSON com prompt para IA

Canal A da §41. Cópia consciente do ritual de flashcards (`ImportFlashcardsJsonSheet`, ADR-038), aplicado ao Atlas.

A IA corre **fora** do app. O Colony gera um prompt que descreve o mapa *actual*, o utilizador cola esse prompt num modelo à escolha, cola de volta (ou escolhe) um JSON, e o app valida.

## 76.1 Ritual

```text
Copiar prompt vivo
    → colar num LLM externo (com um pedido em linguagem natural)
    → receber JSON
    → colar no campo  ou  escolher ficheiro
    → Pré-visualizar
    → confirmar o plano
    → aplicar transação
    → relatório + undo
```

Strings no mesmo espírito de `flashcardsImportPromptLive`: o texto **muda** quando territórios, nós, áreas, baralhos ou tags mudam.

## 76.2 Onde vive

- rota `/research/music-atlas/import?source=json`;
- sheet a partir do Atlas, do inspect de território, e do command palette;
- atalho em `/settings/integrations` (“Importar Atlas via JSON”) — não exige `IntegrationKind` se o picker já for explícito.

Não meter dumps no `TextField`. Ficheiro: o picker devolve **path**; uma isolate percorre o JSON com `TimelineByteCursor` (ADR-038 §6 / ADR-042). Colar JSON pequeno continua no campo.

Sem teto de tamanho. Sem `jsonDecode` da árvore inteira.

## 76.3 Intenções do prompt

O prompt builder gera um **núcleo** (papel + schema + estado actual) e o utilizador acrescenta o pedido. Intenções suportadas no texto de ajuda:

| Intenção | O que o JSON costuma trazer |
|---|---|
| Cartografar um território | nós + claims + scope |
| Montar uma expedição | `expeditions[]` com pergunta e paradas |
| Reconciliar uma lista de discos | nós + external ids + encounters `contact` |
| Gerar prática | `cards[]` no schema de flashcards |
| Ligar a pesquisa | `researchLinks[]` (ids ou títulos de nós existentes) |
| Comparar obras | `comparisons[]` (rascunhos, exigem confirmação) |

O prompt **proíbe** o modelo de:

- afirmar influência sem `provenance` ou `uncertainty`;
- marcar `discovery_state` acima de `contact` / `sighted`;
- inventar letras ou biografias;
- emitir percentagens de “cobertura da música”;
- criar cartões para todos os álbuns.

## 76.4 Conteúdo do prompt vivo

Gerado por `MusicAtlasJsonPromptBuilder.build(...)`, no mesmo estilo de `FlashcardJsonPromptBuilder`:

1. papel: “formatas um documento do Atlas Musical do Life Colony OS; responde **apenas** JSON”;
2. schema da §79;
3. regras de dedup e de estados;
4. **territórios / scopes** actuais (título + id curto);
5. **nós** actuais compactos (tipo, nome, ids externos se houver) — teto razoável + “há N mais; não os dupliques pelo nome”;
6. **claims** já aceites (from → type → to);
7. **áreas de conhecimento** (floresta ADR-037, sobretudo `Artes / Música`) e baralhos;
8. **tags** (ADR-039);
9. **nós de pesquisa** ligados (`ResearchKnowledgeLink`) e títulos;
10. prateleiras canónicas `arts.music*`, `arts.harmony`, `arts.piano`;
11. liberdade de criar ramos novos, preferindo grafia existente.

Se o mapa estiver vazio, o prompt diz-no e pede uma árvore mínima (um território + alguns nós + uma pergunta de expedição).

## 76.5 Plano de importação

Espelho de `FlashcardJsonImportPlan`:

```text
MusicAtlasJsonImportPlan
  nodes:       create | link | skip | conflict
  claims:      create | skip | conflict
  encounters:  create | skip          (nunca sobe estado sozinho)
  expeditions: create draft
  repertoire:  create | link
  cards:       delega a FlashcardJsonImportPolicy
  researchLinks: create se o ResearchNode existir ou for criado com confirmação
```

Dedup de nós, por ordem:

1. `externalIds[]` (spotify / musicbrainz / wikidata / isrc);
2. `localId` se o documento o citar e existir;
3. `normalized(title) + normalized(artist/credit) + nodeType`;
4. conflito (mesmo título, artista diferente / tipo diferente) → o utilizador escolhe.

Claims: o mesmo par `from + to + relationType` com provenance diferente **acrescenta fonte**, não duplica a aresta.

## 76.6 Apply

Uma transação:

1. criar/ligar nós e identidades;
2. criar claims com `status=proposed` ou `accepted` conforme o documento — `accepted` só se `acceptedByUser=true` no JSON **e** o utilizador não desmarcou no preview;
3. encontros com `source_type=imported_json`;
4. expedições em draft;
5. repertório;
6. cartões via política já existente;
7. `music_import_runs` + relatório;
8. evento `MusicAtlasJsonImported`;
9. undo (reverter o run).

Nenhum apply marca `cartographed` / `demonstrated`.

## 76.7 Proveniência

```yaml
Provenance:
  source_type: imported_json
  parser_version: music_atlas_json_v1
  run_id: uuid
  imported_at: iso
  prompt_fingerprint: hash do prompt vivo (não o pedido do utilizador)
```

O pedido em linguagem natural que a pessoa escreveu no LLM **não** é obrigatório no JSON. Se vier em `meta.userRequest`, guarda-se no run (privacidade: faz parte do export local; não telemetria).

---

# 77. Flashcards, tags e mapa de conhecimento

O Atlas é cartografia. Flashcards são prática. Pesquisa é intenção + evidência. Os três encontram-se; nenhum absorve os outros.

## 77.1 Contrato

| Sistema | Pergunta que responde | O Atlas não pode |
|---|---|---|
| Atlas | O que já avistei, visitei, comparei? | obrigar um cartão por álbum |
| Flashcards + SRS | O que consigo *recuperar* amanhã? | substituir o mapa |
| KnowledgeArea | Em que prateleira isto vive? | virar árvore de géneros musicais única |
| ResearchNode | Que objectivo estou a demonstrar? | ser marcado demonstrado por um listen |

ADR-036: conhecimento sem cartão é válido. Baralho sem área é válido. Área sem baralho é válida.

## 77.2 Onde o Atlas gera candidatos

Depois de acções com fricção consciente — nunca no import em massa, nunca no pull Spotify:

- sessão de escuta atenta concluída;
- laboratório de comparação com nota salva;
- peça adicionada ao repertório;
- claim histórico aceite pelo utilizador (“quero lembrar a data / a relação”);
- inspect de um conceito (`MusicConcept`) com “praticar isto”.

Cada candidato é um rascunho:

```yaml
FlashcardCandidate:
  origin: listening_session | comparison | repertoire | claim | concept
  origin_id: uuid
  suggested_kind: basic | cloze | freeRecall | exercise | repertoire
  front: ...
  back: ...
  deckTitle: ...
  areaPath: [Artes, Música, ...]
  tags: [Jazz, ...]
  researchNodeId?: ...
  accepted: false
```

UI: sheet “Sugerir prática” com checkboxes. Recusar é o default honesto. Aceitar chama o mesmo apply que o import de flashcards.

## 77.3 Kinds e exemplos

- `basic` — “Em que ano saiu *Kind of Blue*?” / “1959”;
- `cloze` — “O jazz {{c1::modal}} desloca o foco do ii–V–I para {{c2::escalas e centros}}.”;
- `repertoire` — frente: trecho ou forma a tocar; verso: referência (gravação, tonalidade, notas de prática);
- `exercise` — “Canta o baixo dos primeiros 8 compassos de X e grava”;
- `freeRecall` — “O que mudou no teu ouvido entre as duas escutas de Y?”.

Bidireccional só quando faz sentido (obra ↔ ano, tema ↔ compositor). Não inverter prosa de opinião.

## 77.4 Prateleiras e tags

Preferir caminhos existentes:

```text
Artes / Música
Artes / Música / Teoria musical
Artes / Música / Tropicalismo     (também em Humanidades / História / Brasil)
Artes / Harmonia
Artes / Piano
```

O import e os candidatos podem criar folhas novas (`Artes / Música / Jazz modal`). Tags hierárquicas (ADR-039) cruzam o mapa: `Jazz / Piano`, `Cena / Recife`, `Prática / ii–V–I`.

Estudar `?area=musica` ou `?tagId=` usa as filas já implementadas. O Atlas só deep-linka.

## 77.5 Pesquisa

`ResearchKnowledgeLink.kind`:

- `primary` — o nó de pesquisa *é* este território ou conceito;
- `related` — contexto (um álbum que ilustra o nó);
- `practice` — baralho ou área que treina o nó.

Uma expedição longa pode promover-se a `Quest` com link quest↔research (ADR-022). Sessões de escuta podem virar `LearningSession` + `ResearchEvidence` **quando o utilizador afirma** a evidência (tipos da §45.3). Ouvir não demonstra.

WIP e canvas de pesquisa (ADR-021) não são o mapa do Atlas. O Atlas pode *abrir* o nó de pesquisa ligado; não desenha uma segunda árvore.

## 77.6 Habitat e agenda

- Objecto piano/estante no Habitat → “Praticar repertório” / “Abrir Atlas” / “Fila de flashcards de Música”. Sem autoplay.
- `WorkType.music` e blocos `escuta` / `prática` → deep link para a sessão ou para `/flashcards/study?deckId=`.
- Digest da home: se houver cartões vencidos na área Música **e** uma expedição activa, um bullet `rules_v1` pode citar ambos, com ids de evidência, sem culpa.

---

# 78. Superfície no app atual

O Atlas não é um segundo aplicativo. Encaixa nas superfícies que já existem em agosto de 2026.

## 78.1 Home (ADR-044)

Catálogo `ColonyMiniApps`:

- tile **Música** / **Atlas** → `/research/music-atlas` (pinned opcional);
- quick action **O que estou ouvindo** → captura Spotify ou captura manual;
- o digest abaixo da grelha pode incluir, via `NarrativeDigest` `rules_v1`:
  - expedição activa (“Parada 2 de 5: …”);
  - N gravados Spotify sem encontro;
  - cartões de Música vencidos;
  - próximo bloco `WorkType.music` na agenda.

Sem widget de player. Sem capa a autoplay.

## 78.2 Command palette e menu Mais

Destinos:

```text
Atlas Musical
Capturar encontro
Importar Atlas (JSON)
Ligar / abrir Spotify
Flashcards · Música
Pesquisa · nós ligados
```

## 78.3 Pesquisa

`/research` lista nós com link ao Atlas. O detalhe de um `ResearchNode` mostra:

- territórios/obras ligados;
- evidências de escuta/prática;
- baralhos `practice`;
- “Abrir no Atlas”.

O canvas de pesquisa não mistura `MusicNode` como se fossem o mesmo tipo.

## 78.4 Flashcards

Hub já existente. Filtros `area=musica` e tags. O Atlas não reimplementa SRS, pace (ADR-040) nem prioridade (ADR-041).

## 78.5 Integrações

`/settings/integrations` ganha o cartão Spotify (e, se M7 estiver ligado, MusicBrainz como “resolver público, sem conta”). Import JSON do Atlas pode aparecer como acção secundária no mesmo ecrã.

## 78.6 Crônica, inbox, missões, pessoas, viagens, ledger

Já especificados nas §35–§39. Reforço de encaixe:

- inbox: captura de URI Spotify partilhado; “gravado sem encontro”;
- missões: expedição longa → `Quest` com tag `music-expedition`;
- pessoas: `Person` como recomendador; compromisso “aula / show”;
- viagens: cena e festival no trip;
- ledger: `Transaction` com proveniência, sem ROI cultural;
- export: entidades musicais no snapshot; tokens fora.

## 78.7 Feature flag e empty states

Flag `musicAtlas`. Off: o tile pode esconder-se ou abrir um empty “em breve”. On e sem nós: empty que oferece (1) criar um disco à mão, (2) copiar o prompt JSON, (3) ligar Spotify — nesta ordem, porque (1) e (2) funcionam offline.

---

# 79. Contrato JSON v1 do Atlas

Documento raiz. Aceita objecto ou, por tolerância, uma lista só de nós. Aceita cerca ````json`. Parser streaming: percorre `nodes[]`, `claims[]`, `encounters[]`, `expeditions[]`, `cards[]` / `decks[].cards[]` um objecto de cada vez.

```json
{
  "version": 1,
  "kind": "music_atlas",
  "meta": {
    "title": "Tropicalismo — recorte",
    "userRequest": "opcional; o que a pessoa pediu ao LLM",
    "generatedBy": "external_llm"
  },
  "territories": [
    {
      "key": "tropicalismo",
      "title": "Tropicalismo",
      "scopeStatement": "Recorte pessoal da canção popular brasileira 1967–1972.",
      "timeRange": { "from": "1967", "to": "1972" }
    }
  ],
  "nodes": [
    {
      "key": "panis",
      "nodeType": "release_group",
      "title": "Tropicália ou Panis et Circencis",
      "sortTitle": "Tropicalia ou Panis et Circencis",
      "artists": ["Caetano Veloso", "Gilberto Gil"],
      "year": 1968,
      "territoryKeys": ["tropicalismo"],
      "externalIds": [
        { "provider": "musicbrainz", "entityType": "release-group", "id": "…" },
        { "provider": "spotify", "entityType": "album", "id": "…" }
      ],
      "summary": "Marco colectivo. Não é biografia.",
      "discoveryState": "sighted",
      "notes": "opcional; vira AtomicNote se o utilizador confirmar"
    }
  ],
  "claims": [
    {
      "fromKey": "panis",
      "toKey": "alegria",
      "relationType": "shares_scene",
      "validFrom": "1967",
      "validTo": "1969",
      "description": "Mesmo ciclo de intervenção cultural.",
      "confidence": 0.6,
      "uncertainties": ["A cena não é um género único."],
      "sources": [{ "title": "…", "url": "https://…" }],
      "acceptedByUser": false
    }
  ],
  "encounters": [
    {
      "nodeKey": "panis",
      "encounterType": "contact",
      "occurredAt": "2026-08-01",
      "note": "Sinalizado por um amigo.",
      "resonance": 3
    }
  ],
  "expeditions": [
    {
      "title": "Ouvir o disco colectivo com a pergunta certa",
      "question": "O que neste disco é canção e o que é intervenção?",
      "territoryKey": "tropicalismo",
      "stops": [
        {
          "nodeKey": "panis",
          "role": "camp",
          "reason": "Ponto de entrada colectivo.",
          "cues": ["arranjo", "ironia", "citação"],
          "optional": false
        }
      ]
    }
  ],
  "repertoire": [
    {
      "nodeKey": "panis",
      "title": "Linda",
      "instrument": "piano",
      "practiceLine": "tirar de ouvido"
    }
  ],
  "researchLinks": [
    {
      "nodeKey": "tropicalismo-conceito",
      "researchTitle": "Contextualizar o Tropicalismo em 10 sessões",
      "kind": "primary",
      "areaPath": ["Artes", "Música", "Tropicalismo"]
    }
  ],
  "comparisons": [
    {
      "nodeKeys": ["panis", "alegria"],
      "dimensions": ["ironia", "orquestração"],
      "observation": "rascunho; exige confirmação"
    }
  ],
  "cards": [
    {
      "front": "Em que ano saiu Tropicália ou Panis et Circencis?",
      "back": "1968",
      "kind": "basic",
      "deck": "Tropicalismo",
      "areaPath": ["Artes", "Música", "Tropicalismo"],
      "tags": ["Brasil / 1968"],
      "schedule": "scheduled",
      "priority": 4
    }
  ]
}
```

## 79.1 Campos e defaults

- `version` — inteiro; v1 é o único aceite nesta spec. Versão desconhecida → erro claro, sem apply parcial silencioso.
- `kind` — `music_atlas`. Se ausente e existirem `nodes` / `territories`, o codec aceita. Se o documento for só `cards[]` (schema de flashcards), **não** é um import do Atlas: o sheet deve oferecer “abrir em Flashcards”.
- `nodeType` — `artist` | `work` | `recording` | `release_group` | `release` | `territory` | `scene` | `concept` | `label` | `place` | `show`.
- `discoveryState` no JSON só pode ser `unknown` | `sighted` | `contact`. Qualquer outro valor é **clamp** para `sighted` e entra no relatório.
- `confidence` em claims: 0–1; ausente = null, não 1.
- `cards[]` / `decks[]` — **idênticos** a `FlashcardJsonCard` (ADR-038). Reutilizar o codec. Não inventar um segundo schema de cartões.
- `areaPath` aceita string `"Artes / Música / Jazz"` ou array, como nos flashcards.
- Chaves (`key`) são locais ao documento. O apply resolve para `EntityId`.

## 79.2 O que o parser ignora

- chaves desconhecidas (janela deslizante, ADR-038 §6);
- blobs enormes (`lyrics`, `audio`, capas em base64) — saltar, reportar;
- HTML;
- percentagens de cobertura global.

## 79.3 Exemplo mínimo válido

```json
{
  "version": 1,
  "kind": "music_atlas",
  "nodes": [
    {
      "key": "kind-of-blue",
      "nodeType": "release_group",
      "title": "Kind of Blue",
      "artists": ["Miles Davis"],
      "year": 1959
    }
  ]
}
```

Aplica um nó. Estado pessoal: `sighted` se o utilizador confirmar o plano. Sem claims, sem cartões, sem Spotify.

## 79.4 Testes do codec

Espelhar `flashcard_json_import_test.dart`:

- JSON puro, cerca markdown, array na raiz (só nós);
- `areaPath` string vs array;
- clamp de `discoveryState`;
- dedup por Spotify ID e por título+artista;
- claim duplicado acrescenta fonte;
- `cards[]` delega e não reseta SRS no overwrite;
- ficheiro grande: `parseSource` sem carregar o dump na UI;
- documento só com `cards` → erro de kind ou redirect.

---

# 80. Critérios de aceite das fatias novas

Complementam a §65. Uma fatia só fecha com empty/loading/error/offline, strings localizadas e testes no `test_all`.

## 80.1 JSON + prompt (M2)

1. Com o mapa vazio, o prompt diz que não há categorias/nós e pede um recorte mínimo.
2. Depois de criar um território, o prompt **muda** e lista esse título.
3. Colar o exemplo mínimo da §79.3 produz um plano com 1 `create` e 0 cartografados.
4. Reimportar o mesmo documento produz só `skip`.
5. Um JSON com `discoveryState: "cartographed"` é clampado e o relatório mostra o clamp.
6. Escolher um ficheiro grande não coloca o conteúdo no `TextField`; a isolate devolve plano ou erro.
7. Apply é transacional; undo reverte o `music_import_run`.
8. `cards[]` válidos passam por `FlashcardJsonImportPolicy` (dedup/overwrite sem resetar SRS).
9. Offline: o ritual funciona por completo (o LLM externo é que precisa de rede — o app não).
10. Tokens / rede Spotify não são requisitos.

## 80.2 Spotify (M8)

1. App útil com o toggle off.
2. Ligar pede PKCE; cancelar não deixa consent “ligado” a meio.
3. Com `user-library-read`, pull cria nós + Encounter(`contact`) apenas.
4. Nenhum saved album nasce `cartographed`.
5. Constelação mostra as três partições (gravado∩atento, gravado sem encontro, local-only) ou empty honesto.
6. Playlist → draft de expedição com pergunta obrigatória antes de activar.
7. “O que estou ouvindo” com scope e playback activo abre a captura; sem playback, empty claro.
8. “Abrir no Spotify” lança deep link ou HTTPS.
9. Revogar apaga tokens e cursors; nós locais permanecem; export **não** contém tokens (teste de snapshot).
10. 401/403/429 não crasham; capability probe grava o motivo.
11. Sem SDK de playback no processo.
12. Development Mode: utilizador fora da allowlist vê erro de quota, não um mapa vazio fingido.

## 80.3 Flashcards e pesquisa (M5)

1. Sessão de escuta / comparação / repertório oferece candidatos; nenhum é criado sem checkbox.
2. Aceitar dois candidatos cria cartões em `/flashcards` com `areaPath` sob `Artes / Música` (ou folha criada).
3. Recusar fecha o sheet sem side-effects.
4. `ResearchKnowledgeLink.practice` só nasce se o utilizador afirmar a ponte.
5. Um listen importado **não** cria evidência de research nem cartão.
6. Deep link `/flashcards?area=musica` abre a fila existente.
7. Habitat piano não inicia áudio.

## 80.4 Superfície (M4)

1. Tile Música na home abre o Atlas (ou empty da flag).
2. Command palette encontra Capturar, Import JSON e Atlas.
3. `WorkType.music` na agenda abre sessão ou Atlas.
4. Digest `rules_v1` pode citar expedição / inbox Spotify / cartões vencidos com evidência; sem LLM; sem culpa.
5. Feature flag off não parte o routing do resto do app.

## 80.5 Privacidade transversal

1. Export após JSON + Spotify contém entidades musicais e **zero** secrets.
2. Delete de perfil / wipe remove tokens.
3. Sem telemetry de gosto por defeito.
4. Nenhuma percentagem “de toda a música” ou “do Spotify” na UI.

---

# Fim da especificação

Este documento deve permanecer versionado junto ao spec mestre. Mudanças em estados, schemas, providers, algoritmos ou critérios de recomendação exigem migration, testes e ADR quando alterarem comportamento observável ou interpretação dos dados.
