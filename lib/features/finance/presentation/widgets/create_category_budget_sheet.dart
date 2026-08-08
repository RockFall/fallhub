import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/finance_controllers.dart';

class CreateCategoryBudgetSheet extends ConsumerStatefulWidget {
  const CreateCategoryBudgetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateCategoryBudgetSheet(),
    );
  }

  @override
  ConsumerState<CreateCategoryBudgetSheet> createState() =>
      _CreateCategoryBudgetSheetState();
}

class _CreateCategoryBudgetSheetState
    extends ConsumerState<CreateCategoryBudgetSheet> {
  final _limitController = TextEditingController();
  TransactionCategory _category = TransactionCategory.food;
  String? _limitError;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _outflowCategories =>
      TransactionCategoryPolicy.categoriesForDirection(
        TransactionDirection.outflow,
      );

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
    final profile = await ref.read(repositoriesProvider).profiles.getActive();
    if (profile == null || !mounted) return;

    final amountText = _limitController.text.trim().replaceAll(',', '.');
    final amount = double.parse(amountText);
    final limitMinor = (amount * 100).round();

    final created = await ref.read(financeControllerProvider.notifier).createBudget(
          categoryId: TransactionCategoryPolicy.categoryIdFor(_category),
          currency: profile.baseCurrency,
          limitAmountMinor: limitMinor,
        );
    if (!mounted) return;
    if (created != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            AppStrings.financeNewBudget,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<TransactionCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: AppStrings.financeCategory,
            ),
            items: _outflowCategories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(AppStrings.financeCategoryLabel(c)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
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
