import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/finance_controllers.dart';

class EditCategoryBudgetSheet extends ConsumerStatefulWidget {
  const EditCategoryBudgetSheet({super.key, required this.budget});

  final CategoryBudget budget;

  static Future<void> show(BuildContext context, CategoryBudget budget) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditCategoryBudgetSheet(budget: budget),
    );
  }

  @override
  ConsumerState<EditCategoryBudgetSheet> createState() =>
      _EditCategoryBudgetSheetState();
}

class _EditCategoryBudgetSheetState
    extends ConsumerState<EditCategoryBudgetSheet> {
  late final TextEditingController _limitController;
  String? _limitError;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: (widget.budget.limitAmountMinor / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool _validate() {
    final text = _limitController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);
    setState(() {
      _limitError = amount == null || amount <= 0
          ? AppStrings.financeAmountInvalid
          : null;
    });
    return _limitError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final amountText = _limitController.text.trim().replaceAll(',', '.');
    final amount = double.parse(amountText);
    final limitMinor = (amount * 100).round();

    final updated = await ref.read(financeControllerProvider.notifier).updateBudget(
          widget.budget.copyWith(limitAmountMinor: limitMinor),
        );
    if (!mounted) return;
    if (updated != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategoryPolicy.fromCategoryId(
      widget.budget.categoryId,
    );
    final categoryLabel = category == null
        ? widget.budget.categoryId.value
        : AppStrings.financeCategoryLabel(category);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.financeEditBudget,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            categoryLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _limitController,
            decoration: InputDecoration(
              labelText: AppStrings.financeBudgetLimit,
              errorText: _limitError,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: _save,
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
