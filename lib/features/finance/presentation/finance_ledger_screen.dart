import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/localization/app_strings.dart';
import '../application/finance_controllers.dart';
import '../application/finance_providers.dart';
import 'widgets/create_financial_account_sheet.dart';
import 'widgets/create_category_budget_sheet.dart';
import 'widgets/edit_category_budget_sheet.dart';
import 'widgets/edit_financial_account_sheet.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/edit_transaction_sheet.dart';
import 'widgets/import_finance_csv_sheet.dart';

class FinanceLedgerScreen extends ConsumerStatefulWidget {
  const FinanceLedgerScreen({super.key});

  @override
  ConsumerState<FinanceLedgerScreen> createState() =>
      _FinanceLedgerScreenState();
}

class _FinanceLedgerScreenState extends ConsumerState<FinanceLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financeBootstrapProvider.notifier).ensureSeeded();
    });
  }

  Future<void> _exportCsv(BuildContext context) async {
    final csv =
        await ref.read(financeControllerProvider.notifier).exportTransactionsCsv();
    if (!context.mounted) return;
    if (csv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
      return;
    }
    if (csv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.financeExportCsvEmpty)),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: csv, subject: 'colony-finance.csv'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(financialAccountsProvider);
    final transactionsAsync = ref.watch(filteredLedgerTransactionsProvider);
    final showValues = ref.watch(financeShowValuesProvider);
    final balances = ref.watch(financeAccountBalancesProvider);
    final netWorth = ref.watch(financeNetWorthProvider);
    final netWorthMasked = ref.watch(financeNetWorthMaskedProvider);
    final budgetProgress = ref.watch(financeBudgetProgressProvider);
    final period = ref.watch(financePeriodFilterProvider);
    final accountFilter = ref.watch(financeAccountFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.financeLedgerTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: AppStrings.financeImportCsv,
                onPressed: () => ImportFinanceCsvSheet.show(context),
                icon: const Icon(Icons.upload_file_outlined),
              ),
              IconButton(
                tooltip: AppStrings.financeExportCsv,
                onPressed: () => _exportCsv(context),
                icon: const Icon(Icons.table_rows_outlined),
              ),
              IconButton(
                tooltip: showValues
                    ? AppStrings.financeHideValues
                    : AppStrings.financeShowValues,
                onPressed: () =>
                    ref.read(financeShowValuesProvider.notifier).toggle(),
                icon: Icon(
                  showValues ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          _FinanceDisclaimerBanner(),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (accounts) => transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
                data: (transactions) {
                  final activeAccounts =
                      accounts.where((a) => !a.isArchived).toList();
                  if (activeAccounts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppStrings.financeAccountsEmpty),
                          const SizedBox(height: ColonySpacing.sm),
                          Text(
                            AppStrings.financeAccountsEmptyHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  final recent = transactions.take(40).toList();

                  return ListView(
                    children: [
                      Text(
                        AppStrings.financeNetWorthSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      _NetWorthCard(
                        totals: netWorth,
                        masked: netWorthMasked,
                      ),
                      const SizedBox(height: ColonySpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.financeBudgetsSection,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                CreateCategoryBudgetSheet.show(context),
                            child: Text(AppStrings.financeNewBudget),
                          ),
                        ],
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      _BudgetsPanel(
                        progress: budgetProgress,
                        showValues: showValues,
                      ),
                      const SizedBox(height: ColonySpacing.lg),
                      Text(
                        AppStrings.financeAccountsSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      ...activeAccounts.map((account) {
                        final balance = balances[account.id.value] ?? 0;
                        final masked = FinanceDisplayPolicy.shouldMask(
                          account: account,
                          showValues: showValues,
                        );
                        final subtitleParts = [
                          AppStrings.financeAccountTypeLabel(account.type),
                          account.institution,
                          if (!account.includeInNetWorth)
                            AppStrings.financeNetWorthExcludedHint,
                        ];
                        return Card(
                          margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                          child: ListTile(
                            title: Text(account.name),
                            subtitle: Text(subtitleParts.join(' · ')),
                            trailing: Text(
                              FinanceDisplayPolicy.formatAmountMinor(
                                amountMinor: balance,
                                currency: account.currency,
                                masked: masked,
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () =>
                                EditFinancialAccountSheet.show(context, account),
                          ),
                        );
                      }),
                      const SizedBox(height: ColonySpacing.lg),
                      Text(
                        AppStrings.financeRecentTransactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      Wrap(
                        spacing: ColonySpacing.sm,
                        children: [
                          for (final option in FinancePeriod.values)
                            ChoiceChip(
                              label: Text(AppStrings.financePeriodLabel(option)),
                              selected: period == option,
                              onSelected: (_) => ref
                                  .read(financePeriodFilterProvider.notifier)
                                  .select(option),
                            ),
                        ],
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      DropdownButtonFormField<String?>(
                        value: accountFilter?.value,
                        decoration: const InputDecoration(
                          labelText: AppStrings.financeFilterAccount,
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(AppStrings.financeFilterAllAccounts),
                          ),
                          ...activeAccounts.map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id.value,
                              child: Text(account.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => ref
                            .read(financeAccountFilterProvider.notifier)
                            .select(value == null ? null : EntityId(value)),
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      if (recent.isEmpty)
                        Text(AppStrings.financeFilterEmpty)
                      else
                        ...recent.map((tx) {
                          final account = accounts.firstWhere(
                            (a) => a.id == tx.accountId,
                          );
                          final masked = FinanceDisplayPolicy.shouldMask(
                            account: account,
                            showValues: showValues,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tx.descriptionOriginal),
                            subtitle: Text(
                              AppStrings.financeTransactionSubtitle(
                                accountName: account.name,
                                occurredAt: tx.occurredAt,
                                category: TransactionCategoryPolicy.fromCategoryId(
                                  tx.categoryId,
                                ),
                              ),
                            ),
                            trailing: Text(
                              FinanceDisplayPolicy.formatSignedAmountMinor(
                                signedAmountMinor: tx.signedAmountMinor,
                                currency: tx.currency,
                                masked: masked,
                              ),
                            ),
                            onTap: () => EditTransactionSheet.show(context, tx),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CreateFinancialAccountSheet.show(context),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: Text(AppStrings.financeNewAccount),
                ),
              ),
              const SizedBox(width: ColonySpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: accountsAsync.asData?.value.isNotEmpty ?? false
                      ? () => AddTransactionSheet.show(context)
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.financeAddTransaction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetsPanel extends ConsumerWidget {
  const _BudgetsPanel({
    required this.progress,
    required this.showValues,
  });

  final List<BudgetProgress> progress;
  final bool showValues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.financeBudgetsEmpty),
          const SizedBox(height: ColonySpacing.xs),
          Text(
            AppStrings.financeBudgetsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...progress.map((item) {
          final category = TransactionCategoryPolicy.fromCategoryId(
            item.budget.categoryId,
          );
          final label = category == null
              ? item.budget.categoryId.value
              : AppStrings.financeCategoryLabel(category);
          final spentText = FinanceDisplayPolicy.formatAmountMinor(
            amountMinor: item.spentMinor,
            currency: item.budget.currency,
            masked: !showValues,
          );
          final limitText = FinanceDisplayPolicy.formatAmountMinor(
            amountMinor: item.budget.limitAmountMinor,
            currency: item.budget.currency,
            masked: !showValues,
          );
          final barColor = item.isOverLimit
              ? ColonyColors.statusCritical
              : ColonyColors.statusGood;
          return Card(
            margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(ColonySpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        item.isOverLimit
                            ? AppStrings.financeBudgetOverLimit
                            : AppStrings.financeBudgetWithinLimit,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: barColor,
                            ),
                      ),
                      IconButton(
                        tooltip: AppStrings.financeEditBudget,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => EditCategoryBudgetSheet.show(
                          context,
                          item.budget,
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.delete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => ref
                            .read(financeControllerProvider.notifier)
                            .deleteBudget(item.budget.id),
                      ),
                    ],
                  ),
                  Text('$spentText / $limitText'),
                  const SizedBox(height: ColonySpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.ratio.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: barColor,
                      backgroundColor: ColonyColors.borderStandard,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.totals,
    required this.masked,
  });

  final List<NetWorthByCurrency> totals;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        border: Border.all(color: ColonyColors.borderHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totals.isEmpty)
            Text(
              AppStrings.financeNetWorthEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...totals.map(
              (total) => Padding(
                padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                child: Text(
                  FinanceDisplayPolicy.formatAmountMinor(
                    amountMinor: total.totalMinor,
                    currency: total.currency,
                    masked: masked,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          Text(
            AppStrings.financeNetWorthHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FinanceDisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        border: Border.all(color: ColonyColors.borderStandard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: ColonyColors.textMuted,
          ),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(
            child: Text(
              AppStrings.financeDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
