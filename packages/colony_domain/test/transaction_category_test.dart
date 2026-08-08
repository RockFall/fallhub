import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('TransactionCategoryPolicy', () {
    test('categoryIdFor uses stable prefixed ids', () {
      expect(
        TransactionCategoryPolicy.categoryIdFor(TransactionCategory.food).value,
        'cat_food',
      );
    });

    test('fromCategoryId round-trips known categories', () {
      for (final category in TransactionCategory.values) {
        final id = TransactionCategoryPolicy.categoryIdFor(category);
        expect(TransactionCategoryPolicy.fromCategoryId(id), category);
      }
    });

    test('fromCategoryId returns null for unknown ids', () {
      expect(
        TransactionCategoryPolicy.fromCategoryId(EntityId('unknown')),
        isNull,
      );
      expect(TransactionCategoryPolicy.fromCategoryId(null), isNull);
    });

    test('validateCategoryId rejects unknown ids', () {
      expect(
        () => TransactionCategoryPolicy.validateCategoryId(EntityId('bad')),
        throwsArgumentError,
      );
      expect(
        () => TransactionCategoryPolicy.validateCategoryId(null),
        returnsNormally,
      );
    });

    test('categoriesForDirection filters income for outflows', () {
      final outflow = TransactionCategoryPolicy.categoriesForDirection(
        TransactionDirection.outflow,
      );
      expect(outflow, isNot(contains(TransactionCategory.income)));

      final inflow = TransactionCategoryPolicy.categoriesForDirection(
        TransactionDirection.inflow,
      );
      expect(inflow, contains(TransactionCategory.income));
      expect(inflow, contains(TransactionCategory.other));
    });
  });
}
