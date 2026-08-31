# Identidade de marca — exploração

**Documento:** exploração de marca, naming e arquitetura verbal  
**Status:** não-normativo — não altera a spec, não é ADR, não é decisão  
**Data:** 31 de agosto de 2026  
**Pai:** [`LIFE_COLONY_OS_SPEC.md`](LIFE_COLONY_OS_SPEC.md)  
**Visual já decidido (chrome):** [ADR-049](../adr/ADR-049-fallhub-terminal-visual.md)  
**Audiência:** fundador, produto, design

Este texto existe para responder uma pergunta real: a metáfora da colônia é o coração do produto, ou um andaime que já cumpriu o papel? A resposta curta está na seção 0. O resto justifica.

---

# 0. Veredito

**Não abandone a colônia como modelo mental. Aposente-a como nome de produto.**

A colônia é a melhor ideia deste projeto: tratar a vida como um sistema de recursos limitados, atividades que competem, estados que degradam e se recuperam, e decisões que deixam rastro. Isso não é skin de jogo. É a tese.

O nome **Colônia** / **Life Colony OS** é outra coisa. É a tese vazada para a loja, para o ícone, para a primeira frase que um estranho lê. Aí ela começa a trabalhar contra o produto:

- soa como jogo, não como instrumento de décadas;
- puxa RimWorld com uma força que a spec passa o tempo inteiro tentando negar;
- carrega bagagem colonial que não precisa ser o primeiro debate;
- compete com um nome que o repositório, o GitHub e o chrome visual **já escolheram**: Fallhub.

A arquitetura que este documento recomenda:

| Camada | Nome | Função |
|---|---|---|
| Autor | **RockFall** | quem faz |
| Produto | **Fallhub** | o que se instala, o que se busca, o que está na loja |
| Lugar diegético | **Colônia** | a home, o mapa operacional, o “aqui” dentro do app |
| Corpo visível | **Habitat** | o mundo persistente com o pawn |
| Codinome interno | **Life Colony OS** | título da spec; não vai para a vitrine |

Se Fallhub não resistir ao teste de boca (seção 9), o território certo para um nome novo não é “vida + gestão + OS”. É **estação civil + instrumento de orientação**. Atalaia, Prumo, Lastro, Sextante. Não Clareira, não Kernel, não LifeOS.

O resto deste documento é o raciocínio. Não é moodboard.

---

# 1. O que o produto é, sem metáfora

Antes de naming, convém dizer a coisa em prosa chata. Se a marca não sobrevive a essa frase, ela está vestindo o produto, não revelando.

**Fallhub (como produto) é um instrumento local para ver a própria vida como um sistema, decidir o próximo movimento, e guardar o rastro das escolhas — sem pontuar a pessoa.**

Ele junta, no mesmo objeto:

- captura rápida (inbox, check-in, gasto, humor);
- inspeção (de onde veio o número, quão fresco, quão confiável);
- operação (hoje, prioridades, missões, agenda);
- aprendizagem (árvore de pesquisa, evidência, flashcards);
- corpo e casa (saúde sem diagnóstico, habitat vivo, zonas, inventário);
- recursos (ledger, patrimônio);
- vínculos (pessoas, organizações, compromissos);
- memória (crônica, revisões, decisões registradas);
- ignição (sair da inércia sem streak nem culpa).

A north star da spec não é engajamento. É **semana em que houve revisão informada e pelo menos uma decisão registrada com dados suficientemente confiáveis**. Isso não é o KPI de um jogo. É o KPI de um instrumento.

O antiobjetivo mais importante para marca: não ser “lista de tarefas com skin de videogame”. Toda escolha de nome, tom e ícone que empurre o produto de volta para Habitica, The Sims ou “RimWorld da sua vida” é um tiro no próprio norte.

O usuário inicial da spec é alguém com muitas frentes simultâneas — estudo, software, empresas, finanças, saúde, música, viagens, casa, relações. Não é um gamer procurando um segundo RimWorld. É uma pessoa complexa que precisa de um painel que não minta por simplificação.

Isso já define o registro da marca: **sério, denso, civil, durável**. Humano sem ser wellness. Lúdico sem ser toy. Técnico sem ser SaaS.

