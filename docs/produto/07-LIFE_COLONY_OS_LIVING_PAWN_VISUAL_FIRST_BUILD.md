# Living Pawn — Build orientado a resultados visuais

**Documento pai:** `05-LIFE_COLONY_OS_LIVING_PAWN_SPEC.md`  
**Assets:** `06-LIFE_COLONY_OS_LIVING_PAWN_ASSET_CATALOG.md`  
**Status:** guia de execução  
**Versão:** 1.4.4  
**Data:** 2026-08-07

---

## 0. Por que este guia existe

A spec `05` descreve o sistema completo (jobs, agenda, projection, Drift, Pawn-Guia…). Construir isso na ordem “arquitetura → tudo” produz muita infra e pouco na tela.

Aqui a ordem inverte:

```text
pixels na tela → comportamento visível → interação rica → cosmética / customização
  → multi-pawn / multi-ambiente → só então domínio (agenda, projection) → persistência
```

Cada milestone só começa quando a anterior está **visível e reproduzível** (`flutter run` + screenshot).

**Política (v1.1):** depois do núcleo jogável (V0–V3 + criador), **não** saltar para agenda/projection.  
Investir várias milestones em **parecer e sentir RimWorld**: cosmético, interativo, customizável, inspect profundo, bubbles, vários pawns e vários habitats. Domínio Life Colony entra só quando a cena já for divertida sozinha.

---

## 1. Regra de ouro

| Faça | Não faça |
|---|---|
| Abrir uma rota e ver o habitat | Criar 6 packages vazios “para depois” |
| Pawn andando com sprites reais | Placeholder infinito “enquanto modelamos domínio” |
| Um comportamento (wander) sólido | Utility AI + pathfinding + DB no mesmo PR |
| Usar assets de `living_pawn/` | Redesenhar o pawn do zero no V0 |
| Screenshot / golden por milestone | ADR de 12 páginas antes do primeiro frame |
| Editor / tint / bubble **na tela** | Ligar agenda “porque a spec manda” antes da cena estar viva |

**Proibido até o fim do Visual++ Extra (antes de V10):** schemas Drift de simulação, projection de tarefas/projetos, leitura de agenda real, Utility AI completa, sync remoto, Ignition/Atlas como dependência.

**Permitido cedo:** Flame, assets locais, screens Flutter finas, estado em memória / SharedPreferences leve, hardcode de mapas de demo, A* de grid local, tint modulate, UI de criação.

---

## 2. Definição de “pronto” visual

Uma milestone está pronta quando:

1. alguém abre o app e **vê** o resultado em &lt; 30 s;
2. o comportamento cabe em uma frase (“pawn fala em bubble”, “troquei o tapete”);
3. há caminho de reprodução documentado;
4. há pelo menos um screenshot no PR / pasta `docs/produto/assets/generated/habitat/`.

---

## 3. Núcleo jogável — status

| Milestone | Resultado | Status |
|---|---|---|
| **V0** | Grid + pawn layered + wander | ✅ feito |
| **V1** | Cômodo, walls, props, walkable/blocked | ✅ feito |
| **V2** | Tap select + inspect stub | ✅ feito |
| **V3** | A* + jobs manuais (dormir / sentar / mesa) | ✅ feito |
| **V3.5** | Tint (pele/cabelo/stuff) + tela **Criar colonista** | ✅ feito |
| **V4** | Inspect dockável + float menu no cursor + outline | ✅ feito |
| **V5** | Bubbles speech/thought/mote | ✅ feito |
| **V6** | Cosmética: body types, apparel, barba, loadouts | ✅ feito |
| **V7** | Editor cosmético do cômodo (piso/props/paredes/undo) | ✅ feito |
| **V8** | Vários ambientes (Quarto / Escritório / Cozinha / Terraço) | ✅ feito |
| **V9** | Colônia visual: vários pawns + roster | ✅ feito |
| **V9.5** | Polish: câmera, dia/noite, mute, mini-habitat | ✅ feito |
| **V9.6** | Draft + ordem por hold | ✅ feito |
| **V9.7** | Room roles + stats cosméticos | ✅ feito |
| **V9.8** | Beauty overlay + decoração | ✅ feito |
| **V9.9** | Filth, limpeza, cleanliness | ✅ feito |
| **V9.10** | Joy stations / recreate | ✅ feito |
| **V9.11** | Conforto, qualidade, luz | ✅ feito |
| **V9.12** | Temperatura e clima cosmético | ✅ feito |
| **V9.13** | Zonas permitidas (allowed area) | ✅ feito |
| **V9.14** | Engine social orgânica | ✅ feito |
| **V9.9+** | Visual++ Extra (filth/joy…) | ✅ feito |

Rotas atuais: `/colony/habitat`, `/colony/pawn-create?memberId=`.  
Assets: `packages/living_habitat_assets/`.  
Screenshots: `v0_wander.png` … `v98_beauty.png`, `v99_filth.png` … `v912_temperature.png`, `v913_zones.png`, `v914_social.png`.

Detalhe histórico do V0 (escopo original) permanece na §9 como anexo; não reabrir como trabalho pendente.

---

## 4. Roadmap — bloco Visual++ (obrigatório antes de agenda)

Cada fase = resultado novo na tela. **Sem** query de agenda, **sem** projection de projetos/tarefas, **sem** Drift de Habitat até V14 (persistência cosmética pode ser local leve antes disso).

```text
V0–V3.5   ████████    núcleo (feito)
V4–V9.5   ████████    Visual++ núcleo (feito)
V9.6      ████████    Draft + hold (feito)
V9.7      ████████    Room stats (feito)
V9.8      ████████    Beauty overlay (feito)
V9.9–V9.12 ████████    Visual++ Extra (feito)
V9.13–V9.14  ████████    zonas + social engine (feito)
V9.15       ░░░░░░░░    arquitetura rica
V10–V12   ░░░░░░░░    domínio fraco (só depois)
V13+      ░░░░░░░░    spec 05 completa
```

O bloco **Visual++ Extra** (§4.1) é opcional em ordem interna, mas **obrigatório como fase** antes de V10: pelo menos algumas fatias devem deixar a cena mais “jogo” sem tocar agenda/needs reais.

---

### V4 — Inspect RimWorld-grade

**Resultado:** selecionar pawn/objeto abre um inspect **útil e bonito**, não um stub.

- painel dockável (direita/baixo) no chrome Colony;
- pawn: retrato layered + nome + estado do job + facing + biografia curta editável (texto livre local);
- prop: nome, stuff/tint, footprint, ações rápidas (“Ir até aqui”, “Sentar” se aplicável);
- float menu no estilo RimWorld (botão direito / long-press) com 3–6 opções;
- estados vazio/seleção clara;
- screenshot: `v4_inspect.png`.

---

### V5 — Bubbles de interação (speech / thought)

**Resultado:** o habitat “fala” — bubbles acima do pawn como no RimWorld (e mods de speech bubble).

