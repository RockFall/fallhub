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
}