---

# 2. Auditoria: a identidade já está fendida

Hoje o projeto fala com três nomes e duas visões. Não é charme de estúdio. É incoerência que vai do `pubspec` até a loja.

## 2.1 Três nomes, nenhum dono da vitrine

| Superfície | O que aparece | Efeito |
|---|---|---|
| GitHub, README, package, web manifest | `fallhub` | identidade de repositório / estúdio-produto |
| Spec mestre | `Life Colony OS` | nome de tese acadêmica |
| UI (`AppStrings.appName`) | `Colônia` | o que o usuário vê no aparelho |
| Chrome visual (ADR-049) | **Fallhub Terminal** | o que o olho acredita |
| Org do GitHub | RockFall | autor |

Nenhum produto maduro sustenta isso. O usuário não distingue “codinome interno”, “nome de spec” e “nome de app”. Ele lê a barra de título. Hoje ela diz Colônia. O kit gráfico diz Fallhub. O repositório diz Fallhub. A spec diz Life Colony OS.

Quando três nomes competem, o mercado escolhe o mais fácil de zombar. Aqui, “o RimWorld da vida”.

## 2.2 Duas visões visuais, uma delas ilegal de propósito

A spec mestre (§0.1, §7, §57) pede linguagem original de “painel de gestão de colônia de fronteira”, civil, industrial, humano — **não** HUD militar, **não** cópia de RimWorld.

O documento `04-LIFE_COLONY_OS_RIMWORLD_UI_STYLE_SPEC.md` pede o oposto, com clareza quase agressiva: a captura deve transmitir “isso é RimWorld”; a diferença deve ser só o conteúdo.

O ADR-049 já tomou partido na prática: **Fallhub Terminal** — pixel art civil, grafite / latão / cobre / ciano, rebites, Pixelify Sans. Isso é uma identidade. É a única que o produto já possui de fato.

A marca não pode servir às duas visões. Uma é o produto. A outra é um exercício de fidelidade que a spec soberana já rejeitou na iteração A (§3.1).

## 2.3 Vocabulário que encanta o iniciado e tranca o resto

A tabela da spec §4 é excelente como **modelo de domínio**. Como fala de marca, é um dialeto:

Pawn, Bill, Storyteller, Draft, Faction, Gear, Hediff, Need, Passion.

A UI já começou a traduzir o que importa: o destino de navegação do pawn chama-se **Perfil**, não Pawn. Habitat, Crônica, Missões, Pesquisa são palavras que um adulto brasileiro entende. “Colonista ocioso” e “Loadout” no mesmo arquivo de strings mostram o dialeto ainda vazando.

Isso não é pecadilho de copy. É posicionamento. Cada “pawn” na boca do produto escolhe o público: gente que já jogou o jogo de referência. O produto ambiciona décadas de uso real. Décadas incluem a parceira, o pai, o colega, a versão futura de si que não quer mais “ser um pawn”.

## 2.4 O que já é patrimônio de marca (e não deve ser jogado fora)

- a tese sistêmica (recursos, competição, inspeção, incerteza);
- o Habitat como corpo visível, não mascote;
- a ética: sem score de vida, sem streak como chicote, sem diagnóstico, sem banco;
- o terminal civil (ADR-049) — paleta, rebites, latão, ciano funcional;
- **local-first** como caráter, não como feature;
- a Crônica como memória, não como feed;
- RockFall / Fallhub como assinatura já ocupada no mundo real (repo, org, kit).

A exploração parte daqui. Não de uma folha em branco.

---

# 3. O trabalho que a marca precisa fazer

Uma marca neste produto não existe para “ficar bonita”. Ela tem empregos.

