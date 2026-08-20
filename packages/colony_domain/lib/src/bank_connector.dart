import 'financial_account.dart';
import 'captured_notification.dart';
import 'ledger_transaction.dart';

/// Ingestion port for bank data (ADR-011). Local Inter today; remote later.
abstract interface class BankConnector {
  Future<List<FinancialAccount>> accounts();
  Future<List<LedgerTransaction>> transactions();
  Stream<FinanceSpendCandidate> liveTransactions();
}
