import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('InventoryItem', () {
    test('create trims name, notes, tags and location', () {
      final item = InventoryItem.create(
        id: EntityId('inv-1'),
        profileId: EntityId('p-1'),
        name: '  Notebook  ',
        category: InventoryCategory.electronics,
        locationLabel: '  escrivaninha  ',
        notes: '  trabalho  ',
        tags: ['  casa ', '', 'tech'],
        purchasePriceMinor: 350000,
        purchaseCurrency: 'brl',
        createdAt: DateTime.utc(2026, 8, 7),
      );

      expect(item.name, 'Notebook');
      expect(item.locationLabel, 'escrivaninha');
      expect(item.notes, 'trabalho');
      expect(item.tags, ['casa', 'tech']);
      expect(item.purchaseCurrency, 'BRL');
      expect(item.status, InventoryItemStatus.active);
    });

    test('rejects empty name and negative price', () {
      expect(
        () => InventoryItem.create(
          id: EntityId('inv-1'),
          profileId: EntityId('p-1'),
          name: '  ',
          category: InventoryCategory.other,
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
      expect(
        () => InventoryItem.create(
          id: EntityId('inv-1'),
          profileId: EntityId('p-1'),
          name: 'Item',
          category: InventoryCategory.other,
          purchasePriceMinor: -1,
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
    });

    test('disposed and archived are hidden from active list', () {
      expect(InventoryItemStatus.disposed.isHiddenFromActiveList, isTrue);
      expect(InventoryItemStatus.archived.isHiddenFromActiveList, isTrue);
      expect(InventoryItemStatus.active.isHiddenFromActiveList, isFalse);
      expect(InventoryItemStatus.stored.isHiddenFromActiveList, isFalse);
    });
  });
}