1. **Dizer o gênero em três segundos.** Não é tracker. Não é jogo. Não é dashboard. É um instrumento que se habita.
2. **Proteger a tese contra a referência.** Enquanto o nome e o chrome gritarem RimWorld, todo reviewer inteligente vai escrever a frase da cópia e parar de ler o resto — inclusive a ética, que é o que há de mais raro aqui.
3. **Atravessar o tempo.** A spec quer “uso real por muitos anos”. Nome de moda (OS, OS, OS) envelhece. Nome de lugar ou de instrumento envelhece melhor.
4. **Cabe no bolso e na barra de título.** Uma palavra. Acentuação ok em PT-BR. Pronunciável em EN sem palestra.
5. **Não moralizar.** A marca não pode cheirar a coach, a igreja da produtividade, a app de culpa. O produto recusa isso por contrato.
6. **Não militarizar.** Estação remota civil. Não QG, não HUD tático, não “dominate your day”.
7. **Ser dono de um território verbal.** Se o nome poderia ser de um banco, de um Notion-like ou de um roguelike, está errado.

Público primário, hoje: o próprio autor e pares densos (técnicos, polímata, gente com vida em camadas).  
Público que a ambição implica: qualquer adulto que precise ver o próprio sistema sem ser tratado como criança ou como KPI.

A marca tem de servir os dois. O vocabulário interno pode continuar sendo para o primeiro. A vitrine não.

---

# 4. Tensões estruturais (não são “desafios de branding”)

Estas tensões não se resolvem com logo. Elas **são** o produto. A marca escolhe de que lado puxa cada uma.

| Tensão | Um polo | Outro polo | Puxar para |
|---|---|---|---|
| Jogo ↔ instrumento | Habitat, pawn, research tree, terminal pixel | ledger, saúde, decisões, provenance | instrumento que **contém** um mundo |
| RimWorld ↔ original | spec 04, work grid, inspect, needs | spec 0.1, ADR-049, ética | original, gramática de gestão sem cromo alheio |
| Frio de painel ↔ calor humano | grafite, densidade, tabelas | crônica, retrato, habitat, notas | painel com humanidade nos detalhes, não em pastéis |
| Colônia (sistema) ↔ colônia (império) | base, setores, recursos | colonialismo, conquista, “colonista” | sistema; nunca conquista |
| Local-first ↔ “OS na nuvem” | sem conta, exportar, apagar | a palavra OS hoje implica sync e login | recusar a pose de OS na vitrine |
| Densidade ↔ celular | gestão de colônia | captura em <10s, Foco | o nome não deve prometer um MMO de UI |
| Autor-gamer ↔ usuário futuro | pawn, bill, draft | perfil, rotina, revisão | diegese no Habitat; prosa no resto |

A marca que tentar ser as duas pontas ao mesmo tempo vira “ fortnite da vida adulta” ou “Notion com bonequinho”. Os dois matam a tese.

---

# 5. A pergunta da colônia

## 5.1 O que a metáfora faz de insubstituível

Gestão de colônia, como classe de raciocínio (spec §1.1), acerta o que dashboards e to-do lists erram:

- o todo é um lugar, não uma lista de módulos;
- você inspeciona um corpo (o pawn) e um território (setores, zonas, habitat);
- recursos são finitos e visíveis;
- o dia tem clima, carga, incidentes — não só tarefas;
- a história emerge do que aconteceu, não de um feed editorial.

Sem essa metáfora, o produto cai na iteração B que a spec já rejeitou: “dashboard bonito de vida”. Cards de saúde + finanças + hábitos. Morte por genericidade.

O Habitat só faz sentido **dentro** de um lugar que se habita. Colônia, base, estação, habitat: a família é a mesma. Matar a família inteira é matar o produto.

## 5.2 O que a palavra “colônia” faz de ruim

**Como nome de produto:**

1. **Referência inescapável.** Para o público que *entende* a tese, Colônia = RimWorld. A spec gasta energia jurídica e ética para não copiar o jogo, e depois escreve o nome do gênero na testa.
2. **Gênero errado na loja.** “Colônia” na Play Store, ao lado de um ícone pixelado e um pawn, é lido como jogo. Jogos são avaliados como jogos. Instrumentos de saúde/finanças/decisão não podem viver nessa prateleira.
3. **Bagagem.** Em inglês, *colony* em 2026 não é uma palavra inocente. Em português brasileiro é mais manso (colônia de formigas, colônia de férias, Colônia no Sul), mas também é perfume, e também é história colonial. Não é motivo único para trocar — é motivo para não *escolher* essa briga.
4. **“Life Colony OS” é um título, não um nome.** Quatro palavras, duas genéricas (Life, OS), uma carregada (Colony). Não se fala, não se grita, não se borda numa capa.
5. **Já perdeu a guerra interna para Fallhub.** O chrome, o repo e o kit gráfico não se chamam Colônia Terminal. Chamam-se Fallhub Terminal. O olho já votou.

