import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final profile = EntityId('p1');

  KnowledgeArea area({
    required String id,
    required String title,
    String? parent,
    String? catalogKey,
  }) {
    return KnowledgeArea.create(
      id: EntityId(id),
      profileId: profile,
      title: title,
      parentId: parent == null ? null : EntityId(parent),
      catalogKey: catalogKey,
      createdAt: now,
    );
  }

  test('Tropicalismo is reachable from Music and from History of Brazil', () {
    final arts = area(id: 'arts', title: 'Artes');
    final music = area(id: 'music', title: 'Música', parent: 'arts');
    final theory = area(id: 'theory', title: 'Teoria musical', parent: 'music');
    final trop = area(id: 'trop', title: 'Tropicalismo', parent: 'music');
    final hum = area(id: 'hum', title: 'Humanidades');
    final history = area(id: 'hist', title: 'História', parent: 'hum');
    final brazil = area(id: 'br', title: 'História do Brasil', parent: 'hist');
    final areas = [arts, music, theory, trop, hum, history, brazil];
    final placements = [
      KnowledgeAreaPlacement(
        areaId: trop.id,
        parentAreaId: brazil.id,
        linkedAt: now,
        catalogKey: 'humanities.history.brazil',
      ),
    ];

    expect(
      KnowledgeAreaPolicy.descendantIds(rootId: music.id, areas: areas),
      containsAll([music.id, theory.id, trop.id]),
    );
    expect(
      KnowledgeAreaPolicy.descendantIds(
        rootId: brazil.id,
        areas: areas,
        placements: placements,
      ),
      contains(trop.id),
    );
    expect(
      KnowledgeAreaPolicy.isAliasUnder(
        areaId: trop.id,
        parentId: brazil.id,
        areas: areas,
        placements: placements,
      ),
      isTrue,
    );
    expect(
      KnowledgeAreaPolicy.isAliasUnder(
        areaId: trop.id,
        parentId: music.id,
        areas: areas,
        placements: placements,
      ),
      isFalse,
    );
    expect(
      KnowledgeAreaPolicy.childrenOf(
        parentId: brazil.id,
        areas: areas,
        placements: placements,
      ).map((a) => a.id),
      contains(trop.id),
    );
    expect(
      KnowledgeAreaPolicy.pathsTo(
        areaId: trop.id,
        areas: areas,
        placements: placements,
      ),
      containsAll([
        'Artes · Música · Tropicalismo',
        'Humanidades · História · História do Brasil · Tropicalismo',
      ]),
    );
  });

  test('ODD sits under the autonomous-cars branch', () {
    final eng = area(id: 'eng', title: 'Engenharia');
    final auto = area(id: 'auto', title: 'Automotiva', parent: 'eng');
    final av = area(id: 'av', title: 'Carros autônomos', parent: 'auto');
    final odd = area(id: 'odd', title: 'ODD', parent: 'av');
    final areas = [eng, auto, av, odd];
    expect(
      KnowledgeAreaPolicy.descendantIds(rootId: eng.id, areas: areas),
      contains(odd.id),
    );
    expect(
      KnowledgeAreaPolicy.pathLabel(areaId: odd.id, areas: areas),
      'Engenharia · Automotiva · Carros autônomos · ODD',
    );
  });

  test('placement that would cycle the combined graph is rejected', () {
    final root = area(id: 'root', title: 'Raiz');
    final child = area(id: 'child', title: 'Filho', parent: 'root');
    expect(
      () => KnowledgeAreaPolicy.assertPlacementAcyclic(
        areaId: root.id,
        parentAreaId: child.id,
        areas: [root, child],
        placements: const [],
      ),
      throwsA(isA<KnowledgeAreaCycleException>()),
    );
  });
}
