import 'music_atlas.dart';
import 'music_cover_recipe.dart';

class MusicTerritorySpec {
  const MusicTerritorySpec({
    required this.key,
    required this.title,
    this.parentKey,
    required this.hue,
    required this.motif,
    this.aliases = const [],
    required this.loreMarkdown,
  });

  final String key;
  final String title;
  final String? parentKey;
  final double hue;
  final MusicCoverMotif motif;
  final List<String> aliases;
  final String loreMarkdown;

  int get depth {
    if (parentKey == null) return 0;
    var d = 1;
    var parent = MusicGenreAtlas.byKey[parentKey];
    while (parent?.parentKey != null) {
      d++;
      parent = MusicGenreAtlas.byKey[parent!.parentKey];
    }
    return d;
  }
}

/// Curated listening notes. Never a substitute for the user's own field notes.
class MusicAlbumDossier {
  const MusicAlbumDossier({
    required this.slug,
    required this.title,
    required this.artist,
    this.year,
    required this.territoryKeys,
    required this.markdown,
    this.titleAliases = const [],
  });

  final String slug;
  final String title;
  final String artist;
  final int? year;
  final List<String> territoryKeys;
  final String markdown;
  final List<String> titleAliases;
}

/// Built-in cartograph of territories. Overlay of personal listening lives elsewhere.
abstract final class MusicGenreAtlas {
  static const unmappedKey = 'unmapped';
  static const userRootKey = 'user';

  static const unmapped = MusicTerritorySpec(
    key: unmappedKey,
    title: 'Por cartografar',
    hue: 210,
    motif: MusicCoverMotif.ash,
    loreMarkdown:
        'Álbuns que já tocaram na colónia mas ainda não têm rio. '
        'Não é um lixo — é a margem do mapa.',
  );

  static const userRoot = MusicTerritorySpec(
    key: userRootKey,
    title: 'Os teus rios',
    hue: 38,
    motif: MusicCoverMotif.gold,
    loreMarkdown:
        'Territórios que nasceste tu. O catálogo oficial não os conhece; '
        'o Atlas trata-os como ramificações vivas.',
  );