**Como vocabulário interno:** “criar colônia” no onboarding, “tela Colônia” como home, “mapa da base” — isso pode ficar. É lugar. iOS não se chama Springboard. A home é um lugar dentro de um produto que tem outro nome.

## 5.3 Três opções honestas

**A. Colônia é o produto.**  
Dobrar a aposta. Renomear o repo, o terminal, o README. Aceitar o nicho “life-sim operacional para quem jogou RimWorld” como praia e teto. Coerente, corajoso, e pequeno. A ambição da spec é maior que esse teto.

**B. Matar a metáfora.**  
Virar Life OS / Nexus / Hub genérico. Visual Material, módulos, cards. Isso não é rebrand. É outro produto — o da iteração B, já rejeitada.

**C. Separar tese e vitrine.** *(recomendado)*  
A metáfora continua a organizar domínio, Habitat, home e inspeção. O produto público ganha um nome que não é o nome da metáfora. É o que fazem os jogos que a spec admira: RimWorld não se chama Colony Simulator. Factorio não se chama Factory OS. O mundo é colônia; a marca é outra.

A opção C não é covardia. É precisão.

---

# 6. Arquitetura de marca recomendada

Pensar em camadas, como o próprio app pensa em Sinal / Explicação / Evidência.

```text
RockFall          autor, org, crédito, “made by”
    └── Fallhub   produto, binário, loja, domínio, terminal
            ├── Colônia     lugar: home / mapa operacional
            ├── Habitat     lugar: mundo persistente
            ├── Perfil      o corpo inspecionável (pawn por baixo)
            └── Crônica     a memória
```

**RockFall** não precisa aparecer o tempo todo. É a assinatura no rodapé, no about, no GitHub. Rocha → rock. Já é um nome próprio verdadeiro, o que quase nenhum app tem.

**Fallhub** já está pago: repo, package `fallhub`, manifest, ADR-049, pasta de assets, hábito mental de quem mexe no código. Promovê-lo a produto é o caminho de menor violência e maior coerência visual.

**Colônia** desce de nome de app para nome de lugar. Na navegação: o destino continua podendo chamar-se Colônia — como “Início” que tem caráter. No `title` do OS: Fallhub.

**Life Colony OS** permanece como título histórico da spec. Não precisa ser reescrito agora. Precisa deixar de ser usado como se fosse marca.

Essa arquitetura permite um dia ter outro produto RockFall sem orphanar o Habitat, e permite um dia ter outra metáfora de lugar sem orphanar o binário.

---

# 7. Territórios de posicionamento

Cinco territórios possíveis. Só dois prestam. Um terceiro é tentação.

## T1 — Colônia / gestão de base *(atual, vitrine)*

Promessa: “sua vida como uma colônia.”  
Força: única, memorável para o nicho, explica a UI.  
Fraqueza: jogo, RimWorld, império.  
Uso: **manter como território diegético**, não como slogan de loja.

## T2 — Estação civil / terminal *(recomendado para vitrine)*

Promessa: “o terminal de onde você opera a própria vida.”  
Força: já materializado no ADR-049; industrial-humano; fronteira sem conquista; cabine, não QG.  
Fraqueza: pode parecer frio ou prepper se a copy militarizar.  
Palavras que servem: estação, posto, atalaia, ponte (de navio), terminal, painel.  
Palavras que não servem: QG, command center, fortress, bunker, ops.

Este é o território em que Fallhub *já vive*. A marca só precisa admitir.

## T3 — Instrumento de orientação

Promessa: “um instrumento para saber onde você está e o que fazer agora.”  
Força: casa com a north star, com provenance, com “como estou de verdade”. Sextante, prumo, bitácula, lastro.  
Fraqueza: pode cheirar a app de mindfulness se a execução for mole; ou a ciência fria se for dura.  
Uso: **tom de voz e tagline**, não necessariamente o nome.

