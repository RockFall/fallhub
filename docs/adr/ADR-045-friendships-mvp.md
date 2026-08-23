# ADR-045: Amizades — gestão local de círculos, cadência e encontros

## Status
Aceito (Iter amizades — vertical slice)

## Contexto
Spec §24 define relações sem virar CRM: `Person`, interações (§24.2), organizações/facções incluindo “grupo de amigos” (§24.3) e commitments (§24.4). O app **pode lembrar compromissos**, mas **não calcula “qualidade da amizade”**.

Hoje (ADR-026 / 028 / 030):
- `Person` é identidade local com `relationshipTypes[]` livres, `lastInteractionAt` e follow-up opcional.
- `PersonInteraction` registra encontro, ligação, mensagem, reunião, etc. — sem distinção explícita de “encontro presencial” vs contacto remoto na persistência.
- `Organization` com `kind = friends` existe, mas não carrega cadência, ritmo nem a pergunta “há quanto tempo não vejo esta pessoa?”.
- A UI de Pessoas é lista + sheet: sem busca, sem aniversário, sem linha do tempo de interações, sem ponte para uma gestão de amizades.

A vida social real tem vários eixos válidos ao mesmo tempo: tipo de vínculo, círculo/contexto, ritmo desejado, história de encontros, e silêncio que **não** é falha. Este ADR escolhe um recorte utilizável offline e deixa os outros caminhos explícitos para iterações seguintes.

## Visão (caminhos válidos — o produto pode crescer em todos)

Amizade **não** é um score. É um overlay consciente sobre uma pessoa: “como eu classifico este vínculo”, “em que grupos ele vive”, “com que ritmo eu quero reencontrar”, e “quando de facto nos vimos”.

### 1. Identidade vs vínculo
- **Pessoa** continua a ser quem a pessoa é (nome, apelido, notas, aniversário, tipos livres de relação).
- **Amizade** é um overlay 1:1 opcional: nem toda pessoa é amizade (família, médico, senhorio, colega estrito).
- Uma pessoa pode ser “amiga” e também “colega” / “família” via `relationshipTypes` — a taxonomia de amizade não apaga os tipos livres.

### 2. Taxonomia de tipo (atribuída pelo utilizador, nunca inferida)
Círculo interno, próxima, regular, casual, conhecida, infância, amiga da família, colega social, vizinha, online, sazonal, dormente, por classificar.

A taxonomia é **memória e intenção**, não diagnóstico. Mudar de “próxima” para “sazonal” é um acto do utilizador, não um algoritmo de frequência.

### 3. Cadência (intervalo desejado, não obrigação)
Semanal, quinzenal, mensal, trimestral, semestral, anual, ou **quando der** (sem lembrete).

Cadência gera atenção (`em atraso` / `em breve` / `em dia` / `sem cadência` / `ainda sem encontro`). Não gera “qualidade”, “saúde da relação” nem ranking social.

Sugestão de cadência por tipo (pré-preenche, o utilizador altera):
- círculo interno → semanal
- próxima → quinzenal
- regular / vizinha / amiga da família → mensal
- casual / colega social / online → trimestral
- conhecida → semestral
- infância / sazonal → anual
- dormente / por classificar → quando der

### 4. Círculos de amizade (grupos)
Contextos de vida: faculdade, mesa de RPG, vizinhos, família da parceira, trabalho remoto, grupo de viagem, “os do carnaval”.

Uma pessoa pertence a N círculos. Um círculo pode ter cadência-default (ainda não aplicada automaticamente a membros nesta slice). Encontro de grupo = o mesmo instante registado em várias pessoas.

Círculos **não** substituem `Organization`. Organização continua empresa/clínica/família institucional. Círculo é o mapa social íntimo.

### 5. Encontros vs contactos
- **Encontro** (desta slice): `meeting` e `gathering` — vimo-nos ou estivemos juntos.
- **Contacto**: ligação, mensagem, presente, introdução, etc. Actualiza `lastInteractionAt` da pessoa, mas **não** zera o relógio de encontro.

O ecrã de Amizades conta tempo desde o **último encontro**, não desde a última mensagem. Pessoas continua a mostrar o último contacto (qualquer interacção).

### 6. Ritmo derivado (proveniência: log manual)
De uma lista de encontros, o domínio deriva:
- último encontro e dias decorridos
- número de encontros
- intervalo típico (mediana dos intervalos)
- data em que a cadência vence
- estado de atenção

Tudo isto é **derivado** e recalculado. Não se persiste “score”. Não se afirma causalidade (“a amizade esfriou”).

### 7. Fila de atenção (nurture queue)
Lista curta: cadência vencida ou quase. É um lembrete do próprio utilizador, não um feed de culpa. Silêncio com cadência `quando der` **nunca** entra na fila.

