import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'finance_providers.dart';

class FinanceBootstrapController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> ensureSeeded() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) return;
      await ref.read(repositoriesProvider).finance.seedDefaults(profile.id);
      ref.invalidate(financialEntitiesProvider);
    });
  }
}

final financeBootstrapProvider =
    AsyncNotifierProvider<FinanceBootstrapController, void>(
  FinanceBootstrapController.new,
);

class FinanceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<FinancialAccount?> createAccount({
    required EntityId entityId,
    required String institution,
    required String name,
    required FinancialAccountType type,
    required String currency,
    int currentBalanceMinor = 0,
    bool includeInNetWorth = true,
    SensitiveDisplayMode sensitiveDisplayMode = SensitiveDisplayMode.hidden,
  }) async {
    state = const AsyncLoading();
    FinancialAccount? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).finance.createAccount(
            profileId: profile.id,
            entityId: entityId,
            institution: institution,
            name: name,
            type: type,
            currency: currency,
            currentBalanceMinor: currentBalanceMinor,
            includeInNetWorth: includeInNetWorth,
            sensitiveDisplayMode: sensitiveDisplayMode,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(financialAccountsProvider);
    return created;
  }

  Future<FinancialAccount?> updateAccount(FinancialAccount account) async {
    state = const AsyncLoading();
    FinancialAccount? updated;
    state = await AsyncValue.guard(() async {
      FinanceLedgerPolicy.validateAccountName(account.name);
      updated = await ref.read(repositoriesProvider).finance.saveAccount(account);
    });
    if (state.hasError) return null;
    ref.invalidate(financialAccountsProvider);
    return updated;
  }

  Future<FinancialAccount?> archiveAccount(FinancialAccount account) async {
    state = const AsyncLoading();
    FinancialAccount? archived;
    state = await AsyncValue.guard(() async {
      archived =
          await ref.read(repositoriesProvider).finance.archiveAccount(account);
    });
    if (state.hasError) return null;
    ref.invalidate(financialAccountsProvider);
    return archived;
  }

  Future<LedgerTransaction?> addTransaction({
    required EntityId accountId,
    required DateTime occurredAt,
    required String description,
    required int amountMinor,
    required String currency,
    required TransactionDirection direction,
    EntityId? categoryId,
    String? notes,
  }) async {
    state = const AsyncLoading();
    LedgerTransaction? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).finance.createTransaction(
            profileId: profile.id,
            accountId: accountId,
            occurredAt: occurredAt,
            descriptionOriginal: description,
            amountMinor: amountMinor,
            currency: currency,
            direction: direction,
            categoryId: categoryId,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(ledgerTransactionsProvider);
    return created;
  }

  Future<LedgerTransaction?> updateTransaction(LedgerTransaction transaction) async {
    state = const AsyncLoading();
    LedgerTransaction? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).finance.saveTransaction(
            transaction,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(ledgerTransactionsProvider);
    return updated;
  }

  Future<bool> deleteTransaction(EntityId id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).finance.deleteTransaction(id);
    });
    if (state.hasError) return false;
    ref.invalidate(ledgerTransactionsProvider);
    return true;
  }

  Future<CategoryBudget?> createBudget({
    required EntityId categoryId,
    required String currency,
    required int limitAmountMinor,
  }) async {
    state = const AsyncLoading();
    CategoryBudget? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).finance.createBudget(
            profileId: profile.id,
            categoryId: categoryId,
            currency: currency,
            limitAmountMinor: limitAmountMinor,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(categoryBudgetsProvider);
    return created;
  }

  Future<CategoryBudget?> updateBudget(CategoryBudget budget) async {
    state = const AsyncLoading();
    CategoryBudget? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).finance.saveBudget(budget);
    });
    if (state.hasError) return null;
    ref.invalidate(categoryBudgetsProvider);
    ref.invalidate(financeBudgetProgressProvider);
    return updated;
  }

  Future<bool> deleteBudget(EntityId id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).finance.deleteBudget(id);
    });
    if (state.hasError) return false;
    ref.invalidate(categoryBudgetsProvider);
    return true;
  }

  /// Builds CSV text for all ledger transactions (fingerprint included).
  Future<String?> exportTransactionsCsv() async {
    state = const AsyncLoading();
    String? csv;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      final txs =
          await ref.read(repositoriesProvider).finance.listTransactions(profile.id);
      if (txs.isEmpty) {
        csv = '';
        return;
      }
      csv = FinanceCsvCodec.encodeTransactions(txs);
    });
    if (state.hasError) return null;
    return csv;
  }

  /// Parses OFX, Inter CSV, or Colony CSV and returns a dedup plan.
  Future<FinanceCsvImportPlan?> planTransactionsCsv(
    String csvText, {
    EntityId? accountOverride,
  }) async {
    state = const AsyncLoading();
    FinanceCsvImportPlan? plan;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      final needsAccount = InterStatementCodec.looksLikeOfx(csvText) ||
          InterStatementCodec.looksLikeInterCsv(csvText);
      if (needsAccount && accountOverride == null) {
        throw const FormatException('needs_account');
      }
      final preview = InterStatementCodec.parse(
        csvText,
        accountId: accountOverride?.value ?? '',
      );
      plan = await ref.read(repositoriesProvider).finance.planCsvImport(
            profileId: profile.id,
            preview: preview,
            accountOverride: accountOverride,
          );
    });
    if (state.hasError) return null;
    return plan;
  }

  /// Persists rows from a previously planned import (fingerprint preserved).
  Future<FinanceCsvImportPlan?> applyTransactionsCsv(
    FinanceCsvImportPlan plan,
  ) async {
    state = const AsyncLoading();
    FinanceCsvImportPlan? applied;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      applied = await ref.read(repositoriesProvider).finance.applyCsvImport(
            profileId: profile.id,
            plan: plan,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(ledgerTransactionsProvider);
    ref.invalidate(filteredLedgerTransactionsProvider);
    ref.invalidate(financeAccountBalancesProvider);
    ref.invalidate(financeNetWorthProvider);
    ref.invalidate(financeBudgetProgressProvider);
    return applied;
  }

  /// Parses CSV and persists new rows; skips known fingerprints.
  Future<FinanceCsvImportPlan?> importTransactionsCsv(
    String csvText, {
    EntityId? accountOverride,
  }) async {
    final plan = await planTransactionsCsv(
      csvText,
      accountOverride: accountOverride,
    );
    if (plan == null) return null;
    return applyTransactionsCsv(plan);
  }

  Future<bool> ensureInterAccounts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      await ref.read(repositoriesProvider).finance.ensureInterAccounts(profile.id);
    });
    if (state.hasError) return false;
    ref.invalidate(financialAccountsProvider);
    ref.invalidate(financialEntitiesProvider);
    return true;
  }
}

final financeControllerProvider =
    AsyncNotifierProvider<FinanceController, void>(FinanceController.new);
