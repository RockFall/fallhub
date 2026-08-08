import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final financialEntitiesProvider =
    StreamProvider<List<FinancialEntity>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).finance.watchEntities(profile.id);
});

final financialAccountsProvider =
    StreamProvider<List<FinancialAccount>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).finance.watchAccounts(profile.id);
});

final ledgerTransactionsProvider =
    StreamProvider<List<LedgerTransaction>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).finance.watchTransactions(profile.id);
});

final financeShowValuesProvider =
    NotifierProvider<FinanceShowValuesNotifier, bool>(
  FinanceShowValuesNotifier.new,
);

class FinanceShowValuesNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void set(bool value) => state = value;
}

final financePeriodFilterProvider =
    NotifierProvider<FinancePeriodFilterNotifier, FinancePeriod>(
  FinancePeriodFilterNotifier.new,
);

class FinancePeriodFilterNotifier extends Notifier<FinancePeriod> {
  @override
  FinancePeriod build() => FinancePeriod.days30;

  void select(FinancePeriod period) => state = period;
}

final financeAccountFilterProvider =
    NotifierProvider<FinanceAccountFilterNotifier, EntityId?>(
  FinanceAccountFilterNotifier.new,
);

class FinanceAccountFilterNotifier extends Notifier<EntityId?> {
  @override
  EntityId? build() => null;

  void select(EntityId? accountId) => state = accountId;
}

final filteredLedgerTransactionsProvider =
    Provider<AsyncValue<List<LedgerTransaction>>>((ref) {
  final transactionsAsync = ref.watch(ledgerTransactionsProvider);
  final period = ref.watch(financePeriodFilterProvider);
  final accountId = ref.watch(financeAccountFilterProvider);

  return transactionsAsync.whenData(
    (transactions) => FinanceTransactionFilterPolicy.filter(
      transactions: transactions,
      period: period,
      accountId: accountId,
    ),
  );
});

final financeAccountBalancesProvider =
    Provider<Map<String, int>>((ref) {
  final accountsAsync = ref.watch(financialAccountsProvider);
  final transactionsAsync = ref.watch(ledgerTransactionsProvider);

  return accountsAsync.when(
    data: (accounts) => transactionsAsync.when(
      data: (transactions) {
        final byAccount = <String, List<LedgerTransaction>>{};
        for (final tx in transactions) {
          byAccount.putIfAbsent(tx.accountId.value, () => []).add(tx);
        }
        return {
          for (final account in accounts)
            account.id.value: FinanceLedgerPolicy.computeBalanceFromTransactions(
              account: account,
              transactions: byAccount[account.id.value] ?? const [],
            ),
        };
      },
      loading: () => const {},
      error: (_, __) => const {},
    ),
    loading: () => const {},
    error: (_, __) => const {},
  );
});

final financeNetWorthProvider = Provider<List<NetWorthByCurrency>>((ref) {
  final accountsAsync = ref.watch(financialAccountsProvider);
  final balances = ref.watch(financeAccountBalancesProvider);
  return accountsAsync.when(
    data: (accounts) => FinanceNetWorthPolicy.compute(
      accounts: accounts,
      balancesByAccountId: balances,
    ),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final financeNetWorthMaskedProvider = Provider<bool>((ref) {
  final accountsAsync = ref.watch(financialAccountsProvider);
  final showValues = ref.watch(financeShowValuesProvider);
  return accountsAsync.when(
    data: (accounts) => FinanceNetWorthPolicy.shouldMaskTotal(
      accounts: accounts,
      showValues: showValues,
    ),
    loading: () => true,
    error: (_, __) => true,
  );
});

final categoryBudgetsProvider =
    StreamProvider<List<CategoryBudget>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).finance.watchBudgets(profile.id);
});

final financeBudgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(categoryBudgetsProvider);
  final transactionsAsync = ref.watch(ledgerTransactionsProvider);
  final now = ref.watch(clockProvider)();
  return budgetsAsync.when(
    data: (budgets) => transactionsAsync.when(
      data: (transactions) => FinanceBudgetPolicy.computeProgress(
        budgets: budgets,
        transactions: transactions,
        now: now,
      ),
      loading: () => const [],
      error: (_, __) => const [],
    ),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final defaultFinancialEntityProvider = Provider<FinancialEntity?>((ref) {
  final entitiesAsync = ref.watch(financialEntitiesProvider);
  return entitiesAsync.when(
    data: (entities) {
      if (entities.isEmpty) return null;
      return entities.firstWhere(
        (e) => e.kind == FinancialEntityKind.personal,
        orElse: () => entities.first,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