  static const territories = <MusicTerritorySpec>[
    MusicTerritorySpec(
      key: 'br',
      title: 'Brasil',
      hue: 42,
      motif: MusicCoverMotif.gold,
      aliases: ['brazilian', 'brasil', 'brazilian music'],
      loreMarkdown: '''
## Brasil
Não é um género — é um continente sonoro. Quem trata "música brasileira"
como prateleira única ainda não saiu do aeroporto.
''',
    ),
    MusicTerritorySpec(
      key: 'br.samba',
      title: 'Samba',
      parentKey: 'br',
      hue: 28,
      motif: MusicCoverMotif.pulse,
      aliases: ['samba', 'samba-enredo', 'partido alto', 'pagode'],
      loreMarkdown: '''
## Samba
O chão que falta quando só se ouve o refrão. Partido alto, enredo, a
cozinha do surdo — o Atlas marca visita quando consegues apontar *quem*
segura o tempo, não só a melodia.
''',
    ),
    MusicTerritorySpec(
      key: 'br.bossa',
      title: 'Bossa nova',
      parentKey: 'br',
      hue: 48,
      motif: MusicCoverMotif.tide,
      aliases: ['bossa', 'bossa nova', 'bossa-nova'],
      loreMarkdown: '''
## Bossa nova
A conversa baixa que o piano e o violão inventaram para o apartamento.
Quem só conhece a exportação de aeroporto ainda está na praia, não no
apartamento de Copacabana.
''',
    ),
    MusicTerritorySpec(
      key: 'br.mpb',
      title: 'MPB',
      parentKey: 'br',
      hue: 36,
      motif: MusicCoverMotif.river,
      aliases: ['mpb', 'musica popular brasileira', 'música popular brasileira'],
      loreMarkdown: '''
## MPB
Nome de arquivo para um rio que recusa fronteira. Caetano, Milton, Elis,
o Clube — cada disco é uma margem diferente do mesmo caudal.
''',
    ),
    MusicTerritorySpec(
      key: 'br.tropicalia',
      title: 'Tropicália',
      parentKey: 'br',
      hue: 12,
      motif: MusicCoverMotif.ember,
      aliases: ['tropicalia', 'tropicália', 'tropicalismo'],
      loreMarkdown: '''
## Tropicália
Não é nostalgia de 68. É o choque deliberado entre a guitarra elétrica
e o terreiro — uma tese, não um mood.
''',
    ),
    MusicTerritorySpec(
      key: 'br.forro',
      title: 'Forró',
      parentKey: 'br',
      hue: 22,
      motif: MusicCoverMotif.brass,
      aliases: ['forro', 'forró', 'baião', 'xote', 'pé de serra'],
      loreMarkdown: '''
## Forró
Sanfona, zabumba, triângulo: três pontos e o salão inteiro. Pé-de-serra
não é "folk brasileiro" — é arquitectura rítmica.
''',
    ),
    MusicTerritorySpec(
      key: 'br.mangue',
      title: 'Manguebeat',
      parentKey: 'br',
      hue: 95,
      motif: MusicCoverMotif.spore,
      aliases: ['mangue', 'manguebeat', 'mangue bit'],
      loreMarkdown: '''
## Manguebeat
Recife a injectar circuitos no lodo. Nação Zumbi não é "rock brasileiro":
é um manifesto de antena fincada no mangue.
''',
    ),
    MusicTerritorySpec(
      key: 'jazz',
      title: 'Jazz',
      hue: 198,
      motif: MusicCoverMotif.brass,
      aliases: ['jazz'],
      loreMarkdown: '''
## Jazz
Território-mãe. As ramificações (bop, modal, espiritual, fusão) são
cidades; o nome "jazz" sozinho é só o porto.
''',
    ),
    MusicTerritorySpec(
      key: 'jazz.bebop',
      title: 'Bebop',
      parentKey: 'jazz',
      hue: 212,
      motif: MusicCoverMotif.pulse,
      aliases: ['bebop', 'be-bop', 'bop', 'hard bop', 'hardbop'],
      loreMarkdown: '''
## Bebop
A linguagem acelerada que expulsou o dançarino. Se ainda contas os
compassos com o pé, estás na porta; se ouves as substituições, já
entraste.
''',
    ),
    MusicTerritorySpec(
      key: 'jazz.modal',
      title: 'Jazz modal',
      parentKey: 'jazz',
      hue: 188,
      motif: MusicCoverMotif.tide,
      aliases: ['modal jazz', 'jazz modal', 'cool jazz', 'modal'],
      loreMarkdown: '''
## Jazz modal
O mapa deixa de ser o acorde e passa a ser o modo. Miles não inventou o
deserto — recusou a cidade. Quem só ouviu *Kind of Blue* no elevador
ainda está na margem.
''',
    ),
    MusicTerritorySpec(
      key: 'jazz.spiritual',
      title: 'Jazz espiritual',
      parentKey: 'jazz',
      hue: 268,
      motif: MusicCoverMotif.spore,
      aliases: ['spiritual jazz', 'free jazz', 'avant-garde jazz', 'fire music'],
      loreMarkdown: '''
## Jazz espiritual
Coltrane depois do solo como oração. Não é "mais intenso": é outra
função para o som. O Atlas só marca visita se houver escuta atenta —
o rumor do nome não chega.
''',
    ),
    MusicTerritorySpec(
      key: 'jazz.fusion',
      title: 'Fusion',
      parentKey: 'jazz',
      hue: 156,
      motif: MusicCoverMotif.lattice,
      aliases: ['fusion', 'jazz fusion', 'jazz-funk', 'jazz funk'],
      loreMarkdown: '''
## Fusion
A corrente eléctrica no baixo. Bitches Brew é um portal, não um ponto
de chegada — o rio continua para Weather Report, Mahavishnu, e para
os discos que recusaste por "soarem a rock".
''',
    ),
    MusicTerritorySpec(
      key: 'jazz.br',
      title: 'Jazz brasileiro',
      parentKey: 'jazz',
      hue: 172,
      motif: MusicCoverMotif.river,
      aliases: ['brazilian jazz', 'samba jazz', 'samba-jazz'],
      loreMarkdown: '''
## Jazz brasileiro
Onde o ride encontra o partido. Não é bossa exportada: é improvisação
com sotaque de surdo.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic',
      title: 'Electrónica',
      hue: 286,
      motif: MusicCoverMotif.lattice,
      aliases: ['electronic', 'electronica', 'electro'],
      loreMarkdown: '''
## Electrónica
Família de relógios e salas vazias. Techno, house, ambient e IDM não
são "beats" — são arquitecturas de tempo.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic.techno',
      title: 'Techno',
      parentKey: 'electronic',
      hue: 300,
      motif: MusicCoverMotif.concrete,
      aliases: ['techno', 'detroit techno', 'minimal techno'],
      loreMarkdown: '''
## Techno
Detroit como tese: a máquina a suar. Se só ouves o kick, estás no
corredor; a visita começa quando reconheces a sala.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic.house',
      title: 'House',
      parentKey: 'electronic',
      hue: 328,
      motif: MusicCoverMotif.pulse,
      aliases: ['house', 'deep house', 'chicago house', 'acid house'],
      loreMarkdown: '''
## House
Chicago, o piano jack e o corpo como instrumento. House não é playlist
de ginásio — é uma linha de baixo que recusa acabar.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic.ambient',
      title: 'Ambient',
      parentKey: 'electronic',
      hue: 196,
      motif: MusicCoverMotif.tide,
      aliases: ['ambient', 'dark ambient', 'drone', 'new age'],
      loreMarkdown: '''
## Ambient
Música que cabe numa sala sem a ocupar. Eno chamou-lhe mobiliário;
Boards of Canada chamou-lhe memória. O Atlas distingue ouvir de
*habitar*.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic.idm',
      title: 'IDM',
      parentKey: 'electronic',
      hue: 274,
      motif: MusicCoverMotif.lattice,
      aliases: ['idm', 'intelligent dance music', 'braindance', 'glitch'],
      loreMarkdown: '''
## IDM
O nome é péssimo; o território não. Aphex, Autechre, o grid a
desfazer-se. Cartografar aqui é conseguir *descrever* o que o beat
recusa ser.
''',
    ),
    MusicTerritorySpec(
      key: 'electronic.jungle',
      title: 'Jungle / DnB',
      parentKey: 'electronic',
      hue: 132,
      motif: MusicCoverMotif.ember,
      aliases: ['jungle', 'drum and bass', 'dnb', 'drum & bass', 'breakcore'],
      loreMarkdown: '''
## Jungle
Amen break como matéria-prima. Velocidade com fantasma — o baixo a
dobrar o chão.
''',
    ),
    MusicTerritorySpec(
      key: 'rock',
      title: 'Rock',
      hue: 8,
      motif: MusicCoverMotif.ember,
      aliases: ['rock', 'alternative', 'indie', 'indie rock'],
      loreMarkdown: '''
## Rock
Porto velho. As ramificações (pós-punk, kraut, shoegaze) são as
cidades onde ainda vale a pena desembarcar.
''',
    ),
    MusicTerritorySpec(
      key: 'rock.postpunk',
      title: 'Pós-punk',
      parentKey: 'rock',
      hue: 350,
      motif: MusicCoverMotif.ash,
      aliases: ['post-punk', 'post punk', 'pós-punk', 'new wave'],
      loreMarkdown: '''
## Pós-punk
O rock a desconfiar de si. Joy Division, Talking Heads, o baixo à
frente da guitarra. Uma visita pede que apontes o *espaço* entre as
notas, não o riff.
''',
    ),
    MusicTerritorySpec(
      key: 'rock.kraut',
      title: 'Krautrock',
      parentKey: 'rock',
      hue: 18,
      motif: MusicCoverMotif.concrete,
      aliases: ['krautrock', 'kraut', 'kosmische', 'motorik'],
      loreMarkdown: '''
## Krautrock
Motorik: o pulso que recusa o solo de estrela. Can, Neu!, Faust —
laboratório alemão, não "rock progressivo com sotaque".
''',
    ),
    MusicTerritorySpec(
      key: 'rock.shoegaze',
      title: 'Shoegaze',
      parentKey: 'rock',
      hue: 320,
      motif: MusicCoverMotif.spore,
      aliases: ['shoegaze', 'dream pop', 'dreampop', 'noise pop'],
      loreMarkdown: '''
## Shoegaze
A parede de guitarra como clima. Loveless não se "ouve a letra" —
habita-se. Marca visita quando consegues separar as camadas de novo.
''',
    ),
    MusicTerritorySpec(
      key: 'rock.psych',
      title: 'Psychedelia',
      parentKey: 'rock',
      hue: 4,
      motif: MusicCoverMotif.ember,
      aliases: ['psychedelic', 'psychedelic rock', 'psych', 'acid rock'],
      loreMarkdown: '''
## Psychedelia
O drone, o órgão, o tempo que estica. Não é um filtro de Instagram
de 1967 — é uma técnica de atenção.
''',
    ),
    MusicTerritorySpec(
      key: 'hiphop',
      title: 'Hip-hop',
      hue: 30,
      motif: MusicCoverMotif.concrete,
      aliases: ['hip hop', 'hip-hop', 'rap', 'hiphop'],
      loreMarkdown: '''
## Hip-hop
Território de amostra, de sala e de esquina. Boom-bap, jazz-rap e o
laboratório experimental são bairros, não "eras".
''',
    ),
    MusicTerritorySpec(
      key: 'hiphop.boombap',
      title: 'Boom-bap',
      parentKey: 'hiphop',
      hue: 24,
      motif: MusicCoverMotif.pulse,
      aliases: ['boom bap', 'boom-bap', 'east coast hip hop', '90s hip hop'],
      loreMarkdown: '''
## Boom-bap
O kick no um, o snare a cortar o verso. A visita não é saber o
sample — é ouvir o *espaço* que o MPC deixou.
''',
    ),
    MusicTerritorySpec(
      key: 'hiphop.jazzrap',
      title: 'Jazz rap',
      parentKey: 'hiphop',
      hue: 40,
      motif: MusicCoverMotif.brass,
      aliases: ['jazz rap', 'jazz-rap', 'jazz hop', 'jazzhop'],
      loreMarkdown: '''
## Jazz rap
Não é "rap com saxofone em cima". É o break de jazz como língua,
de Guru a To Pimp a Butterfly.
''',
    ),
    MusicTerritorySpec(
      key: 'hiphop.experimental',
      title: 'Rap experimental',
      parentKey: 'hiphop',
      hue: 16,
      motif: MusicCoverMotif.lattice,
      aliases: ['experimental hip hop', 'abstract hip hop', 'industrial hip hop'],
      loreMarkdown: '''
## Rap experimental
Death Grips, clipping., o beat a recusar o loop confortável. Cartografar
aqui pede comparação — um disco isolado vira fetiche.
''',
    ),
    MusicTerritorySpec(
      key: 'metal',
      title: 'Metal',
      hue: 0,
      motif: MusicCoverMotif.ash,
      aliases: ['metal', 'heavy metal'],
      loreMarkdown: '''
## Metal
Família de densidade. As ramificações (doom, black, post) importam mais
do que o guarda-chuva.
''',
    ),
    MusicTerritorySpec(
      key: 'metal.doom',
      title: 'Doom',
      parentKey: 'metal',
      hue: 14,
      motif: MusicCoverMotif.concrete,
      aliases: ['doom', 'doom metal', 'sludge', 'stoner'],
      loreMarkdown: '''
## Doom
O riff como geologia. Tempo lento não é preguiça — é peso.
''',
    ),
    MusicTerritorySpec(
      key: 'metal.black',
      title: 'Black metal',
      parentKey: 'metal',
      hue: 260,
      motif: MusicCoverMotif.ash,
      aliases: ['black metal', 'atmospheric black metal', 'depressive black metal'],
      loreMarkdown: '''
## Black metal
Atmosfera como doutrina. O Atlas não romantiza a cena: cartografa o
som e a tua relação com ele.
''',
    ),
    MusicTerritorySpec(
      key: 'metal.post',
      title: 'Post-metal',
      parentKey: 'metal',
      hue: 220,
      motif: MusicCoverMotif.tide,
      aliases: ['post-metal', 'post metal', 'atmospheric sludge'],
      loreMarkdown: '''
## Post-metal
O crescendo como forma. Neurosis, Isis, o peso a abrir espaço em vez
de o fechar.
''',
    ),
    MusicTerritorySpec(
      key: 'composed',
      title: 'Música composta',
      hue: 54,
      motif: MusicCoverMotif.gold,
      aliases: ['classical', 'contemporary classical', 'erudita', 'modern classical'],
      loreMarkdown: '''
## Música composta
Partitura, sala, fita. Minimalismo e contemporânea são ramificações —
"clássica" sozinha é um museu sem planta.
''',
    ),
    MusicTerritorySpec(
      key: 'composed.minimal',
      title: 'Minimalismo',
      parentKey: 'composed',
      hue: 62,
      motif: MusicCoverMotif.lattice,
      aliases: ['minimalism', 'minimalist', 'process music'],
      loreMarkdown: '''
## Minimalismo
Reich, Glass, a fase que se desloca. Visitar é conseguir *contar* o
que muda quando parece que nada muda.
''',
    ),
    MusicTerritorySpec(
      key: 'composed.contemporary',
      title: 'Contemporânea',
      parentKey: 'composed',
      hue: 70,
      motif: MusicCoverMotif.spore,
      aliases: ['contemporary classical', 'avant-garde classical', 'new music'],
      loreMarkdown: '''
## Contemporânea
O território depois do tonal fácil. Não exige que gostes — exige que
não finjas ter cartografado.
''',
    ),
    MusicTerritorySpec(
      key: 'folk',
      title: 'Folk',
      hue: 78,
      motif: MusicCoverMotif.river,
      aliases: ['folk', 'singer-songwriter', 'americana', 'traditional'],
      loreMarkdown: '''
## Folk
Canção com chão. Americana e o nordeste brasileiro não são o mesmo
rio — por isso ramificam.
''',
    ),
    MusicTerritorySpec(
      key: 'folk.americana',
      title: 'Americana',
      parentKey: 'folk',
      hue: 32,
      motif: MusicCoverMotif.ember,
      aliases: ['americana', 'alt-country', 'folk rock'],
      loreMarkdown: '''
## Americana
Estrada, harmónio, a guitarra a contar o quarto vazio. Visitar é
ouvir o *espaço* rural sem o transformar em postal.
''',
    ),
    MusicTerritorySpec(
      key: 'folk.nordeste',
      title: 'Cantoria / nordeste',
      parentKey: 'folk',
      hue: 44,
      motif: MusicCoverMotif.brass,
      aliases: ['cantoria', 'repentismo', 'coco', 'maracatu'],
      loreMarkdown: '''
## Cantoria
A palavra em duelo, o coco, o maracatu. Não cabe em "world music".
''',
    ),
  ];

  static const dossiers = <MusicAlbumDossier>[
    MusicAlbumDossier(
      slug: 'kind-of-blue',
      title: 'Kind of Blue',
      artist: 'Miles Davis',
      year: 1959,
      territoryKeys: ['jazz.modal'],
      markdown: '''
## Kind of Blue — Miles Davis (1959)
O disco que toda a gente "já ouviu" e quase ninguém cartografou. Cinco
peças, modos em vez de mudanças rápidas, o espaço entre Bill Evans e
Coltrane a valer mais do que o tema.

### O que escutar de propósito
- **So What**: o baixo a anunciar o modo; o piano a *não* encher.
- **Flamenco Sketches**: cinco escalas, uma só respiração.
- **Blue in Green**: Evans a escrever a névoa.

### Nota de campo
Ouvir no elevador conta como rumor. Uma escuta atenta pede que
consigas dizer, sem olhar à ficha, *onde* o modo muda.
''',
    ),
    MusicAlbumDossier(
      slug: 'a-love-supreme',
      title: 'A Love Supreme',
      artist: 'John Coltrane',
      year: 1965,
      territoryKeys: ['jazz.spiritual'],
      markdown: '''
## A Love Supreme — John Coltrane (1965)
Quatro movimentos, uma tese. Não é "o disco espiritual" como selo de
prateleira — é uma forma. Acknowledgement devolve o motivo até ele
virar oração; Psalm recita.

### O que escutar de propósito
- O motivo de quatro notas a atravessar o disco.
- A secção falada em Psalm — se a saltaste, ainda não visitaste.
''',
    ),
    MusicAlbumDossier(
      slug: 'tropicalia',
      title: 'Tropicália ou Panis et Circencis',
      artist: 'Vários',
      year: 1968,
      territoryKeys: ['br.tropicalia'],
      titleAliases: ['tropicalia', 'tropicália', 'panis et circencis'],
      markdown: '''
## Tropicália ou Panis et Circencis (1968)
Manifesto em forma de disco colectivo. Caetano, Gil, Os Mutantes, Tom
Zé, Nara — a guitarra eléctrica sentada à mesa do terreiro.

### O que escutar de propósito
- **Miserere nobis** e a ironia da procissão.
- **Baby**: a canção de amor que é também uma tese sobre o mercado.
''',
    ),
    MusicAlbumDossier(
      slug: 'chega-de-saudade',
      title: 'Chega de Saudade',
      artist: 'João Gilberto',
      year: 1959,
      territoryKeys: ['br.bossa'],
      markdown: '''
## Chega de Saudade — João Gilberto (1959)
O violão a recusar o espetáculo. A batida que cabe num quarto. Se
ouvistes só a exportação posterior, volta aqui: é o documento, não o
postal.
''',
    ),
    MusicAlbumDossier(
      slug: 'clube-da-esquina',
      title: 'Clube da Esquina',
      artist: 'Milton Nascimento & Lô Borges',
      year: 1972,
      territoryKeys: ['br.mpb'],
      titleAliases: ['clube da esquina'],
      markdown: '''
## Clube da Esquina (1972)
Minas como geografia afectiva. Dois compositores, um coro de cidade.
**Tudo que você podia ser** e **O trem azul** não são faixas — são
ruas do mesmo bairro.

### Nota de campo
Cartografar o Clube é conseguir ligar uma faixa a um sítio (a esquina,
o trem, o frio), não só a um "mood mineiro".
''',
    ),
    MusicAlbumDossier(
      slug: 'unknown-pleasures',
      title: 'Unknown Pleasures',
      artist: 'Joy Division',
      year: 1979,
      territoryKeys: ['rock.postpunk'],
      markdown: '''
## Unknown Pleasures — Joy Division (1979)
O baixo à frente, a voz no poço, a capa que toda a gente reconhece
sem ter ouvido o disco. **She's Lost Control** e **New Dawn Fades**
pedem volume baixo e atenção ao espaço — o post-punk mora no intervalo.
''',
    ),
    MusicAlbumDossier(
      slug: 'remain-in-light',
      title: 'Remain in Light',
      artist: 'Talking Heads',
      year: 1980,
      territoryKeys: ['rock.postpunk'],
      markdown: '''
## Remain in Light — Talking Heads (1980)
Afrobeat filtrado por Nova Iorque e Eno. **Once in a Lifetime** é a
porta; **Born Under Punches** é a casa. Visitar é seguir *uma* linha
rítmica até ao fim sem te distraíres com o refrão.
''',
    ),
    MusicAlbumDossier(
      slug: 'saw-85-92',
      title: 'Selected Ambient Works 85-92',
      artist: 'Aphex Twin',
      year: 1992,
      territoryKeys: ['electronic.ambient', 'electronic.idm'],
      titleAliases: ['selected ambient works', 'saw 85-92', 'selected ambient works 85-92'],
      markdown: '''
## Selected Ambient Works 85–92 — Aphex Twin
Não é mobília. Os beats estão lá, só que a sala é outra. **Xtal** e
**Ageispolis** pedem que descrevas o *espaço* — graves, poeira, o
hi-hat a parecer longe.
''',
    ),
    MusicAlbumDossier(
      slug: 'geogaddi',
      title: 'Geogaddi',
      artist: 'Boards of Canada',
      year: 2002,
      territoryKeys: ['electronic.ambient', 'electronic.idm'],
      markdown: '''
## Geogaddi — Boards of Canada (2002)
Memória falsificada com fita e numerologia. Mais denso que *Music Has
the Right*. Cartografar é aguentar o disco inteiro sem tratar
**1969** como single.
''',
    ),
    MusicAlbumDossier(
      slug: 'mezzanine',
      title: 'Mezzanine',
      artist: 'Massive Attack',
      year: 1998,
      territoryKeys: ['electronic'],
      markdown: '''
## Mezzanine — Massive Attack (1998)
Trip-hop no momento em que deixa de ser um género e vira uma sala
escura. **Teardrop** é a porta conhecida; **Group Four** é o corredor
que a maior parte salta.
''',
    ),
    MusicAlbumDossier(
      slug: 'tpab',
      title: 'To Pimp a Butterfly',
      artist: 'Kendrick Lamar',
      year: 2015,
      territoryKeys: ['hiphop.jazzrap', 'hiphop.experimental'],
      titleAliases: ['to pimp a butterfly', 'tpab'],
      markdown: '''
## To Pimp a Butterfly — Kendrick Lamar (2015)
Jazz, funk e verso como tese política. O interlúdio da borboleta não
é ornamentação. Uma visita pede que ligues **Wesley's Theory** a
**Mortal Man** — o disco é uma forma, não um stack de singles.
''',
    ),
    MusicAlbumDossier(
      slug: 'loveless',
      title: 'Loveless',
      artist: 'My Bloody Valentine',
      year: 1991,
      territoryKeys: ['rock.shoegaze'],
      markdown: '''
## Loveless — My Bloody Valentine (1991)
A guitarra como clima. Se tentaste "ouvir a letra" e desististe, volta
com outro contrato: separa *uma* camada e segue-a. **Soon** e **When
You Sleep** são portas diferentes do mesmo nevoeiro.
''',
    ),
    MusicAlbumDossier(
      slug: 'bitches-brew',
      title: 'Bitches Brew',
      artist: 'Miles Davis',
      year: 1970,
      territoryKeys: ['jazz.fusion'],
      markdown: '''
## Bitches Brew — Miles Davis (1970)
Edição como instrumento. Duas horas, o grupo a sobrepor-se, o jazz a
aceitar a corrente. Não é "o disco de fusion": é o portal. Visitar
pede uma escuta contínua — saltar faixas é ficar no rumor.
''',
    ),
    MusicAlbumDossier(
      slug: 'aguas-de-marco-wave',
      title: 'Wave',
      artist: 'Antônio Carlos Jobim',
      year: 1967,
      territoryKeys: ['br.bossa', 'jazz.br'],
      titleAliases: ['wave'],
      markdown: '''
## Wave — Antônio Carlos Jobim (1967)
Jobim no momento em que a bossa já não precisa de se explicar.
Arranjos de Claus Ogerman, a linha a flutuar. **Wave** e **Triste**
pedem que ouças o *espaço* da orquestra, não só a voz que talvez te
falte nesta edição.
''',
    ),
  ];

  static final Map<String, MusicTerritorySpec> byKey = {
    for (final spec in territories) spec.key: spec,
    unmappedKey: unmapped,
    userRootKey: userRoot,
  };

  static List<MusicTerritorySpec> childrenOf(String? parentKey) {
    return [
      for (final spec in territories)
        if (spec.parentKey == parentKey) spec,
    ];
  }

  static List<String> ancestorKeys(
    String key, {
    List<MusicTerritorySpec> extra = const [],
  }) {
    final lookup = {
      ...byKey,
      for (final spec in extra) spec.key: spec,
    };
    final keys = <String>[];
    var current = lookup[key];
    if (current == null) return [key];
    while (current != null) {
      keys.add(current.key);
      final parent = current.parentKey;
      current = parent == null ? null : lookup[parent];
    }
    return keys;
  }

  static List<String> descendantKeys(
    String key, {
    List<MusicTerritorySpec> extra = const [],
  }) {
    final all = [...territories, ...extra];
    final keys = <String>[key];
    void walk(String parent) {
      for (final spec in all) {
        if (spec.parentKey == parent) {
          keys.add(spec.key);
          walk(spec.key);
        }
      }
    }

    walk(key);
    return keys;
  }

  static String? matchGenreLabel(String raw) {
    final needle = MusicIdentityPolicy.normalizeTitle(raw);
    if (needle.isEmpty) return null;
    String? best;
    var bestScore = -1;
    var bestDepth = -1;
    for (final spec in territories) {
      final labels = [
        spec.title,
        spec.key,
        spec.key.split('.').last,
        ...spec.aliases,
      ];
      for (final label in labels) {
        final alias = MusicIdentityPolicy.normalizeTitle(label);
        if (alias.isEmpty) continue;
        final score = alias == needle
            ? 1000 + alias.length
            : (alias.length >= 4 &&
                  (needle.contains(alias) || alias.contains(needle)))
            ? alias.length
            : -1;
        if (score < 0) continue;
        if (score > bestScore ||
            (score == bestScore && spec.depth > bestDepth)) {
          bestScore = score;
          bestDepth = spec.depth;
          best = spec.key;
        }
      }
    }
    return best;
  }

  static List<String> matchGenreLabels(Iterable<String> raw) {
    final keys = <String>{};
    for (final label in raw) {
      final key = matchGenreLabel(label);
      if (key != null) keys.add(key);
    }
    return keys.toList();
  }

  static MusicAlbumDossier? dossierFor({
    required String title,
    String? artist,
  }) {
    final t = MusicIdentityPolicy.normalizeTitle(title);
    final a = artist == null || artist.trim().isEmpty
        ? null
        : MusicIdentityPolicy.normalizeArtist(artist);
    for (final dossier in dossiers) {
      final titles = [
        dossier.title,
        ...dossier.titleAliases,
      ].map(MusicIdentityPolicy.normalizeTitle);
      if (!titles.contains(t)) continue;
      if (a == null) return dossier;
      final da = MusicIdentityPolicy.normalizeArtist(dossier.artist);
      if (a.contains(da) || da.contains(a) || da == 'vários') {
        return dossier;
      }
    }
    return null;
  }
}
