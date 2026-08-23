import 'music_atlas.dart';
import 'music_canon.dart';
import 'music_cover_recipe.dart';
import 'music_ontology.dart';

class MusicTerritorySpec {
  const MusicTerritorySpec({
    required this.key,
    required this.title,
    this.parentKey,
    this.secondaryParentKeys = const [],
    required this.hue,
    required this.motif,
    this.aliases = const [],
    required this.loreMarkdown,
    this.axis = MusicAxisKind.genre,
    this.sceneKeys = const [],
    this.traditionKeys = const [],
    this.movementKeys = const [],
  });

  final String key;
  final String title;
  final String? parentKey;
  final List<String> secondaryParentKeys;
  final double hue;
  final MusicCoverMotif motif;
  final List<String> aliases;
  final String loreMarkdown;
  final MusicAxisKind axis;
  final List<String> sceneKeys;
  final List<String> traditionKeys;
  final List<String> movementKeys;

  factory MusicTerritorySpec.fromTaxon(MusicTaxon taxon) {
    return MusicTerritorySpec(
      key: taxon.key,
      title: taxon.title,
      parentKey: taxon.primaryParent,
      secondaryParentKeys: taxon.secondaryParentKeys,
      hue: MusicCanon.hueOf(taxon),
      motif: MusicCanon.motifOf(taxon),
      aliases: taxon.aliases,
      loreMarkdown: taxon.loreMarkdown,
      axis: taxon.axis,
      sceneKeys: taxon.sceneKeys,
      traditionKeys: taxon.traditionKeys,
      movementKeys: taxon.movementKeys,
    );
  }

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

/// Map-facing projection of [MusicCanon] genre rivers.
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

  static final List<MusicTerritorySpec> territories = [
    for (final taxon in MusicCanon.genres) MusicTerritorySpec.fromTaxon(taxon),
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
      territoryKeys: ['jazz.avant.spiritual'],
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
      territoryKeys: ['brazilian.tropicalia'],
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
      territoryKeys: ['brazilian.bossa'],
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
      territoryKeys: [
        'brazilian.clube_da_esquina',
        'brazilian.mpb',
        'scene.clube_da_esquina',
      ],
      titleAliases: ['clube da esquina'],
      markdown: '''
## Clube da Esquina (1972)
Minas como geografia afectiva. Dois compositores, um coro de cidade.
**Tudo que você podia ser** e **O trem azul** não são faixas — são
ruas do mesmo bairro. A cena não é um subgénero da MPB — cruza folk
rock, pop progressivo e jazz.

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
      territoryKeys: ['punk.postpunk'],
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
      territoryKeys: ['punk.postpunk'],
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
      territoryKeys: ['electronic.downtempo.trip_hop'],
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
      territoryKeys: ['hiphop.east.jazz_rap', 'hiphop.experimental'],
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
      territoryKeys: ['rock.alt.shoegaze'],
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
      territoryKeys: ['brazilian.bossa', 'jazz.latin.brazilian'],
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
    for (final taxon in MusicCanon.all)
      if (taxon.axis != MusicAxisKind.genre)
        taxon.key: MusicTerritorySpec.fromTaxon(taxon),
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
    final seen = <String>{};
    final keys = <String>[];
    final queue = [key];
    while (queue.isNotEmpty) {
      final currentKey = queue.removeAt(0);
      if (!seen.add(currentKey)) continue;
      keys.add(currentKey);
      final current = lookup[currentKey];
      if (current == null) continue;
      if (current.parentKey != null) queue.add(current.parentKey!);
      queue.addAll(current.secondaryParentKeys);
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
        final isChild =
            spec.parentKey == parent ||
            spec.secondaryParentKeys.contains(parent);
        if (isChild && !keys.contains(spec.key)) {
          keys.add(spec.key);
          walk(spec.key);
        }
      }
    }

    walk(key);
    return keys;
  }

  /// Picker pool: empty query shows genre-family roots; a needle
  /// searches every axis so a scene or tradition can sit on the same album.
  static List<MusicTerritorySpec> searchAssignable(String raw) {
    final needle = MusicIdentityPolicy.normalizeTitle(raw);
    if (needle.isEmpty) {
      return [for (final spec in territories) if (spec.parentKey == null) spec];
    }
    final hits = <MusicTerritorySpec>[];
    for (final spec in byKey.values) {
      if (spec.key == unmappedKey || spec.key == userRootKey) continue;
      final labels = [spec.title, spec.key, ...spec.aliases];
      final matched = labels.any(
        (label) => MusicIdentityPolicy.normalizeTitle(label).contains(needle),
      );
      if (matched) hits.add(spec);
    }
    hits.sort((a, b) {
      final axis = a.axis.index.compareTo(b.axis.index);
      if (axis != 0) return axis;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return hits;
  }

  /// Resolves a user/AI label to a canon key on any axis.
  /// Forbidden roots (`world music`, lone `progressive`) stay null.
  static String? resolveTaxonKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (byKey.containsKey(trimmed) &&
        trimmed != unmappedKey &&
        trimmed != userRootKey) {
      return trimmed;
    }
    final needle = MusicIdentityPolicy.normalizeTitle(trimmed);
    if (needle.isEmpty) return null;
    if (MusicOntologyPolicy.forbiddenGenreRoots.contains(needle)) {
      return null;
    }
    String? best;
    var bestScore = -1;
    var bestDepth = -1;
    for (final spec in byKey.values) {
      if (spec.key == unmappedKey || spec.key == userRootKey) continue;
      final labels = [
        spec.title,
        spec.key,
        spec.key.split('.').last,
        ...spec.aliases,
      ];
      for (final label in labels) {
        final alias = MusicIdentityPolicy.normalizeTitle(label);
        if (alias != needle) continue;
        final score = 1000 + alias.length;
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

  static List<String> resolveTaxonKeys(Iterable<String> raw) {
    final keys = <String>{};
    for (final label in raw) {
      final resolved = resolveTaxonKey(label);
      if (resolved != null) {
        keys.add(resolved);
      } else if (label.trim().startsWith('user.')) {
        keys.add(label.trim());
      }
    }
    return keys.toList();
  }

  static String? matchGenreLabel(String raw) {
    final needle = MusicIdentityPolicy.normalizeTitle(raw);
    if (needle.isEmpty) return null;
    if (MusicOntologyPolicy.forbiddenGenreRoots.contains(needle)) {
      return null;
    }
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