- bubble de texto curto acima da cabeça (anchor no pawn, follow câmera);
- tipos: `speech` (fala), `thought` (pensamento), `mote` (status rápido);
- triggers locais: ao concluir job, ao idle longo, ao tap no pawn, ao chegar na cama/mesa;
- pool de frases **hardcoded / localizadas** (sem LLM);
- duração, fade, fila (máx. 1–2 visíveis por pawn);
- opcional: ícone mote (sono, fome fake, “…”);
- screenshot: `v5_bubbles.png`.

Referência visual: bubbles do RimWorld + legibilidade estilo Speech Bubbles / Interaction Bubbles (só o **comportamento de UI**, não copiar assets proprietários de mods).

---

### V6 — Cosmética profunda do pawn

**Resultado:** o criador deixa de ser “pele + cabelo” e vira identidade visual.

- body types / silhuetas disponíveis nos assets (Male/Female/… conforme bundle);
- mais cortes + cores; barba/acessório se houver PNG;
- camada apparel mínima (1–2 peças tintáveis) se assets cobrirem;
- loadout visual nomeado (“Casa”, “Trabalho”) trocável sem domínio;
- preview 4 dirs + walk cycle curto no criador;
- randomizar por categoria (nunca pele sem opt-in);
- screenshot: `v6_cosmetics.png`.

---

### V7 — Personalizar o ambiente (editor cosmético) ✅

**Resultado:** o usuário muda o cômodo **agora**, sem “editor completo” da spec 05.

- modo Editar no Habitat: colocar / mover / remover props do catálogo V0+;
- pintar floor tiles (wood / carpet / concrete);
- walls/door cosméticos; células walkable recalculadas;
- stuff color no place tool + tint no inspect;
- undo local da sessão de edição;
- screenshot: `v7_room_edit.png`.

---

### V8 — Vários ambientes (mapas) ✅

**Resultado:** não existe um único room hardcoded — há **locais** trocáveis.

- 4 habitats preset: Quarto, Escritório, Cozinha, Terraço;
- seletor de local na UI (chips);
- cada mapa: floors, props, walkable próprios; edições da sessão persistem por local;
- transição visual simples (fade);
- pawn “aparece” no spawn do mapa ao trocar (sem simulação de viagem ainda);
- screenshot: `v8_multi_map.png`.

---

### V9 — Colônia visual: vários personagens ✅

**Resultado:** mais de um pawn vivo na cena; criação de “outros” (amigos/NPCs cosméticos).

- 2–4 pawns no mesmo mapa (jogador + extras);
- cada um: `PawnAppearance` + nome + wander/jobs independentes;
- tela criar/editar qualquer colonista da lista (reusa criador, `?memberId=`);
- seleção / inspect / bubble por indivíduo;
- float menu “Priorizar este” / “Seguir câmera”;
- screenshot: `v9_multi_pawn.png`.

---

### V9.5 — Polish de presença ✅

**Resultado:** a cena parece “jogo”, não protótipo.

- câmera pan/zoom (scroll + pinch) + follow opcional do pawn;
- day/night tint alinhado à hora local do dispositivo;
- sons stub opcionais (mute default);
- mini-habitat / portrait no header do app (spec §49 — versão mínima);
- screenshot: `v95_polish.png`.

---

## 4.1 Visual++ Extra — atmosfera jogável no Habitat (após V9.5)

Bloco de implementação: aprofundar a **gramática visual** do Habitat (draft, cômodos, beleza, recreação, luz, sujeira, zonas, social…). Cada fatia descreve o que aparece na tela, como o jogador interage e qual animação deve rodar. Domínio Life Colony (agenda, projection, Drift de simulação) entra só em V10+.

