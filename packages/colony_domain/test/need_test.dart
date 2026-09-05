import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('NeedSnapshotCalculator marks unknown without reading', () {
    final def = NeedDefinition(
      id: EntityId('n1'),
      profileId: EntityId('p1'),
      name: 'Sono',
      slug: 'sono',
      calculationMode: CalculationMode.manual,
      privacyClass: NeedPrivacyClass.standard,
      createdAt: DateTime.utc(2026, 8, 6),
      updatedAt: DateTime.utc(2026, 8, 6),
    );

    final snapshot = NeedSnapshotCalculator.build(
      def,
      null,
      DateTime.utc(2026, 8, 6, 12),
    );

    expect(snapshot.freshness, DataFreshness.unknown);
    expect(snapshot.statusText, 'Desconhecido');
  });

  test('normalizeScale5 maps 1-5 to 0-1', () {
    expect(normalizeScale5(1), 0);
    expect(normalizeScale5(5), 1);
    expect(normalizeScale5(3), 0.5);
  });

  test('DefaultNeedSeeds lists inspect catalog without humor', () {
    expect(DefaultNeedSeeds.core, hasLength(12));
    expect(DefaultNeedSeeds.core.map((s) => s.slug).toList(), [
      'sono',
      'alimentacao',
      'lazer',
      'social',
      'higiene',
      'organizacao',
      'ar_livre',
      'sexo',
      'realizacao',
      'foco',
      'movimento',
      'ansiedade',
    ]);
    expect(
      DefaultNeedSeeds.core.any((s) => s.matchesSlug('conexao_social')),
      isTrue,
    );
    expect(DefaultNeedSeeds.core.any((s) => s.matchesSlug('descanso')), isTrue);
    expect(DefaultNeedSeeds.core.any((s) => s.slug == 'humor'), isFalse);
  });

  test('NeedHistorySeries keeps every sample in the local window', () {
    final window = NeedHistorySeries.lastLocalDays(
      nowLocal: DateTime(2026, 8, 31, 18),
      samples: [
        NeedHistorySample(
          id: EntityId('a'),
          observedAt: DateTime(2026, 8, 30, 8),
          value: 0.25,
        ),
        NeedHistorySample(
          id: EntityId('b'),
          observedAt: DateTime(2026, 8, 30, 21),
          value: 0.75,
        ),
        NeedHistorySample(
          id: EntityId('c'),
          observedAt: DateTime(2026, 8, 31, 9),
          value: 0.5,
        ),
        NeedHistorySample(
          id: EntityId('old'),
          observedAt: DateTime(2026, 8, 20, 12),
          value: 0.1,
        ),
      ],
    );

    expect(window.days, hasLength(7));
    expect(window.days.first, DateTime(2026, 8, 25));
    expect(window.days.last, DateTime(2026, 8, 31));
    expect(window.points.map((p) => p.id.value), ['a', 'b', 'c']);
    expect(window.points[0].day, DateTime(2026, 8, 30));
    expect(window.points[1].day, DateTime(2026, 8, 30));
    expect(window.points[1].value, 0.75);
    expect(window.points[2].day, DateTime(2026, 8, 31));
  });

  test('same-day samples sit closer than adjacent days', () {
    final window = NeedHistorySeries.lastLocalDays(
      nowLocal: DateTime(2026, 8, 31, 18),
      samples: [
        NeedHistorySample(
          id: EntityId('a'),
          observedAt: DateTime(2026, 8, 30, 10),
          value: 0.2,
        ),
        NeedHistorySample(
          id: EntityId('b'),
          observedAt: DateTime(2026, 8, 30, 14),
          value: 0.4,
        ),
        NeedHistorySample(
          id: EntityId('c'),
          observedAt: DateTime(2026, 8, 31, 14),
          value: 0.6,
        ),
      ],
    );

    final sameDay = window.points[1].x - window.points[0].x;
    final nextDay = window.points[2].x - window.points[1].x;
    expect(sameDay, greaterThan(0));
    expect(sameDay, lessThan(nextDay / 2));
  });
}
