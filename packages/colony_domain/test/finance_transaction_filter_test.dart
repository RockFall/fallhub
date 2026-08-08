import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FinanceTransactionFilterPolicy', () {
    final accountA = EntityId('acc-a');
    final accountB = EntityId('acc-b');
    final profileId = EntityId('profile-1');
    final now = DateTime.utc(2026, 8, 7, 12);

    LedgerTransaction tx({
      required String id,
      required EntityId accountId,
      required DateTime occurredAt,
    }) {
      return LedgerTransaction.create(
        id: EntityId(id),
        profileId: profileId,
        accountId: accountId,
        occurredAt: occurredAt,
        descriptionOriginal: id,
        amountMinor: 1000,
        currency: 'BRL',
        direction: TransactionDirection.outflow,
        createdAt: occurredAt,
      );
    }

    final transactions = [
      tx(id: 'tx-old', accountId: accountA, occurredAt: DateTime.utc(2026, 5, 1)),
      tx(id: 'tx-a-recent', accountId: accountA, occurredAt: DateTime.utc(2026, 8, 5)),
      tx(id: 'tx-b-recent', accountId: accountB, occurredAt: DateTime.utc(2026, 8, 6)),
      tx(id: 'tx-mid', accountId: accountA, occurredAt: DateTime.utc(2026, 7, 20)),
    ];

    test('filters by period days7', () {
      final result = FinanceTransactionFilterPolicy.filter(
        transactions: transactions,
        period: FinancePeriod.days7,
        now: now,
      );
      expect(result.map((t) => t.id.value), ['tx-b-recent', 'tx-a-recent']);
    });

    test('filters by account', () {
      final result = FinanceTransactionFilterPolicy.filter(
        transactions: transactions,
        accountId: accountB,
        now: now,
      );
      expect(result.map((t) => t.id.value), ['tx-b-recent']);
    });

    test('combines period and account', () {
      final result = FinanceTransactionFilterPolicy.filter(
        transactions: transactions,
        period: FinancePeriod.days30,
        accountId: accountA,
        now: now,
      );
      expect(result.map((t) => t.id.value), ['tx-a-recent', 'tx-mid']);
    });

    test('all returns newest first', () {
      final result = FinanceTransactionFilterPolicy.filter(
        transactions: transactions,
        period: FinancePeriod.all,
        now: now,
      );
      expect(result.first.id.value, 'tx-b-recent');
      expect(result, hasLength(4));
    });
  });
}
