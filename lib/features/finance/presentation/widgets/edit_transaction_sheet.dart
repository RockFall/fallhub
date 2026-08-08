import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/finance_controllers.dart';
import '../../application/finance_providers.dart';
import 'transaction_category_picker.dart';

class EditTransactionSheet extends ConsumerStatefulWidget {
  const EditTransactionSheet({super.key, required this.transaction});

  final LedgerTransaction transaction;

  static Future<void> show(
    BuildContext context,
    LedgerTransaction transaction,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditTransactionSheet(transaction: transaction),
    );
  }

  @override
  ConsumerState<EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<EditTransactionSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late EntityId _accountId;
  late TransactionDirection _direction;
  late DateTime _occurredAt;
  TransactionCategory? _category;
  String? _descriptionError;
  String? _amountError;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _descriptionController = TextEditingController(text: tx.descriptionOriginal);
    _amountController = TextEditingController(
      text: (tx.amountMinor / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _accountId = tx.accountId;
    _direction = tx.direction;
    _occurredAt = tx.occurredAt;
    _category = TransactionCategoryPolicy.fromCategoryId(tx.categoryId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _validate() {
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    setState(() {
      _descriptionError =
          description.isEmpty ? AppStrings.financeDescriptionRequired : null;
      _amountError = amount == null || amount <= 0
          ? AppStrings.financeAmountInvalid
          : null;
      _accountError = _accountId.value.isEmpty
          ? AppStrings.financeAccountRequired
          : null;
    });

    return _descriptionError == null &&
        _amountError == null &&
        _accountError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amountMajor = double.parse(amountText);
    final amountMinor = (amountMajor * 100).round();

    final account = ref
        .read(financialAccountsProvider)
        .asData
        ?.value
        .where((a) => a.id == _accountId)
        .firstOrNull;

    final categoryId = _category == null
        ? null
        : TransactionCategoryPolicy.categoryIdFor(_category!);

    final updated = widget.transaction.copyWith(
      accountId: _accountId,
      occurredAt: _occurredAt,
      descriptionOriginal: _descriptionController.text.trim(),
      amountMinor: amountMinor,
      currency: account?.currency ?? widget.transaction.currency,
      direction: _direction,
      categoryId: categoryId,
      clearCategoryId: _category == null,
      updatedAt: DateTime.now().toUtc(),
    );

    final saved = await ref
        .read(financeControllerProvider.notifier)
        .updateTransaction(updated);

    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.financeDeleteTransaction),
        content: Text(AppStrings.financeDeleteTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.financeDeleteTransaction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await ref
        .read(financeControllerProvider.notifier)
        .deleteTransaction(widget.transaction.id);

    if (!mounted || !deleted) return;
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
              AppStrings.financeEditTransaction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            accountsAsync.when(
              data: (accounts) => DropdownButtonFormField<EntityId>(
                value: _accountId,
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
                onChanged: (value) {
                  if (value != null) setState(() => _accountId = value);
                },
              ),
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
            const SizedBox(height: ColonySpacing.sm),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(AppStrings.financeDeleteTransaction),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
