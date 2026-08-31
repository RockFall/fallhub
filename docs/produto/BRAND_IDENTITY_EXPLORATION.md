# Identidade de marca

Exploração. Não muda a spec. Não é decisão.

A pergunta era se faz sentido largar a ideia de colônia. Resposta: a ideia, não. O nome, sim.

---

O que esse app é, de verdade: um lugar no celular onde você vê a própria vida como um sistema — sono, dinheiro, trabalho, casa, estudo, gente — e decide o que fazer agora, sem ninguém te dar nota.

A north star da spec não é tempo de tela. É semana em que você olhou os dados e registrou uma decisão. Isso é ferramenta de adulto, das que se usa dez anos. Não é jogo.

A metáfora da colônia entra exatamente aqui. Gestão de colônia acerta uma coisa que to-do list e dashboard não acertam: recursos são finitos, as coisas competem entre si, estados pioram e melhoram, você precisa ver o todo e depois abrir uma peça. O Habitat só existe porque existe um *lugar*. Sem isso, vira card de saúde + card de finanças + card de hábitos, o produto genérico que a spec já jogou fora.

Então não, não larga a colônia. Larga o hábito de chamar o *produto* de Colônia.

Porque “Colônia” na loja, com pawn pixelado, é lido como jogo. E o primeiro texto que qualquer um escreve é “o RimWorld da vida”. A spec inteira se esforça pra não ser uma cópia, e o nome entrega o gênero de bandeja. “Life Colony OS” então nem é nome — é título de documento. Ninguém fala isso em voz alta.

Tem um segundo problema, mais chato: o projeto já tem outro nome, e o olho já votou nele. O repo é fallhub. O terminal é Fallhub Terminal. O kit gráfico, os assets, o package, o GitHub. A barra de título ainda diz Colônia. Três nomes ao mesmo tempo não é profundidade, é bagunça. Quem mexe no código sabe o que é cada um. Quem baixa o APK vê “Colônia” e um bonequinho.

RimWorld não se chama Colony Simulator. A home do iPhone não se chama Springboard. O mundo interno pode ser colônia. O app, não.

Como eu organizaria:

- **RockFall** é você. Fica no about e no GitHub.
- **Fallhub** é o app. É o que se instala, o que se busca, o que está escrito embaixo do ícone.
- **Colônia** é o lugar dentro do app — a home, o mapa. Pode continuar na tab.
- **Habitat** continua Habitat. É o melhor nome que tem aqui.
- **Life Colony OS** fica no topo da spec e ninguém mais precisa fingir que isso vai pra loja.

Fallhub não explica o produto. Não precisa. Nike também não. O que ele tem é que já existe, não puxa RimWorld, e combina com o visual que vocês realmente fizeram (grafite, latão, rebites, ciano) — não com o visual que a spec 04 ainda pede, que é “parece RimWorld”. Essa spec 04, pra marca, é arquivo morto. A gramática de painel (inspect, densidade, prioridades) fica. O cromo alheio, não.

“Fall” em inglês pode soar a queda. Se a copy for adulta, isso até serve: a vida cai, o hub é pra onde se volta. Se o logo for um bonequinho caindo, vira piada. Pronúncia: FÓL-hub, uma palavra, de rockfall, não de fail.

Antes de cravar, fala o nome em voz alta pra três pessoas que não mexem nesse repo. Se a reação for “tá, e faz o quê?”, o nome ficou e a frase embaixo trabalha. Se for cara de quem não entendeu nem o som, não tenta consertar Fallhub. Troca.

Se for pra trocar, o território certo não é “Life alguma coisa OS”. É estação / instrumento. Coisas que eu levaria a sério:

- **Atalaia** — torre de vigia. Você sobe e vê o sistema. Brasileiro, adulto, não é jogo. O melhor plano B.
- **Prumo** — “pôr no prumo”. Curto, nosso, exato. Morre em inglês.
- **Lastro** — o que segura o navio. Anti-produtividade-tóxica. Pode soar a peso morto.

Longe disso: Clareira, Farol, Foco, Kernel, Nexus, Hub, qualquer coach, qualquer nome de mascote. O pawn não é a marca. É quem mora lá dentro. Ícone de loja com o pawn transforma o app em Tamagotchi, que é o oposto do que o Habitat pede.

Sobre tom: imagina alguém numa estação, olhando o painel, escrevendo o diário de bordo. Fala pouco. Se o dado é velho, diz que é velho. Se você não treinou, não inventa uma narrativa de fracasso. “Sono com dados de ontem, confiança média” serve. “Sua colônia está em colapso” não serve. Se a metáfora precisa de drama de jogo pra ter graça, está mal usada.

E o vocabulário interno. Pawn, Bill, Draft, Loadout, Colonista, Hediff, Storyteller — ótimo pra modelar o domínio. Péssimo na tela de exame, no ledger, no onboarding. A UI já começou a acertar: a tab não diz Pawn, diz Perfil. Continua nessa linha. Habitat pode falar a língua do mundo. Saúde e dinheiro falam português normal. “Colonista ocioso” é a frase pra apagar primeiro.

O que eu *não* faria agora: renomear `colony_domain`. Reescrever a spec. Inventar lore da estação. Dar nome fofo pra IA. Colocar OS no ícone. Fazer um terceiro visual além do terminal. Esse tipo de rebrand de PowerPoint é como o projeto acaba com quatro nomes em vez de três.

Se a ambição for mesmo a da spec — ferramenta pra muita gente, muito tempo, inclusive quem nunca jogou RimWorld — o caminho é o C: metáfora dentro, outro nome na porta. Se o teto for “life-sim pra quem já ama esse gênero”, aí assume Colônia e para de dançar. A spec, se for pra levar a sério, já escolheu o primeiro.

Até decidir, o único movimento de marca que já está certo é o do terminal. O olho já chama de Fallhub. A boca que ainda diz Colônia é o que está atrasado.