Referência de vibe (wiki): [Rooms](https://rimworldwiki.com/wiki/Rooms), [Beauty](https://rimworldwiki.com/wiki/Beauty), [Joy](https://rimworldwiki.com/wiki/Joy), [Drafting](https://rimworldwiki.com/wiki/Drafting), [Temperature](https://rimworldwiki.com/wiki/Temperature), [Quality](https://rimworldwiki.com/wiki/Quality).

### Modelo de interação (base para Extra)

| Gesto | Efeito |
|---|---|
| **Hold** no pawn | Entra em **draft** (selecionado para ordens). Anel ciano. |
| **Tap** no pawn (sem draft) | Só inspeciona (sem draft). |
| **Tap** em célula / prop (com draft) | Ordem de movimento/uso + **linha branca** do path. |
| **Tap** fora do mapa / no drafted | Libera draft → volta a vaguear. |
| **Right-click** / hold no pawn já drafted | Menu secundário (liberar, seguir câmera, personalizar). |
| **Martelo** | Modo construção (V7); HUD inferior troca para dock de ferramentas. |

#### Animação de interação — pipeline comum

Todas as fatias Extra que movem o pawn reutilizam este pipeline (já parcial em V9.6):

1. **Feedback do gesto (0–120 ms)**  
   - Hold: círculo de progresso sutil no ponto do dedo/cursor (anel cinza → ciano ao completar).  
   - Ao confirmar: flash curto na célula/prop alvo (outline 1 frame + fade 200 ms).
2. **Ack do pawn (imediato)**  
   - Anel de draft pulsa uma vez (scale 1.0 → 1.08 → 1.0 em ~180 ms).  
   - Bubble thought opcional (“Beleza.” / “Indo.”) só se a fatia pedir.
3. **Path + walk**  
   - A* célula a célula; walk-bob e squash já existentes; facing atualiza por delta.  
   - Células do path podem brilhar em sequência fraca (breadcrumb, alpha 0.15, some após o pawn passar).
4. **Arrival + pose**  
   - Snap à célula de approach; facing sul (ou para o prop).  
   - Pose: 0.8–4 s conforme o tipo (ver fatia); bob mínimo parado.  
   - Bubble speech/mote de chegada; depois resume wander (ou idle da fatia).
5. **Cancel**  
   - Liberar draft: anel some com fade 150 ms; pawn retoma wander no próximo tick.

---

### V9.6 — Draft + ordem por tap/hold ✅

**O quê.** O jogador aponta um colonista, marca-o como drafted e dá ordens de movimento/uso no mapa (estilo draft RimWorld). É o input principal da colônia visual.

**Como funciona**

- **Hold** no pawn → `drafted = true`: anel ciano + HUD “Draft · &lt;job&gt;”.
- **Com draft ativo**, tap em célula walkable → `goTo` + linha branca fina do A* (some ao chegar / undraft); draft permanece para encadear.
- Tap/hold em cadeira → approach + pose **sentar**; mesa → **na mesa**; cama/lâmpada/outros → approach curto (`goTo`).
- Tap de novo no pawn drafted **ou tap fora do habitat** → `undraft` + wander.
- Menu de contexto (right-click / hold no pawn já drafted): liberar, seguir câmera, personalizar.
- Implementação: ordens no **tap-up**; hold no pawn para draft; pinch fora do `ScaleDetector` do Flame.

**Animação de interação (detalhe)**

| Momento | Animação |
|---|---|
| Entrar em draft | Anel ciano desenha-se em 120 ms (stroke expand); barra teal no retrato do roster. |
| Hold em progresso | Anel de carga no alvo (arco 0→360°); cancela se o dedo sair da célula. |
| Ordem confirmada | Alvo pisca branco; pawn olha na direção do primeiro passo (~1 frame de facing). |
| Caminho | Walk-bob + squash; breadcrumb opcional nas células restantes. |
| Sentar / mesa | Na chegada: offset Y −2 px (assento), idle 2.5–3 s, bubble (“Ah.” / “Foco.”). |
| Approach cama/objeto | Chega na célula vizinha, facing para o prop, idle 0.8 s, mote curto. |
| Liberar draft | Anel dissolve; se estava em path, completa o passo atual e volta a wander. |

**Aceite:** screenshot `v96_draft_hold.png` com pawn drafted a meio do path.

---

### V9.7 — Room roles + stats cosméticos ✅

**O quê.** O Habitat reconhece o “papel” do cômodo a partir dos props e mostra uma faixa compacta de impressão do ambiente (beleza, espaço, limpeza, riqueza visual).

**Como funciona**

- Heurística por props presentes: cama → Quarto; mesa+cadeiras → Refeitório; lâmpada+cadeira sem cama → Rec/Escritório; terraço → Exterior.
- Quatro meters 0–100 derivados do mapa atual (piso, props, arte futura da V9.8, filth da V9.9).
- Rótulo de impressiveness em degraus (Medíocre → Agradável → Bonito → Extasiado).
- Strip discreta no topo ou canto (não cobre a colonist bar).

**Animação de interação**

| Momento | Animação |
|---|---|
| Troca de local / edit que muda role | Label do role faz cross-fade 200 ms; meters animam valor com ease-out 400 ms. |
| Hover/tap no strip | Expande 1 linha com breakdown (“Mesa +12 beauty”); recolhe ao soltar. |
| Idle no cômodo “bom” | Pawn drafted ou idle: bubble thought ocasional (“Bonito aqui.”) com fade-in 150 ms. |
| Cômodo apertado | Bubble (“Meio apertado.”); meter Space pisca âmbar 1×. |

**Aceite:** screenshot `v97_room_stats.png` com role + 4 meters visíveis.

---

### V9.8 — Beauty overlay + arte / decoração ✅

**O quê.** Modo de visualização da beleza por célula e novos props decorativos que alimentam o score do cômodo.

**Como funciona**

- Toggle (ícone ou atalho) ativa heatmap: verde suave → neutro → marrom; paredes bloqueiam contribuição.
- Catálogo placeable: planta, quadro/escultura, tapete premium, vaso (tintável).
- Beauty agregada atualiza V9.7 em tempo real ao colocar/remover.

**Animação de interação**

| Momento | Animação |
|---|---|
| Ligar overlay | Células tintam em cascade do centro da câmera (~8 ms/célula, total &lt; 250 ms). |
| Desligar | Fade global do heatmap 200 ms. |
| Colocar decoração | Ghost do prop segue o cursor (já V7); no drop, pop scale 0.85→1.05→1.0 + ripple de beauty nas células vizinhas (verde, 300 ms). |
| Remover decoração | Prop some com fade; ripple marrom inverso. |
| Pawn “observa” arte (idle) | Path curto até célula em frente; pose 2 s olhando o prop; bubble “Hmm.” |

**Aceite:** screenshot `v98_beauty.png` com overlay ligado e pelo menos um prop novo.

---

### V9.9 — Filth, limpeza e cleanliness ✅

**O quê.** O chão acumula sujeira visual com o tráfego e pode ser limpo por ordem ou por idle do pawn — ritual de manutenção da colônia.

**Como funciona**

- Pegadas / manchas leves nas células mais andadas (camada acima do piso, abaixo dos props).
- Hold “limpar” (ou ferramenta no draft) / pawn idle escolhe célula suja vizinha.
- Cleanliness do V9.7 sobe ao limpar e desce com tráfego.

**Animação de interação**

| Momento | Animação |
|---|---|
| Acúmulo | Filth aparece gradualmente (alpha 0→target em vários passos do pawn). |
| Ordem limpar | Hold na célula suja → path; na chegada, ciclo de 3 “vassouradas”: pawn faz bob lateral 4 px × 3, sprite de mote poeira sobe e some. |
| Célula limpa | Mancha faz dissolve 250 ms; +flash no meter Cleanliness. |
| Overlay limpeza (opcional) | Mesma linguagem do beauty overlay, paleta marrom→claro. |

**Aceite:** screenshot `v99_filth.png` com filth visível e pawn a meio da limpeza.

---

### V9.10 — Joy stations (recreação diegética) ✅

**O quê.** Props e comportamentos de recreação: pawns usam estações de lazer na cena, com variedade e poses distintas.

**Como funciona**

- Props: jogo de mesa, TV/monitor, instrumento, planta para observar, rota de caminhada no terraço.
- Job local `recreate`: approach → pose específica → bubble → tolerância leve (mesmo prop menos escolhido por um tempo na sessão).
- Idle wander pode escolher recreate sozinho se houver estação livre.

**Animação de interação**

| Momento | Animação |
|---|---|
| Hold na estação | Pipeline comum + facing para o prop. |
| Jogo de mesa | Senta (offset Y); a cada ~1.2 s mote “peça” ou bob de braço; duração 4–6 s. |
| TV / monitor | Em pé ou sentado; flicker sutil na tela do prop (tint 2–3 Hz baixo); bubble “…” thought. |
| Instrumento | Pose frontal; 3 notes mote sobem em arco; duração ~4 s. |
| Observar planta | Em pé na célula vizinha; facing planta; idle respiração (scale Y 1.0↔1.02). |
| Caminhada terraço | Path ao longo da borda outdoor; sem pose final — só wander dirigido 5–8 s. |
| Tolerância | Próxima escolha evita o mesmo `kind` por N minutos de relógio de sessão. |

**Aceite:** screenshot `v910_joy.png` com pawn em pose de recreate + bubble.

---

### V9.11 — Conforto, qualidade e luz ✅

**O quê.** Props ganham qualidade visual e as lâmpadas projetam luz no grid; o cômodo muda de atmosfera conforme o mobiliário.

**Como funciona**

- Cada prop tem qualidade (Normal / Bom / Excelente) editável no dock ou no inspect.
- Qualidade altera rótulo, contribuição de beauty/comfort nos meters V9.7.
- Lâmpadas: radius de iluminação; células fora do radius indoor recebem tint mais escuro.
- Pawn em área **muito** escura (darkness ≥ ~0.78 — noite indoor sem luz; não penumbra outdoor): bubble “Escuro demais.” raro (cooldown longo) e preferência de wander para células iluminadas.

**Animação de interação**

| Momento | Animação |
|---|---|
| Trocar qualidade | Badge no prop faz flip horizontal 200 ms; meter Comfort anima. |
| Ligar/criar lâmpada | Radius cresce ease-out 350 ms (máscara radial). |
| Apagar / remover lâmpada | Radius contrai; tint de noite reforça 200 ms. |
| Pawn entra na luz | Soft rim light no mesh 150 ms (modulate +8% branco). |
| Pawn na escuridão real | Tint pawn −10% por 200 ms; bubble thought após ~3 s parado, cooldown ~80–130 s. |
| Sentar em cadeira “Excelente” | Pose sentar + mote estrela curta (1×). |

**Aceite:** screenshot `v911_comfort_light.png` com radius de luz e badge de qualidade.

---

### V9.12 — Temperatura e clima cosmético ✅

**O quê.** Cada mapa tem temperatura visual; heater/cooler e o ciclo dia/noite (V9.5) alteram overlay e preferência de wander.

**Como funciona**

- Temperatura base por locale (quarto ameno, terraço mais extremo).
- Props heater/cooler deslocam ± a temperatura do mapa.
- Overlay frio (azul) / calor (laranja) quando fora da faixa confortável.
- Wander prefere células indoor confortáveis se o outdoor estiver extremo.

**Animação de interação**

| Momento | Animação |
|---|---|
| Colocar heater | Prop + ondas de calor (3 anéis laranja, sobem 400 ms). |
| Colocar cooler | Flocos/partículas frias curtas. |
| Transição de faixa | Overlay global lerp 600 ms. |
| Pawn com frio/calor | Bob de tremor (frio, 2 px) ou wipe suor mote (calor); bubble (“Brr.” / “Ufa.”). |
| Troca dia→noite no terraço | Já V9.5; temperatura outdoor desce com a fase e atualiza overlay. |

**Aceite:** screenshot `v912_temperature.png` com overlay + heater ou cooler.

---

### V9.13 — Zonas permitidas (allowed area) ✅

**O quê.** Ferramenta para pintar a área onde o pawn pode vaguear e receber ordens de movimento.

**Como funciona**

- No modo construção (ou toggle Zona): expand / erase células da zona do pawn focado.
- Wander e hold-order respeitam a zona (ordens fora = path até a borda mais próxima ou rejeição com feedback).
- Visual: hatch suave nas células permitidas quando a ferramenta está ativa.

**Animação de interação**

| Momento | Animação |
|---|---|
| Pintar zona | Células preenchem com hatch ciano em stagger 30 ms. |
| Apagar zona | Hatch dissolve. |
| Ordem fora da zona | Flash vermelho na célula alvo 200 ms; pawn faz head-shake (facing left-right 2× rápido) + bubble “Não.” |
| Ordem dentro | Pipeline V9.6 normal; path nunca sai da zona. |
| Trocar pawn focado | Hatch faz cross-fade para a zona do novo drafted. |

**Aceite:** screenshot `v913_zones.png` com hatch visível e pawn dentro da área.

---

### V9.14 — Engine social (encontros orgânicos) ✅

**O quê.** Uma **engine social leve** faz a colônia parecer viva: colonistas se notam, se aproximam, conversam, riem, se despedem e evitam repetir o mesmo ritual de forma robótica — sem Utility AI completa, sem grafo Drift de relações e sem custo relevante de frame.

**Fora de escopo (V10+ / spec 05):** opinion tracking persistente, romance/família, social need numérico, LLM, pathfinding multi-agente cooperativo. Aqui tudo é **cosmética + sessão**.

#### Princípios de design

1. **Emergente, não scriptado** — não há cutscenes; há *chances* + *affordances* (mesa, sofá, gathering spot, corredor).
2. **Poucos atores ativos** — no máx. **1 encontro social** por mapa ao mesmo tempo (ou 2 se N≥5 pawns); o resto só contribui como “presença”.
3. **Barato por padrão** — a maior parte dos ticks só faz aritmética em índices já em memória; A* só quando o encontro *confirma*.
4. **Anti-loop** — cooldowns por par, por local e por tipo de gesto; variedade de bubbles/poses.
5. **Respeita o jogador** — pawn **drafted**, em job manual (`clean` / `goTo` / `recreate` ordenado), ou em path de ordem **nunca** é puxado para social.
6. **Orgânico ≠ aleatório puro** — pesos suaves (beleza do cômodo, luz, mesa livre, hora do dia) + jitter, nunca RNG binário a cada frame.

---

#### Arquitetura (módulos sugeridos)

```text
HabitatSocialDirector          // orquestra; 1 por HabitatGame
  ├─ SocialCandidateCache      // pares elegíveis / scores (dirty)
  ├─ SocialEncounter           // estado da interação ativa (FSM)
  ├─ SocialAffinitySession     // mapa leve par→afinidade 0..1 (só sessão)
  ├─ SocialMemory              // cooldowns + lastVenue + lastBeat
  └─ SocialPhraseBank          // pools localizados por beat/venue/mood
```

**Arquivos alvo (implementação):**  
`habitat_social.dart` (puro), `components` opcional só para motes; wiring em `HabitatGame.update` via director — **não** um `update` social dentro de cada pawn.

---

#### Modelo de dados (leve, em memória)

| Entidade | Campos | Notas |
|---|---|---|
| `SocialPairKey` | `(minId, maxId)` ordenado | chave estável do par |
| `SocialAffinity` | `float 0..1`, `lastMetAt` | sobe um pouco após encontro bom; desce com o tempo (decay lento) |
| `SocialMemory` | `pairCooldownUntil`, `venueCooldownUntil[kind]`, `globalQuietUntil` | evita spam |
| `SocialEncounter` | `phase`, `members[]`, `venue`, `beatIndex`, `t` | FSM única |
| `SocialVenue` | `stand`, `table`, `sofa`, `gatheringSpot`, `doorwayChat` | affordance resolvida na confirmação |

Afinidade **não** persiste em Drift nesta fatia; opcionalmente espelhar em SharedPreferences depois se for barato (fora do aceite mínimo).

---

#### Máquina de estados do encontro

```text
Idle (director)
  → Probe (candidato existe, score > limiar)
    → Approach (1 ou 2 paths curtos; budget A*)
      → FormUp (facing + offsets)
        → BeatLoop (2–5 beats de diálogo/gesto)
          → WindDown (despedida)
            → Cooldown → Idle
```

Cancelamento imediato se: draft em qualquer membro, ordem do jogador, mapa switch, pawn removido, path impossível, ou `globalQuietUntil`.

---

#### Pipeline de decisão (orgânico + barato)

**Cadência (não por frame):**

| Fase | Intervalo típico | Trabalho |
|---|---|---|
| Refresh candidatos | **400–700 ms** (jitter) | O(n²) só se n≤8; senão amostragem |
| Score / roleta | no refresh | aritmética + 1 RNG |
| Tick encontro ativo | **cada frame** (só 1 FSM) | timers + facing + bubbles |
| Decay afinidade | **5–10 s** | O(pares tocados), não O(n²) |

**Com N pawns:**

- `N ≤ 4` — avaliar todos os pares elegíveis.
- `N > 4` — a cada refresh, amostrar até **K=6 pares** (shuffle parcial / reservoir) entre pawns idle; nunca varrer n² completo todo tick.
- Rookie guard: se `N < 2`, director dorme (zero custo além do timer).

**Elegibilidade rápida (rejeição barata primeiro):**

1. `job == wander` (ou idle pose curta pós-goTo) e **não** drafted.  
2. Não está em `pairCooldown` / `globalQuiet`.  
3. Distância Chebyshev ≤ **R_near** (default 3) **ou** ambos veem o mesmo `SocialVenue` com vagas (mesa com 2+ cadeiras livres num raio 4).  
4. Mesmo mapa / mesma “sala” aproximada: se houver paredes, exigir LOS barato (reusar rotina de light/beauty) **só no par finalista**, não em todos.

**Score (0..1) — pesos sugeridos:**

| Fator | Peso | Sinal |
|---|---|---|
| Proximidade | 0.25 | `1 - dist/R` |
| Affinity sessão | 0.20 | favorece reencontros leves, não clones |
| Venue (mesa/sofá/spot) | 0.20 | mesa livre > stand |
| Conforto / beleza do cômodo | 0.10 | meters V9.7 já calculados |
| Luz (não escuro) | 0.10 | `darkness < 0.55` |
| Hora social | 0.10 | dia/entardecer ↑; madrugada ↓↓ |
| Anti-repetição | 0.05 | penaliza mesmo `venue`+mesmo par recente |
| Jitter | ±0.05 | desync artificial |

Roleta ponderada entre top-3 candidatos (não “sempre o melhor”) → sensação menos robótica.

**Limiares:**

- Começar Probe só se `score ≥ 0.55` (ajustável).  
- Após rejeição, aquele par entra em cooldown curto **8–20 s** (falha barata).  
- Após encontro completo: cooldown do par **45–120 s**; venue **30–60 s**; quiet global **5–12 s**.

---

#### Venues e formação espacial

| Venue | Como resolve | Formação |
|---|---|---|
| `stand` | encontro no lugar (dist≤2) | ombro a ombro ou face-a-face (1 célula de gap) |
| `table` | mesa + ≥2 approach cells livres | sentam/ficam nas cadeiras ou approach sul da mesa |
| `sofa` | prop sofá (se existir) / fallback table | side-by-side |
| `gatheringSpot` | marcador de chão (editor, 1×1, `blocksWalk:false`) | cluster radial ≤2 células |
| `doorwayChat` | perto da porta, só se corredor não bloqueado | 2 células adjacentes à porta, facing cruzado |

Regra: **um** pawn patha (o de maior score “host”) **ou** ambos patham para venue — escolher a opção com **menor soma de path length**; se path > 8 passos, aborta (barato: length do A* ou greedy).

Integra gathering spot do backlog Extra **dentro** desta engine (não como fatia separada).

---

#### Beats + montagem combinatória de falas

Um encontro = sequência de **2–5 beats**. O texto **não** vem de uma lista fixa “sorteia frase”: vem de um **gerador de diálogo por slots** (`SocialLineAssembler`) que combina peças gramaticais coerentes. Assim cada conversa parece nova, mas continua fazendo sentido no contexto (venue, hora, cômodo, luz, sujeira, afinidade).

**Sem LLM** nesta fatia. Tudo é dados locais + regras. O espaço combinatório é o que gera “inovação”.

---

##### 1) Ideia central — diálogo como grafo de peças tipadas

Cada fala é uma **instância** de um *pattern* preenchido com *slots* que só aceitam fichas do tipo certo:

```text
pattern:  "{opener} {topic_clause}{tail}"
exemplo:  "Olha… essa mesa aqui tá bem boa."
           └opener┘ └──── topic_clause ────┘ └tail┘
```

**Peças (fichas) têm tags.** O assembler só junta fichas cuja interseção de tags é válida → nonsense fica estruturalmente impossível.

| Tipo de ficha | Exemplos (PT) | Tags típicas |
|---|---|---|
| `opener` | “Olha…”, “Pois é,”, “Ei,”, “Hmm,” | `soft`, `direct`, `warm` |
| `address` | nome curto do parceiro / ∅ | (opcional; max 1× por encontro) |
| `topic_seed` | `room_beauty`, `lamp_light`, `filth`, `weather_out`, `meal_table`, `idle_life`, `work_desk`, `night_quiet` | define o assunto |
| `observation` | “tá bonito aqui”, “essa luz ajuda”, “o chão pede vassoura” | amarrada a `topic_seed` |
| `opinion` | “eu curto”, “não é mau”, “podia melhorar” | `pos` / `neu` / `neg` |
| `react` | “Pois é.”, “Né?”, “Ha.”, “Sério?” | `agree`, `laugh`, `surprise` |
| `tail` | “.”, “…” , “ hein?” | pontuação / tom |
| `farewell` | “Até.”, “Falou.”, “Vou andando.” | só no beat final |

Uma ficha `observation` com tag `topic:filth` **nunca** entra num pattern de `topic:room_beauty`. Isso é a base do “faz todo sentido”.

---

##### 2) Contexto congelado no início do encontro (`TalkContext`)

No commit do encontro (antes do 1º beat), capturar um snapshot imutável — barato, O(1) a partir de meters já existentes:

| Campo | Origem | Uso nas tags |
|---|---|---|
| `venue` | stand/table/sofa/spot/door | libera seeds `meal_table`, `doorway`, … |
| `phaseLabel` | HabitatPresence | `time:day` / `dusk` / `night` / `dawn` |
| `beautyBand` | roomStats.beauty → low/mid/high | `mood:pos` se high |
| `cleanBand` | cleanliness / filth local | seed `filth` se dirty |
| `lightBand` | darkness na célula | `dark` bloqueia seeds visuais “bonito” |
| `tempBand` | climate comfortDelta | `cold` / `hot` / `ok` |
| `affinity` | sessão do par | `warm` openers se affinity alta |
| `speakerTone` | derivado do nome/role cosmético leve* | `soft` vs `direct` (opcional) |
| `recentTopics` | SocialMemory do par | exclusão (anti-eco) |

\*Tom cosmético: hash estável do `memberId` → 1 de 3 personalidades de fala (`soft`, `dry`, `bright`) — **não** é utility AI; só enviesa pools.

---

##### 3) Agenda do encontro (`DialoguePlan`) — beats com assunto

Antes de FormUp, o assembler monta um **plano** (não o texto final):

```text
greet → (talk|joke|glance)×1..3 → agree? → farewell
         └─ todos os beats do meio compartilham 1 topic_seed dominante
```

Regras de plano:

1. Escolher **1 topic_seed dominante** por roleta ponderada entre seeds **habilitados** pelo `TalkContext` (ver tabela abaixo).  
2. Com 20% de chance (se ≥3 beats no meio), um beat `glance` pode usar um **topic satélite** compatível (ex.: dominante `room_beauty`, satélite `lamp_light`).  
3. `joke` só se `affinity ≥ 0.35` **ou** topic ∈ {`idle_life`, `meal_table`} e não `time:night` profundo.  
4. `recentTopics` do par: seeds usados nos últimos 2 encontros têm peso ×0.15 (quase banidos).  
5. Guardar o plano na `SocialEncounter` — gerar texto **lazy** no início de cada beat (permite cancel sem desperdício).

**Topics e quando existem (habilitação):**

| `topic_seed` | Habilitado se | Observações compatíveis (amostra) |
|---|---|---|
| `room_beauty` | beautyBand ≥ mid e lightBand ≠ dark | “tá agradável aqui”, “o cômodo respira” |
| `lamp_light` | há lâmpada e lightBand ≠ dark | “essa luz muda tudo”, “bem melhor iluminado” |
| `filth` | filth local ≥ 0.25 ou cleanBand low | “o chão denuncia”, “vassoura chamando” |
| `weather_out` | locale outdoor **ou** phase dusk/night | “lá fora pesa”, “noite mansa” |
| `meal_table` | venue = table | “mesa boa pra conversa”, “cadeira certa” |
| `work_desk` | role office / há mesa+lâmpada | “parece dia de foco”, “depois a gente resolve” |
| `night_quiet` | phase night/madrugada | “silêncio bom”, “hora baixa” |
| `idle_life` | sempre (fallback) | “e aí a vida”, “só passando” |
| `crowding` | spaceTight | “tá apertado”, “falta ar” |
| `cozy_warm` | tempBand ok e beauty mid+ | “aconchegante”, “dá pra ficar” |

Se nenhum seed “especial” passar, cai em `idle_life` — sempre há fala possível.

---

##### 4) Patterns por beat (templates com slots)

Cada beat type tem 3–8 patterns. Slots entre `{ }`. Ex.:

**`greet`**

- `{opener}`  
- `{opener} {address}`  
- `{opener} {time_nod}` → time_nod ∈ {“boa hora.”, “ainda acordado?”} filtrado por phase  

**`talk` (iniciador A)**

- `{opener} {observation}{tail}`  
- `{observation} — {opinion}{tail}`  
- `{address}, {observation}{tail}`  

**`talk` (resposta B — thought ou speech curto)**

- `{react}`  
- `{react} {opinion_echo}{tail}` onde `opinion_echo` espelha polaridade de A (pos→pos/neu, neg→neu/agree)  
- `{soft_ack} {observation_short}` (observation do **mesmo** topic, formulação diferente)

**`joke`**

- `{observation} {twist}{tail}` com `twist` tag `humor` + mesmo topic  
- Só patterns com tag `humor_ok` no topic  

**`glance`**

- thought: `{observation}` (sem opener; tom interno)  

**`agree`**

- `{react:agree}` / `{react:agree} {opinion:pos|neu}`  

**`farewell`**

- `{farewell}`  
- `{farewell} {venue_bye}` → “fico por aqui.” se venue table/spot  

**Concordância obrigatória (validador):**

| Regra | Efeito |
|---|---|
| Polaridade | Se A usou `opinion:neg` sobre filth, B não responde com “tá lindo” |
| Topic lock | Todas as fichas do beat compartilham `topic:*` do plano (exceto react genérico) |
| Tempo | `time_nod` / weather só com tags de phase ativas |
| Escuro | Se `lightBand=dark`, banir observations `visual_beauty`; preferir `night_quiet` / `idle_life` |
| Comprimento | String final ≤ **42 caracteres** (bubble legível); se estourar, cair no pattern mais curto do mesmo beat |
| Eco | Não repetir a **mesma** observation id nos últimos 8 falas da sessão (ring buffer global) |

Se o preenchimento falhar (pool vazio), **fallback em cascata:** pattern mais simples → react só → “…” — nunca crash, nunca frase pela metade.

---

##### 5) Algoritmo do assembler (barato)

```text
assemble(beat, plan, ctx, speaker, listener):
  1. patterns = PATTERNS[beat] filtrados por ctx.tags
  2. escolher pattern (roleta; evitar lastPatternId do par)
  3. para cada slot:
       pool = FICHAS[slot] ∩ tags(plan.topic) ∩ tags(ctx) ∩ tone(speaker)
       remover ids em recentLineIds / recentObservationIds
       se vazio → relaxar 1 tag (tone) → se ainda vazio, fallback
       pick ponderado
  4. concat + normalizar espaços/pontuação
  5. se len > 42 → retry com pattern curto (máx 2 retries)
  6. registrar ids usados na memória do encontro + ring global
```

Custo: dezenas de interseções de sets pequenos (fichas ~80–150 no MVP). **&lt; 0.05 ms** por fala. Zero alocação quente se pools forem `const` e o pick usar índices.

---

##### 6) Micro-gramática PT (para soar natural)

- Openers que terminam com reticências **não** ganham vírgula extra.  
- `address` só se affinity ≥ 0.4 **e** nome do listener tem ≤10 chars.  
- Evitar dois openers seguidos no mesmo encontro (flag `usedOpener`).  
- Resposta B em `talk`: 55% thought (“…” / react curto), 45% speech — parece escuta real.  
- Alternância A/B rígida nos beats; o assembler só decide o **texto**, não quem fala (isso é do FSM).  
- Feminino/masculino: **evitar** concordância de gênero em adjetivos; preferir formas invariáveis (“tá bom”, “agradável”, “tranquilo o clima”) para não errar com nomes neutros.

---

##### 7) Espaço combinatório (por que parece sempre novo)

Ordem de grandeza no MVP sugerido:

| Camada | Cardinalidade aprox. |
|---|---|
| Topics habilitáveis | ~8–10 |
| Patterns / beat | ~5 |
| Observations / topic | ~6–10 |
| Openers | ~12 |
| Reacts | ~10 |
| Opinions | ~8 |

Uma linha `talk` típica: `opener × observation × opinion? × tail` → centenas de combos **por topic**; × topics × plans × quem fala → milhares de encontros distintos sem repetir a mesma string completa. Com anti-eco de observation ids, a repetição perceptível cai ainda mais.

**Inovação controlada:** o jogador sente variedade; o sistema nunca inventa lexicalmente fora do banco (sem alucinação).

---

##### 8) Exemplos gerados (mesmo topic `lamp_light`)

| # | Pattern | Resultado |
|---|---|---|
| 1 | `{opener} {observation}{tail}` | “Olha… essa luz muda tudo.” |
| 2 | `{observation} — {opinion}{tail}` | “Bem melhor iluminado — eu curto.” |
| 3 | react B | “Né?” |
| 4 | joke | “Essa luz muda tudo… quase um holofote.” |

Mesmo seed, quatro superfícies diferentes; tags garantem que não vira “vassoura” no meio.

---

##### 9) Dados e localização

- Fichas e patterns em estruturas `const` no Dart (ou JSON asset local), chaves estáveis (`obs_lamp_01`).  
- Texto PT em `AppStrings` **ou** mapa `SocialLexicon.pt` espelhando o padrão de bubbles V5 — **não** hardcode espalhado no director.  
- Extensão futura: segundo idioma = segundo lexicon; patterns reutilizam as mesmas keys.

---

##### 10) Orquestração visual dos beats (inalterada na forma, alimentada pelo assembler)

| Beat | Duração | Visual | Texto |
|---|---|---|---|
| `greet` | 0.6–1.0 s | facing mútuo; mote “…” | `assemble(greet)` |
| `talk` | 1.0–1.6 s | speech A → thought/speech B | `assemble(talk)` ×2 (A depois B) |
| `joke` | 1.2–1.8 s | squash nod + mote riso | `assemble(joke)` |
| `glance` | 0.8–1.2 s | olha prop/venue | thought `assemble(glance)` |
| `agree` | 0.7–1.0 s | nod sync | `assemble(agree)` |
| `farewell` | 0.7–1.1 s | half-turn; wave mote | `assemble(farewell)` |

**Bubbles:** máx. **2** vivos; gap 0.55–1.1 s com jitter.

**Gestos baratos:** nod squash Y; lean `poseOffsetX` ±2 px; facing no início do `talk`.

---


#### Interação com o jogador e outras fatias

| Situação | Comportamento |
|---|---|
| Draft em membro do encontro | cancel → WindDown instantâneo (fade 120 ms) |
| Ordem goTo/clean/recreate | cancel; ordem ganha |
| Idle recreate (V9.10) | social **pode** interromper recreate só se score ≥ 0.7 e recreate já >40% da pose; senão espera |
| Escuro (V9.11) | score luz baixo; se já em BeatLoop e darkness sobe, encurta para farewell |
| Filth sob os pés | chance de beat `glance` “Precisa limpar…” (só flavor) |
| Zona (V9.13) | approach respeita allowed area; se venue fora, fallback `stand` dentro da zona |

---

#### Performance — orçamento obrigatório

**Metas (device médio / desktop debug):**

| Item | Orçamento |
|---|---|
| Director quando idle | **&lt; 0.05 ms**/frame médio (quase só timer) |
| Refresh candidatos | **&lt; 0.3 ms** a cada ~0.5 s |
| A* por approach | no máx. **2** paths curtos por encontro; cache fail 2 s |
| Alocações | zero `List` grandes por frame; reutilizar buffers do director |
| Bubbles | cap global existente; social não cria >2 |
| Draw | **nenhum** overlay full-map; só motes pontuais já no bubble layer |

**Técnicas obrigatórias:**

1. **Spatial hash opcional** (se N≥6): grid 4×4 células → buckets; pares só dentro do mesmo bucket ou vizinhos. Com N≤5, hash é opcional (custo de montar > benefício).  
2. **Dirty flags:** só recalcular scores se alguém mudou de célula, job, draft, ou venue props mudaram (`notifyMapVisualChanged` marca dirty).  
3. **Early-out:** se há encontro ativo, skip refresh de candidatos.  
4. **LOS lazy:** só no par escolhido / top-3, nunca em todos.  
5. **Sem isolate/compute** — tudo no game thread; trabalho fragmentado no intervalo do refresh.  
6. **Sem pathfinding especulativo** — path só em `Approach` após commit do encontro.

**Telemetria debug (flag off por default):** contador `socialProbes`, `socialStarts`, `socialCancels`, `lastRefreshMs` — útil em dev, zero custo se compilado fora.

---

#### Animações de interação (detalhe)

| Momento | Animação |
|---|---|
| Probe aceito | Ambos param o wander (pause); facing preliminar um ao outro em 120 ms. |
| Approach | Path branco **não** mostra (só draft do jogador mostra path); walk-bob normal. |
| FormUp | Slide final 1 célula se necessário; lean 2 px; mote “…” 200 ms. |
| Beat `talk` | Bubble speech fade-in 120 ms; parceiro thought atrasado 0.35–0.55 s. |
| Beat `joke` | Nod squash + mote “Ha” sobe 12 px / 400 ms. |
| WindDown | Farewell bubble; half-turn oposto; resume wander com preferência de direções divergentes (bias ±90°). |
| Cancel por draft | Encontro dissolve 120 ms; sem farewell se o jogador “interrompeu”. |

---

#### Implementação sugerida (ordem interna da fatia)

1. `SocialDirector` + FSM + cooldown + 1 venue `stand` (2 pawns).  
2. `SocialLineAssembler` + lexicon mínimo (`idle_life` + `greet`/`talk`/`farewell`) + validador de tags.  
3. Bubbles cruzados alimentados pelo assembler + gestos squash/lean.  
4. Topics contextuais (`room_beauty`, `filth`, `lamp_light`, …) + `DialoguePlan`.  
5. Venue `table` / cadeiras (reusa `approachCell`).  
6. Affinity sessão + roleta top-3 + dirty/refresh.  
7. Gathering spot no editor + preferência de score.  
8. Spatial hash se N≥6 + telemetria debug.  
9. Screenshot + testes (score/cooldown/**combinatória**/anti-eco).

---

#### Testes de aceite (automáticos + visual)

| Teste | Esperado |
|---|---|
| Unit: cooldown | mesmo par não re-inicia antes de `pairCooldown` |
| Unit: draft lock | pawn drafted nunca entra em candidate set |
| Unit: score venue | mesa livre > stand à mesma distância |
| Unit: budget N | com 8 pawns mock, refresh usa ≤K pares |
| Unit: assembler tags | ficha `filth` nunca aparece com ctx `beauty` sem seed filth |
| Unit: assembler variedade | 30 gerações `talk`+mesmo topic → ≥12 strings distintas |
| Unit: assembler length | nenhuma linha &gt; 42 chars após fallback |
| Unit: polaridade | opinião neg de A bloqueia react “tá lindo” em B |
| Visual | `v914_social.png` — 2+ pawns em FormUp/BeatLoop + bubbles cruzados |
| Perf smoke | 60 s de wander com 4 pawns: refresh p95 &lt; 1 ms; assemble p95 &lt; 0.1 ms |

**Aceite de produto:** a colônia “conversa sozinha” com falas que **variam e fazem sentido** no contexto; drafting interrompe sem travar jobs; FPS do Habitat não regrede de forma perceptível vs V9.12.

**Implementado:** `HabitatSocialDirector` (FSM Approach→FormUp→BeatLoop→WindDown) + `meetingCells`/A* curto (abort >8 passos) + **SpeakUp-lite** `SocialLineAssembler` (opener com `replyTag` → reply condicionado do mesmo tag; frases ancoradas em fase/temp/venue/nome; script A→B→opcional A→bye) + venues + cooldowns/afinidade + gathering spot + stack de balões compartilhada + testes + `v914_social.png`.

---


### V9.15 — Arquitetura rica (paredes, portas, telhado)

**O quê.** O modo construção oferece materiais de parede, variantes de porta e indicação de teto (indoor/outdoor) por célula.

**Como funciona**

- Dock: madeira / pedra / aço (tint + sprite de parede).
- Portas: simples, dupla (2 células), autoclose (fecha sozinha após o pawn passar).
- Roof flag por célula; outdoor sem roof recebe weather/luz de V9.12/V9.5 com mais força.

**Animação de interação**

| Momento | Animação |
|---|---|
| Colocar parede | Ghost → drop com slam curto (1–2 px Y) + poeira mote. |
| Remover parede | Crumble: alpha out + partículas 200 ms. |
| Porta abre | Ao pawn entrar na célula adjacente: rotação/slide do leaf 150 ms; fecha 400 ms depois que o pawn sai (autoclose). |
| Porta dupla | Dois leafs espelhados. |
| Toggle roof | Ícone de telhado faz fade nas células; indoor recebe vinheta leve. |

**Aceite:** screenshot `v915_architecture.png` com materiais distintos e porta aberta/meio aberta.

---

### Backlog Extra (sem número — puxar se sobrar tempo)

Ordem sugerida após V9.6–V9.11 sólidos. Cada item deve ganhar a mesma estrutura (o quê / animação) ao ser promovido a VN:

- **Power aesthetic** — cabos decorativos; lâmpada desligada apaga radius (animação V9.11 inversa).
- **Stockpile / shelves** — pilhas decorativas no grid; drop com bounce.
- **Weather pass** — chuva/neve no terraço (partículas em loop), intensidade ligada à fase do dia.
- **Pet cosmético** — 1 animal com wander próprio e bob mais rápido.
- **Gathering spot** — absorvido pela engine **V9.14** (venue `gatheringSpot` + prop de editor).
- **Thought ticker** — fila de textos ambientais no canto (slide-in).
- **Room rename** — label editável no strip V9.7.
- **Blueprint ghost** — preview semi-transparente antes do confirm no editor.

---

### Critério de saída do Visual++ Extra → V10

Pode abrir V10 quando:

1. V9.6 (draft/hold + animações de ordem) estiver estável;
2. pelo menos **duas** fatias de atmosfera (ex.: V9.7 + V9.10, ou V9.8 + V9.9) estiverem jogáveis com as animações descritas;
3. o Habitat Extra continuar **só visual** — sem leitura de agenda/projection (isso é V10+).

---

## 5. Só depois do Visual++ — domínio fraco

Estas milestones **não começam** enquanto V4–V9.5 estiverem verdes **e** o critério de saída do Visual++ Extra (§4.1) for atendido (ou explicitamente waivado pelo produto).

### V10 — Ligação fraca com a vida (agenda)

**Resultado:** se existe bloco de agenda “sono” agora, o pawn prioriza a cama; senão wander.

- ler agenda **já existente** (query)
- sem escrever de volta
- provenance “sugerido” no HUD + bubble “hora de dormir?”
- **não** inventar Rest need paralelo — o sinal vem da vida real / agenda

### V11 — Projection de objetos

**Resultado:** projeto ativo aparece como bancada; tarefa aberta destaca a mesa.

- mapear 2–3 entidades → props
- tap abre a tela real do módulo

### V12 — Persistência do Habitat

**Resultado:** layouts, aparências, multi-mapa, zonas e posições sobrevivem a restart.

- Drift / snapshot mínimo
- fast-forward trivial (pawn na última célula)

### V13+ — Spec completa

Pawn-Guia, editor avançado (§47), crônica, Atlas, Ignition, Utility AI — só com Visual++ (+ Extra) e V10–V12 estáveis.

---

## 6. Anti-padrões

1. **“Primeiro o domain package limpo”** — não. Domain nasce em V10+.
2. **Pular Visual++ / Extra** para “já ligar a agenda” — proibido; a cena precisa carregar identidade e diversão sozinha.
3. **Placeholder geométrico eterno** — PNGs reais desde V0.
4. **Refatorar o monorepo** para caber Habitat — feature slice fina.
5. **Simular o mundo inteiro offline** antes de ver um frame.
6. **Paralisia de licença** — use assets locais catalogados no 06; troca pontual depois.
7. **Inspect eterno “em breve”** — V4 existe para matar stubs.
8. **Um único room para sempre** — V8 obriga multi-ambiente.
9. **Fatia Extra sem animação de interação** — cada VN da §4.1 precisa do pipeline de gesto → path → pose descrito, não só de um meter estático.

---

## 7. Loop de trabalho recomendado (por dia)

```text
1. Escolher 1 critério de aceite da milestone atual (V4+)
2. Implementar o mínimo que o torna verdadeiro
3. flutter run → olhar 20 s (bubbles, edit, multi-pawn…)
4. Screenshot se melhorou
5. Commit pequeno
6. Só então o próximo critério
```

Se em meio dia não há mudança **visível**, o escopo está errado — cortar infra.

---

## 8. Checklist do agente / PR (milestone atual)

Substitua `VN` pela milestone em curso (começando em **V4**).

```text
[ ] Lê este guia (v1.1+) + catálogo 06 + trecho da 05 ligado na §10
[ ] Resultado cabe em uma frase
[ ] Rota / UI acessível em < 30 s
[ ] Screenshot docs/produto/assets/generated/habitat/vN_*.png
[ ] Strings em AppStrings (l10n)
[ ] Sem agenda / projection / Drift de simulação (até Visual++ Extra inclusive)
[ ] Se for fatia Extra (§4.1): implementa o descritivo + animações de interação da VN
[ ] flutter analyze limpo na fatia tocada + testes da feature
```

---

## 9. Anexo — V0 histórico (já entregue)

### Resultado

Grid + pawn layered + wander idle; rota `/colony/habitat`; assets em `living_habitat_assets`.

### Critérios (marcados ✅)

- [x] Rota renderiza a cena  
- [x] Grid / tiles distintos  
- [x] Sprites empilhados  
- [x] Ciclos anda/para  
- [x] Troca de direção south/east/north  
- [x] Screenshot `v0_wander.png`

---

## 10. Ligação com a spec 05

| Spec 05 | Momento neste guia |
|---|---|
| §11 pawn visual, §58 camadas | V0 ✅ |
| §15 cenário, §18 cômodos | V1 ✅ |
| §48 menu contextual (stub), §45 inspect stub | V2 ✅ |
| §21 jobs manuais, pathfinding curto | V3 ✅ |
| §12 / §46 personalização rápida + tint | V3.5 ✅ |
| §45 inspect pane rico, §48 float menu | **V4** |
| interação diegética / mote / fala na cena | **V5** (bubbles) |
| §12 cosmética profunda, apparel/loadout visual | **V6** |
| §47 editor (fatia cosmética) | **V7** ✅ |
| §18 multi-cômodo / mapas | **V8** ✅ |
| multi-pawn cosmético (antes de §39 relações) | **V9** ✅ |
| §49 mini-habitat, atmosfera | **V9.5** ✅ |
| draft + hold order | **V9.6** ✅ |
| room roles + meters | **V9.7** ✅ |
| beauty overlay + decor | **V9.8** ✅ |
| atmosfera RW extra (filth/joy…) | **V9.9+** (§4.1) |
| engine social orgânica (perf-aware) | **V9.14** (spec elaborada) |
| §24 agenda, §27 confiança | **V10** (depois do Visual++ Extra) |
| §17 objetos projetados | **V11** |
| §64 dados, §62 background | **V12** |
| §32 Pawn-Guia, editor completo, Atlas, Ignition… | **V13+** |

A spec 05 continua normativa para o produto final. Este arquivo manda na **ordem de construção**.  
**Regra v1.4:** Visual++ (V4–V9.5) + fatias Extra (§4.1, com animações de interação) antes das milestones de domínio (V10+).
