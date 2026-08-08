import 'id_generator.dart';
import 'ledger_transaction.dart';

enum FinancePeriod {
  days7,
  days30,
  days90,
  all;

  int? get dayCount => switch (this) {
        FinancePeriod.days7 => 7,
        FinancePeriod.days30 => 30,
        FinancePeriod.days90 => 90,
        FinancePeriod.all => null,
      };
}

abstract final class FinanceTransactionFilterPolicy {
  static List<LedgerTransaction> filter({
    required List<LedgerTransaction> transactions,
    FinancePeriod period = FinancePeriod.all,
    EntityId? accountId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    final days = period.dayCount;
    final cutoff = days == null
        ? null
        : reference.subtract(Duration(days: days));

    final filtered = transactions.where((tx) {
      if (accountId != null && tx.accountId != accountId) return false;
      if (cutoff != null && tx.occurredAt.isBefore(cutoff)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return filtered;
  }
}
