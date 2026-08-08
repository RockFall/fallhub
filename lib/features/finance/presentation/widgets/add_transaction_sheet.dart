import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/finance_controllers.dart';
import '../../application/finance_providers.dart';
import 'transaction_category_picker.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  EntityId? _accountId;
  TransactionDirection _direction = TransactionDirection.outflow;
  DateTime _occurredAt = DateTime.now().toUtc();
  TransactionCategory? _category;
  String? _descriptionError;
  String? _amountError;
  String? _accountError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _validate() {
    final accounts = ref.read(financialAccountsProvider).asData?.value ?? const [];
    final accountId = _accountId ?? (accounts.length == 1 ? accounts.first.id : null);
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    setState(() {
      _descriptionError =
          description.isEmpty ? AppStrings.financeDescriptionRequired : null;
      _amountError = amount == null || amount <= 0
          ? AppStrings.financeAmountInvalid
          : null;
      _accountError =
          accountId == null ? AppStrings.financeAccountRequired : null;
    });

    return _descriptionError == null &&
        _amountError == null &&
        _accountError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final accounts = ref.read(financialAccountsProvider).asData?.value ?? const [];
    final accountId = _accountId ?? (accounts.length == 1 ? accounts.first.id : null);
    if (accountId == null) {
      setState(() {
        _accountError = AppStrings.financeAccountRequired;
      });
      return;
    }

    final profile = await ref.read(repositoriesProvider).profiles.getActive();
    if (profile == null) return;

    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amountMajor = double.parse(amountText);
    final amountMinor = (amountMajor * 100).round();

    final account = ref
        .read(financialAccountsProvider)
        .asData
        ?.value
        .where((a) => a.id == accountId)
        .firstOrNull;

    final tx = await ref.read(financeControllerProvider.notifier).addTransaction(
          accountId: accountId,
          occurredAt: _occurredAt,
          description: _descriptionController.text.trim(),
          amountMinor: amountMinor,
          currency: account?.currency ?? profile.baseCurrency,
          direction: _direction,
          categoryId: _category == null
              ? null
              : TransactionCategoryPolicy.categoryIdFor(_category!),
        );

    if (!mounted || tx == null) return;
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt.toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _occurredAt = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(financialAccountsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.financeAddTransaction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            accountsAsync.when(
              data: (accounts) {
                final selectedId =
                    _accountId ?? (accounts.length == 1 ? accounts.first.id : null);
                return DropdownButtonFormField<EntityId>(
                  value: selectedId,
                decoration: InputDecoration(
                  labelText: AppStrings.financeAccount,
                  errorText: _accountError,
                ),
                items: accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _accountId = value),
              );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppStrings.financeDescription,
                errorText: _descriptionError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
              ],
              decoration: InputDecoration(
                labelText: AppStrings.financeAmount,
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            SegmentedButton<TransactionDirection>(
              segments: [
                ButtonSegment(
                  value: TransactionDirection.inflow,
                  label: Text(AppStrings.financeDirectionInflow),
                  icon: const Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionDirection.outflow,
                  label: Text(AppStrings.financeDirectionOutflow),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) {
                setState(() {
                  _direction = selection.first;
                  final allowed = TransactionCategoryPolicy.categoriesForDirection(
                    _direction,
                  );
                  if (_category != null && !allowed.contains(_category)) {
                    _category = null;
                  }
                });
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TransactionCategoryPicker(
              direction: _direction,
              selected: _category,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: ColonySpacing.md),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(AppStrings.financeOccurredAt(_occurredAt)),
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
