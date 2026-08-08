import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class TransactionCategoryPicker extends StatelessWidget {
  const TransactionCategoryPicker({
    super.key,
    required this.direction,
    required this.selected,
    required this.onChanged,
  });

  final TransactionDirection direction;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategoryPolicy.categoriesForDirection(direction);

    return DropdownButtonFormField<TransactionCategory?>(
      value: selected != null && categories.contains(selected)
          ? selected
          : null,
      decoration: InputDecoration(
        labelText: AppStrings.financeCategory,
      ),
      items: [
        DropdownMenuItem<TransactionCategory?>(
          value: null,
          child: Text(AppStrings.financeCategoryNone),
        ),
        ...categories.map(
          (category) => DropdownMenuItem<TransactionCategory?>(
            value: category,
            child: Text(AppStrings.financeCategoryLabel(category)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
