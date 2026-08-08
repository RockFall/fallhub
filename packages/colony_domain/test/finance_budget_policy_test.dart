import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 15, 12);
  final profileId = EntityId('profile-1');
  final foodId = TransactionCategoryPolicy.categoryIdFor(
    TransactionCategory.food,
  );

  CategoryBudget budget({int limit = 10000, String currency = 'BRL'}) {
    return CategoryBudget.create(
      id: EntityId('budget-1'),
      profileId: profileId,
      categoryId: foodId,
      currency: currency,
      limitAmountMinor: limit,
      createdAt: now,
    );
  }

  LedgerTransaction outflow({
    required int amount,
    required DateTime at,
    EntityId? categoryId,
    String currency = 'BRL',
  }) {
    return LedgerTransaction.create(
      id: EntityId('tx-${at.millisecondsSinceEpoch}-$amount'),
      profileId: profileId,
      accountId: EntityId('acc-1'),
      occurredAt: at,
      descriptionOriginal: 'gasto',
      amountMinor: amount,
      currency: currency,
      direction: TransactionDirection.outflow,
      categoryId: categoryId ?? foodId,
      createdAt: at,
    );
  }

  test('spentInMonth sums matching outflows in calendar month', () {
    final txs = [
      outflow(amount: 3000, at: DateTime.utc(2026, 8, 1)),
      outflow(amount: 2000, at: DateTime.utc(2026, 8, 20)),
      outflow(amount: 9000, at: DateTime.utc(2026, 7, 31, 23)), // prior month
      outflow(
        amount: 1000,
        at: DateTime.utc(2026, 8, 10),
        categoryId: TransactionCategoryPolicy.categoryIdFor(
          TransactionCategory.transport,
        ),
      ),
      outflow(
        amount: 500,
        at: DateTime.utc(2026, 8, 12),
        currency: 'USD',
      ),
    ];

    expect(
      FinanceBudgetPolicy.spentInMonth(
        transactions: txs,
        categoryId: foodId,
        currency: 'BRL',
        now: now,
      ),
      5000,
    );
  });

  test('computeProgress remaining and over-limit', () {
    final b = budget(limit: 4000);
    final txs = [
      outflow(amount: 2500, at: DateTime.utc(2026, 8, 5)),
      outflow(amount: 2000, at: DateTime.utc(2026, 8, 10)),
    ];
    final progress = FinanceBudgetPolicy.computeProgress(
      budgets: [b],
      transactions: txs,
      now: now,
    );
    expect(progress, hasLength(1));
    expect(progress.single.spentMinor, 4500);
    expect(progress.single.remainingMinor, -500);
    expect(progress.single.isOverLimit, isTrue);
  });

  test('CategoryBudget rejects income category and non-positive limit', () {
    expect(
      () => CategoryBudget.create(
        id: EntityId('b'),
        profileId: profileId,
        categoryId: TransactionCategoryPolicy.categoryIdFor(
          TransactionCategory.income,
        ),
        currency: 'BRL',
        limitAmountMinor: 100,
        createdAt: now,
      ),
      throwsArgumentError,
    );
    expect(
      () => CategoryBudget.create(
        id: EntityId('b'),
        profileId: profileId,
        categoryId: foodId,
        currency: 'BRL',
        limitAmountMinor: 0,
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });
}
