import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/finance/presentation/widgets/import_finance_csv_sheet.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('ImportFinanceCsvSheet previews and applies CSV with snackbar',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'entity-1',
        'account-1',
        'event-acc',
        'tx-1',
        'event-tx',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));
    await repos.finance.seedDefaults(profile.id);
    final entity = (await repos.finance.listEntities(profile.id)).first;
    final account = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Corrente',
      type: FinancialAccountType.checking,
      currency: 'BRL',
    );

    final csv = [
      FinanceCsvCodec.headerColumns.join(','),
      '${account.id.value},2026-08-07T12:00:00.000Z,Padaria,1200,BRL,outflow,,',
    ].join('\n');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ImportFinanceCsvSheet.show(context),
                child: const Text('open-import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-import'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeImportCsv), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, csv);
    await tester.tap(find.text(AppStrings.financeImportCsvPreviewAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(AppStrings.financeImportCsvPlanSummary(1, 0)),
      findsOneWidget,
    );
    expect(find.text('• Padaria'), findsOneWidget);

    await tester.tap(find.text(AppStrings.financeImportCsvApplyAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(AppStrings.financeImportCsvResult(1, 0)),
      findsOneWidget,
    );

    final txs = await repos.finance.listTransactions(profile.id);
    expect(txs, hasLength(1));
    expect(txs.single.descriptionOriginal, 'Padaria');

    await _drainTimers(tester);
  });

  testWidgets('ImportFinanceCsvSheet shows invalid CSV error', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ImportFinanceCsvSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'a,b,c\n1,2,3');
    await tester.tap(find.text(AppStrings.financeImportCsvPreviewAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.financeImportCsvInvalid), findsOneWidget);

    await _drainTimers(tester);
  });

  testWidgets('ImportFinanceCsvSheet nothing-to-apply when all duplicates',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'entity-1',
        'account-1',
        'event-acc',
        'tx-1',
        'event-tx',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));
    await repos.finance.seedDefaults(profile.id);
    final entity = (await repos.finance.listEntities(profile.id)).first;
    final account = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Corrente',
      type: FinancialAccountType.checking,
      currency: 'BRL',
    );
    final existing = await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 8, 7, 12),
      descriptionOriginal: 'Padaria',
      amountMinor: 1200,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
    );

    final csv = FinanceCsvCodec.encodeTransactions([existing]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ImportFinanceCsvSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, csv);
    await tester.tap(find.text(AppStrings.financeImportCsvPreviewAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(AppStrings.financeImportCsvPlanSummary(0, 1)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.financeImportCsvApplyAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.financeImportCsvNothingToApply), findsOneWidget);

    await _drainTimers(tester);
  });

  testWidgets('ImportFinanceCsvSheet account override remaps destination',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'entity-1',
        'account-1',
        'event-acc1',
        'account-2',
        'event-acc2',
        'tx-1',
        'event-tx',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));
    await repos.finance.seedDefaults(profile.id);
    final entity = (await repos.finance.listEntities(profile.id)).first;
    final accountA = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Corrente',
      type: FinancialAccountType.checking,
      currency: 'BRL',
    );
    final accountB = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Poupança',
      type: FinancialAccountType.savings,
      currency: 'BRL',
    );

    final csv = [
      FinanceCsvCodec.headerColumns.join(','),
      '${accountA.id.value},2026-08-07T12:00:00.000Z,Override,990,BRL,outflow,,',
    ].join('\n');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ImportFinanceCsvSheet.show(context),
                child: const Text('open-import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-import'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Poupança').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, csv);
    await tester.tap(find.text(AppStrings.financeImportCsvPreviewAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(AppStrings.financeImportCsvPlanSummary(1, 0)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.financeImportCsvApplyAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final txs = await repos.finance.listTransactions(profile.id);
    expect(txs, hasLength(1));
    expect(txs.single.accountId, accountB.id);
    expect(txs.single.descriptionOriginal, 'Override');

    await _drainTimers(tester);
  });

  testWidgets('ImportFinanceCsvSheet shows empty error without apply',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ImportFinanceCsvSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final applyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.financeImportCsvApplyAction),
    );
    expect(applyButton.onPressed, isNull);

    await tester.tap(find.text(AppStrings.financeImportCsvPreviewAction));
    await tester.pump();

    expect(find.text(AppStrings.financeImportCsvEmpty), findsOneWidget);

    await _drainTimers(tester);
  });
}
