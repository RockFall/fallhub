import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_fixtures.dart';

void main() {
  test('stores expense slices per profile', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 10, 20, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    expect(await repos.finance.listExpenseSlices(profile.id), isEmpty);

    await repos.finance.saveExpenseSlices(
      profileId: profile.id,
      slices: const [' Compra aprovada ', 'compra aprovada', 'Pix enviado'],
    );
    expect(
      await repos.finance.listExpenseSlices(profile.id),
      ['Compra aprovada', 'Pix enviado'],
    );
  });

  test('ingest books an expense only when the slice is in the notification',
      () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'id-$i')),
      clock: () => DateTime.utc(2026, 10, 20, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.integrations.setConsentEnabled(
      profileId: profile.id,
      kind: IntegrationKind.notificationListener,
      enabled: true,
    );
    await repos.finance.saveExpenseSlices(
      profileId: profile.id,
      slices: const ['compra aprovada'],
    );

    NotificationCapturePayload payload({
      required String nativeKey,
      required String title,
      required String text,
    }) {
      return NotificationCapturePayload(
        nativeKey: nativeKey,
        packageName: 'br.com.intermedium',
        title: title,
        text: text,
        postedAt: DateTime.utc(2026, 10, 20, 15),
      );
    }

    final purchase = await repos.integrations.ingestCapturedNotification(
      profileId: profile.id,
      payload: payload(
        nativeKey: 'buy-1',
        title: 'Compra aprovada',
        text: 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
      ),
    );
    expect(purchase.transaction, isNotNull);
    expect(purchase.transaction!.direction, TransactionDirection.outflow);

    final limit = await repos.integrations.ingestCapturedNotification(
      profileId: profile.id,
      payload: payload(
        nativeKey: 'limit-1',
        title: 'Limite',
        text: 'Seu limite agora é R\$ 5.000,00',
      ),
    );
    expect(limit.transaction, isNull);
    expect(limit.notification!.extractorKind, NotificationExtractorKind.unknown);

    final received = await repos.integrations.ingestCapturedNotification(
      profileId: profile.id,
      payload: payload(
        nativeKey: 'in-1',
        title: 'Pix recebido',
        text: 'Você recebeu um Pix de R\$ 20,00',
      ),
    );
    expect(received.transaction, isNotNull);
    expect(received.transaction!.direction, TransactionDirection.inflow);

    final txs = await repos.finance.listTransactions(profile.id);
    expect(txs, hasLength(2));
  });

  test('migration from v39 creates finance_expense_markers', () async {
    final db = await openMigratedFrom(39, seed: seedProfile);
    addTearDown(db.close);
    final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'finance_expense_markers'",
    ).get();
    expect(rows, hasLength(1));
  });
}
