# Agente 3 — Áreas do saber e categorização multi-caminho

Pilar: **o mesmo conhecimento acessível por várias prateleiras; específico o bastante para ODD; ligado à pesquisa e aos cartões.**  
Fonte de verdade: spec §22, §72, ADR-017, ADR-036 §1, ADR-037.  
Companheiros: `AGENT_FLASHCARD_UX.md`, `AGENT_SPACED_LEARNING.md`.  
Plano: [`docs/dev/KNOWLEDGE_FLASHCARDS_EVOLUTION.md`](../KNOWLEDGE_FLASHCARDS_EVOLUTION.md).

Este agente **não implementa** até o coordenador pedir. Elabora taxonomia, navegação e pontes; quando autorizado, deixa o mapa tão fácil de classificar quanto de consultar.

---

## Missão

O mapa de conhecimento é uma **prateleira** (taxonomia), não a árvore de pesquisa (intenção + evidência). O usuário precisa:

- Enquadrar um tópico **fino** (ODD em Carros autônomos) sem perder o pai.
- Chegar ao **mesmo** tópico por dois caminhos (Tropicalismo ⊂ Música **e** ⊂ História → Brasil).
- Ver e criar cartões **nessa** prateleira, e ver a pesquisa ligada — nos dois sentidos.
- Classificar na captura em poucos toques, não num dropdown de 80 itens planos.

## O que já existe (modelo certo — completar a experiência)

| Peça | Comportamento |
|------|----------------|
| `KnowledgeArea` | Um `parentId` **primário** (breadcrumb e floresta do hub) |
| `KnowledgeAreaPlacement` | Arestas secundárias; mesmo `id`, mesmo calor, sem duplicar nó |
| Ciclos | Proibidos no grafo combinado |
| Catálogo | Opt-in; inclui Tropicalismo com `catalogPlacements: ['humanities.history.brazil']` e ramo `engineering.automotive.autonomous.odd` |
| Calor | Agrega descendentes **primário ∪ secundário** (`StudyQueuePolicy.heatByArea`) |
| Cartão / baralho | `areaId` canônico único (ADR-037: sem N areaIds por cartão) |
| `ResearchKnowledgeLink` | N:N `primary` \| `related` \| `practice` |
| UI área | Filhos + atalho “atalho”; chips “Também em…” com **path string**, não navegam |
| UI pesquisa | Painel prateleiras + painel baralhos no detalhe do nó |
| Hub mapa | Floresta **primária** só; lista indentada; sem colapso; `iconKey` não renderiza |
| Busca | Título de área / baralho / texto do cartão; não busca path nem descrição |
| Seed | Sheet com árvore de checkbox |

Casos de teste: `knowledge_area_dag_test` (Tropicalismo + ODD), `flashcards_area_alias_test`.

## Problemas a resolver

### 1. Classificar ainda é um cadastro de grafo
Criar área → escolher pai num dropdown → “Colocar também em…” noutro dropdown de candidatos crus. Não há typeahead, “criar caminho” (Engenharia / Automotiva / Autônomos / ODD) nem sugerir colocação a partir do catálogo.

Captura do cartão: `areaId` copiado do baralho. Não dá para cravar o cartão em **Teoria musical** se o baralho está em **Música**, sem editar entidade.

### 2. Ver por dois caminhos é incompleto
- Hub não mostra que Tropicalismo também vive em História (proposital no ADR, mas o **detalhe** precisa compensar).
- Chips “Também em…” não são rotas.
- Não dá para **remover** colocação na UI (`removePlacement` existe no controller).
- Voltar da área sempre vai ao hub, ignorando `via=`.

### 3. Mapa não escala nem explica profundidade
Lista sempre expandida. ODD (4 níveis) some no scroll. Sem ícones do catálogo. Sem filtro “só frágeis / só com due”. Sem busca por path `História · Brasil · Tropicalismo`.

### 4. Cartão, baralho e área dessincronizam
Estudo por área filtra `card.areaId ∈ descendentes`. Baralhos da área usam `deck.areaId`. Cartão sem `areaId` (ou deck movido depois) **some** do estudo da prateleira mas aparece na lista de baralhos.

### 5. Pesquisa e mapa ainda são dois mundos
Ligar é manual, kind default `related`. Não há calor de retenção no nó, nem “estes cartões são prática deste foco”. Spec §22.7 trilhas (francês, harmonia, Flutter…) não existem como entidade — o mapa + pesquisa **juntos** deveriam cobrir o caso sem novo tipo ainda.

### 6. Catálogo é ilustrativo, não um atlas
Nove raízes, profundidade real só em música/história/ODD. O usuário precisa criar ramos finos **com a mesma facilidade** do seed. Áreas custom são cidadãs — a UI não parece.

