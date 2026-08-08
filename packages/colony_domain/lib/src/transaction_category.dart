import 'id_generator.dart';
import 'ledger_transaction.dart';

/// Flat predefined categories for finance ledger lite (Iter 21).
/// Stored as stable string IDs in [LedgerTransaction.categoryId].
enum TransactionCategory {
  food,
  transport,
  housing,
  health,
  entertainment,
  shopping,
  utilities,
  education,
  income,
  other,
}

abstract final class TransactionCategoryPolicy {
  static const _prefix = 'cat_';

  static EntityId categoryIdFor(TransactionCategory category) =>
      EntityId('$_prefix${category.name}');

  static TransactionCategory? fromCategoryId(EntityId? categoryId) {
    if (categoryId == null) return null;
    final value = categoryId.value;
    if (!value.startsWith(_prefix)) return null;
    final name = value.substring(_prefix.length);
    for (final category in TransactionCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }

  static bool isKnownCategoryId(EntityId? categoryId) =>
      categoryId == null || fromCategoryId(categoryId) != null;

  static void validateCategoryId(EntityId? categoryId) {
    if (!isKnownCategoryId(categoryId)) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'unknown transaction category',
      );
    }
  }

  static List<TransactionCategory> categoriesForDirection(
    TransactionDirection direction,
  ) {
    if (direction == TransactionDirection.inflow) {
      return [
        TransactionCategory.income,
        TransactionCategory.other,
      ];
    }
    return TransactionCategory.values
        .where((c) => c != TransactionCategory.income)
        .toList();
  }
}
