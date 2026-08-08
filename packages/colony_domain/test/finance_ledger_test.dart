import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FinanceLedgerPolicy', () {
    test('computeBalanceFromTransactions sums signed amounts', () {
      final account = FinancialAccount.create(
        id: EntityId('acc-1'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Banco',
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
        currentBalanceMinor: 10000,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final transactions = [
        LedgerTransaction.create(
          id: EntityId('tx-1'),
          profileId: EntityId('profile-1'),
          accountId: account.id,
          occurredAt: DateTime.utc(2026, 1, 2),
          descriptionOriginal: 'Salário',
          amountMinor: 500000,
          currency: 'BRL',
          direction: TransactionDirection.inflow,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        LedgerTransaction.create(
          id: EntityId('tx-2'),
          profileId: EntityId('profile-1'),
          accountId: account.id,
          occurredAt: DateTime.utc(2026, 1, 3),
          descriptionOriginal: 'Mercado',
          amountMinor: 15000,
          currency: 'BRL',
          direction: TransactionDirection.outflow,
          createdAt: DateTime.utc(2026, 1, 3),
        ),
      ];

      expect(
        FinanceLedgerPolicy.computeBalanceFromTransactions(
          account: account,
          transactions: transactions,
        ),
        495000,
      );
    });

    test('validateTransactionAmount rejects non-positive', () {
      expect(
        () => FinanceLedgerPolicy.validateTransactionAmount(0),
        throwsArgumentError,
      );
    });
  });

  group('FinanceDisplayPolicy', () {
    test('masks hidden accounts when showValues is false', () {
      final account = FinancialAccount.create(
        id: EntityId('acc-1'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Banco',
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
        sensitiveDisplayMode: SensitiveDisplayMode.hidden,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        FinanceDisplayPolicy.shouldMask(account: account, showValues: false),
        isTrue,
      );
      expect(
        FinanceDisplayPolicy.formatAmountMinor(
          amountMinor: 12345,
          currency: 'BRL',
          masked: true,
        ),
        '••••',
      );
    });
  });

  group('FinanceNetWorthPolicy', () {
    test('sums only includeInNetWorth accounts by currency', () {
      final included = FinancialAccount.create(
        id: EntityId('acc-1'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Banco',
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
        currentBalanceMinor: 10000,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final excluded = FinancialAccount.create(
        id: EntityId('acc-2'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Banco',
        name: 'Invest',
        type: FinancialAccountType.investment,
        currency: 'BRL',
        currentBalanceMinor: 99999,
        includeInNetWorth: false,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final usd = FinancialAccount.create(
        id: EntityId('acc-3'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Broker',
        name: 'USD',
        type: FinancialAccountType.investment,
        currency: 'USD',
        currentBalanceMinor: 500,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final result = FinanceNetWorthPolicy.compute(
        accounts: [included, excluded, usd],
        balancesByAccountId: {
          'acc-1': 25000,
          'acc-2': 99999,
          'acc-3': 500,
        },
      );

      expect(result, hasLength(2));
      expect(result[0].currency, 'BRL');
      expect(result[0].totalMinor, 25000);
      expect(result[0].includedAccountCount, 1);
      expect(result[1].currency, 'USD');
      expect(result[1].totalMinor, 500);
    });

    test('shouldMaskTotal when any included account is hidden', () {
      final hidden = FinancialAccount.create(
        id: EntityId('acc-1'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Banco',
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
        sensitiveDisplayMode: SensitiveDisplayMode.hidden,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final visible = FinancialAccount.create(
        id: EntityId('acc-2'),
        profileId: EntityId('profile-1'),
        entityId: EntityId('entity-1'),
        institution: 'Caixa',
        name: 'Dinheiro',
        type: FinancialAccountType.cash,
        currency: 'BRL',
        sensitiveDisplayMode: SensitiveDisplayMode.visible,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        FinanceNetWorthPolicy.shouldMaskTotal(
          accounts: [hidden, visible],
          showValues: false,
        ),
        isTrue,
      );
      expect(
        FinanceNetWorthPolicy.shouldMaskTotal(
          accounts: [hidden, visible],
          showValues: true,
        ),
        isFalse,
      );
      expect(
        FinanceNetWorthPolicy.shouldMaskTotal(
          accounts: [visible],
          showValues: false,
        ),
        isFalse,
      );
    });
  });

  group('computeTransactionFingerprint', () {
    test('is stable for same inputs', () {
      final accountId = EntityId('acc-1');
      final occurredAt = DateTime.utc(2026, 8, 6, 12);
      final a = computeTransactionFingerprint(
        accountId: accountId,
        occurredAt: occurredAt,
        amountMinor: 999,
        currency: 'BRL',
        direction: TransactionDirection.outflow,
        descriptionOriginal: 'Café',
      );
      final b = computeTransactionFingerprint(
        accountId: accountId,
        occurredAt: occurredAt,
        amountMinor: 999,
        currency: 'BRL',
        direction: TransactionDirection.outflow,
        descriptionOriginal: 'Café',
      );
      expect(a, b);
      expect(a, isNotEmpty);
    });

    test('LedgerTransaction.create sets fingerprint', () {
      final tx = LedgerTransaction.create(
        id: EntityId('tx-1'),
        profileId: EntityId('profile-1'),
        accountId: EntityId('acc-1'),
        occurredAt: DateTime.utc(2026, 8, 6),
        descriptionOriginal: 'Teste',
        amountMinor: 100,
        currency: 'BRL',
        direction: TransactionDirection.inflow,
        categoryId: TransactionCategoryPolicy.categoryIdFor(
          TransactionCategory.income,
        ),
        createdAt: DateTime.utc(2026, 8, 6),
      );
      expect(tx.fingerprint, isNotEmpty);
      expect(tx.categoryId?.value, 'cat_income');
    });
  });
}