Casa com T2: o terminal *é* o instrumento. Estação + orientação = o mesmo objeto.

## T4 — Habitat / lugar habitado

Promessa: “um lugar vivo que é a sua vida.”  
Força: o pawn vivo é o ativo emocional mais raro do produto; “habitar” é o oposto de otimizar.  
Fraqueza: Habitat já é módulo; a palavra é ecológica/técnica; sozinha não carrega finanças nem decisões.  
Uso: o módulo, o trailer, a imagem de marca — não o nome do binário.

## T5 — Sistema operacional pessoal *(evitar na vitrine)*

Promessa: “o OS da sua vida.”  
Força: descreve o escopo.  
Fraqueza: 2020–2026 esgotou “OS” (every app is an OS). Implica conta, nuvem, plataforma. O produto é o contrário: local, sem conta, exportável.  
Uso: frase longa em documentação (“sistema operacional pessoal”), nunca como nome.

**Combinação recomendada:** T2 na vitrine, T3 na boca, T4 na imagem, T1 no mundo interno, T5 só no parágrafo de spec.

Frase de posicionamento (trabalho, não slogan final):

> Fallhub é o terminal civil da sua vida: um instrumento local para ver o sistema inteiro, decidir o próximo movimento e guardar o rastro — com um habitat que torna isso visível, sem pontuar quem você é.

---

# 8. Personalidade e voz

## 8.1 Se fosse uma pessoa

Um operador de estação remota que também escreve o diário de bordo. Fala pouco. Mostra o painel. Não te chama de guerreiro. Não te chama de pawn na frente dos outros. Se o dado é incerto, diz que é incerto. Se você não fez o treino, não inventa uma narrativa de queda. Se você tomou uma decisão, anota as premissas.

Não é terapeuta. Não é mestre de jogo. Não é gerente. Não é mascote.

## 8.2 Traços

| Traço | Sim | Não |
|---|---|---|
| Civil | estação, ofício, cuidado | tropa, missão suicida, rank |
| Denso | painel, inspeção, proveniência | card de wellness, confete |
| Humano | crônica, retrato, notas | corporativês, “synergy” |
| Sóbrío | humor seco, curto | piada de nerd a cada tooltip |
| Reversível | “pausar”, “reduzir escopo” | “você quebrou a sequência” |
| Local | “fica neste aparelho” | “sua conta Fallhub” |

## 8.3 Tom na prática

A spec de ignição já tem a regra certa: ação antes de input; descanso planejado é execução correta; “Estou travado agora” é um comando digno, não uma confissão.

A marca deve soar como isso.

- Certo: “Sono com dados de ontem. Confiança média.”
- Errado: “Você falhou na higiente do sono!”
- Certo: “Próximo movimento: colocar o casaco. O resto espera.”
- Errado: “+50 XP por sair da inércia.”
- Certo: “Três compromissos em risco esta semana.”
- Errado: “Sua colônia está em colapso.”

O último exemplo é o teste. Se a metáfora exige drama de rimworld para ter graça, a metáfora está mal usada. Uma colônia civil real não anuncia colapso a cada barra amarela.

## 8.4 O que a voz herda do visual

Grafite, latão, ciano. Uppercase moderado nos títulos de painel. Sem neon. Sem coral de startup. Sem roxo de IA.

IA, quando aparecer, é subordinada: assistente no terminal, não oráculo com nome próprio fofo. Sem “Luna”, sem “Atlas-bot”. O Storyteller pode continuar como função — curadoria de revisão — desde que nunca vire personagem que “acontece” com o usuário.

---

# 9. Naming

## 9.1 Testes que um nome precisa passar

