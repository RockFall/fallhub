import 'financial_account.dart';
import 'id_generator.dart';
import 'ledger_transaction.dart';
import 'transaction_category.dart';

abstract final class FinanceLedgerPolicy {
  static int computeBalanceFromTransactions({
    required FinancialAccount account,
    required List<LedgerTransaction> transactions,
  }) {
    var balance = account.currentBalanceMinor;
    for (final tx in transactions) {
      balance += tx.signedAmountMinor;
    }
    return balance;
  }

  static void validateTransactionAmount(int amountMinor) {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
  }

  static void validateAccountName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  static void validateEntityName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  static void validateCategoryId(EntityId? categoryId) {
    TransactionCategoryPolicy.validateCategoryId(categoryId);
  }
}
