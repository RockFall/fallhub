import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification ingest', () {
    late ColonyDatabase db;
    late ColonyRepositories repos;
    late ColonyProfile profile;

    setUp(() async {
      db = ColonyDatabase.inMemory();
      repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(List.generate(80, (i) => 'id-$i')),
        clock: () => DateTime.utc(2026, 8, 20, 12),
      );
      profile = await repos.profiles.create(
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
    });

    tearDown(() async {
      await db.close();
    });

    NotificationCapturePayload payload({
      String nativeKey = 'br.com.intermedium|1',
      String packageName = 'br.com.intermedium',
      String title = 'Compra aprovada',
      String text = 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
    }) {
      return NotificationCapturePayload(
        nativeKey: nativeKey,
        packageName: packageName,
        title: title,
        text: text,
        postedAt: DateTime.utc(2026, 8, 20, 15, 30),
      );
    }

    test('books Inter credit-card spend on Inter Cartão', () async {
      final result = await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(),
      );
      expect(result.skipped, isFalse);
      expect(result.duplicate, isFalse);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.amountMinor, 4290);
      expect(result.transaction!.direction, TransactionDirection.outflow);
      expect(result.transaction!.fingerprint, 'notif:br.com.intermedium|1');
      final accounts = await repos.finance.listAccounts(profile.id);
      final card = accounts.singleWhere(
        (a) => a.type == FinancialAccountType.creditCard,
      );
      expect(card.name, 'Inter Cartão');
      expect(result.transaction!.accountId, card.id);
    });

    test('books Pix sent on Inter Conta checking', () async {
      final result = await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(
          nativeKey: 'pix-1',
          title: 'Pix enviado',
          text: 'Pix de R\$ 50,00 enviado para Maria Silva',
        ),
      );
      expect(result.transaction!.amountMinor, 5000);
      final account = await repos.finance.getAccountById(
        result.transaction!.accountId,
      );
      expect(account!.type, FinancialAccountType.checking);
      expect(account.name, 'Inter Conta');
    });

    test('skips OTP without persisting', () async {
      final result = await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(
          nativeKey: 'otp-1',
          title: '123456',
          text: '',
        ),
      );
      expect(result.skipped, isTrue);
      expect(await repos.integrations.listCapturedNotifications(profile.id), isEmpty);
      expect(await repos.finance.listTransactions(profile.id), isEmpty);
    });

    test('duplicate nativeKey does not create a second ledger row', () async {
      await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(),
      );
      final again = await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(),
      );
      expect(again.duplicate, isTrue);
      expect(await repos.finance.listTransactions(profile.id), hasLength(1));
      expect(
        await repos.integrations.listCapturedNotifications(profile.id),
        hasLength(1),
      );
    });

    test('revoking consent does not wipe ledger', () async {
      await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(),
      );
      await repos.integrations.setConsentEnabled(
        profileId: profile.id,
        kind: IntegrationKind.notificationListener,
        enabled: false,
      );
      expect(await repos.finance.listTransactions(profile.id), hasLength(1));
      expect(
        () => repos.integrations.ingestCapturedNotification(
          profileId: profile.id,
          payload: payload(nativeKey: 'other'),
        ),
        throwsStateError,
      );
    });

    test('stores unknown notifications without a ledger row', () async {
      final result = await repos.integrations.ingestCapturedNotification(
        profileId: profile.id,
        payload: payload(
          nativeKey: 'wa-1',
          packageName: 'com.whatsapp',
          title: 'Oi',
          text: 'vamos jantar?',
        ),
      );
      expect(result.transaction, isNull);
      expect(result.notification!.extractorKind, NotificationExtractorKind.unknown);
      expect(await repos.finance.listTransactions(profile.id), isEmpty);
    });
  });

  group('Inter statement import', () {
    test('planCsvImport accepts Inter semicolon CSV with account override',
        () async {
      final db = ColonyDatabase.inMemory();
      addTearDown(db.close);
      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(List.generate(20, (i) => 'csv-$i')),
        clock: () => DateTime.utc(2026, 8, 20, 12),
      );
      final profile = await repos.profiles.create(
        colonyName: 'Test',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
      );
      final accounts = await repos.finance.ensureInterAccounts(profile.id);
      final checking = accounts.firstWhere(
        (a) => a.type == FinancialAccountType.checking,
      );
      const csv = '''
Data Lançamento;Histórico;Descrição;Valor
01/08/2026;PIX ENVIADO;Maria;-50,00
02/08/2026;PIX RECEBIDO;João;1.200,00
''';
      final preview = InterStatementCodec.parse(
        csv,
        accountId: checking.id.value,
      );
      final plan = await repos.finance.planCsvImport(
        profileId: profile.id,
        preview: preview,
      );
      expect(plan.importCount, 2);
      final applied = await repos.finance.applyCsvImport(
        profileId: profile.id,
        plan: plan,
      );
      expect(applied.importCount, 2);
      final txs = await repos.finance.listTransactions(profile.id);
      expect(txs, hasLength(2));
      expect(txs.every((t) => t.accountId == checking.id), isTrue);
    });
  });
}