1. **Boca:** cabe numa frase falada. “Abre o ___.” “Manda um print do ___.”
2. **Barra:** 8–12 letras ideal; uma palavra; não parece empresa de consultoria.
3. **Loja:** não parece jogo de estratégia genérico nem banco digital.
4. **PT e EN:** não vira piada ao cruzar o idioma. (Colônia → cologne. Prumo → plummet? Cuidado.)
5. **Busca:** googla sem cair em perfume, em cidade alemã, em RimWorld, em perfume de novo.
6. **Domínio / handle:** possível ou aceitavelmente composta (`getfallhub`, `fallhub.app`).
7. **Vizinhança:** não soa como Notion, Linear, Obsidian, YNAB, Habitica, RimWorld, Colony Survival.
8. **Ética:** não implica conquista, score, vigilância, coaching.
9. **Já nosso:** nomes que o projeto já usa têm vantagem brutal de coerência.

## 9.2 Fallhub como produto — o candidato default

**Vantagens**

- já é o nome do mundo real (repo, package, terminal, assets);
- não é RimWorld, não é Colony, não é OS;
- soa como lugar / estação / porto — território T2;
- liga a RockFall sem ser o nome da pessoa;
- pixel-industrial aguenta o nome; Material Design não precisaria dele, o que é um bom sinal: o nome *pede* o visual que vocês já fizeram.

**Riscos**

- “Fall” em inglês: queda, outono, fail. Em branding de produtividade isso pode ser lido como azar. Em branding deste produto, pode ser lido como honestidade — a vida inclui queda, e o hub é o lugar para onde se volta. Essa leitura só funciona se a copy for adulta, não se o logo for um bonequinho caindo.
- “Hub” está gasto (GitHub, Discord, every hub). O composto Fallhub é mais próprio que Hub sozinho. Não separar.
- Não explica o produto. Tagline precisa trabalhar. Isso é aceitável: Nike também não explica.
- Pronúncia em PT: *fól-rabi*? *fáu-hub*? Precisa de uma pronúncia oficial. Recomendação: **FÓL-hub** (fall como em “rockfall”, não como “fail”), uma palavra, ênfase na primeira.

**Julgamento:** é o nome certo para vitrine, a menos que o teste de boca com três pessoas fora do projeto seja um silêncio constrangido. Nesse caso, não “melhorar” Fallhub. Trocar de território T2/T3 com um nome próprio em português.

## 9.3 Se não for Fallhub: shortlist

Nomes em português, uma palavra, território estação/instrumento. Nenhum é “Life X OS”.

| Nome | Por quê serve | Por quê pode morrer | Território |
|---|---|---|---|
| **Atalaia** | Torre de vigia civil. Ver o todo. Ibérico, próprio, adulto. Casa com terminal e crônica. | Pode puxar militar / farol de costa. Busca: palavra real, SEO disputável. | T2 |
| **Prumo** | “Pôr no prumo” é brasileiro e exato: alinhamento, verdade vertical, instrumento. Curto. | Em EN *prumo* não existe; *plumb* é encanamento. Expansão internacional fraca. | T3 |
| **Lastro** | O que dá estabilidade ao navio. Anti-hustle. Recursos como peso que equilibra, não score. Único. | Pouco conhecido. Pode soar a lastro de dívida / peso morto. | T3 |
| **Sextante** | Instrumento para saber onde se está. Casa literal com a pergunta “como estou agora?”. | Longo. Cheira a marca de relógio ou app de astronomia. | T3 |
| **Bitácula** | Caixa iluminada da bússola, no navio, à noite. Quase uma descrição do terminal. Belíssimo. | Impronunciável para metade das pessoas. Spelling. | T2+T3 |
| **Pouso** | Aterrissar, fazer um lugar. Fronteira sem império. Macio. | Fraco, comum, pode parecer pousada. | T2 |
| **Reduto** | Lugar interior, protegido, local-first. | Defensivo, isolacionista, um pouco amargo. | T2 |

**Não ir:**

- Clareira, Ninho, Farol, Norte, Rumo, Foco — wellness / genérico.
- Kernel, Nexus, OS, Hub, Base, Station — inglês de pitch deck.
- Colônia, Colony, Rim-, Pawn, Settler, Outpost Empire — a pergunta original.
- Nomes de pawn / mascote. Este produto não é um personagem; contém um.
- Qualquer coisa com AI, Copilot, Sensei, Coach.

**Atalaia** é o melhor substituto se Fallhub cair. Tem lugar (T2), tem olhar (T3), não é jogo, não é colônia, é pronunciável, é brasileiro sem folclore.

