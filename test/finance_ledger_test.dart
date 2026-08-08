import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/finance/presentation/finance_ledger_screen.dart';

void main() {
  testWidgets('FinanceLedgerScreen shows disclaimer and empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'entity-1']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.financeAccountsEmpty), findsOneWidget);
    expect(find.text(AppStrings.financeNewAccount), findsOneWidget);
    expect(find.byIcon(Icons.table_rows_outlined), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen lists account and masks values by default',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
    await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Poupança',
      type: FinancialAccountType.savings,
      currency: 'BRL',
      currentBalanceMinor: 50000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Poupança'), findsOneWidget);
    expect(find.text(AppStrings.financeNetWorthSection), findsOneWidget);
    expect(find.text(AppStrings.financeBudgetsSection), findsOneWidget);
    expect(find.text(AppStrings.financeBudgetsEmpty), findsOneWidget);
    expect(find.text('••••'), findsAtLeastNWidgets(2));

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('500,00 BRL'), findsAtLeastNWidgets(2));

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen excludes account from net worth hint',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
    await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Investimento',
      type: FinancialAccountType.investment,
      currency: 'BRL',
      currentBalanceMinor: 100000,
      includeInNetWorth: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investimento'), findsOneWidget);
    expect(find.textContaining(AppStrings.financeNetWorthExcludedHint),
        findsOneWidget);
    expect(find.text(AppStrings.financeNetWorthEmpty), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen opens edit sheet and shows category',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'tx-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 8, 5),
      descriptionOriginal: 'Mercado',
      amountMinor: 8500,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.textContaining('Alimentação'), findsOneWidget);

    await tester.tap(find.text('Mercado'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeEditTransaction), findsOneWidget);
    expect(find.text(AppStrings.financeDeleteTransaction), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen opens edit account sheet on tap',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
    await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Poupança',
      type: FinancialAccountType.savings,
      currency: 'BRL',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poupança'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeEditAccount), findsOneWidget);
    expect(find.text(AppStrings.financeIncludeInNetWorth), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen archives account and hides from list',
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
        'event-1',
        'event-2',
        'event-3',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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
    await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Poupança',
      type: FinancialAccountType.savings,
      currency: 'BRL',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poupança'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.financeArchiveAccount));
    await tester.pumpAndSettle();

    expect(find.text('Poupança'), findsNothing);
    expect(find.text(AppStrings.financeAccountsEmpty), findsOneWidget);

    final accounts = await repos.finance.listAccounts(profile.id);
    expect(accounts.single.isArchived, isTrue);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen period filter hides old transactions',
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
        'tx-1',
        'tx-2',
        'event-1',
        'event-2',
        'event-3',
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
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 8, 6),
      descriptionOriginal: 'Recente',
      amountMinor: 1000,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
    );
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 5, 1),
      descriptionOriginal: 'Antiga',
      amountMinor: 2000,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financePeriod30d), findsOneWidget);
    expect(find.text('Recente'), findsOneWidget);
    expect(find.text('Antiga'), findsNothing);

    await tester.tap(find.text(AppStrings.financePeriodAll));
    await tester.pumpAndSettle();

    expect(find.text('Antiga'), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen shows budget over-limit chip', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DateTime clock() => DateTime.utc(2026, 8, 15, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'entity-1',
        'account-1',
        'event-1',
        'budget-1',
        'event-2',
        'tx-1',
        'event-3',
      ]),
      clock: clock,
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
      currentBalanceMinor: 0,
    );
    await repos.finance.createBudget(
      profileId: profile.id,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
      currency: 'BRL',
      limitAmountMinor: 1000,
    );
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 8, 10),
      descriptionOriginal: 'Almoço',
      amountMinor: 2500,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeBudgetsSection), findsOneWidget);
    expect(find.text(AppStrings.financeBudgetOverLimit), findsOneWidget);
    expect(find.text(AppStrings.financeCategoryLabel(TransactionCategory.food)),
        findsWidgets);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FinanceLedgerScreen edits budget limit', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DateTime clock() => DateTime.utc(2026, 8, 15, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'entity-1',
        'account-1',
        'event-1',
        'budget-1',
        'event-2',
        'event-3',
      ]),
      clock: clock,
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
    await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Corrente',
      type: FinancialAccountType.checking,
      currency: 'BRL',
      currentBalanceMinor: 0,
    );
    await repos.finance.createBudget(
      profileId: profile.id,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
      currency: 'BRL',
      limitAmountMinor: 10000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FinanceLedgerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.financeEditBudget));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.financeEditBudget), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.financeBudgetLimit),
      '250,00',
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pumpAndSettle();

    final budgets = await repos.finance.listBudgets(profile.id);
    expect(budgets, hasLength(1));
    expect(budgets.single.limitAmountMinor, 25000);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
