import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('canonical genre base has twenty-six families and deep leaves', () {
    expect(MusicCanon.genreRootKeys, hasLength(26));
    expect(MusicCanon.genreRoots, hasLength(26));
    expect(MusicCanon.genres.length, greaterThan(450));
    expect(MusicCanon.byKey['jazz.modal']?.title, 'Modal Jazz');
    expect(MusicCanon.byKey['electronic.dnb.neurofunk']?.title, 'Neurofunk');
    expect(MusicCanon.byKey['metal.black.blackgaze']?.title, 'Blackgaze');
    expect(MusicCanon.byKey['brazilian.mpb']?.title, 'MPB');
    expect(MusicCanon.byKey['scene.canterbury']?.axis, MusicAxisKind.scene);
    expect(MusicCanon.byKey['function.stage_screen']?.axis, MusicAxisKind.function);
  });

  test('Brazilian music is a tradition-family, MPB is not the universal parent', () {
    expect(MusicCanon.byKey['brazilian.samba']?.primaryParent, 'brazilian');
    expect(MusicCanon.byKey['brazilian.choro']?.primaryParent, 'brazilian');
    expect(MusicCanon.byKey['brazilian.mpb']?.primaryParent, 'brazilian');
    expect(MusicCanon.byKey['brazilian.funk_br']?.primaryParent, 'brazilian');
    expect(
      MusicCanon.byKey['brazilian.funk_br']?.secondaryParentKeys,
      isNot(contains('funk')),
    );
  });

  test('polyhierarchy: Blackgaze hangs from metal and shoegaze', () {
    final taxon = MusicCanon.byKey['metal.black.blackgaze']!;
    expect(taxon.primaryParent, 'metal.black');
    expect(taxon.secondaryParentKeys, contains('rock.alt.shoegaze'));
    expect(
      MusicGenreAtlas.ancestorKeys('metal.black.blackgaze'),
      containsAll(['metal', 'rock.alt.shoegaze', 'rock']),
    );
  });

  test('functional categories and moods are not genre roots', () {
    expect(MusicCanon.genreRootKeys, isNot(contains('function')));
    expect(MusicCanon.genreRootKeys, isNot(contains('progressive')));
    expect(MusicCanon.byKey['function.game']?.isGenreRiver, isFalse);
    expect(MusicGenreAtlas.matchGenreLabel('world music'), isNull);
    expect(MusicGenreAtlas.matchGenreLabel('progressive'), isNull);
  });

  test('semantic graph edges exist besides parentOf', () {
    final kinds = MusicCanon.links.map((link) => link.kind).toSet();
    expect(kinds, contains(MusicTaxonLinkKind.derivedFrom));
    expect(kinds, contains(MusicTaxonLinkKind.fusedWith));
    expect(kinds, contains(MusicTaxonLinkKind.historicallyPrecedes));
    expect(
      MusicCanon.linksFrom('jazz.fusion').any(
        (link) =>
            link.kind == MusicTaxonLinkKind.fusedWith && link.toKey == 'rock',
      ),
      isTrue,
    );
  });

  test('Clube da Esquina is a scene as well as a Brazilian river', () {
    expect(MusicCanon.byKey['scene.clube_da_esquina']?.axis, MusicAxisKind.scene);
    expect(
      MusicCanon.byKey['brazilian.clube_da_esquina']?.sceneKeys,
      contains('scene.clube_da_esquina'),
    );
    final empty = MusicGenreAtlas.searchAssignable('');
    expect(empty, hasLength(26));
    expect(empty.every((spec) => spec.parentKey == null), isTrue);
    final scenes = MusicGenreAtlas.searchAssignable('clube da esquina');
    expect(
      scenes.any((spec) => spec.key == 'scene.clube_da_esquina'),
      isTrue,
    );
    expect(
      MusicGenreAtlas.searchAssignable('progressive').any(
        (spec) => spec.key == 'progressive' || spec.title == 'Progressive',
      ),
      isFalse,
    );
    final dossier = MusicGenreAtlas.dossierFor(
      title: 'Clube da Esquina',
      artist: 'Milton Nascimento',
    );
    expect(dossier!.territoryKeys, contains('scene.clube_da_esquina'));
    expect(dossier.territoryKeys, contains('brazilian.mpb'));
  });
}