## 9.4 Taglines de trabalho (não para gravar em pedra)

Para Fallhub:

- “O terminal da sua vida.”
- “Veja o sistema. Decida o próximo movimento.”
- “Instrumento pessoal, dados locais.”
- “Sua vida, inspecionável.”

Evitar: “o RimWorld da vida real.” Mesmo como piada interna, essa frase é um ímã de reviewer. Se alguém precisar explicar o produto por analogia, a analogia certa não é o jogo. É: **um painel de estação + um diário de bordo + um lugar habitado.**

## 9.5 O ícone (só o princípio)

Não: pawn de frente estilo game, “C” de Colônia, planeta, coroa, bandeira, foguete, checkmark, coração, cérebro.

Sim, na família do terminal já existente: um recorte de painel (rebite, pip, pequena cruz de atalaia, ou a silhueta de uma estação em pixel). O ícone deve sobreviver a 16 px e não parecer um jogo idle.

Não produzir o ícone neste documento. Quando houver decisão de nome, o ícone segue o chrome do ADR-049, não o contrário.

---

# 10. Vocabulário: o que fica diegético, o que vira prosa

A metáfora continua. A *fala pública* seleciona.

| Interno / domínio | UI hoje | Recomendação pública |
|---|---|---|
| Colony | Colônia | **lugar** (home). Não é o nome do app. |
| Pawn | Perfil (nav), pawn (habitat) | **Perfil** fora do Habitat; pawn só no inspect/habitat |
| Colonista | “Colonista ocioso” | **apagar**. Dizer o nome da pessoa, ou “ocioso”. |
| Need | Necessidades | manter |
| Bill | — | **Rotina** / receita / regra. Bill não sobrevive em PT. |
| Storyteller | — | **Revisão** / crônica assistida. Storyteller só internamente. |
| Draft / Mobilização | Motor de Ignição | **Mobilização** é bom. Draft não. |
| Faction | Relações / organizações | manter prosa |
| Quest | Missões | manter (adulto, claro) |
| Research | Pesquisa | manter |
| Chronicle | Crônica | manter — é um dos melhores nomes do produto |
| Habitat | Habitat | manter |
| Gear / Loadout | Loadout | **roupa / equipamento**. Loadout é jargão. |
| Save | Backup / exportar | prosa. Save é jogo. |
| Letter | Carta / alerta | Carta é belo se o visual aguentar; senão Alerta. |

Regra: **o Habitat pode falar diegético. Saúde, finanças, configurações e onboarding falam prosa.** Quem abre o módulo de exames não pode encontrar “hediff”. Quem abre o ledger não pode encontrar “stockpile”.

Isso não é suavizar o produto. É respeitar o domínio. Um instrumento sério usa a palavra certa para cada superfície.

---

# 11. Implicações visuais (sem redesenhar agora)

O visual **já tem** identidade. O trabalho de marca aqui é de proteção, não de invenção.

- **Paleta:** grafite, latão, cobre, ciano funcional, areia, musgo. Já está na spec §7 e no terminal. Não acrescentar neon, coral, gradient mesh, “AI purple”.
- **Tipo:** Pixelify no chrome; humanoísta no texto longo. Esse contraste *é* a marca: painel + humanidade.
- **Forma:** radius 2–6 px, rebites, painéis encaixados. Cards de 24 px de radius seriam um rebrand acidental para SaaS.
- **Mascote:** o pawn não é a logo. É o habitante. Usá-lo como ícone da loja reduz o produto a Tamagotchi — exatamente o que a spec do Habitat recusa.
- **Fotografia / store art:** mostrar o terminal e o habitat como um só objeto (painel + lugar), nunca screenshot de RimWorld com dados trocados, nunca mockup de dashboard Dribbble.
- **Tema claro:** a spec admite. A marca é o escuro. Tema claro é acessibilidade, não identidade.

A spec 04 (paridade RimWorld) deve ser lida, daqui para frente, como **arquivo histórico de gramática de UI** (inspect, densidade, prioridades) — não como direção de marca. A direção de marca é o ADR-049 + spec §7. Se um dia houver ADR de marca, ele deve dizer isso em uma linha.