## Casos âncora (aceitação narrativa)

**A. Tropicalismo**  
Semeia `arts.music.tropicalismo`. Aparece sob Música (canônico) e sob História do Brasil (atalho). Calor e cartões **não duplicam**. Abrir por História mostra chip “Também em Artes · Música” **clicável**. Um cartão “O que foi o Tropicalismo?” estudável pelos dois lados.

**B. Teoria musical + história da música**  
Dois filhos de Música. Capturar “o que é uma dominante secundária?” escolhe Teoria no typeahead, não o pai genérico.

**C. ODD**  
Caminho Engenharia → Automotiva → Carros autônomos → ODD. Usuário cria o cartão “ODD = Operational Design Domain” **na folha**, vê o breadcrumb completo, e pode colocar ODD também em “Computação · Sistemas” se quiser, sem clonar o nó.

**D. Pesquisa**  
Nó `inResearch` “Ler Caetano / Tropicália”. Ligar prateleira Tropicalismo (`practice`). Do nó: estudar due da prateleira. Da área: ver o nó. Demonstrar o nó **não** exige zerar flashcards.

## Direção de produto (obrigatória)

1. **Um nó, vários caminhos** — já no domínio; a UI tem de tornar colocação tão fácil quanto “também em…”.
2. **Typeahead de prateleira** na captura e na criação de área: busca por título e por path; Enter cria folha sob o pai selecionado.
3. **Cartão herda área do baralho, mas pode especializar** para um descendente (não para um primo). Pai do baralho continua válido para agregação.
4. **Estudo/calor da área** = cartões cujo `areaId` **ou** `deck.areaId` cai no subconjunto de descendentes (definir no domínio, um teste, uma regra).
5. **Mapa:** ramos colapsáveis; ícone `iconKey`; calor no row; indicador sutil “tem atalho”; filtro due/frágil.
6. **Chips de path clicáveis** + remover colocação com confirmação leve.
7. **Pesquisa:** no detalhe da área, nós agrupados por kind; no detalhe do nó, CTA estudar se houver due na prateleira `practice`/`primary`.
8. **Não fundir** `ResearchNode` com `KnowledgeArea`. Sem LLM sugerindo colocações neste ciclo.

## Entregáveis quando autorizado a implementar

1. **Regra de visibilidade** cartão↔área (deck fallback) + testes de domínio.
2. **Navegação de path** — chips, `via`, back stack, remover colocação.
3. **Typeahead** de área (feature, sem DS de grafo).
4. **Captura com especialização** de área (filho do baralho).
5. **Mapa colapsável + ícones + filtro**.
6. **Pontes pesquisa** — CTAs e agrupamento; opcionalmente seed de links ao criar baralho a partir do nó.
7. **Criar caminho profundo** (“nova folha aqui”) a partir da área atual, para o caso ODD.

Schema: só se a regra de visibilidade exigir coluna nova — preferir **não** migrar; `areaId` no cartão + `areaId` no deck bastam.

## Critérios de aceitação

- Casos A–D demonstráveis em widget test ou teste de domínio + um fluxo UI.
- Tropicalismo: `descendantIds(Música)` e `descendantIds(História do Brasil)` contêm o mesmo id; heat.cardCount não dobra no hub.
- ODD visível por breadcrumb de 4 níveis sem o usuário semear o catálogo inteiro.
- Classificar “também em…” em ≤ 3 toques a partir do detalhe da área.
- Captura: escolher subárea com busca, não só dropdown.
- Área mostra pesquisa; pesquisa mostra prateleira; estudar a partir dos dois.
- Strings localizadas; analyze 0 erros.

## Fora de escopo deste agente

- Virada de cartão, FAB, Colônia (Agente 1 e 2).
- Múltiplos `areaId` por cartão (proibido pelo ADR-037).
- Grafo force-directed do mapa.
- Fundir pesquisa na taxonomia; LLM; sync.
- Biblioteca §72 (Source, atomic note) — só pontes se um slice futuro pedir.

## Perguntas que este agente deve responder no plano (antes de codar)

1. Especializar cartão só para descendentes do deck — ou permitir qualquer área (e então o baralho vira só agrupamento de estudo)?
2. Hub deve marcar nós com colocação secundária (ícone de ponte) sem duplicar a linha?
3. Seed do catálogo deve oferecer “só este ramo” (ODD) com ancestrais — já faz `expandKeys`; a UI deixa isso óbvio?
4. Trilha §22.7 = pesquisa + prateleira, ou entidade nova? (Recomendação: sem entidade nova neste ciclo.)