### 8. Caminhos válidos deferidos (não implementados agora)
Estes caminhos são intencionais e compatíveis com o modelo; ficam OUT para não virar CRM:

1. **Mapa visual de círculos** (constelação) — layout, não semântica.
2. **Encontro de grupo first-class** (`Encounter` + participantes) em vez de N `PersonInteraction` com o mesmo `occurredAt`.
3. **Canal do encontro** (presencial / videochamada / voz) — hoje inferido pelo kind.
4. **Capacidade social consciente** (estilo Dunbar, opcional, sem quota rígida).
5. **Como nos conhecemos** já entra nesta slice; **quem apresentou quem** (grafo de introduções) fica para depois.
6. **Eventos de vida** (mudou de cidade, teve filho, novo emprego) como entidades — hoje cabem em notas.
7. **Preferência 1:1 vs grupo** e canal preferido de contacto.
8. **Sobreposição com viagens / zonas / calendário** (“vamos estar na mesma cidade”).
9. **Presentes e aniversários** como fila própria (o campo `birthday` de Pessoa já existe; UI passa a editá-lo).
10. **Energia depois do encontro** (nota subjectiva) — perigoso se virar score; só se for log explícito do utilizador.
11. **Tensão / reparação** — notas privadas, nunca “status de conflito” automático.
12. **Amizades sazonais** com janela no calendário (carnaval, réveillon).
13. **Partilha de quests / projectos / commitments** já parcialmente existe; o overlay de amizade só aponta.
14. **Importação de contactos do SO / redes** — proibida nesta fase (minimização §24.2).
15. **Sugestão automática de follow-up por IA / Storyteller** — defer; o utilizador define cadência.
16. **Círculo ↔ Organization `friends`** — ponte opcional futura, sem fundir as tabelas.

## Decisão (slice utilizável offline)

### Escopo IN
1. **`Friendship`** overlay 1:1 com `Person`
   - `id`, `profileId`, `personId` (único), `kind`, `cadence`, `howWeMet?`, `startedAt?`, `notes?`, `archivedAt?`, `createdAt`, `updatedAt`
2. **`FriendshipCircle`** + membership N:N (`personId`, `circleId`)
   - círculo: `name`, `notes?`, `defaultCadence?`, `archivedAt?`
3. **`FriendshipRhythm`** (não persistido) a partir de interacções `meeting`/`gathering`
4. **`FriendshipOverview`** para o quadro: pessoa + amizade + círculos + ritmo
5. **UI**
   - `/relations/friendships` — fila de atenção, lista, filtros (tipo / círculo / atraso), criar/editar, círculos, registar encontro (1 ou N pessoas)
   - Pessoas: busca, ordenação por último contacto, tempo relativo, aniversário no form, linha do tempo de interacções, “adicionar às amizades”
6. **Export v36** (`friendships`, `friendship_circles`, `friendship_circle_memberships`) e **DB v41**
7. Disclaimer de minimização; strings localizadas; empty/loading/error

### Escopo OUT
- Qualidade / scoring / ranking / “saúde da amizade”
- CRM (pipelines, funis, scrape de contactos)
- Entidade `Encounter` multi-participante persistida
- Sync remoto / LLM a classificar vínculos
- Fundir círculos com `Organization`

### Políticas
- Tipo e cadência são **manuais**. Frequência não promove nem rebaixa o tipo.
- `quando der` é um estado de primeira classe, não um “em falta”.
- Notas / como nos conhecemos são `privacyClass` pessoal; export é completo (ADR-015), não parcial.
- Arquivar amizade não arquiva a pessoa; arquivar pessoa esconde a amizade activa.
- App não envia notificações push nesta slice — a fila é in-app.

### Eventos
- `friendshipCreated`, `friendshipUpdated`, `friendshipArchived`
- `friendshipCircleCreated`, `friendshipCircleUpdated`, `friendshipCircleArchived`

### Critérios de aceite
1. Criar/editar/arquivar amizade e círculo offline; uma pessoa tem no máximo uma amizade activa.
2. Quadro mostra último encontro, dias desde então, tipo, cadência e círculos.
3. Fila de atenção só com cadência vencida ou quase; `quando der` não entra.
4. Encontro com várias pessoas gera uma interacção por pessoa e actualiza o ritmo de cada.
5. Pessoas ganha busca, último contacto e ponte para amizade.
6. Export/restore v36 round-trip; migration a partir de schema anterior.
7. Zero cópia RimWorld; textos em `AppStrings`.

## Consequências
- Relations passa a ter quatro hubs: Pessoas, Amizades, Organizações, Compromissos.
- Interacções existentes `meeting`/`gathering` alimentam o ritmo sem backfill de `Friendship` — o utilizador promove a pessoa quando quiser.
- Próximos bumps livres após esta slice: Drift v42 / export v37 (calendário Google e outros ADRs que apontavam v40/v35 precisam rebase de versão).