---

# 12. O que não fazer

- Não trocar nomes de pacotes (`colony_domain`, `colony_database`) nesta fase. Custo alto, ganho zero de marca. Colony no código é arqueologia aceitável, como `NS` na Apple.
- Não reescrever a spec mestre agora. Este documento não pede permissão para isso.
- Não lançar “Colônia by Fallhub” como compromisso. Duas marcas na barra de título é a fenda atual com maquiagem.
- Não contratar um universo narrativo (lore da estação, facções fictícias, lore de RockFall). O lore é a vida do usuário. A Crônica já é o cânone.
- Não criar um personagem de IA com nome. O Storyteller é uma função.
- Não usar “OS” no ícone, no título da loja ou no anúncio. O produto é um OS no sentido da spec; a palavra, no mercado, mente.
- Não fazer rebrand visual paralelo ao terminal. Ou se assume o Fallhub Terminal, ou se abre outro ADR. Não um terceiro cromo.
- Não testar o nome com a pergunta “você jogaria isso?”. A pergunta é “você abriria isso numa segunda de manhã difícil?”.

---

# 13. Como decidir (sem teatro)

Três perguntas, nesta ordem. A primeira já está respondida se a ambição da spec for levada a sério.

1. **O teto é o nicho RimWorld-life, ou é um instrumento de décadas para gente que nunca jogou o jogo?**  
   Se for o nicho: opção A, Colônia é o produto, e que se assuma.  
   Se for o instrumento: opção C, e o resto segue. A spec, lida de verdade, já escolheu o instrumento.

2. **Fallhub passa no teste de boca?**  
   Dizer em voz alta para três pessoas que não mexem no repo: “o app se chama Fallhub.” Se a reação for “ok, e faz o quê?” — a tagline trabalha, o nome fica. Se for “não entendi nem o nome”, ir para Atalaia (ou Prumo, se quiserem apostar em PT puro e mercado local).

3. **A home continua se chamando Colônia?**  
   Recomendação: sim. É o lugar. Perde-se pouco, ganha-se continuidade, o Habitat não órfão. Reavaliar só se “Colônia” na tab inferior continuar puxando a leitura de jogo depois do rename da vitrine.

Não decidir ícone, domínio e l10n antes de 1 e 2. Naming por comitê de paleta é como o produto acaba com três nomes.

---

# 14. Próximos passos, quando houver decisão

Nada disto está sendo feito agora. Quando o fundador fechar 1 e 2:

1. ADR curto de marca (nome de produto, nome de lugar, o que acontece com “Life Colony OS”).
2. `AppStrings.appName` e `title` do OS passam a ser o nome de produto; a tab da home pode permanecer Colônia.
3. README e manifest acompanham. Spec mestre: linha de cabeçalho, não reescrita geral.
4. Onboarding: “criar colônia” pode permanecer como ato diegético (“nome da sua colônia”) *dentro* de um app que já se apresentou como Fallhub.
5. Varredura de copy: colonista, loadout, hediff, save, draft — prosa nas superfícies sérias.
6. Ícone e store listing a partir do kit do terminal, não a partir do pawn.
7. Pacotes `colony_*`: não tocar até uma v1 pública exigir.

Até lá, o único movimento de marca que já está certo é o que o ADR-049 fez: o olho acredita em Fallhub. Falta a boca concordar.

---

# 15. Nota ao fundador

A dúvida “será que abandono a colônia?” é o instinto certo apontando para o alvo errado.

O que incomoda não é a metáfora. É o produto ainda se apresentar como o exercício que o gerou. RimWorld foi o professor. Não precisa ser o sobrenome.

Vocês já têm o que a maior parte dos apps inventa no PowerPoint: um visual próprio (terminal civil), um lugar vivo (Habitat), uma ética que quase ninguém no gênero ousa (não pontuar a pessoa), e um nome de mundo real (Fallhub) esperando ser promovido.

A colônia fica. Como lugar, como tese, como mapa.  
O produto, se a ambição for a da spec, chama-se outra coisa — e essa coisa, na prática, já está escrita no chrome.
