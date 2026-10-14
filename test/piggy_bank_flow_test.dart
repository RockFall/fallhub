import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:fallhub/features/finance/application/piggy_bank_sync.dart';
import 'package:fallhub/features/finance/application/piggy_widget_sink.dart';
import 'package:fallhub/features/integrations/application/notification_capture_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed-app inbox drain books an Inter spend and updates the widget', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 10, 14, 15);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'id-$i')),
      clock: () => now,
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.integrations.setConsentEnabled(
      profileId: profile.id,
      kind: IntegrationKind.notificationListener,
      enabled: true,
    );
    final platform = FakeNotificationCapturePlatform(
      android: true,
      listenerEnabled: true,
      inbox: [
        NotificationCapturePayload(
          nativeKey: 'br.com.intermedium|compra-1',
          packageName: 'br.com.intermedium',
          title: 'Compra aprovada',
          text: 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
          postedAt: now,
        ),
      ],
    );
    final sink = MemoryPiggyWidgetSink();
    final evaluation = await PiggyClosedAppSync(
      repositories: repos,
      sink: sink,
      now: () => now,
      platform: platform,
    ).drainAndPublish();

    expect(platform.inbox, isEmpty);
    final transactions = await repos.finance.listTransactions(profile.id);
    expect(transactions, hasLength(1));
    expect(transactions.single.fingerprint, 'notif:br.com.intermedium|compra-1');
    expect(transactions.single.amountMinor, 4290);
    expect(evaluation, isNotNull);
    expect(evaluation!.snapshot.spentTodayMinor, 4290);
    expect(evaluation.snapshot.balanceMinor, 9000 - 4290);
    expect(evaluation.snapshot.availableTodayMinor, 9000 - 4290);
    expect(sink.last, isNotNull);
    expect(sink.last!.balanceLabel, 'R\$ 47,10');
    expect(sink.last!.spentTodayLabel, contains('42,90'));
    expect(sink.last!.statusName, 'green');

    final again = await PiggyClosedAppSync(
      repositories: repos,
      sink: sink,
      now: () => now,
      platform: FakeNotificationCapturePlatform(
        android: true,
        inbox: [
          NotificationCapturePayload(
            nativeKey: 'br.com.intermedium|compra-1',
            packageName: 'br.com.intermedium',
            title: 'Compra aprovada',
            text: 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
            postedAt: now,
          ),
        ],
      ),
    ).drainAndPublish();
    expect(await repos.finance.listTransactions(profile.id), hasLength(1));
    expect(again!.snapshot.balanceMinor, 9000 - 4290);
  });

  test('manual ledger outflow and a refund update the same snapshot', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 10, 14, 18);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'm-$i')),
      clock: () => now,
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.finance.seedDefaults(profile.id);
    final entity = (await repos.finance.listEntities(profile.id)).single;
    final account = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Inter',
      name: 'Conta',
      type: FinancialAccountType.checking,
      currency: 'BRL',
    );
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: now,
      descriptionOriginal: 'Padaria',
      amountMinor: 2000,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
    );
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: now,
      descriptionOriginal: 'Estorno padaria',
      amountMinor: 500,
      currency: 'BRL',
      direction: TransactionDirection.inflow,
    );
    final sink = MemoryPiggyWidgetSink();
    final evaluation = await PiggyClosedAppSync(
      repositories: repos,
      sink: sink,
      now: () => now,
    ).applyPayloads(const []);
    expect(evaluation!.snapshot.spentTodayMinor, 1500);
    expect(evaluation.snapshot.balanceMinor, 7500);
  });
}
