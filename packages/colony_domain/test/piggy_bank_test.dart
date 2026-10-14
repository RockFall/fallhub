import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final profile = EntityId('profile-1');
  final start = DateTime.utc(2026, 10, 1);

  PiggyBankConfig config({
    int daily = 9000,
    DateTime? end,
    bool installmentTotal = true,
    List<String> excluded = const [],
  }) {
    return PiggyBankConfig(
      profileId: profile,
      dailyAmountMinor: daily,
      startDate: start,
      endDate: end,
      installmentCountsTotal: installmentTotal,
      alertWhenRed: true,
      excludedCategoryIds: excluded,
      updatedAt: DateTime.utc(2026, 10, 1),
    );
  }

  PiggyLedgerInput expense({
    required String id,
    required int amount,
    required DateTime at,
    String description = 'Padaria',
    String? fingerprint,
    TransactionDirection direction = TransactionDirection.outflow,
    String? categoryId,
    String? notificationText,
    bool excluded = false,
    int? overrideMinor,
    int? installmentCount,
    bool? perInstallment,
  }) {
    return PiggyLedgerInput(
      id: id,
      fingerprint: fingerprint ?? 'fp-$id',
      amountMinor: amount,
      direction: direction,
      occurredAt: at,
      description: description,
      categoryId: categoryId,
      notificationText: notificationText,
      excluded: excluded,
      amountOverrideMinor: overrideMinor,
      installmentCount: installmentCount,
      amountIsPerInstallment: perInstallment,
    );
  }

  DateTime sp(int year, int month, int day, [int hour = 12, int minute = 0]) {
    return DateTime.utc(year, month, day, hour + 3, minute);
  }

  group('PiggyBankCalculator', () {
    test('credits valorDiario for each elapsed day including today', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: const [],
        now: sp(2026, 10, 3, 8),
      );
      expect(snapshot.daysElapsed, 3);
      expect(snapshot.balanceMinor, 27000);
      expect(snapshot.spentTodayMinor, 0);
      expect(snapshot.availableTodayMinor, 27000);
      expect(snapshot.status, PiggyBankStatus.green);
      expect(snapshot.debtDays, isNull);
    });

    test('subtracts eligible outflows and carries debt into later days', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'a', amount: 20000, at: sp(2026, 10, 1, 15)),
        ],
        now: sp(2026, 10, 2, 9),
      );
      expect(snapshot.balanceMinor, 18000 - 20000);
      expect(snapshot.debtDays, 1);
      expect(snapshot.status, PiggyBankStatus.red);
      expect(snapshot.history.last.balanceMinor, -2000);
    });

    test('yellow when balance is non-negative but under 20% of the daily', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'a', amount: 8000, at: sp(2026, 10, 1, 10)),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.balanceMinor, 1000);
      expect(snapshot.status, PiggyBankStatus.yellow);
      expect(snapshot.spentTodayMinor, 8000);
    });

    test('green at the 20% threshold', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'a', amount: 7200, at: sp(2026, 10, 1, 10)),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.balanceMinor, 1800);
      expect(snapshot.status, PiggyBankStatus.green);
    });

    test('refund of an eligible purchase returns money to the piggy', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'buy',
            amount: 5000,
            at: sp(2026, 10, 1, 11),
            description: 'RESTAURANTE X',
          ),
          expense(
            id: 'back',
            amount: 5000,
            at: sp(2026, 10, 1, 16),
            description: 'Estorno RESTAURANTE X',
            direction: TransactionDirection.inflow,
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 0);
      expect(snapshot.balanceMinor, 9000);
      expect(snapshot.status, PiggyBankStatus.green);
    });

    test('refund of a fixed bill stays outside the piggy', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'condo',
            amount: 80000,
            at: sp(2026, 10, 1, 9),
            description: 'Condomínio bloco B',
          ),
          expense(
            id: 'back',
            amount: 80000,
            at: sp(2026, 10, 1, 12),
            description: 'Estorno condomínio bloco B',
            direction: TransactionDirection.inflow,
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 0);
      expect(snapshot.balanceMinor, 9000);
    });

    test('dedupes the pipeline fingerprint', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'n1',
            amount: 4290,
            at: sp(2026, 10, 1, 13),
            description: 'RESTAURANTE X',
            fingerprint: 'notif:br.com.intermedium|1',
          ),
          expense(
            id: 'n2',
            amount: 4290,
            at: sp(2026, 10, 1, 13, ),
            description: 'RESTAURANTE X',
            fingerprint: 'notif:br.com.intermedium|1',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 4290);
      expect(snapshot.balanceMinor, 9000 - 4290);
    });

    test('card purchase plus payment notice counts once', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'card',
            amount: 4290,
            at: sp(2026, 10, 1, 13),
            description: 'RESTAURANTE X',
            fingerprint: 'notif:card-1',
          ),
          expense(
            id: 'pay',
            amount: 4290,
            at: sp(2026, 10, 1, 13, 5),
            description: 'Pagamento de R\$ 42,90 aprovado Cartão final 1234',
            fingerprint: 'notif:pay-1',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 4290);
    });

    test('same merchant imported twice on the same day counts once', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'push',
            amount: 3190,
            at: sp(2026, 10, 1, 13),
            description: 'UBER',
            fingerprint: 'notif:uber-1',
          ),
          expense(
            id: 'ofx',
            amount: 3190,
            at: sp(2026, 10, 1, 13, 2),
            description: 'UBER',
            fingerprint: 'ofx:fit-uber',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 3190);
    });

    test('two manual purchases with the same amount both count', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'a', amount: 1500, at: sp(2026, 10, 1, 10), description: 'Padaria'),
          expense(id: 'b', amount: 1500, at: sp(2026, 10, 1, 16), description: 'Padaria'),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 3000);
    });

    test('excludes fixed bills, flagged rows and chosen categories', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(excluded: const ['cat_housing']),
        inputs: [
          expense(id: 'phi', amount: 40000, at: sp(2026, 10, 1, 8), description: 'PHI mensal'),
          expense(id: 'claro', amount: 9900, at: sp(2026, 10, 1, 8), description: 'Claro fibra'),
          expense(id: 'sub', amount: 2190, at: sp(2026, 10, 1, 8), description: 'Assinatura streaming'),
          expense(id: 'bill', amount: 50000, at: sp(2026, 10, 1, 8), description: 'Pagamento de fatura'),
          expense(id: 'xfer', amount: 10000, at: sp(2026, 10, 1, 8), description: 'Transferência entre contas próprias'),
          expense(id: 'flag', amount: 3000, at: sp(2026, 10, 1, 9), excluded: true),
          expense(id: 'rent', amount: 200000, at: sp(2026, 10, 1, 9), categoryId: 'cat_housing', description: 'Aluguel'),
          expense(id: 'food', amount: 2500, at: sp(2026, 10, 1, 12), description: 'Almoço'),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 2500);
      expect(snapshot.todayExpenses.where((line) => line.counts), hasLength(1));
    });

    test('installment purchase counts the total on the purchase day', () {
      final total = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'parcel',
            amount: 3000,
            at: sp(2026, 10, 1, 14),
            description: 'Loja',
            notificationText: 'Compra aprovada 3x de R\$ 30,00 em Loja',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(total.spentTodayMinor, 9000);
      expect(total.balanceMinor, 0);
      expect(total.status, PiggyBankStatus.yellow);

      final installmentOnly = PiggyBankCalculator.evaluate(
        config: config(installmentTotal: false),
        inputs: [
          expense(
            id: 'parcel',
            amount: 3000,
            at: sp(2026, 10, 1, 14),
            description: 'Loja',
            notificationText: 'Compra aprovada 3x de R\$ 30,00 em Loja',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(installmentOnly.spentTodayMinor, 3000);
    });

    test('stated total in "em 3x" is not multiplied again', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'parcel',
            amount: 9000,
            at: sp(2026, 10, 1, 14),
            description: 'Loja',
            notificationText: 'Compra de R\$ 90,00 em 3x na Loja',
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 9000);
    });

    test('dataFim yields the required daily pace and freezes after the end', () {
      final mid = PiggyBankCalculator.evaluate(
        config: config(end: DateTime.utc(2026, 10, 10)),
        inputs: const [],
        now: sp(2026, 10, 5, 12),
      );
      expect(mid.daysElapsed, 5);
      expect(mid.balanceMinor, 45000);
      expect(mid.daysRemaining, 5);
      expect(mid.requiredPaceMinor, 18000);

      final after = PiggyBankCalculator.evaluate(
        config: config(end: DateTime.utc(2026, 10, 10)),
        inputs: [
          expense(id: 'late', amount: 5000, at: sp(2026, 10, 12, 12)),
        ],
        now: sp(2026, 10, 12, 12),
      );
      expect(after.daysElapsed, 10);
      expect(after.balanceMinor, 90000);
      expect(after.requiredPaceMinor, isNull);
      expect(after.daysRemaining, isNull);
    });

    test('São Paulo midnight rolls the credit, not UTC midnight', () {
      final before = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: const [],
        now: DateTime.utc(2026, 10, 2, 2, 59),
      );
      expect(PiggyBankCalendar.civilDate(DateTime.utc(2026, 10, 2, 2, 59)), DateTime.utc(2026, 10, 1));
      expect(before.daysElapsed, 1);
      expect(before.balanceMinor, 9000);

      final after = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: const [],
        now: DateTime.utc(2026, 10, 2, 3),
      );
      expect(after.daysElapsed, 2);
      expect(after.balanceMinor, 18000);
    });

    test('amount override replaces the counted value', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'a',
            amount: 8000,
            at: sp(2026, 10, 1, 11),
            overrideMinor: 1000,
          ),
        ],
        now: sp(2026, 10, 1, 18),
      );
      expect(snapshot.spentTodayMinor, 1000);
    });

    test('burst reports how many days the last purchase cost', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'big', amount: 20700, at: sp(2026, 10, 1, 15), description: 'Mercado'),
        ],
        now: sp(2026, 10, 1, 16),
      );
      expect(snapshot.status, PiggyBankStatus.red);
      expect(snapshot.burstDayCost, closeTo(2.3, 0.001));
      expect(PiggyMoney.daysCost(snapshot.burstDayCost!), 'essa compra custou 2,3 dias');
      expect(snapshot.debtDays, 2);
    });

    test('salary inflow does not change the piggy', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(
            id: 'pay',
            amount: 500000,
            at: sp(2026, 10, 1, 9),
            description: 'Você recebeu um Pix',
            direction: TransactionDirection.inflow,
          ),
        ],
        now: sp(2026, 10, 1, 12),
      );
      expect(snapshot.balanceMinor, 9000);
      expect(snapshot.todayExpenses, isEmpty);
    });

    test('last seven days are civil dates ending today', () {
      final snapshot = PiggyBankCalculator.evaluate(
        config: config(),
        inputs: [
          expense(id: 'a', amount: 1000, at: sp(2026, 10, 3, 12)),
        ],
        now: sp(2026, 10, 3, 18),
      );
      expect(snapshot.last7SpentMinor, [0, 0, 0, 0, 0, 0, 1000]);
    });
  });

  group('FinanceNotificationExtractor installment', () {
    test('parses per-installment and total forms', () {
      final per = FinanceNotificationExtractor.tryParse(
        NotificationExtractInput(
          packageName: 'br.com.intermedium',
          title: 'Compra aprovada',
          text: '3x de R\$ 30,00 em LOJA',
          postedAt: DateTime.utc(2026, 10, 1, 15),
        ),
      );
      expect(per!.amountMinor, 3000);
      expect(per.installmentCount, 3);
      expect(per.amountIsPerInstallment, isTrue);

      final total = FinanceNotificationExtractor.tryParse(
        NotificationExtractInput(
          packageName: 'br.com.intermedium',
          title: 'Compra aprovada',
          text: 'R\$ 90,00 em 3x na LOJA',
          postedAt: DateTime.utc(2026, 10, 1, 15),
        ),
      );
      expect(total!.amountMinor, 9000);
      expect(total.installmentCount, 3);
      expect(total.amountIsPerInstallment, isFalse);
    });
  });

  test('alert only when a previous non-red status crosses into red', () {
    expect(
      PiggyPublishPolicy.shouldAlert(
        alertWhenRed: true,
        status: PiggyBankStatus.red,
        previousStatus: 'green',
      ),
      isTrue,
    );
    expect(
      PiggyPublishPolicy.shouldAlert(
        alertWhenRed: true,
        status: PiggyBankStatus.red,
        previousStatus: 'red',
      ),
      isFalse,
    );
    expect(
      PiggyPublishPolicy.shouldAlert(
        alertWhenRed: true,
        status: PiggyBankStatus.red,
        previousStatus: null,
      ),
      isFalse,
    );
  });
}
