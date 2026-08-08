import 'category_budget.dart';
import 'id_generator.dart';
import 'ledger_transaction.dart';

/// Progress of a [CategoryBudget] against outflows in the current month.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentMinor,
  });

  final CategoryBudget budget;
  final int spentMinor;

  int get remainingMinor => budget.limitAmountMinor - spentMinor;

  bool get isOverLimit => spentMinor > budget.limitAmountMinor;

  double get ratio {
    if (budget.limitAmountMinor <= 0) return 0;
    return spentMinor / budget.limitAmountMinor;
  }
}

/// Pure spent/remaining math for monthly category budgets (MVP, no FX).
abstract final class FinanceBudgetPolicy {
  static DateTime monthStart(DateTime now) =>
      DateTime.utc(now.toUtc().year, now.toUtc().month, 1);

  static DateTime monthEndExclusive(DateTime now) {
    final start = monthStart(now);
    return DateTime.utc(start.year, start.month + 1, 1);
  }

  static int spentInMonth({
    required List<LedgerTransaction> transactions,
    required EntityId categoryId,
    required String currency,
    required DateTime now,
  }) {
    final start = monthStart(now);
    final end = monthEndExclusive(now);
    final normalizedCurrency = currency.trim().toUpperCase();
    var total = 0;
    for (final tx in transactions) {
      if (tx.direction != TransactionDirection.outflow) continue;
      if (tx.categoryId != categoryId) continue;
      if (tx.currency.toUpperCase() != normalizedCurrency) continue;
      final at = tx.occurredAt.toUtc();
      if (at.isBefore(start) || !at.isBefore(end)) continue;
      total += tx.amountMinor;
    }
    return total;
  }

  static List<BudgetProgress> computeProgress({
    required List<CategoryBudget> budgets,
    required List<LedgerTransaction> transactions,
    required DateTime now,
  }) {
    final sorted = [...budgets]
      ..sort((a, b) => a.categoryId.value.compareTo(b.categoryId.value));
    return [
      for (final budget in sorted)
        BudgetProgress(
          budget: budget,
          spentMinor: spentInMonth(
            transactions: transactions,
            categoryId: budget.categoryId,
            currency: budget.currency,
            now: now,
          ),
        ),
    ];
  }
}
