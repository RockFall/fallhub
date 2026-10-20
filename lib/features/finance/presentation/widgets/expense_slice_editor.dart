import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/finance_controllers.dart';
import '../../application/finance_providers.dart';

class ExpenseSliceEditor extends ConsumerWidget {
  const ExpenseSliceEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(financeExpenseMarkersProvider);
    return markers.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text(AppStrings.errorGeneric),
      data: (slices) {
        final encoded = FinanceExpenseMarkerPolicy.encodeField(slices);
        return _ExpenseSliceForm(
          key: ValueKey(encoded),
          initialText: encoded,
        );
      },
    );
  }
}

class _ExpenseSliceForm extends ConsumerStatefulWidget {
  const _ExpenseSliceForm({super.key, required this.initialText});

  final String initialText;

  @override
  ConsumerState<_ExpenseSliceForm> createState() => _ExpenseSliceFormState();
}

class _ExpenseSliceFormState extends ConsumerState<_ExpenseSliceForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.financeExpenseSliceTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          AppStrings.financeExpenseSliceHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: ColonySpacing.sm),
        TextField(
          key: const Key('finance.expenseSlices'),
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.financeExpenseSliceLabel,
            alignLabelWithHint: true,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('finance.expenseSlices.save'),
            onPressed: _save,
            child: const Text(AppStrings.financeExpenseSliceSave),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final parsed = FinanceExpenseMarkerPolicy.parseField(_controller.text);
    if (!parsed.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.financeExpenseSliceTooShort)),
      );
      return;
    }
    final saved = await ref
        .read(financeControllerProvider.notifier)
        .saveExpenseSlices(parsed.slices);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? AppStrings.financeExpenseSliceSaved
              : AppStrings.errorGeneric,
        ),
      ),
    );
  }
}
